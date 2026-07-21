"""
Clean the price inputs for the Q2 cost model and Q3 variance analysis.

Input : data_raw/Weekly_Oil_Bulletin_Prices_History_maticni_4web.xlsx
        data_raw/nrg_pc_205__electricity_price_nonhousehold.csv
Output: data_clean/diesel_price_de_weekly.csv
        data_clean/electricity_price_de.csv

Decisions (see docs/data_notes.md):
- Diesel: German series only, both with-tax and without-tax, converted from
  EUR per 1000 litres to EUR per litre. Weekly, ascending by date.
  The sheet has ~25 footer rows of legends/disclaimers below the data; they
  are removed by requiring column 0 to parse as a real date.
- Electricity: Germany, EUR only. Consumption band (nrg_cons) and tax basis
  (tax) are KEPT as columns so the SQL layer can pick and run sensitivities.

Run from anywhere:  python src/clean_prices.py
"""

from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = REPO_ROOT / "data_raw"
CLEAN_DIR = REPO_ROOT / "data_clean"

OIL_XLSX = "Weekly_Oil_Bulletin_Prices_History_maticni_4web.xlsx"
ELEC_CSV = "nrg_pc_205__electricity_price_nonhousehold.csv"


def _de_diesel_series(raw: pd.DataFrame, col_name: str) -> pd.Series:
    """Pull the German diesel column out of one Oil Bulletin price sheet.

    The sheet has a stacked 3-row header: row 0 holds group labels like
    'DE_price_with_tax_diesel', row 1 product names, row 2 units ('1000 l').
    Data starts at row 3. We locate the column by its row-0 label rather
    than hardcoding an index, so a column insert upstream won't break us.
    """
    row0 = [str(x) for x in raw.iloc[0].tolist()]
    matches = [
        i for i, lab in enumerate(row0)
        if lab.startswith("DE_") and "diesel" in lab.lower()
    ]
    if not matches:
        raise ValueError("no DE diesel column found in this sheet")
    idx = matches[0]

    body = raw.iloc[3:, [0, idx]].copy()
    body.columns = ["date", col_name]

    # Real data rows are exactly those whose first cell is a date. This is
    # what drops the footer legends and the copyright block.
    body["date"] = pd.to_datetime(body["date"], errors="coerce")
    body = body.dropna(subset=["date"])

    # EUR per 1000 litres -> EUR per litre.
    body[col_name] = pd.to_numeric(body[col_name], errors="coerce") / 1000.0
    return body.dropna(subset=[col_name]).set_index("date")[col_name]


def clean_diesel() -> pd.DataFrame:
    xl = pd.ExcelFile(RAW_DIR / OIL_XLSX)
    with_tax = _de_diesel_series(
        pd.read_excel(xl, sheet_name="Prices with taxes", header=None),
        "price_with_tax_eur_per_l",
    )
    wo_tax = _de_diesel_series(
        pd.read_excel(xl, sheet_name="Prices wo taxes", header=None),
        "price_wo_tax_eur_per_l",
    )

    df = pd.concat([with_tax, wo_tax], axis=1).sort_index()
    df.index.name = "date"
    df = df.reset_index()
    df["date"] = df["date"].dt.date

    out = CLEAN_DIR / "diesel_price_de_weekly.csv"
    df.to_csv(out, index=False, encoding="utf-8-sig")
    print(f"diesel -> {out.name}: {len(df)} weekly rows, "
          f"{df.date.min()} to {df.date.max()}")
    return df


def clean_electricity() -> pd.DataFrame:
    src = RAW_DIR / ELEC_CSV
    raw = pd.read_csv(src).rename(columns={"geo\\TIME_PERIOD": "geo"})

    period_cols = [c for c in raw.columns if str(c)[:4].isdigit()]
    id_cols = [c for c in raw.columns if c not in period_cols]

    long = raw.melt(id_vars=id_cols, value_vars=period_cols,
                    var_name="period", value_name="price_eur_per_kwh")
    long = long.dropna(subset=["price_eur_per_kwh"])

    de = long[(long["geo"] == "DE") & (long["currency"] == "EUR")].copy()

    # 'period' looks like 2024-S1 -> split into year and semester.
    de["year"] = de["period"].str[:4].astype(int)
    de["semester"] = de["period"].str[-2:]

    de = de[["geo", "nrg_cons", "tax", "period", "year", "semester",
             "price_eur_per_kwh"]]
    de = de.sort_values(["nrg_cons", "tax", "year", "semester"])
    de = de.reset_index(drop=True)

    out = CLEAN_DIR / "electricity_price_de.csv"
    de.to_csv(out, index=False, encoding="utf-8-sig")
    print(f"electricity -> {out.name}: {len(de)} rows, "
          f"{de.year.min()}-{de.year.max()}, "
          f"{de.nrg_cons.nunique()} bands x {de.tax.nunique()} tax bases")
    return de


if __name__ == "__main__":
    CLEAN_DIR.mkdir(exist_ok=True)
    clean_diesel()
    clean_electricity()
    print("done.")

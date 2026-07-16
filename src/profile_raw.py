"""
Profile the raw downloads. The output of this script is not analysis,
it is a list of problems to fix in the cleaning step.

Run from anywhere (path is anchored to the repo, not the current dir):
    python src/profile_raw.py
Then write what you find into docs/data_notes.md.
"""

import re
from pathlib import Path

import pandas as pd

# Anchor to the repo root (parent of src/) so the script works no matter
# which directory it is launched from. Path("data_raw") only worked when
# run from the repo root; from inside src/ it silently found nothing.
REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = REPO_ROOT / "data_raw"


def profile_csv(path: Path) -> None:
    print("=" * 70)
    print(f"CSV: {path.name}")
    print("=" * 70)
    df = pd.read_csv(path)

    print(f"shape: {df.shape}")
    print(f"\ncolumns:\n{list(df.columns)}")
    print(f"\ndtypes:\n{df.dtypes}")
    print(f"\nfirst 5 rows:\n{df.head()}")

    # Eurostat quirk 1: data comes wide, one column per year,
    # often named like '2023' or '2023 ' with flags in the values
    year_cols = [c for c in df.columns if str(c).strip()[:4].isdigit()]
    print(f"\nyear columns detected: {len(year_cols)} -> {year_cols[:8]} ...")

    # Eurostat quirk 2: missing values are ':' and values can carry
    # letter flags like 'b' (break in series), 'e' (estimate), 'p' (provisional)
    if year_cols:
        sample_col = df[year_cols[-1]].astype(str)
        flagged = sample_col[sample_col.str.contains(r"[a-z:]", na=False)]
        print(f"\nflagged/missing values in latest year column: {len(flagged)}")
        print(flagged.value_counts().head(10))

    # Categorical dimensions: know every code before you filter
    dim_cols = [c for c in df.columns if c not in year_cols]
    for c in dim_cols:
        uniques = df[c].unique()
        print(f"\nunique values in '{c}' ({len(uniques)}):")
        print(uniques[:20])


def profile_excel(path: Path) -> None:
    print("=" * 70)
    print(f"XLSX: {path.name}")
    print("=" * 70)

    xl = pd.ExcelFile(path)
    print(f"sheets ({len(xl.sheet_names)}): {xl.sheet_names}")

    for sheet in xl.sheet_names:
        print("-" * 70)
        print(f"sheet: {sheet}")
        print("-" * 70)

        # Read the top rows with NO header: the Oil Bulletin uses a stacked
        # multi-row header (title / product name / unit) before the data
        # starts, so pandas cannot infer a clean header on its own.
        head = pd.read_excel(xl, sheet_name=sheet, header=None, nrows=4)
        print(f"raw shape (header=None, first read): rows>=4, cols={head.shape[1]}")
        print("top-left 4x4 block (the messy header):")
        print(head.iloc[:4, :4].to_string())

        # Column group labels live in row 0, formatted like
        # 'DE_price_with_tax_diesel'. Pull the country/area prefixes so we
        # know exactly which series exist before filtering.
        row0 = [str(x) for x in head.iloc[0].tolist()]
        prefixes = sorted(
            {m.group(1) for x in row0 if (m := re.match(r"([A-Za-z]+)_", x))}
        )
        print(f"\ncountry/area prefixes in group labels ({len(prefixes)}): {prefixes}")

        # Where is the German diesel series, and what unit is it in?
        for i, label in enumerate(row0):
            low = label.lower()
            if low.startswith("de_") and "diesel" in low:
                unit = head.iloc[2, i] if head.shape[0] > 2 else "?"
                print(f"Germany diesel -> col index {i}: '{label}' | unit row: {unit}")

        # Coverage: the first column is Date (weekly price sheets), Year
        # (annual Consumption sheet), or a text label (tax sheets). Only the
        # Date sheets are real timestamps, so only parse those as dates -
        # calling pd.to_datetime on the others triggers a dateutil fallback
        # warning and tells us nothing useful.
        label_col = str(head.iloc[2, 0]).strip()  # 'Date' / 'Year' sits in row 2
        series = pd.read_excel(xl, sheet_name=sheet, header=2, usecols=[0]).iloc[:, 0]

        if label_col == "Date":
            # Excel already hands these back as datetimes; parse with an
            # explicit format to keep it deterministic and warning-free.
            dates = pd.to_datetime(series, format="%Y-%m-%d", errors="coerce").dropna()
            print(
                f"coverage ('Date'): {dates.min().date()} -> "
                f"{dates.max().date()} across {len(dates)} weekly rows"
            )
        elif label_col == "Year":
            years = pd.to_numeric(series, errors="coerce").dropna().astype(int)
            print(
                f"coverage ('Year'): {years.min()} -> {years.max()} "
                f"across {len(years)} annual rows"
            )
        else:
            print(
                f"coverage: first column is '{label_col}' (not a time axis), "
                f"{len(series)} rows - this sheet has a different layout"
            )


if __name__ == "__main__":
    if not RAW_DIR.exists():
        raise SystemExit(f"data_raw not found at {RAW_DIR} - nothing to profile")

    csv_files = sorted(RAW_DIR.glob("*.csv"))
    xlsx_files = sorted(RAW_DIR.glob("*.xlsx"))
    print(f"Profiling {len(csv_files)} CSV + {len(xlsx_files)} XLSX from {RAW_DIR}\n")

    for f in csv_files:
        profile_csv(f)
    for f in xlsx_files:
        profile_excel(f)

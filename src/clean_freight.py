"""
Clean the two Eurostat road-freight files into tidy, Germany-focused tables.

Input : data_raw/road_go_ta_dc__freight_by_distance_class.csv
        data_raw/road_go_na_rl3g__freight_by_region_loading.csv
        data_raw/nuts_de_names.csv        (optional, for region names)
Output: data_clean/freight_distance_class_de.csv
        data_clean/freight_region_de.csv

Decisions (see docs/data_notes.md for the why):
- Wide -> tidy long: one row per (dimensions, year, value).
- ':' was already turned into NaN on read; we drop NaN value rows.
- Germany only. Distance file is country-level (geo == 'DE'); region file
  is NUTS3 (geo starts with 'DE'). Filtering to DE also removes the EU
  aggregates (EU15/EU27_2020/...) automatically.
- Units and TOTAL aggregates are KEPT as columns/rows, not dropped, so the
  SQL layer can choose. TOTAL rows are real aggregates - do not sum them
  together with their components.

Run from anywhere:  python src/clean_freight.py
"""


from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = REPO_ROOT / "data_raw"
CLEAN_DIR = REPO_ROOT / "data_clean"

GEO_COL = "geo\\TIME_PERIOD"  # Eurostat ships the geo column with this literal name


def _melt_years(df: pd.DataFrame) -> pd.DataFrame:
    df = df.rename(columns={GEO_COL: "geo"})
    year_cols = [c for c in df.columns if str(c).isdigit()]
    id_cols = [c for c in df.columns if c not in year_cols]
    long = df.melt(id_vars=id_cols, value_vars=year_cols,
                   var_name="year", value_name="value")
    long["year"] = long["year"].astype(int)
    return long.dropna(subset=["value"])


def clean_distance() -> pd.DataFrame:
    src = RAW_DIR / "road_go_ta_dc__freight_by_distance_class.csv"
    long = _melt_years(pd.read_csv(src))
    de = long[long["geo"] == "DE"].copy()
    de = de[["geo", "tra_type", "distance", "unit", "year", "value"]]
    de = de.sort_values(["unit", "tra_type", "distance", "year"]).reset_index(drop=True)
    out = CLEAN_DIR / "freight_distance_class_de.csv"
    de.to_csv(out, index=False, encoding="utf-8-sig")
    print(f"distance -> {out.name}: {len(de)} rows, "
          f"units={sorted(de.unit.unique())}, years {de.year.min()}-{de.year.max()}")
    return de


def clean_region() -> pd.DataFrame:
    src = RAW_DIR / "road_go_na_rl3g__freight_by_region_loading.csv"
    long = _melt_years(pd.read_csv(src))
    de = long[long["geo"].str.startswith("DE")].copy()

    # Tag NUTS level by code length (DE=2 country, DE1=3 NUTS1, DE11=4 NUTS2,
    # DE111=5 NUTS3). This dataset is NUTS3-only for DE, but tag defensively.
    lvl = {2: "country", 3: "NUTS1", 4: "NUTS2", 5: "NUTS3"}
    de["nuts_level"] = de["geo"].str.len().map(lvl).fillna("other")

    # Optional region-name join. Run download_data.py to create the lookup.
    names_path = RAW_DIR / "nuts_de_names.csv"
    if names_path.exists():
        names = pd.read_csv(names_path)[["geo", "region_name"]]
        de = de.merge(names, on="geo", how="left")
        missing = de["region_name"].isna().sum()
        if missing:
            print(f"  note: {missing} region rows had no name match")
    else:
        de["region_name"] = pd.NA
        print("  note: data_raw/nuts_de_names.csv not found - "
              "run download_data.py to fill region names")

    de = de[["geo", "region_name", "nuts_level", "nst07", "unit", "year", "value"]]
    de = de.sort_values(["geo", "nst07", "year"]).reset_index(drop=True)
    out = CLEAN_DIR / "freight_region_de.csv"
    de.to_csv(out, index=False, encoding="utf-8-sig")
    print(f"region   -> {out.name}: {len(de)} rows, "
          f"{de.geo.nunique()} regions, years {de.year.min()}-{de.year.max()}")
    return de


if __name__ == "__main__":
    CLEAN_DIR.mkdir(exist_ok=True)
    clean_distance()
    clean_region()
    print("done.")

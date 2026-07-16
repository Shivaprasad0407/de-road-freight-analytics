"""
Download raw data for the German road freight cost and CO2 project.

Eurostat datasets are pulled via the `eurostat` package (pip install eurostat).
The Weekly Oil Bulletin xlsx must be downloaded manually from the
EC energy website into data_raw/ because its URL changes periodically.

Run from the repo root:  python src/download_data.py
"""

from pathlib import Path

import eurostat

RAW_DIR = Path("data_raw")

# Dataset code -> short description
DATASETS = {
    # Tonne-km by distance class and type of transport, annual
    "road_go_ta_dc": "freight_by_distance_class",
    # National freight by region of loading (NUTS 3) and group of goods
    "road_go_na_rl3g": "freight_by_region_loading",
    # Electricity prices for non-household (industrial) consumers, bi-annual,
    # by consumption band. Used for the e-truck charging cost in Q2.
    "nrg_pc_205": "electricity_price_nonhousehold",
}


def download_all() -> None:
    RAW_DIR.mkdir(exist_ok=True)
    for code, name in DATASETS.items():
        out_path = RAW_DIR / f"{code}__{name}.csv"
        if out_path.exists():
            print(f"skip (exists): {out_path}")
            continue
        print(f"downloading {code} ...")
        df = eurostat.get_data_df(code)
        df.to_csv(out_path, index=False)
        print(f"saved {out_path}  shape={df.shape}")


if __name__ == "__main__":
    download_all()
    print(
        "\nReminder: download the Weekly Oil Bulletin price history xlsx "
        "manually into data_raw/ (search 'Weekly Oil Bulletin', "
        "energy.ec.europa.eu, file: price history)."
    )
    print(
        "Note: UBA road-freight emission factors and Toll Collect Maut rates "
        "have no machine API. They are hand-transcribed from PDFs into "
        "data_raw/uba_emission_factors_freight_2024.csv and "
        "data_raw/tollcollect_maut_rates_2024.csv (committed to the repo, "
        "unlike the other raw files). Sources are in docs/data_notes.md."
    )

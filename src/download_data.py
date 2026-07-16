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

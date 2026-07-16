# Data notes

Everything odd, missing, or surprising in the raw data, found during profiling.
This file is interview material: it proves the cleaning was real work.

Profiled with `python src/profile_raw.py` (2 CSV + 1 XLSX in `data_raw/`).

## road_go_ta_dc (freight by distance class)

Shape 3778 x 31. Wide format, one column per year 1999–2024 (26 year columns).

- Format issues found:
  - Four different units are stacked in one file: `MIO_TKM` (tonne-km), `MIO_VKM` (vehicle-km), `THS_BTO` (gross tonnes), `THS_T` (tonnes). You must filter to ONE unit before any sum — `MIO_TKM` is the one for emissions per tonne-km.
  - `tra_type` mixes the `TOTAL` aggregate with its components `HIRE` / `NSP` / `OWN`. Keep either TOTAL or the three parts, never both, or you double-count.
  - `geo` (37 values) mixes countries with EU aggregates: `EU15`, `EU25`, `EU27_2007`, `EU27_2020`, `EU28`. Drop aggregates before ranking countries. Greece is `EL`, not `GR`.
- Missing value handling (':' cells, flag letters b/e/p):
  - `pd.read_csv` already parsed the year columns as float64, so Eurostat's `:` (missing) was silently turned into NaN on read and the letter flags (b/e/p) are NOT preserved in these files. The flag-detector in the script therefore finds nothing real here — it only picks up the literal string `nan`.
  - 2024 column: 1178 / 3778 rows missing (31.2%). Missingness grows in recent years — expect gaps at the tail.
- Distance class codes and their meaning:
  - `KM_LT50`, `KM50-149`, `KM150-299`, `KM300-499`, `KM500-999`, `KM1000-1999`, `KM2000-5999`, `KM_GE6000`, plus `TOTAL`. Nine values, listed out of order in the raw file. `TOTAL` is an aggregate — exclude when summing buckets.
- Coverage: years 1999–2024; usable series thins out toward 2024.

## road_go_na_rl3g (freight by region of loading)

Shape 38486 x 21. Wide format, one column per year 2008–2024 (17 year columns). Single unit `THS_T` (thousand tonnes).

- NUTS region codes needing a name mapping:
  - `geo\TIME_PERIOD` holds 1904 NUTS-3 codes (e.g. `AT111`). These are codes only — a NUTS3 code→name lookup is needed before anything is human-readable.
  - `nst07` (goods type, NST2007) has 22 values: `GT01`–`GT20`, plus `TOTAL` (aggregate — exclude when summing) and `UNK` (unknown goods type).
- German regions present / missing:
  - 475 DE NUTS-3 regions present (`DE111`, `DE112`, … `DE11A`, `DE11B` …). Codes go hex-style past 9 (DE11A/B/C), so treat them as strings, never numeric.
- Format issues found:
  - Column name is the literal `geo\TIME_PERIOD` (backslash in the header) — rename on load.
  - Very high missingness: 2024 is 55.2% missing, 2008 is 48.8% missing. Root cause is survey suppression of small regions (see caveats). Region-level values for small NUTS3 areas are unreliable.
  - Same `:`→NaN behaviour as the distance file; flags not preserved.

## Weekly Oil Bulletin (diesel prices)

XLSX with 7 sheets: `Prices with taxes`, `Prices wo taxes`, `Consumption`, `VAT`, `Excise duties`, `Excise duties - components`, `Other Indirect Taxes`.

- Sheet structure of the xlsx:
  - The two price sheets are the ones we need. Each is ~226 columns with a stacked 3-row header, so pandas cannot infer a header — read with `header=None` and build columns manually:
    - row 0 = group label, e.g. `DE_price_with_tax_diesel`
    - row 1 = product name (multilingual, e.g. "Gas oil automobile / Automotive gas oil / Dieselkraftstoff")
    - row 2 = `Date` in col 0 and the unit (`1000 l`) in the value columns
    - row 3 onward = data
  - 30 country/area prefixes: AT, BE, BG, CY, CZ, DE, DK, EE, ES, EU, EUR, FI, FR, GR, HR, HU, IE, IT, LT, LU, LV, MT, NL, PL, PT, RO, SE, SI, SK, UK. Note both `EU` and `EUR` (euro-area) aggregates, and `GR` here for Greece (vs `EL` in the freight CSVs — reconcile the two).
  - Rows are newest-first (descending dates).
- Germany series location, units (EUR per 1000 l vs per litre), tax vs pre-tax:
  - With-tax diesel: sheet `Prices with taxes`, column index 55, label `DE_price_with_tax_diesel`.
  - Pre-tax diesel: sheet `Prices wo taxes`, column index 55, label `DE_price_wo_tax_diesel`.
  - Unit is EUR per 1000 litres ("1000 l") — divide by 1000 for EUR/litre. Confirm currency is EUR (the EU rows are labelled `EU_`).
- Gaps or breaks in the weekly series:
  - Weekly, 2005-01-03 → 2026-07-06, 1074 rows. Continuous enough for a weekly series; check for occasional gaps around holidays before resampling.
- Other sheets (do not assume same layout):
  - `Consumption` is ANNUAL, not weekly: first column is `Year` (2024, 2023, …) and units are 1000 t / kt. The profiler's date parser misreads it (it assumes a Date column) — parse it separately if used.
  - `VAT`, `Excise duties`, `Excise duties - components`, `Other Indirect Taxes` use a completely different layout (the country `XX_...` group-label pattern is absent). Not needed for the diesel price series — ignore unless modelling the tax component directly.

## Known caveats to carry into the analysis

- 21.6% of EU road freight vehicle-km in 2024 were empty runs (Eurostat). Emission factors per tonne-km partially absorb this, note in limitations.
- Eurostat road freight is survey-based, small-region values can be unreliable or suppressed (this is why the region file is ~50% empty).
- `:`→NaN happens silently on CSV read: the raw Eurostat missing/flag markers are already lost by the time pandas hands you floats. If the original flags (b/e/p) matter, re-read those columns as strings.
- Country code mismatch: Greece is `EL` in the freight CSVs but `GR` in the oil bulletin — normalise before any join.
- The profiler's XLSX assumptions (group labels in row 0, unit in row 2, Date in col 0) only hold for the two price sheets; the tax and consumption sheets need bespoke parsing.

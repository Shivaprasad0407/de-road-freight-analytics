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
- Sum-of-bands does not always equal the reported `TOTAL` row. In most years they match to ~1 unit (rounding), but 2011 (314,998 vs 315,026), 2012 (297,502 vs 297,575) and 2015 (305,054 vs 305,070) differ by up to ~75 mio tkm (<0.03%). Some freight is evidently not allocated to a distance band. Small, but state which basis you used.
- The number of reported distance bands varies by year: 7 in most years, 8 in 2016 and 2021 (the `KM_GE6000` band only reports occasionally). So a year-over-year sum-of-bands series is not built on a constant set of bands. Immaterial here (that band is tiny), but it is the kind of thing that silently breaks trend comparisons.
- Trend: tonne-km peaked in 2007 (335,056), fell ~10% in 2009 (financial crisis), and has declined since 2019. COVID (2020) cost only -2.4%, far less than 2009 - freight kept moving while passenger transport collapsed.

## road_go_na_rl3g (freight by region of loading)

Shape 38486 x 21. Wide format, one column per year 2008–2024 (17 year columns). Single unit `THS_T` (thousand tonnes).

- NUTS region codes needing a name mapping:
  - `geo\TIME_PERIOD` holds 1904 NUTS-3 codes (e.g. `AT111`). These are codes only — a NUTS3 code→name lookup is needed before anything is human-readable.
  - `nst07` (goods type, NST2007) has 22 values: `GT01`–`GT20`, plus `TOTAL` (aggregate — exclude when summing) and `UNK` (unknown goods type).
- German regions present / missing:
  - 475 DE NUTS-3 regions present (`DE111`, `DE112`, … `DE11A`, `DE11B` …). Codes go hex-style past 9 (DE11A/B/C), so treat them as strings, never numeric.
- Tonnage measures weight, not economic value (evidenced, 2024, `sql/goods_type_tonnage.sql`):
  mining/quarrying products 749,693 THS_T dominate, at 2.6x the next category;
  transport equipment is 64,985 (~1/11th) and machinery/computers/electrical is
  30,370 (~1/25th, last in the top 15). Germany's automotive and machinery
  exports barely register by weight. Consequence: any regional or goods ranking
  built on tonnes is largely a map of quarrying and construction activity.
  This is why the top regions are Rhein-Erft (lignite), Mayen-Koblenz (basalt)
  and Börde, and why CO2-by-region from tonnage was rejected (assumption #9).
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

## UBA emission factors (freight, g CO2e per tonne-km)

Stored as `data_raw/uba_emission_factors_freight_2024.csv` (committed, unlike the other raw files).

- Source: UBA "Vergleich der durchschnittlichen Emissionen einzelner Verkehrsmittel im Güterverkehr in Deutschland 2024", table PDF, `vtv_2024_gv_tab_pdf_0.pdf`, from https://www.umweltbundesamt.de/themen/verkehr/emissionsdaten. Model: TREMOD 6.71B (10/2025). Reference year 2024. Date checked: 2026-07-16.
- No machine API — hand-transcribed from the PDF. Nine rows: trucks (total + four sub-classes), rail (total + diesel + electric), inland ship.
- Key values (g CO2e/tkm): Lkw total 118; rigid 3.5–7.5t 561; 7.5–12t 393; >12t 250; truck-trailer & articulated 101; rail 14; inland ship 32.
- Scope caveat (important): these are **well-to-wheel CO2-equivalents** — they include the energy supply chain (fuel/electricity production) and CH4+N2O (AR5), not just tailpipe CO2. This matches the GLEC framework the project cites. But Q2's toll CO2 surcharge is tailpipe-based; do not silently mix well-to-wheel freight factors with tank-to-wheel cost-model factors.
- The per-tkm factor falls sharply as trucks get heavier (561 → 101), because big articulated trucks carry far more payload per litre. This means the distance-band dimension in Q1 is meaningful: short-haul (lighter trucks) is more carbon-intense per tkm than long-haul. The choice of which factor to apply to which band is logged as assumption #7.

## Toll Collect Maut rates (Q2)

Stored as `data_raw/tollcollect_maut_rates_2024.csv` (committed reference).

- Source: Toll Collect / BALM per-km rate table, in force since 1 July 2024. Primary file: `mautsaetze_07_2024_vergleich_d.pdf` (toll-collect.de), cross-checked against the impargo rate-table article. Date checked: 2026-07-16.
- Rates are cent/km, total = infrastructure + air pollution + noise + CO2 surcharge. The CSV keeps the total and the CO2 component (the surcharge e-trucks avoid — the whole point of Q2).
- Table covers all six weight/axle classes. CO2 class 1 is given for every Euro class; CO2 classes 2-4 only for Euro 6 (older trucks can only be class 1). CO2 class 5 = zero-emission, exempt until 30 June 2031 (rows set to 0).
- 40t long-haul reference row: >18t, 5+ axles, Euro 6, CO2 class 1 = 34.8 ct/km total, of which 15.8 ct/km is the CO2 surcharge. This is the diesel baseline for Q2; the e-truck pays 0 (class 5).
- Every truck is placed in CO2 class 1 by default; better classes need an application. Use class 1 as the realistic diesel default unless modelling the re-classification case.
- CO2 reference values tighten yearly (2.5%/yr to 2026, 3%/yr from 2027), so a truck can slip to a worse class over time without changing. Note if modelling multi-year.

## Industrial electricity price (Q2)

- Pulled via `download_data.py` as Eurostat `nrg_pc_205` (electricity prices for non-household consumers, bi-annual, by consumption band) into data_raw (reproducible, not committed).
- Planning value: ~0.20 EUR/kWh for German industrial/depot charging (Eurostat non-household, Dec 2024). Medium band (20-500 MWh) ~23.3 ct/kWh; average without reductions ~16.77 ct/kWh in 2024. Logged as assumption #8.
- Caveat: public fast-charging is 2-3x higher and would erase much of the e-truck cost advantage. Treat electricity price as a sensitivity axis.

## Truck cost and consumption assumptions (Q2, Q3)

All logged in `docs/assumptions.md` (#1-5, #8) with sources. Key points:
- Diesel 40t long-haul: 30 l/100km (ICCT combined-load reference). E-truck: 103 kWh/100km (eActros 600 real-world test). E-truck range 500 km/charge.
- Purchase-price gap (~180-220k EUR) is an ESTIMATE — manufacturers don't publish e-truck list prices. It is the weakest input and the Q2 break-even is very sensitive to it; run a range, don't report a single point.

## Known caveats to carry into the analysis

- 21.6% of EU road freight vehicle-km in 2024 were empty runs (Eurostat). Emission factors per tonne-km partially absorb this, note in limitations.
- Eurostat road freight is survey-based, small-region values can be unreliable or suppressed (this is why the region file is ~50% empty).
- `:`→NaN happens silently on CSV read: the raw Eurostat missing/flag markers are already lost by the time pandas hands you floats. If the original flags (b/e/p) matter, re-read those columns as strings.
- Country code mismatch: Greece is `EL` in the freight CSVs but `GR` in the oil bulletin — normalise before any join.
- The profiler's XLSX assumptions (group labels in row 0, unit in row 2, Date in col 0) only hold for the two price sheets; the tax and consumption sheets need bespoke parsing.

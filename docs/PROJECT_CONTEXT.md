# Project context and handoff (read this first)

Start-here note for resuming the German road-freight cost & CO2 project in a
new chat. Read this, then `docs/sql_progress.md` and `docs/assumptions.md`.

## Working agreement (important - do not deviate)
- **Prasad is the doer for SQL and Power BI.** He writes every query and every
  Power BI step himself, to learn. The assistant GUIDES and NAVIGATES: explain
  the concept, give the shape/pieces and expected results, review what he
  writes, and point out bugs - but do NOT write his SQL or Power BI for him.
  When he's genuinely stuck he may ask for a worked example; give it, but
  default to guiding.
- **Python is the assistant's job.** Cleaning scripts, downloads, data fetching
  and verification are done by the assistant, not Prasad.
- Prasad runs everything on his own Windows machine and pastes output back.
- Preferences: direct, senior-advisor tone; point out weak reasoning and errors
  plainly; concise; teach the "why", not just the fix.

## Environment quirks (save time)
- SQL runs in the **DuckDB CLI**: `duckdb freight.duckdb` from the repo root
  (`C:\Users\mrshi\Repos\de-road-freight-analytics`). SQL goes at the `D` prompt;
  `.quit` returns to PowerShell. `freight.duckdb` is gitignored (rebuildable via
  `sql/load_tables.sql` + `sql/q2_params.sql`).
- The assistant's sandbox **cannot reach Eurostat** (no network to it) and
  **cannot delete files** under `.git/` or overwrite files Prasad's machine
  created (mount permissions). So: Eurostat pulls and script runs happen on
  Prasad's side; git commits happen on Prasad's side.
- Every commit: `rm -f .git/index.lock` first (a stale lock keeps reappearing),
  then `git add <explicit files>` (never `git add .` - avoids stray folders and
  CRLF churn), commit, push.
- `data_raw/uba_emission_factors_freight_2024.csv` perpetually shows as modified
  = harmless CRLF noise; leave it out of commits.
- String filters in SQL are CASE-SENSITIVE on values (`'Euro 6'` not `'EURO 6'`,
  `'TOTAL'` not `'Total'`). `!=` with wrong case fails invisibly by keeping rows.

## Roadmap position
3-week plan. Done: Week 1 (data, cleaning, SQL foundation) and Q1 in full.
Now in **Week 2, Q2** (cost model), stage 2b.

## Q1 - COMPLETE
- ~31.9 Mt CO2e from German road freight, 2024 (`sql/q1_co2_by_distance_band.sql`).
- ~81% of tonne-km (and so of CO2) is within a 500 km single-charge e-truck
  range (`sql/q1_electrifiable_share.sql`, 80.9% / 19.1%). Assumption #4.
- Regional view reported in tonnes, not CO2 (assumption #9): region data has no
  tonne-km. Hamburg leads (`sql/q1_top_regions_tonnage.sql`).
- Tonnage measures bulk not value: mining/quarrying dominates, machinery is last
  (`sql/goods_type_tonnage.sql`).
- Trend: peak 2007, -10% in 2009 (crisis), COVID only -2.4% (`sql/freight_tkm_yoy.sql`).

## Q2 - IN PROGRESS (cost model, 4 stages)
- Stage 1 DONE: `sql/q2_params.sql` builds `params` (long) and `p` (wide 1-row).
- Stage 2a DONE: the `p` pivot.
- Stage 2b step 1 DONE and VERIFIED - three price CTEs cross joined onto `p`:
  diesel with-tax 2024 = **1.647 EUR/l**, electricity (X_VAT, MWH500-1999) =
  **0.23435 EUR/kWh**, diesel toll (CO2 class 1, Euro 6, >18t 5+ axles) =
  **0.348 EUR/km**. All correct.
- **Stage 2b step 2 = NEXT.** Add the cost-per-km arithmetic to that query:
  - diesel/km = (diesel_l_per_100km/100) * (avg_diesel_price / (1 + vat_rate))
                + diesel_toll_per_km + maint_diesel_eur_per_km   -> expect ~0.91
  - electric/km = (etruck_kwh_per_100km/100) * avg_elec_price
                + 0 (CO2 class 5 exempt) + maint_electric_eur_per_km -> ~0.32
  Note the diesel price is divided by 1.19 because hauliers reclaim VAT.
- Stage 3: break-even mileage =
  purchase_gap_eur / ((diesel_per_km - electric_per_km) * ownership_years).
- Stage 4: sensitivity - diesel +/-20 ct, toll exemption ending 2031,
  electricity doubling, purchase gap 150k-250k.
- Hypothesis to test: the toll exemption (~0.35/km) exceeds the fuel-vs-
  electricity saving (~0.17/km), so POLICY not fuel economics drives e-truck
  competitiveness, making the 2031 exemption expiry the key sensitivity.

## Q3 - not started
Quarterly actual diesel cost/km vs a fixed budget price. Budget = 2021 annual
mean German diesel = 1.389 EUR/l (pre-shock base year, assumption #5).

## Then: Week 3 = Power BI (Prasad builds), pseudonymization note, README write-up.

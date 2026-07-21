# SQL progress log

Where the SQL work stands, so it's easy to resume.

## Status
Week 1, Days 5-6 (SQL foundation) in progress, using DuckDB.

## Setup
- Database file: `freight.duckdb` (created at repo root).
- Start a session from the repo root: `duckdb freight.duckdb`
- Load the three tables: `.read sql/load_tables.sql`
- Tables: `freight_distance`, `freight_region`, `emission_factors`.

## Done so far (saved in sql/)
1. `sql/q1_tkm_share_by_distance_band.sql` - tonne-km share per distance band, 2024.
   Key result: ~81% of tonne-km is under 500 km; ~97% under 1000 km.
2. `sql/q1_co2_by_distance_band.sql` - CO2e per distance band, 2024.
   Key result: ~31.9 million tonnes CO2e total; ~81% of it from trips under 500 km.
   National total tonne-km 2024: ~270,326 million tkm (7 bands; KM_GE6000 has no 2024 value).

SQL concepts covered: SELECT/WHERE/GROUP BY/ORDER BY, string filters are
case-sensitive (silent empty result if they don't match), CTEs (WITH),
window function SUM() OVER (), CROSS JOIN to attach a single constant.

## In progress (pick up here)
Year-over-year change in national tonne-km using LAG(). Last error was
"Table yearly does not exist" - the outer query referenced a CTE named
`yearly` that wasn't defined. Fix: define it first, e.g.

```sql
WITH yearly AS (
    SELECT year, SUM(value) AS total_tkm
    FROM freight_distance
    WHERE unit = 'MIO_TKM' AND tra_type = 'TOTAL' AND distance != 'TOTAL'
    GROUP BY year
)
SELECT year,
       total_tkm,
       total_tkm - LAG(total_tkm) OVER (ORDER BY year) AS change_vs_prev
FROM yearly
ORDER BY year;
```

## Open modeling caveats (before doing CO2 by region)
- `freight_region` is in THS_T (thousand tonnes = weight loaded), NOT tonne-km.
  The emission factor is per tonne-km, so CO2-by-region is not a copy of the
  distance query. Needs a stated proxy or assumption (log it in assumptions.md).
- Emission factor used is the fleet average 118 g CO2e/tkm, well-to-wheel
  (assumptions #6/#7). Refining to per-band factors would use a keyed INNER JOIN.

## Q1 COMPLETE (all outputs in sql/)
1. `q1_co2_by_distance_band.sql` - ~31.9 Mt CO2e total, 2024.
2. `q1_tkm_share_by_distance_band.sql` - band shares of tonne-km.
3. `q1_top_regions_tonnage.sql` - top regions by tonnage (Hamburg 54,855 leads).
4. `q1_electrifiable_share.sql` - 80.9% within 500 km, 19.1% beyond.
Supporting: `goods_type_tonnage.sql` (tonnage-bias evidence),
`freight_tkm_yoy.sql` (2009 crisis -10%, COVID only -2.4%).

Q1 headline: ~31.9 Mt CO2e from German road freight in 2024, and ~81% of it
sits on routes within a 500 km single-charge electric range (assumption #4).
Regional view is reported in tonnes, not CO2 (assumption #9).

SQL concepts now covered: SELECT/WHERE/GROUP BY/ORDER BY/LIMIT, aggregate
aliases, CTEs, window functions (SUM() OVER (), LAG()), CROSS JOIN, keyed
INNER JOIN, CASE WHEN / IN, GROUP BY on a CASE alias. Debugging lessons:
case-sensitive string filters fail silently (and `!=` fails invisibly by
keeping rows), CTEs are statement-scoped, joins never persist, and a passing
sanity check only validates the thing it tests.

## Q2 IN PROGRESS (cost model, 4 stages)
Stage 1 DONE - `sql/q2_params.sql` builds `params` (long) and `p` (wide, 1 row,
7 DOUBLE columns). Prices deliberately excluded: they come from the real tables.

Stage 2 NEXT - cost per km, built in two steps:
  2a DONE - the `p` pivot.
  2b TODO - fetch the three prices and verify, THEN add arithmetic. Write three
  CTEs each returning one row, and CROSS JOIN them onto `p`:
    - diesel_2024:  AVG(price_with_tax_eur_per_l) FROM diesel_price
                    WHERE year(date) = 2024                  -> expect ~1.647
    - elec_2024:    AVG(price_eur_per_kwh) FROM electricity_price
                    WHERE year = 2024 AND tax = 'X_VAT'
                      AND nrg_cons = 'MWH500-1999'           -> expect ~0.2344
                    (that band ~= a 10-truck fleet; a 1-truck operator would
                     use MWH20-499 at ~0.272 - state the choice)
    - toll_diesel:  total_ct_km / 100.0 FROM toll_rates
                    WHERE co2_class = 1 AND euro_class = 'Euro 6'
                      AND weight_axle_class = '>18t 5+ axles' -> expect 0.348
  Then the arithmetic:
    diesel/km  = (diesel_l_per_100km/100) * (with_tax / (1 + vat_rate))
                 + toll_eur_per_km + maint_diesel_eur_per_km   -> expect ~0.91
    electric/km= (etruck_kwh_per_100km/100) * eur_per_kwh
                 + 0 (CO2 class 5 exempt) + maint_electric_eur_per_km -> ~0.32

Stage 3 TODO - break-even annual mileage:
  purchase_gap_eur / ((diesel_per_km - electric_per_km) * ownership_years).
Stage 4 TODO - sensitivity: diesel +/-20 ct, toll exemption ending (2031),
  electricity doubling, purchase gap 150k-250k.

Expected headline to test: the toll exemption (0.348 EUR/km) looks larger than
the fuel-vs-electricity saving (~0.17), i.e. policy not fuel economics is what
makes e-trucks competitive - which makes the 2031 expiry the key sensitivity.

## Next steps
1. Finish the LAG year-over-year query (above).
2. Decide and document the CO2-by-region approach (proxy for tonne-km).
3. Move into Week 2, Q1: assemble CO2 by region + distance band and the
   electrifiable share into the Q1 output, with the range assumption stated.

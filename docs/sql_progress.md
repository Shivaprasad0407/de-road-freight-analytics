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

## Next steps
1. Finish the LAG year-over-year query (above).
2. Decide and document the CO2-by-region approach (proxy for tonne-km).
3. Move into Week 2, Q1: assemble CO2 by region + distance band and the
   electrifiable share into the Q1 output, with the range assumption stated.

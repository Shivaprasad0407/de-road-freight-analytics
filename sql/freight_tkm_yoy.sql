-- German road-freight tonne-km per year, with year-over-year change.
-- Teaches: LAG() OVER (ORDER BY year) reaches back to the previous row.
-- The earliest year returns NULL for change_vs_prev (no prior row) - correct.
--
-- Key results: biggest drop 2009 (-33,711 mio tkm, ~-10%, financial crisis).
-- COVID 2020 cost only -7,263 (-2.4%) - freight kept moving while passenger
-- transport collapsed. Peak was 2007 (335,056); 2024 is ~19% below that.
--
-- Caveat: this sums the distance bands, and the band count is not constant
-- (8 bands in 2016 and 2021, 7 otherwise). See docs/data_notes.md.

WITH yearly AS (
    SELECT year, SUM(value) AS total_tkm
    FROM freight_distance
    WHERE unit = 'MIO_TKM'
      AND tra_type = 'TOTAL'
      AND distance != 'TOTAL'
    GROUP BY year
)
SELECT year,
       total_tkm,
       total_tkm - LAG(total_tkm) OVER (ORDER BY year) AS change_vs_prev,
       ROUND(
           (total_tkm - LAG(total_tkm) OVER (ORDER BY year))
           / LAG(total_tkm) OVER (ORDER BY year) * 100, 1
       ) AS change_pct
FROM yearly
ORDER BY year;

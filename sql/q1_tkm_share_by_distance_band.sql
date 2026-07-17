-- Q1 (part 1): share of German road-freight tonne-km by distance band, 2024.
-- Feeds the "electrifiable share": ~81% of tonne-km is under 500 km.
-- Teaches: CTE + window function SUM() OVER () for share-of-total.

WITH bands AS (
    SELECT distance, SUM(value) AS total_tkm
    FROM freight_distance
    WHERE unit = 'MIO_TKM'
      AND tra_type = 'TOTAL'
      AND year = 2024
      AND distance != 'TOTAL'
    GROUP BY distance
)
SELECT distance,
       total_tkm,
       ROUND(total_tkm / SUM(total_tkm) OVER () * 100, 1) AS share_pct
FROM bands
ORDER BY share_pct DESC;

-- Q1 (part 4): the electrifiable share of German road freight, 2024.
--
-- ASSUMPTION (#4): e-truck single-charge range = 500 km, from the
-- Mercedes eActros 600 (621 kWh, 40t GCW). This number moves entirely with
-- that assumption - always report it as "X% under a 500 km range assumption".
--
-- Result: 218,572 mio tkm (80.9%) within 500 km; 51,754 (19.1%) beyond.
-- Because the emission factor is flat (118 g CO2e/tkm), the CO2 share equals
-- the tonne-km share: ~81% of German road-freight CO2 is on routes within
-- current single-charge electric range.
--
-- Teaches: CASE WHEN for classifying text codes into buckets, IN for list
-- membership, GROUP BY on the CASE alias (define the CASE once, not twice).

WITH bands AS (
    SELECT distance, SUM(value) AS mio_tkm
    FROM freight_distance
    WHERE unit = 'MIO_TKM'
      AND tra_type = 'TOTAL'
      AND year = 2024
      AND distance != 'TOTAL'
    GROUP BY distance
),
classed AS (
    SELECT CASE
             WHEN distance IN ('KM_LT50', 'KM50-149', 'KM150-299', 'KM300-499')
             THEN 'within 500 km'
             ELSE 'beyond 500 km'
           END AS distance_class,
           SUM(mio_tkm) AS total_mio_tkm
    FROM bands
    GROUP BY distance_class
)
SELECT distance_class,
       total_mio_tkm,
       ROUND(total_mio_tkm / SUM(total_mio_tkm) OVER () * 100, 1) AS share_percentage
FROM classed
ORDER BY total_mio_tkm DESC;

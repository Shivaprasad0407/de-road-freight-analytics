-- Q1 (part 2): German road-freight CO2e by distance band, 2024.
-- tonne-km (MIO_TKM) x UBA fleet-average factor (118 g CO2e/tkm, assumption #6).
-- Units gift: million tonne-km x grams/tonne-km = tonnes CO2e (10^6 g = 1 t).
-- Total ~31.9 million tonnes CO2e; ~81% from trips under 500 km.
-- Teaches: CROSS JOIN to attach a single constant from another table.

WITH bands AS (
    SELECT distance, SUM(value) AS mio_tkm
    FROM freight_distance
    WHERE unit = 'MIO_TKM'
      AND tra_type = 'TOTAL'
      AND year = 2024
      AND distance != 'TOTAL'
    GROUP BY distance
)
SELECT b.distance,
       b.mio_tkm,
       b.mio_tkm * e.ghg_gco2e_per_tkm AS co2_tonnes
FROM bands b
CROSS JOIN (
    SELECT ghg_gco2e_per_tkm
    FROM emission_factors
    WHERE vehicle_category = 'All trucks >=3.5t GVW (total)'
) e
ORDER BY co2_tonnes DESC;

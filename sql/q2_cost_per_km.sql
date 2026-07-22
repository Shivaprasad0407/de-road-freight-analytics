-- Q2 stage 2b: total operating cost per km, diesel vs electric.
--
-- Builds on q2_params.sql (the `p` wide row). Prices are NOT hardcoded: three
-- CTEs pull them live from the real tables, then CROSS JOIN onto p's single row.
--   diesel_2024 - AVG pump price 2024, with tax        -> ~1.647 EUR/l
--   elec_2024   - AVG industrial price, X_VAT, MWH500-1999 -> ~0.23435 EUR/kWh
--   toll_diesel - CO2 class 1, Euro 6, >18t 5+ axles   -> 0.348 EUR/km
--
-- Each cost/km = energy + toll + maintenance. Diesel energy divides the price
-- by (1 + vat_rate) because hauliers reclaim VAT; the electricity figure is
-- already X_VAT (net) so it is NOT divided. Electric toll is 0 (CO2 class 5
-- exempt) - written as a literal to keep the exemption visible in the query.
--
-- Result (verified): diesel 0.9132 EUR/km, electric 0.3164 EUR/km.

WITH diesel_2024 AS (
    SELECT AVG(price_with_tax_eur_per_l) AS avg_diesel_price
    FROM diesel_price
    WHERE YEAR(date) = 2024
),
elec_2024 AS (
    SELECT AVG(price_eur_per_kwh) AS avg_elec_price
    FROM electricity_price
    WHERE year = 2024
      AND tax = 'X_VAT'
      AND nrg_cons = 'MWH500-1999'
),
toll_diesel AS (
    SELECT total_ct_km / 100.0 AS diesel_toll_per_km
    FROM toll_rates
    WHERE co2_class = 1
      AND euro_class = 'Euro 6'
      AND weight_axle_class = '>18t 5+ axles'
)
SELECT
    p.*,
    ((p.diesel_l_per_100km / 100.0) * (d.avg_diesel_price / (1.0 + p.vat_rate)))
        + t.diesel_toll_per_km
        + p.maint_diesel_eur_per_km AS diesel_cost_per_km,
    ((p.etruck_kwh_per_100km / 100.0) * e.avg_elec_price)
        + 0.0
        + p.maint_electric_eur_per_km AS electric_cost_per_km
FROM p
CROSS JOIN diesel_2024 d
CROSS JOIN elec_2024 e
CROSS JOIN toll_diesel t;

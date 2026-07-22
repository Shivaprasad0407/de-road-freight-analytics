-- Q2 stage 3: break-even annual mileage for the e-truck.
--
-- Question: how many km/year must a truck run before the e-truck's per-km
-- savings (fuel + toll + maintenance) repay its higher purchase price?
--
--   break_even_annual_km = purchase_gap_eur
--                          / ((diesel_per_km - electric_per_km) * ownership_years)
--
-- The Stage 2b cost query is wrapped as the `costs` CTE (cross joins stay INSIDE
-- it, where the price columns are consumed); the outer SELECT does the division.
--
-- Result (verified): saving 0.5968 EUR/km, break-even 67,021 km/year - below
-- typical long-haul mileage (100-130k), so the e-truck repays the ~200k gap in
-- ~2.8 years. The saving decomposes as toll 0.348 (58%) + energy 0.174 (29%)
-- + maintenance 0.075 (13%): policy, not fuel economics, drives the advantage.

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
),
costs AS (
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
    CROSS JOIN toll_diesel t
)
SELECT
    c.*,
    (c.diesel_cost_per_km - c.electric_cost_per_km) AS eur_saved_per_km,
    c.purchase_gap_eur
        / ((c.diesel_cost_per_km - c.electric_cost_per_km) * c.ownership_years)
        AS break_even_annual_km
FROM costs c;

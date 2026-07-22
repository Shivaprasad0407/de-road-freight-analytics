-- Q2 stage 4: sensitivity analysis (one-lever-at-a-time tornado).
--
-- Each scenario nudges ONE input and recomputes break-even, holding the rest at
-- baseline, so each lever's impact is isolated. A `scenarios` VALUES CTE holds
-- the overrides and is CROSS JOINed into the cost model, fanning the single
-- baseline row into seven. Break-even is computed in a wrapping subquery because
-- a SELECT alias can't be referenced by another expression in the same SELECT.
--
-- Levers: diesel_delta (EUR/l pump shock, applied before VAT division),
-- elec_mult (electricity price multiplier), electric_toll_mult (0 = exempt,
-- 1 = exemption ended -> pays the sourced diesel toll, no hardcoded 0.348),
-- gap_override (purchase premium in EUR).
--
-- Result (verified, break-even km/yr, ascending):
--   gap_150k 50,266 | diesel_plus_0_20 61,800 | baseline 67,021 |
--   diesel_minus_0_20 73,205 | gap_250k 83,776 | electricity_doubles 112,534 |
--   toll_exemption_ends 160,753.
-- Finding: ending the toll exemption moves break-even +94k (the only lever that
-- pushes it above real-world mileage of 100-130k), vs only ~5k for a 20 ct
-- diesel swing. Policy, not fuel economics, drives e-truck competitiveness; the
-- 2031 exemption expiry is the decisive variable.

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
scenarios AS (
    SELECT * FROM (VALUES
        ('baseline',              0.00, 1.0, 0.0, 200000.0),
        ('diesel_minus_0_20',    -0.20, 1.0, 0.0, 200000.0),
        ('diesel_plus_0_20',      0.20, 1.0, 0.0, 200000.0),
        ('electricity_doubles',   0.00, 2.0, 0.0, 200000.0),
        ('toll_exemption_ends',   0.00, 1.0, 1.0, 200000.0),
        ('gap_150k',              0.00, 1.0, 0.0, 150000.0),
        ('gap_250k',              0.00, 1.0, 0.0, 250000.0)
    ) AS t(scenario, diesel_delta, elec_mult, electric_toll_mult, gap_override)
),
costs AS (
    SELECT
        s.scenario,
        s.gap_override,
        p.ownership_years,
        ((p.diesel_l_per_100km / 100.0) * ((d.avg_diesel_price + s.diesel_delta) / (1.0 + p.vat_rate)))
            + t.diesel_toll_per_km
            + p.maint_diesel_eur_per_km AS diesel_cost_per_km,
        ((p.etruck_kwh_per_100km / 100.0) * (e.avg_elec_price * s.elec_mult))
            + (s.electric_toll_mult * t.diesel_toll_per_km)
            + p.maint_electric_eur_per_km AS electric_cost_per_km
    FROM p
    CROSS JOIN diesel_2024 d
    CROSS JOIN elec_2024 e
    CROSS JOIN toll_diesel t
    CROSS JOIN scenarios s
)
SELECT
    c.scenario,
    c.diesel_cost_per_km,
    c.electric_cost_per_km,
    (c.diesel_cost_per_km - c.electric_cost_per_km) AS eur_saved_per_km,
    c.break_even_annual_km
FROM (
    SELECT
        *,
        gap_override / ((diesel_cost_per_km - electric_cost_per_km) * ownership_years) AS break_even_annual_km
    FROM costs
) c
ORDER BY break_even_annual_km ASC;

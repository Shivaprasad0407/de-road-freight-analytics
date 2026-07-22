-- Export the verified Q1-Q3 query outputs to dashboard/data/*.csv for Power BI.
--
-- PREREQUISITES (run from the repo root, in this order, in one duckdb session):
--   duckdb freight.duckdb
--   .read sql/load_tables.sql      -- (only if tables aren't already persisted)
--   .read sql/q2_params.sql        -- builds params + p (needed by Q2/Q3 exports)
--   .read sql/export_dashboard_csvs.sql
--
-- COPY writes relative to the process cwd, so launch duckdb from the repo root
-- and create the folder first:  mkdir dashboard\data   (PowerShell)
--
-- Re-run any time the models change; the CSVs are the Power BI data source.

-- Q1: CO2e by distance band (+ band_order for a correct Power BI axis) --------
COPY (
    WITH bands AS (
        SELECT distance, SUM(value) AS mio_tkm
        FROM freight_distance
        WHERE unit = 'MIO_TKM' AND tra_type = 'TOTAL'
          AND year = 2024 AND distance != 'TOTAL'
        GROUP BY distance
    )
    SELECT b.distance,
           CASE b.distance
               WHEN 'KM_LT50'     THEN 1 WHEN 'KM50-149'   THEN 2
               WHEN 'KM150-299'   THEN 3 WHEN 'KM300-499'  THEN 4
               WHEN 'KM500-999'   THEN 5 WHEN 'KM1000-1999' THEN 6
               WHEN 'KM_GE2000'   THEN 7 ELSE 99 END AS band_order,
           b.mio_tkm,
           b.mio_tkm * e.ghg_gco2e_per_tkm AS co2_tonnes
    FROM bands b
    CROSS JOIN (
        SELECT ghg_gco2e_per_tkm FROM emission_factors
        WHERE vehicle_category = 'All trucks >=3.5t GVW (total)'
    ) e
    ORDER BY band_order
) TO 'dashboard/data/q1_co2_by_band.csv' (HEADER, DELIMITER ',');

-- Q1: electrifiable share (within vs beyond 500 km) ---------------------------
COPY (
    WITH bands AS (
        SELECT distance, SUM(value) AS mio_tkm
        FROM freight_distance
        WHERE unit = 'MIO_TKM' AND tra_type = 'TOTAL'
          AND year = 2024 AND distance != 'TOTAL'
        GROUP BY distance
    ),
    classed AS (
        SELECT CASE
                 WHEN distance IN ('KM_LT50','KM50-149','KM150-299','KM300-499')
                 THEN 'within 500 km' ELSE 'beyond 500 km' END AS distance_class,
               SUM(mio_tkm) AS total_mio_tkm
        FROM bands GROUP BY distance_class
    )
    SELECT distance_class, total_mio_tkm,
           ROUND(total_mio_tkm / SUM(total_mio_tkm) OVER () * 100, 1) AS share_percentage
    FROM classed ORDER BY total_mio_tkm DESC
) TO 'dashboard/data/q1_electrifiable.csv' (HEADER, DELIMITER ',');

-- Q1: top 15 regions by tonnage loaded ---------------------------------------
COPY (
    SELECT region_name, value AS thousand_tonnes
    FROM freight_region
    WHERE unit = 'THS_T' AND year = 2024 AND nst07 = 'TOTAL'
    ORDER BY thousand_tonnes DESC LIMIT 15
) TO 'dashboard/data/q1_regions.csv' (HEADER, DELIMITER ',');

-- Q1: national tonne-km trend, year over year --------------------------------
COPY (
    WITH yearly AS (
        SELECT year, SUM(value) AS total_tkm
        FROM freight_distance
        WHERE unit = 'MIO_TKM' AND tra_type = 'TOTAL' AND distance != 'TOTAL'
        GROUP BY year
    )
    SELECT year, total_tkm,
           total_tkm - LAG(total_tkm) OVER (ORDER BY year) AS change_vs_prev,
           ROUND((total_tkm - LAG(total_tkm) OVER (ORDER BY year))
                 / LAG(total_tkm) OVER (ORDER BY year) * 100, 1) AS change_pct
    FROM yearly ORDER BY year
) TO 'dashboard/data/q1_tkm_yoy.csv' (HEADER, DELIMITER ',');

-- Q2: baseline cost per km + break-even (single row) --------------------------
COPY (
    WITH diesel_2024 AS (
        SELECT AVG(price_with_tax_eur_per_l) AS avg_diesel_price
        FROM diesel_price WHERE YEAR(date) = 2024
    ),
    elec_2024 AS (
        SELECT AVG(price_eur_per_kwh) AS avg_elec_price
        FROM electricity_price
        WHERE year = 2024 AND tax = 'X_VAT' AND nrg_cons = 'MWH500-1999'
    ),
    toll_diesel AS (
        SELECT total_ct_km / 100.0 AS diesel_toll_per_km
        FROM toll_rates
        WHERE co2_class = 1 AND euro_class = 'Euro 6'
          AND weight_axle_class = '>18t 5+ axles'
    ),
    costs AS (
        SELECT
            ((p.diesel_l_per_100km / 100.0) * (d.avg_diesel_price / (1.0 + p.vat_rate)))
                + t.diesel_toll_per_km + p.maint_diesel_eur_per_km AS diesel_cost_per_km,
            ((p.etruck_kwh_per_100km / 100.0) * e.avg_elec_price)
                + 0.0 + p.maint_electric_eur_per_km AS electric_cost_per_km,
            p.purchase_gap_eur, p.ownership_years
        FROM p
        CROSS JOIN diesel_2024 d CROSS JOIN elec_2024 e CROSS JOIN toll_diesel t
    )
    SELECT diesel_cost_per_km, electric_cost_per_km,
           (diesel_cost_per_km - electric_cost_per_km) AS eur_saved_per_km,
           purchase_gap_eur
             / ((diesel_cost_per_km - electric_cost_per_km) * ownership_years) AS break_even_annual_km
    FROM costs
) TO 'dashboard/data/q2_costs.csv' (HEADER, DELIMITER ',');

-- Q2: sensitivity tornado (7 scenarios) --------------------------------------
COPY (
    WITH diesel_2024 AS (
        SELECT AVG(price_with_tax_eur_per_l) AS avg_diesel_price
        FROM diesel_price WHERE YEAR(date) = 2024
    ),
    elec_2024 AS (
        SELECT AVG(price_eur_per_kwh) AS avg_elec_price
        FROM electricity_price
        WHERE year = 2024 AND tax = 'X_VAT' AND nrg_cons = 'MWH500-1999'
    ),
    toll_diesel AS (
        SELECT total_ct_km / 100.0 AS diesel_toll_per_km
        FROM toll_rates
        WHERE co2_class = 1 AND euro_class = 'Euro 6'
          AND weight_axle_class = '>18t 5+ axles'
    ),
    scenarios AS (
        SELECT * FROM (VALUES
            ('baseline',            0.00, 1.0, 0.0, 200000.0),
            ('diesel_minus_0_20',  -0.20, 1.0, 0.0, 200000.0),
            ('diesel_plus_0_20',    0.20, 1.0, 0.0, 200000.0),
            ('electricity_doubles', 0.00, 2.0, 0.0, 200000.0),
            ('toll_exemption_ends', 0.00, 1.0, 1.0, 200000.0),
            ('gap_150k',            0.00, 1.0, 0.0, 150000.0),
            ('gap_250k',            0.00, 1.0, 0.0, 250000.0)
        ) AS t(scenario, diesel_delta, elec_mult, electric_toll_mult, gap_override)
    ),
    costs AS (
        SELECT s.scenario, s.gap_override, p.ownership_years,
            ((p.diesel_l_per_100km / 100.0) * ((d.avg_diesel_price + s.diesel_delta) / (1.0 + p.vat_rate)))
                + t.diesel_toll_per_km + p.maint_diesel_eur_per_km AS diesel_cost_per_km,
            ((p.etruck_kwh_per_100km / 100.0) * (e.avg_elec_price * s.elec_mult))
                + (s.electric_toll_mult * t.diesel_toll_per_km)
                + p.maint_electric_eur_per_km AS electric_cost_per_km
        FROM p
        CROSS JOIN diesel_2024 d CROSS JOIN elec_2024 e CROSS JOIN toll_diesel t
        CROSS JOIN scenarios s
    )
    SELECT scenario, diesel_cost_per_km, electric_cost_per_km,
           (diesel_cost_per_km - electric_cost_per_km) AS eur_saved_per_km,
           gap_override / ((diesel_cost_per_km - electric_cost_per_km) * ownership_years) AS break_even_annual_km
    FROM costs ORDER BY break_even_annual_km ASC
) TO 'dashboard/data/q2_sensitivity.csv' (HEADER, DELIMITER ',');

-- Q3: quarterly diesel variance vs 2021 budget -------------------------------
COPY (
    WITH budget_2021 AS (
        SELECT AVG(price_with_tax_eur_per_l) AS budget_price
        FROM diesel_price WHERE YEAR(date) = 2021
    ),
    quarterly_actuals AS (
        SELECT DATE_TRUNC('quarter', date) AS quarter_start,
               AVG(price_with_tax_eur_per_l) AS actual_price
        FROM diesel_price WHERE YEAR(date) BETWEEN 2021 AND 2024
        GROUP BY 1
    )
    SELECT q.quarter_start, q.actual_price, b.budget_price,
           (q.actual_price - b.budget_price) AS absolute_variance_eur_l,
           ((q.actual_price - b.budget_price) / b.budget_price) * 100.0 AS percent_variance,
           ((p.diesel_l_per_100km / 100.0) * (q.actual_price / (1.0 + p.vat_rate))) AS actual_cost_per_km,
           ((p.diesel_l_per_100km / 100.0) * (b.budget_price / (1.0 + p.vat_rate))) AS budget_cost_per_km,
           ((p.diesel_l_per_100km / 100.0) * (q.actual_price / (1.0 + p.vat_rate)))
             - ((p.diesel_l_per_100km / 100.0) * (b.budget_price / (1.0 + p.vat_rate))) AS variance_cost_per_km
    FROM quarterly_actuals q
    CROSS JOIN budget_2021 b CROSS JOIN p
    ORDER BY q.quarter_start
) TO 'dashboard/data/q3_variance.csv' (HEADER, DELIMITER ',');

-- Q2 stage 1: the parameterised cost-model inputs.
--
-- Two tables:
--   params - long/key-value, one row per assumption (easy to read and edit)
--   p      - the same values pivoted to a single wide row (easy to compute with)
--
-- Every value traces to docs/assumptions.md. Prices are NOT here: diesel,
-- electricity and toll rates come from their own tables, so the model always
-- uses real data rather than hardcoded constants.
--
-- Weakest inputs, to be flexed in the stage-4 sensitivity: purchase_gap_eur
-- (manufacturers don't publish e-truck list prices) and maint_diesel_eur_per_km.

CREATE OR REPLACE TABLE params AS
SELECT * FROM (VALUES
    ('diesel_l_per_100km',        30.0),      -- #1  ICCT, 40t long-haul
    ('etruck_kwh_per_100km',     103.0),      -- #2  eActros 600 real-world
    ('purchase_gap_eur',      200000.0),      -- #3  ESTIMATE, midpoint of 180-220k
    ('maint_diesel_eur_per_km',    0.15),     -- #10 ESTIMATE, industry-typical
    ('maint_electric_eur_per_km',  0.075),    -- #10 ~50% lower than diesel (TNO)
    ('ownership_years',            5.0),      -- #11 first-owner horizon
    ('vat_rate',                   0.19)      -- German VAT; hauliers reclaim it
) AS t(param, value);

-- Pivot long -> wide via conditional aggregation. Each CASE yields the value
-- on its one matching row and NULL elsewhere; MAX ignores NULLs and picks it
-- out. No GROUP BY: the whole table collapses to a single row.
-- Cast to DOUBLE so later division doesn't inherit DECIMAL rounding.
CREATE OR REPLACE TABLE p AS
SELECT
    MAX(CASE WHEN param = 'diesel_l_per_100km'        THEN value END)::DOUBLE AS diesel_l_per_100km,
    MAX(CASE WHEN param = 'etruck_kwh_per_100km'      THEN value END)::DOUBLE AS etruck_kwh_per_100km,
    MAX(CASE WHEN param = 'purchase_gap_eur'          THEN value END)::DOUBLE AS purchase_gap_eur,
    MAX(CASE WHEN param = 'maint_diesel_eur_per_km'   THEN value END)::DOUBLE AS maint_diesel_eur_per_km,
    MAX(CASE WHEN param = 'maint_electric_eur_per_km' THEN value END)::DOUBLE AS maint_electric_eur_per_km,
    MAX(CASE WHEN param = 'ownership_years'           THEN value END)::DOUBLE AS ownership_years,
    MAX(CASE WHEN param = 'vat_rate'                  THEN value END)::DOUBLE AS vat_rate
FROM params;

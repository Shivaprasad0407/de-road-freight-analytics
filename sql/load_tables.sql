-- Load every table into DuckDB. Run once from the repo root:
--   duckdb freight.duckdb
--   .read sql/load_tables.sql
-- IF NOT EXISTS makes it safe to re-run.
--
-- freight.duckdb is gitignored (a rebuildable artefact), so this file plus
-- sql/q2_params.sql is what actually reproduces the database.

-- Q1: freight volumes
CREATE TABLE IF NOT EXISTS freight_distance AS
    SELECT * FROM read_csv_auto('data_clean/freight_distance_class_de.csv');

CREATE TABLE IF NOT EXISTS freight_region AS
    SELECT * FROM read_csv_auto('data_clean/freight_region_de.csv');

-- Q1: emission factors and goods-type labels
CREATE TABLE IF NOT EXISTS emission_factors AS
    SELECT * FROM read_csv_auto('data_raw/uba_emission_factors_freight_2024.csv');

CREATE TABLE IF NOT EXISTS nst07_goods AS
    SELECT * FROM read_csv_auto('data_raw/nst07_goods_names.csv');

-- Q2: toll rates by CO2 class (the exemption is the core of Q2)
CREATE TABLE IF NOT EXISTS toll_rates AS
    SELECT * FROM read_csv_auto('data_raw/tollcollect_maut_rates_2024.csv');

-- Q2/Q3: prices
CREATE TABLE IF NOT EXISTS diesel_price AS
    SELECT * FROM read_csv_auto('data_clean/diesel_price_de_weekly.csv');

CREATE TABLE IF NOT EXISTS electricity_price AS
    SELECT * FROM read_csv_auto('data_clean/electricity_price_de.csv');

-- Then run sql/q2_params.sql to build the params and p tables.

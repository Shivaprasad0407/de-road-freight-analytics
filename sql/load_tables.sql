-- Load the clean tables into DuckDB. Run once against a persistent database:
--   duckdb freight.duckdb
--   .read sql/load_tables.sql
-- IF NOT EXISTS makes it safe to re-run.

CREATE TABLE IF NOT EXISTS freight_distance AS
    SELECT * FROM read_csv_auto('data_clean/freight_distance_class_de.csv');

CREATE TABLE IF NOT EXISTS freight_region AS
    SELECT * FROM read_csv_auto('data_clean/freight_region_de.csv');

CREATE TABLE IF NOT EXISTS emission_factors AS
    SELECT * FROM read_csv_auto('data_raw/uba_emission_factors_freight_2024.csv');

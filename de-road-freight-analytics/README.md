# German Road Freight: Cost and CO2 Analytics

An end-to-end analysis of road freight costs and emissions in Germany, built on public data (Eurostat, Umweltbundesamt, Toll Collect, EU Weekly Oil Bulletin).

**Stack:** Python (pandas) for ingestion and cleaning, DuckDB (SQL) for modeling, Power BI for reporting.

## The three questions this project answers

**Q1. Where does road freight CO2 concentrate in Germany, and what share could realistically be electrified?**
Total emissions are known. The open question is the distribution: which regions and which distance bands carry the most CO2, and how much of that freight falls within the range where battery-electric trucks are viable today. The output is CO2 by region and distance band, plus an "electrifiable share" under explicitly stated range assumptions.

**Q2. At what annual mileage does an electric truck beat a diesel truck on total cost, under the current German toll system?**
Since December 2023 the German truck toll (Lkw-Maut) includes a CO2 surcharge of 200 EUR per tonne of CO2. Electric trucks are exempt from the toll until mid-2031. Diesel therefore pays fuel plus toll plus CO2 surcharge, electric pays electricity and no toll, but costs more to buy. This project models cost per km for both drivetrains and finds the break-even annual mileage, with sensitivity analysis on diesel price, electricity price, and the end of the toll exemption.

**Q3. How much did diesel price volatility from 2021 to 2025 move freight cost per km against a fixed budget?**
Using weekly diesel prices, the model computes actual fuel cost per km per quarter against a budgeted price and reports the variance in EUR and percent. This is a standard budget-vs-actual variance analysis applied to fleet operations.

## Data sources

| Data | Source | Used for |
|---|---|---|
| Road freight volumes (tonnes, tonne-km) by region and distance class | Eurostat, road freight transport statistics (road_go family) | Q1 |
| Average CO2 emission factors for road freight (g CO2 per tonne-km) | Umweltbundesamt, Emissionsdaten des Verkehrs | Q1, Q2 |
| Toll rates per km by CO2 emission class | Toll Collect, official Mauttarife | Q2 |
| Weekly diesel prices, Germany | European Commission, Weekly Oil Bulletin | Q2, Q3 |
| Industrial electricity prices | Destatis / BDEW | Q2 |
| Truck consumption and purchase price assumptions | Manufacturer and ICCT publications, documented in docs/assumptions.md | Q2 |

Methodology reference for emissions accounting: GLEC Framework (Smart Freight Centre).

## Repository structure

```
data_raw/     Raw downloads, not committed (see .gitignore). Download scripts in src/ reproduce them.
data_clean/   Cleaned, analysis-ready tables.
src/          Python scripts for download and cleaning.
sql/          DuckDB models: staging, emissions, cost model, variance.
dashboard/    Power BI file and exported screenshots.
docs/         Assumptions log and data notes.
```

## Status

- [x] Questions defined, scaffold created
- [ ] Data downloaded and profiled
- [ ] Cleaning scripts
- [ ] SQL models (Q1, Q2, Q3)
- [ ] Power BI report
- [ ] Final write-up

## Limitations

Documented in docs/ as the project progresses. Key known ones upfront: emission factors are fleet averages, not vehicle-specific, and the cost model uses stated assumptions for consumption and purchase prices rather than proprietary fleet data.

# German Road Freight: Cost and CO2 — Project Report

**Question in one line:** Can battery-electric trucks beat diesel on cost in
Germany today, where does road-freight CO2 actually sit, and what has the
post-2021 diesel market done to fleet operating cost?

**Answer in one line:** Most freight CO2 is on routes already within electric
range; e-trucks *do* win on total cost today — but mainly because they are
exempt from the CO2 truck toll, not because of fuel savings — and diesel has
settled onto a structurally higher cost plateau that never returned to its
pre-2021 level.

---

## 1. Executive summary

Three findings, each built on public data and a transparent SQL cost model:

- **Q1 — The CO2 is where the trucks can already go electric.** German road
  freight emitted about **31.9 million tonnes of CO2e in 2024**. About **81% of
  tonne-kilometres — and therefore of the CO2 — is carried on trips within a
  500 km single-charge range**, where today's battery-electric trucks are
  viable. Electrification is not blocked by range for the bulk of the problem.

- **Q2 — E-trucks win today, but on policy, not physics.** Modelled operating
  cost is about **0.91 EUR/km for diesel versus 0.32 EUR/km for electric**, a
  break-even annual mileage of **~67,000 km**. Typical long-haul trucks run
  100,000–130,000 km/year, so an e-truck repays its ~200,000 EUR price premium
  in roughly **2.8 years**. But the sensitivity analysis shows the **toll
  exemption alone is 58% of that per-km advantage**. If the exemption ends in
  2031, break-even jumps to **~161,000 km/year — above real-world mileage** —
  and the case collapses. Diesel price is almost irrelevant by comparison.

- **Q3 — The diesel shock became a plateau.** Against a fixed pre-shock budget
  (the 2021 German annual mean, 1.389 EUR/l), diesel peaked at **+46.8% in
  Q2 2022 and never came back**. Every quarter from 2022 through 2024 sits
  **14–47% above the 2021 baseline**. At the peak that is **+0.164 EUR/km, or
  about 16,000 EUR/year of extra fuel per truck** versus plan.

**The through-line:** Q1 sizes the opportunity, Q2 shows the switch pays off
under current policy, and Q3 shows the diesel status quo keeps getting more
expensive. The single most important variable in the whole analysis is a policy
lever — the 2031 expiry of the truck-toll CO2 exemption — not a market price.

---

## 2. Background

Since December 2023 the German truck toll (Lkw-Maut) includes a CO2 surcharge.
Zero-emission trucks are exempt from the toll until the end of 2031. Diesel
trucks therefore pay fuel, toll, and the CO2 surcharge; electric trucks pay for
electricity, no toll, but cost far more to buy. That trade-off — plus a diesel
market that has been anything but stable since 2021 — is what this project
quantifies.

## 3. Data and method

**Sources (all public, all aggregate):**

| Data | Source | Used for |
|---|---|---|
| Road-freight volumes (tonne-km, tonnes) by distance class and region | Eurostat (road_go family) | Q1 |
| CO2 emission factors (g CO2e per tonne-km) | Umweltbundesamt (UBA), TREMOD | Q1, Q2 |
| Truck toll rates per km by CO2 class | Toll Collect / BALM (in force 1 July 2024) | Q2 |
| Weekly diesel prices, Germany | EU Weekly Oil Bulletin | Q2, Q3 |
| Industrial electricity prices by consumption band | Eurostat nrg_pc_205 | Q2 |
| Truck consumption and price assumptions | Manufacturer + ICCT publications | Q2 |

**Tooling:** Python (pandas) for download and cleaning; DuckDB (SQL) for the
model; Power BI for the report. The emission accounting follows the GLEC
Framework (well-to-wheel).

**Key modelling choices (full log in `docs/assumptions.md`):**

- Diesel consumption 30 l/100km; e-truck 103 kWh/100km (eActros 600 real-world).
- Purchase-price gap 200,000 EUR — an **estimate**, and the weakest single input,
  because manufacturers do not publish e-truck list prices. Flexed in Q2's
  sensitivity from 150,000 to 250,000.
- Maintenance 0.15 EUR/km diesel, 0.075 EUR/km electric (~50% lower, TNO).
- 5-year first-owner horizon.
- **VAT is reclaimed by hauliers**, so the cost-relevant diesel price is the
  pump price divided by 1.19, not the raw pump price. Actual and budget prices
  are treated identically, so the Q3 variance is pure price movement.
- Electricity is priced at the industrial depot-charging band (~10-truck fleet,
  0.234 EUR/kWh ex-VAT). Public fast-charging is 2–3× higher and would erase
  much of the advantage — so charging cost is itself a sensitivity, not a fact.

Every price in the model is pulled live from a real table (a CTE), never
hardcoded, so the model updates when the data does.

## 4. Q1 — Where the CO2 is, and what is electrifiable

Applying UBA's fleet-average factor of 118 g CO2e/tonne-km to 2024 tonne-km
gives roughly **31.9 Mt CO2e**. Split by distance band, the CO2 concentrates on
short and medium hauls: trips under 500 km carry **218,572 million tonne-km
(80.9%)**, versus **51,754 (19.1%)** beyond 500 km. Because the emission factor
is flat, the CO2 share equals the tonne-km share — so about **81% of German
road-freight CO2 is on routes already within single-charge electric range**
(assumption: 500 km per charge, eActros 600).

The regional view is reported in **tonnes loaded, not CO2**, because the NUTS3
regional dataset has no tonne-km and the emission factor is per tonne-km.
Ports and extraction hubs dominate — **Hamburg leads at 54,855 thousand tonnes**,
nearly double the next region. This measures where freight originates, not where
the CO2 is emitted.

Historical context: national tonne-km peaked in 2007, fell about 10% in the 2009
financial crisis, and dipped only 2.4% during COVID in 2020 — freight kept
moving while passenger transport collapsed.

## 5. Q2 — The cost model and the policy finding

Per-kilometre operating cost, built from real 2024 prices:

| Component | Diesel (EUR/km) | Electric (EUR/km) |
|---|---|---|
| Energy | 0.415 | 0.241 |
| Toll | 0.348 | 0.000 (exempt) |
| Maintenance | 0.150 | 0.075 |
| **Total** | **0.913** | **0.316** |

The e-truck saves **0.597 EUR/km**. Dividing the 200,000 EUR purchase gap by that
saving over 5 years gives a **break-even mileage of ~67,000 km/year** — well
below typical long-haul use, so the truck pays back in about **2.8 years**.

The decisive result is *where* the saving comes from. Of the 0.597 EUR/km
advantage, the **toll exemption is 0.348 (58%)**, energy is 0.174 (29%), and
maintenance is 0.075 (13%). The sensitivity analysis makes the consequence
explicit:

| Scenario | Break-even (km/yr) |
|---|---|
| Purchase gap 150k | 50,300 |
| Diesel +0.20 EUR/l | 61,800 |
| **Baseline** | **67,000** |
| Diesel −0.20 EUR/l | 73,200 |
| Purchase gap 250k | 83,800 |
| Electricity doubles | 112,500 |
| **Toll exemption ends** | **160,800** |

Only the end of the toll exemption pushes break-even above real-world mileage.
A 20-cent swing in diesel moves it by ~5,000 km; ending the exemption moves it by
~94,000 km. **Policy, not fuel economics, is what makes the e-truck competitive**,
which makes the 2031 exemption expiry the variable that matters most — and the
one a haulier cannot control.

## 6. Q3 — What the diesel market did to operating cost

Using the 2021 German annual mean diesel price (1.389 EUR/l, with tax) as a
fixed pre-shock budget, each quarter's actual price is compared to it. The 2021
quarters straddle the budget and average to it (an internal consistency check).
From 2022 on the picture is a shock that never healed: diesel peaked at
**+46.8% over budget in Q2 2022**, and **every quarter through Q4 2024 stayed
14–47% above** the baseline.

Expressed per kilometre driven (same consumption and VAT treatment as Q2), the
Q2 2022 peak is **+0.164 EUR/km** — about **16,000 EUR/year of extra fuel cost
for a single 100,000 km/year truck** versus the 2021 plan. Even the cheapest
recent quarter (Q4 2024) still runs ~0.049 EUR/km, roughly 5,000 EUR/year, over
budget. The variance never closes. For a 50-truck fleet, that is a quarter of a
million euros a year of fuel cost the pre-shock budget never anticipated — the
structural backdrop that makes the Q2 e-truck economics worth acting on.

## 7. Conclusion

Electrification of German road freight is technically addressable — most of the
CO2 is on routes within electric range — and economically attractive *today*.
But the economics rest on a policy scaffold. The toll exemption, not diesel
prices or battery costs, is doing most of the work in the break-even, and it is
scheduled to end in 2031. Anyone underwriting an e-truck purchase on today's
~2.8-year payback is really betting on that exemption staying in place. The
diesel side offers no relief: cost has re-based permanently higher since 2021.
The strategic recommendation follows directly — treat the 2031 policy cliff, not
fuel price, as the primary risk in any fleet-electrification business case, and
prioritise mileage-heavy routes that repay the premium well before it.

## 8. Limitations

- **Emission factors are fleet averages** (well-to-wheel), not vehicle-specific.
  A per-band split would refine Q1 but not change its headline.
- **The purchase-price gap is an estimate** and the weakest input; it is the
  reason Q2 flexes it across 150k–250k.
- **Maintenance costs are industry-typical estimates**, not sourced fleet data.
- **Regional freight is in tonnes, not tonne-km**, so it cannot be converted to
  CO2; it answers "where freight originates", not "where CO2 is emitted".
- **Empty running** (~21.6% of EU vehicle-km in 2024) is only partly absorbed by
  per-tonne-km factors.
- **Charging is priced at industrial depot rates**; reliance on public fast
  charging would materially weaken the e-truck case.
- **Toll rates are the July 2024 schedule**; future CO2-surcharge changes are
  not modelled beyond the exemption-expiry scenario.

## 9. Data protection / pseudonymisation note

This project uses **only public, aggregate statistics** — Eurostat, the German
Umweltbundesamt, Toll Collect/BALM tariff tables, and the EU Weekly Oil Bulletin.
None of these contain personal data, and no natural person is identifiable at any
point in the pipeline, so **no pseudonymisation is required** under GDPR.

If the model were later extended with a real operator's data — for example fleet
telematics, driver records, or customer consignments — that data *would* fall
under GDPR. In that case the approach would be: strip direct identifiers on
ingestion, replace vehicle/driver IDs with salted surrogate keys held in a
separate restricted mapping, aggregate to the route/quarter level before
analysis, and never commit raw operational data to the repository (the existing
`.gitignore` already keeps raw downloads out of version control).

## 10. Reproducibility

The whole analysis rebuilds from public data:

1. `src/` — Python scripts download and clean the source data into `data_clean/`.
2. `sql/load_tables.sql` + `sql/q2_params.sql` — build the DuckDB tables and the
   cost-model parameters.
3. `sql/q1_*.sql`, `sql/q2_*.sql`, `sql/q3_diesel_variance.sql` — the models,
   each documented with its result and the SQL concept it uses.
4. `sql/export_dashboard_csvs.sql` — exports the verified result sets to
   `dashboard/data/*.csv`.
5. `dashboard/Freight Dashboard.pbix` — the Power BI report, reading those CSVs,
   themed with `dashboard/freight_theme.json`.

Assumptions and data caveats are logged in `docs/assumptions.md` and
`docs/data_notes.md`.

# Assumptions log

Every number that is not directly from a source dataset is recorded here with its origin and date checked.

| # | Assumption | Value | Source | Date checked |
|---|---|---|---|---|
| 1 | Diesel truck fuel consumption (40t long-haul) | 30 l/100km (range 30-33) | ICCT: 30 l/100km combined-load reference for 40t tractor-trailer; 33.1 l/100km for a 2015 baseline long-haul cycle | 2026-07-16 |
| 2 | E-truck energy consumption (40t long-haul) | 103 kWh/100km | Daimler Truck eActros 600, real-world average over 15,000 km European test tour | 2026-07-16 |
| 3 | Diesel vs e-truck purchase price gap | ~180,000-220,000 EUR (ESTIMATE, weakest input) | Mercedes eActros 600 ~2.5x a comparable diesel Actros; exact list prices not published. Cross-check with ICCT TCO before final | 2026-07-16 |
| 4 | E-truck viable range per charge | 500 km | Mercedes eActros 600 (621 kWh LFP battery, 40t GCW) | 2026-07-16 |
| 5 | Budget diesel price for variance model (Q3) | provisional 1.50 EUR/l; finalize as base-year mean | Method: compute the annual mean DE diesel price for a chosen base year (e.g. 2021) from the Oil Bulletin we already hold, then hold it fixed as the budget | 2026-07-16 |
| 8 | Industrial electricity price for e-truck charging (Q2) | ~0.20 EUR/kWh depot; sensitivity to public charging 0.40-0.60 | Eurostat non-household DE ~0.20 EUR/kWh (Dec 2024); medium band 20-500 MWh 23.3 ct/kWh; avg without reductions 16.77 ct/kWh 2024 | 2026-07-16 |
| 6 | Emission factor applied to freight tonne-km (Q1) | 118 g CO2e/tkm fleet average, OR per-band split (see note) | UBA Verkehrsmittelvergleich Gueterverkehr 2024, TREMOD 6.71B | 2026-07-16 |
| 7 | Distance-band to vehicle-class mapping for emission factors (Q1) | Short bands lean to lighter/rigid trucks (higher g/tkm), long bands to Sattelzuege (101 g/tkm) | Modeling choice, not sourced | 2026-07-16 |

Notes on #6 and #7:
- The UBA factors are well-to-wheel CO2e (include fuel supply chain + CH4/N2O), not tailpipe CO2. Q2's toll CO2 surcharge is tailpipe-based. Do not mix the two scopes across questions without stating it.
- Simplest defensible Q1 default: apply 118 g CO2e/tkm (Lkw gesamt) uniformly. The richer version maps distance bands to vehicle classes, but that mapping is an assumption we have to defend (#7), not data.

| 9 | Q1 regional view is reported in tonnes loaded, not CO2 | Regional freight = THS_T (tonnes loaded); CO2 reported only at distance-band level | Data limitation: `road_go_na_rl3g` has no tonne-km at NUTS3, and the emission factor is per tonne-km | 2026-07-17 |

Note on #9:
- CO2 per region cannot be derived from tonnes alone - the units don't match the per-tonne-km factor. Allocating national tonne-km to regions by tonnage share was considered and rejected: it assumes identical average haul distance in every region, and under a flat factor it produces a CO2 ranking mathematically identical to the tonnage ranking, i.e. no new information dressed up as a carbon result. Report tonnes for the regional view, keep CO2 at the distance-band level, and state this in the README limitations.

Notes on #3, #5, #8:
- #3 is the weakest number in the whole model. Manufacturers do not publish e-truck list prices, so the gap is an estimate. The break-even mileage in Q2 is highly sensitive to it — run the cost model across a price-gap range (e.g. 150k-250k), do not report a single break-even point as if it were precise.
- #5: the "budget" price is a choice, not a fact. Tying it to a base-year mean from our own Oil Bulletin data keeps it reproducible and defensible. State the base year explicitly in the Q3 output.
- #8: depot charging at industrial rates is the realistic base case; public fast-charging is 2-3x higher and would erase much of the e-truck advantage. Treat electricity price as a sensitivity axis, not a fixed input.

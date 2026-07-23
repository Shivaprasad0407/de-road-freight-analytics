# Dashboard makeover — punch-list

Ordered by impact. The first three items do 80% of the "advanced + actionable"
lift. Everything here you apply in Power BI Desktop; nothing changes the data.

## 1. Import the theme (2 minutes, biggest visual jump)
View → Themes → Browse for themes → `dashboard/freight_theme.json`.
This restyles all four pages at once: coherent palette, Segoe UI Semibold
titles, white cards with rounded borders and a soft shadow on a light-grey
canvas. Diesel/amber vs electric/green is baked into the palette order.

## 2. Fix two Q3 correctness bugs (not cosmetic)
- **Both Q3 charts use the auto Date Hierarchy**, so the axis shows *Year* and
  needs drill-down. In each chart's X-axis well, remove the
  `quarter_start` hierarchy and drag `quarter_start` back in, then click the
  field dropdown and pick **`quarter_start`** (not "Date Hierarchy"). You'll get
  a clean 16-quarter timeline.
- **The "peak variance" card is set to Sum** — it's adding all 16 quarters into
  a meaningless number. Click the field in the card → change aggregation to
  **Maximum**. It should then read ~+46.8%.

## 3. Insight-driven titles (turns charts into statements)
A title that states the finding is what makes a dashboard read as "actionable."
Replace every auto-title. Format visual → General → Title → Text:

Q1 · Emissions
- Column: **"Most freight CO2 comes from trips under 500 km (2024)"**
- Donut: **"81% of tonne-km sits within a 500 km electric range"**
- Bar: **"Freight originates at ports & extraction hubs — Hamburg leads"**
- Card: **"Total road-freight CO2e, 2024"**

Q2 · Cost model
- Diesel card: **"Diesel cost / km"**  · Electric card: **"Electric cost / km"**
- Break-even card: **"Break-even mileage (km/yr)"**
- Tornado: **"Only ending the toll exemption pushes break-even above real mileage"**
- Payback card: **"Payback at selected mileage (years)"**
- Slicer: **"Annual mileage (km)"**

Q3 · Diesel variance
- Line: **"Diesel has sat above the 2021 budget every quarter since 2022"**
- Column: **"Quarterly diesel variance vs the 2021 budget"**
- Peak card: **"Peak variance vs budget"**
- Overrun card: **"Extra fuel per truck at peak (€/yr)"**

## 4. Number formatting (kills the "raw data" look)
- All €/km cards and axes → 2 decimals, currency or "€" suffix.
- `break_even_annual_km`, mileage → whole number, thousands separator.
- `percent_variance` → 1 decimal, "%" suffix.
- Total CO2 card → display units Millions, 1 decimal ("31.9M").
- Turn on data labels on the donut (percentage) and the tornado (values).

## 5. Conditional formatting (the "actionable" signal)
- **Tornado bars** — Format → Bars → Color → fx (conditional):
  Rules on `break_even_annual_km`: if value >= 100000 → red (#A34A3F),
  else → green (#2E5E4E). Now the eye instantly sees which scenarios blow past
  real-world mileage (only electricity-doubles and toll-exemption-ends go red).
- **Q3 variance columns** — fx on column color, rules on `percent_variance`:
  if < 0 → green (under budget), if >= 0 → red (over budget). The 2021 dip is
  green, the 2022+ plateau is a wall of red.

## 6. Build the summary page (currently near-empty "Page 1")
Rename the tab **"Overview"** and drag it first. Layout:
- A text box across the top: **"German Road Freight — Cost & CO2 (2024)"**,
  and a subtitle line: *"Can battery-electric trucks beat diesel, and what does
  the diesel status quo cost?"*
- Three big KPI cards in a row (reuse existing measures):
  - `co2_tonnes` (Sum, Millions) → **"31.9 Mt CO2e in 2024"**
  - `break_even_annual_km` from q2_costs → **"67k km/yr break-even"**
  - `percent_variance` (Max) from q3_variance → **"+46.8% peak diesel variance"**
- Under each card, a one-line text box (the finding):
  - *"81% of it is on routes within electric range."*
  - *"Below typical 100–130k mileage — e-trucks pay back in ~2.8 yrs."*
  - *"Diesel never returned to its pre-shock 2021 budget."*
- Optional: three Buttons (Insert → Buttons → Blank) titled Q1 / Q2 / Q3 with
  Action = Page navigation, so the overview doubles as a nav menu.

## 7. Alignment & spacing (quiet professionalism)
- Select related visuals → Format → Align (left/top) and Distribute, so cards
  and charts sit on a clean grid. Misaligned visuals are the #1 amateur tell.
- Keep one consistent gap (e.g. 16 px) between visuals.
- Give each page a short title text box top-left if the tab name isn't enough.

## Optional stretch
- On the tornado, add an X-axis constant line at 100,000 labelled
  "typical long-haul mileage" (Analytics pane) so the threshold is explicit.
- On the Q3 line, add a constant line at the 1.389 budget if you dropped the
  budget series, or keep both lines and shade the gap.

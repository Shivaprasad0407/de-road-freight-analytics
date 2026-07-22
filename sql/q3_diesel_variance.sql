-- Q3: quarterly diesel cost variance vs a fixed pre-shock budget.
--
-- Budget-vs-actual pattern: each quarter's actual diesel price is compared to a
-- fixed budget = the 2021 DE annual mean (1.389 EUR/l with tax, assumption #5,
-- pre-shock base year). The budget is SOURCED from a CTE, not hardcoded, so it
-- stays reproducible. 16 quarters, 2021-2024.
--
-- Two layers:
--   per-litre: actual - budget, and percent variance.
--   per-km:    both prices converted to operating EUR/km using the SAME
--              consumption and VAT assumptions as the Q2 model (CROSS JOIN p:
--              30 l/100km, VAT reclaimed via / (1 + vat_rate)). Percent variance
--              is identical to the per-litre percent (linear rescale), so the
--              value of this layer is the absolute EUR/km number.
--
-- Findings (verified):
--   * 2021 quarters straddle the budget and cancel to ~0 (budget is the 2021
--     mean) - internal consistency check. 2024 avg ~+18.6% (mean 1.647).
--   * Shock: Q2 2022 peaked +46.8% / +0.164 EUR/km over budget and NEVER
--     returned. Every quarter 2022-2024 sits +14% to +47% above baseline: a
--     structural plateau, not a transient spike.
--   * +0.164 EUR/km = ~16,380 EUR/yr extra fuel per 100,000 km/yr truck vs the
--     2021 plan; even Q4 2024 (+0.049) is still ~4,940 EUR/yr. Variance never closes.

WITH budget_2021 AS (
    -- Sourced budget baseline (with tax)
    SELECT AVG(price_with_tax_eur_per_l) AS budget_price
    FROM diesel_price
    WHERE YEAR(date) = 2021
),
quarterly_actuals AS (
    -- Weekly Oil Bulletin rolled up to quarters (with tax)
    SELECT
        DATE_TRUNC('quarter', date) AS quarter_start,
        AVG(price_with_tax_eur_per_l) AS actual_price
    FROM diesel_price
    WHERE YEAR(date) BETWEEN 2021 AND 2024
    GROUP BY 1
)
SELECT
    q.quarter_start,
    q.actual_price,
    b.budget_price,
    (q.actual_price - b.budget_price) AS absolute_variance_eur_l,
    ((q.actual_price - b.budget_price) / b.budget_price) * 100.0 AS percent_variance,
    -- Operating fuel cost per km, ex-VAT (haulier reclaims VAT); assumptions from p
    ((p.diesel_l_per_100km / 100.0) * (q.actual_price  / (1.0 + p.vat_rate))) AS actual_cost_per_km,
    ((p.diesel_l_per_100km / 100.0) * (b.budget_price   / (1.0 + p.vat_rate))) AS budget_cost_per_km,
    ((p.diesel_l_per_100km / 100.0) * (q.actual_price  / (1.0 + p.vat_rate)))
        - ((p.diesel_l_per_100km / 100.0) * (b.budget_price / (1.0 + p.vat_rate))) AS variance_cost_per_km
FROM quarterly_actuals q
CROSS JOIN budget_2021 b
CROSS JOIN p
ORDER BY q.quarter_start ASC;

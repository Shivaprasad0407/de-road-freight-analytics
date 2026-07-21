-- German road-freight tonnage by goods type (NST2007), 2024.
-- Teaches: keyed INNER JOIN (freight_region.nst07 = nst07_goods.nst07),
-- GROUP BY on the joined label, aggregate alias used in ORDER BY.
--
-- Purpose: tests whether tonnage-based rankings are dominated by heavy bulk
-- goods rather than high-value goods. Result: yes, decisively.
--   Mining/quarrying products   749,693 (2.6x the next category)
--   Transport equipment          64,985 (~1/11th of quarry products)
--   Machinery/computers/electr.  30,370 (last in top 15, ~1/25th)
-- This is the evidence behind the "tonnes measure rock, not economic value"
-- limitation, and behind assumption #9 (no CO2-by-region from tonnage).

SELECT g.goods_name,
       SUM(f.value) AS total_tonnes
FROM freight_region f
INNER JOIN nst07_goods g ON f.nst07 = g.nst07
WHERE f.unit = 'THS_T'
  AND f.year = 2024
  AND f.nst07 != 'TOTAL'
GROUP BY g.goods_name
ORDER BY total_tonnes DESC
LIMIT 15;

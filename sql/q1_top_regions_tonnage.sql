-- Q1 (part 3): top German NUTS3 regions by freight tonnage loaded, 2024.
--
-- Reported in TONNES, not CO2, on purpose: the region dataset has no
-- tonne-km, and the emission factor is per tonne-km (assumption #9).
-- So this answers "where does freight originate", not "where is the CO2".
--
-- nst07 = 'TOTAL' is the all-goods aggregate. Use it OR sum GT01..GT20,
-- never both. No GROUP BY needed: after these filters each region has
-- exactly one row.
--
-- Result pattern: ports and logistics gateways (Hamburg 54,855 - nearly
-- double #2, Bremen, Duisburg) plus heavy extraction regions (Rhein-Erft
-- lignite, Mayen-Koblenz basalt, Börde, Saalekreis). See the tonnage-bias
-- note in docs/data_notes.md before drawing economic conclusions.

SELECT region_name,
       value AS thousand_tonnes
FROM freight_region
WHERE unit = 'THS_T'
  AND year = 2024
  AND nst07 = 'TOTAL'
ORDER BY thousand_tonnes DESC
LIMIT 15;

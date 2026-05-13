-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_CATCH
--
-- Non-zero catch records from hauls in RACEBASE.HAUL 
-- where ABUNDANCE_HAUL = 'Y'. 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_CATCH AS
SELECT 
cc.HAULJOIN, 
cc.SPECIES_CODE, 
cc.WEIGHT AS WEIGHT_KG, 
cc.NUMBER_FISH COUNT, 
cc.VOUCHER -- could be an important add for us later on?
FROM RACEBASE.CATCH cc
-- RIGHT JOIN GAP_PRODUCTS.AKFIN_HAUL hh -- interchangable with the previous line if you also delete the WHERE statement
LEFT JOIN RACEBASE.HAUL hh
ON cc.HAULJOIN = hh.HAULJOIN
WHERE hh.ABUNDANCE_HAUL = 'Y'

-- File slated to be will be removed by end of 2026 if not sooner
-- Table slated to be discontinued, as it is redundant to AKFIN_CPUE

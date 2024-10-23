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
SELECT CRUISEJOIN, HAULJOIN, CATCHJOIN, SPECIES_CODE, 
WEIGHT WEIGHT_KG, NUMBER_FISH COUNT
FROM RACEBASE.CATCH
JOIN RACEBASE.HAUL USING (CRUISEJOIN, HAULJOIN)
WHERE RACEBASE.HAUL.ABUNDANCE_HAUL = 'Y'

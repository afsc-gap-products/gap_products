-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_SPECIMEN
--
-- Created by querying records from RACEBASE.SPECIMEN but only using hauls 
-- with ABUNDANCE_HAUL = 'Y' from the five survey areas w/ survey_definition_id:
-- "AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_SPECIMEN AS 
SELECT HAULJOIN, SPECIMENID AS SPECIMEN_ID, SPECIES_CODE, LENGTH AS LENGTH_MM, 
SEX, WEIGHT AS WEIGHT_G, AGE, MATURITY, GONAD_WT AS GONAD_G, 
SPECIMEN_SUBSAMPLE_METHOD, SPECIMEN_SAMPLE_TYPE, AGE_DETERMINATION_METHOD 

FROM RACEBASE.SPECIMEN 
JOIN RACEBASE.HAUL USING (HAULJOIN)
WHERE RACEBASE.HAUL.ABUNDANCE_HAUL = 'Y'

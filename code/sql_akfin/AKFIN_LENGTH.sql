-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_LENGTH
--
-- Created by querying records from RACEBASE.LENGTH but only using hauls 
-- with ABUNDANCE_HAUL = 'Y' from the five survey areas w/ survey_definition_id:
-- "AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_LENGTH AS
SELECT 
A.HAULJOIN, SPECIES_CODE, SEX, FREQUENCY, LENGTH AS LENGTH_MM,
LENGTH_TYPE, SAMPLE_TYPE 
FROM RACEBASE.LENGTH A, 
RACE_DATA.CRUISES B, 
RACE_DATA.SURVEYS C, 
RACE_DATA.SURVEY_DEFINITIONS D, 
RACEBASE.HAUL F
WHERE A.CRUISE = B.CRUISE 
AND A.VESSEL = B.VESSEL_ID
AND A.HAULJOIN = F.HAULJOIN
AND C.SURVEY_ID =  B.SURVEY_ID 
AND C.SURVEY_DEFINITION_ID = D.SURVEY_DEFINITION_ID 
AND D.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78)
AND F.ABUNDANCE_HAUL = 'Y'

-- SQL Command to Create Materialized View GAP_PRODUCTS.LENGTH
--
-- Created by querying records from RACEBASE.LENGTH but only using hauls 
-- with ABUNDANCE_HAUL = 'Y' from the five survey areas w/ survey_definition_id:
-- "AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.LENGTH AS
SELECT 
    A.HAULJOIN,
    A.SPECIES_CODE,
    A.SEX,
    A.FREQUENCY,
    A.LENGTH AS LENGTH_MM,
    A.LENGTH_TYPE,
    A.SAMPLE_TYPE 
FROM RACEBASE.LENGTH A
JOIN RACE_DATA.CRUISES B 
    ON  A.CRUISE = B.CRUISE 
    AND A.VESSEL = B.VESSEL_ID
JOIN RACEBASE.HAUL F 
    ON A.HAULJOIN = F.HAULJOIN
JOIN RACE_DATA.SURVEYS C 
    ON C.SURVEY_ID = B.SURVEY_ID 
JOIN RACE_DATA.SURVEY_DEFINITIONS D 
    ON C.SURVEY_DEFINITION_ID = D.SURVEY_DEFINITION_ID 
WHERE D.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78)
  AND F.ABUNDANCE_HAUL = 'Y';
  
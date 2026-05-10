-- SQL Command to Create Materialized View GAP_PRODUCTS.SPECIMEN
--
-- Created by querying records from RACEBASE.SPECIMEN but only using hauls 
-- with ABUNDANCE_HAUL = 'Y' from the five survey areas w/ survey_definition_id:
-- "AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.SPECIMEN AS
SELECT 
    h.HAULJOIN,
    s.SPECIMENID                 AS SPECIMEN_ID,
    s.SPECIES_CODE,
    s.LENGTH                     AS LENGTH_MM,
    s.SEX,
    s.WEIGHT                     AS WEIGHT_G,
    s.AGE,
    s.MATURITY,
    s.GONAD_WT                   AS GONAD_G,
    s.SPECIMEN_SUBSAMPLE_METHOD,
    s.SPECIMEN_SAMPLE_TYPE,
    s.AGE_DETERMINATION_METHOD 
FROM RACEBASE.SPECIMEN s
JOIN RACEBASE.HAUL h 
    ON h.HAULJOIN = s.HAULJOIN
JOIN RACE_DATA.CRUISES c 
    ON c.RACEBASE_CRUISEJOIN = h.CRUISEJOIN
JOIN RACE_DATA.SURVEYS surv 
    USING (SURVEY_ID)
WHERE h.ABUNDANCE_HAUL = 'Y'
  AND surv.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78);
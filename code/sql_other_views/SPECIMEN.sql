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

CREATE MATERIALIZED VIEW GAP_PRODUCTS.SPECIMEN AS
-- Part 1: Length Frequency Data
SELECT 
    ABS(B.HAUL_ID) AS HAULJOIN,
    C.SPECIES_CODE,
    C.SEX,
    SUM(C.FREQUENCY) AS FREQUENCY,
    C.EDIT_LENGTH AS LENGTH_MM,
    C.LENGTH_TYPE,
    C.LENGTH_SUBSAMPLE_TYPE AS SAMPLE_TYPE,
--    NULL AS SPECIMEN_ID,           -- Placeholder
    NULL AS WEIGHT_G,              -- Placeholder
    NULL AS AGE,                   -- Placeholder
    NULL AS MATURITY,              -- Placeholder
    NULL AS GONAD_G,               -- Placeholder
    NULL AS SPECIMEN_SUBSAMPLE_METHOD, -- Placeholder
    NULL AS AGE_DETERMINATION_METHOD   -- Placeholder
FROM RACE_DATA.CRUISES A
JOIN RACE_DATA.SURVEYS S ON (S.SURVEY_ID = A.SURVEY_ID)
JOIN RACE_DATA.SURVEY_DEFINITIONS SD ON (SD.SURVEY_DEFINITION_ID = S.SURVEY_DEFINITION_ID)
JOIN RACE_DATA.HAULS B ON (B.CRUISE_ID = A.CRUISE_ID)
JOIN RACE_DATA.LENGTHS C ON (C.HAUL_ID = B.HAUL_ID)
GROUP BY 
    --SD.REGION, A.VESSEL_ID, A.CRUISE, 
    B.HAUL_ID, C.SPECIES_CODE, 
    C.SEX, C.EDIT_LENGTH, C.LENGTH_TYPE, C.LENGTH_SUBSAMPLE_TYPE

UNION ALL

-- Part 2: Specimen Data
SELECT 
    ss.HAULJOIN,
    ss.SPECIES_CODE,
    ss.SEX,
    NULL AS FREQUENCY,             -- Placeholder
    ss.LENGTH AS LENGTH_MM,
    NULL AS LENGTH_TYPE,           -- Placeholder
    ss.SPECIMEN_SAMPLE_TYPE AS SAMPLE_TYPE,
--    ss.SPECIMEN_ID,
    ss.WEIGHT WEIGHT_G,
    ss.AGE,
    ss.MATURITY,
    ss.GONAD_WT AS GONAD_G,
    ss.SPECIMEN_SUBSAMPLE_METHOD,
    ss.AGE_DETERMINATION_METHOD
FROM RACEBASE.SPECIMEN ss
RIGHT JOIN RACEBASE.HAUL hh 
ON ss.HAULJOIN = hh.HAULJOIN
WHERE hh.ABUNDANCE_HAUL = 'Y'


-- Code for GAP_PRODUCTS.SPECIMEN for posterity 2026-05-12

-- CREATE MATERIALIZED VIEW GAP_PRODUCTS.SPECIMEN AS
-- SELECT 
--     h.HAULJOIN,
--     s.SPECIMENID                 AS SPECIMEN_ID,
--     s.SPECIES_CODE,
--     s.LENGTH                     AS LENGTH_MM,
--     s.SEX,
--     s.WEIGHT                     AS WEIGHT_G,
--     s.AGE,
--     s.MATURITY,
--     s.GONAD_WT                   AS GONAD_G,
--     s.SPECIMEN_SUBSAMPLE_METHOD,
--     s.SPECIMEN_SAMPLE_TYPE,
--     s.AGE_DETERMINATION_METHOD 
-- FROM RACEBASE.SPECIMEN s
-- JOIN RACEBASE.HAUL h 
--     ON h.HAULJOIN = s.HAULJOIN
-- JOIN RACE_DATA.CRUISES c 
--     ON c.RACEBASE_CRUISEJOIN = h.CRUISEJOIN
-- JOIN RACE_DATA.SURVEYS surv 
--     USING (SURVEY_ID)
-- WHERE h.ABUNDANCE_HAUL = 'Y'
--   AND surv.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78);
  
-- Original code for GAP_PRODUCTS.AKFIN_SPECIMEN for posterity 2026-05-10
  
-- CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_SPECIMEN AS 
-- SELECT HAULJOIN, SPECIMENID AS SPECIMEN_ID, SPECIES_CODE, LENGTH AS LENGTH_MM, 
-- SEX, WEIGHT AS WEIGHT_G, AGE, MATURITY, GONAD_WT AS GONAD_G, 
-- SPECIMEN_SUBSAMPLE_METHOD, SPECIMEN_SAMPLE_TYPE, AGE_DETERMINATION_METHOD 
-- 
-- FROM RACEBASE.SPECIMEN 
-- JOIN RACEBASE.HAUL USING (HAULJOIN)
-- WHERE RACEBASE.HAUL.ABUNDANCE_HAUL = 'Y'

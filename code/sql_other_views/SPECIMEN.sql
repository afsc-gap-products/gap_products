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
SELECT 
    HAULJOIN, 
    SPECIMEN_ID, 
    SPECIES_CODE, 
    SPECIMEN_SUBSAMPLE_METHOD, 
    -- Only apply the age determination method to the 'AGE' variable row
    CASE 
        WHEN SPECIMEN_VARIABLE = 'AGE' THEN AGE_DETERMINATION_METHOD
        ELSE NULL 
    END AS SPECIMEN_SAMPLE_TYPE, 
    SPECIMEN_VARIABLE, 
    SPECIMEN_VALUE
FROM (
    -- 1. Gather the base wide data
    SELECT 
        h.HAULJOIN,
        s.SPECIMENID AS SPECIMEN_ID,
        s.SPECIES_CODE,
        s.SPECIMEN_SUBSAMPLE_METHOD,
        s.AGE_DETERMINATION_METHOD, -- Pass this through to evaluate after unpivoting
        s.LENGTH AS LENGTH_MM,
        s.SEX,
        s.WEIGHT AS WEIGHT_G,
        s.AGE,
        s.MATURITY,
        s.GONAD_WT AS GONAD_G
    FROM RACEBASE.SPECIMEN s
    JOIN RACEBASE.HAUL h 
        ON h.HAULJOIN = s.HAULJOIN
    JOIN RACE_DATA.CRUISES c 
        ON c.RACEBASE_CRUISEJOIN = h.CRUISEJOIN
    JOIN RACE_DATA.SURVEYS surv 
        ON surv.SURVEY_ID = c.SURVEY_ID
    WHERE h.ABUNDANCE_HAUL = 'Y'
      AND surv.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78)
)
-- 2. Dynamically unpivot the columns into rows
UNPIVOT EXCLUDE NULLS (
    SPECIMEN_VALUE FOR SPECIMEN_VARIABLE IN (
        LENGTH_MM AS 'LENGTH_MM',
        SEX AS 'SEX',
        WEIGHT_G AS 'WEIGHT_G',
        AGE AS 'AGE',
        MATURITY AS 'MATURITY',
        GONAD_G AS 'GONAD_G'
    )
)

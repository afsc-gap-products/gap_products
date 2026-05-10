-- SQL Command to Create Materilized View GAP_PRODUCTS.HAUL
--
-- Created by subsetting the RACEBASE.HAUL table to only hauls with 
-- ABUNDANCE_HAUL = 'Y' to a materialized view for AKFIN and does not have 
-- any other object dependencies. 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.HAUL AS
SELECT 
    HAUL.CRUISEJOIN,
    HAUL.HAULJOIN,
    HAUL.HAUL,
    HAUL.HAUL_TYPE,
    HAUL.PERFORMANCE,
    HAUL.START_TIME                                      AS DATE_TIME_START,
    HAUL.DURATION                                        AS DURATION_HR,
    HAUL.DISTANCE_FISHED                                 AS DISTANCE_FISHED_KM,
    HAUL.NET_WIDTH                                       AS NET_WIDTH_M,
    CASE
        WHEN HAUL.NET_MEASURED = 'Y' THEN 1
        WHEN HAUL.NET_MEASURED = 'N' THEN 0
        ELSE NULL
    END                                                AS NET_MEASURED, 
    HAUL.NET_HEIGHT                                      AS NET_HEIGHT_M,
    HAUL.STRATUM,
    HAUL.START_LATITUDE                                  AS LATITUDE_DD_START,
    HAUL.END_LATITUDE                                    AS LATITUDE_DD_END,
    HAUL.START_LONGITUDE                                 AS LONGITUDE_DD_START,
    HAUL.END_LONGITUDE                                   AS LONGITUDE_DD_END,
    HAUL.STATIONID                                       AS STATION,
    HAUL.GEAR_DEPTH                                      AS DEPTH_GEAR_M,
    HAUL.BOTTOM_DEPTH                                    AS DEPTH_M,
    HAUL.BOTTOM_TYPE,
    HAUL.SURFACE_TEMPERATURE                             AS SURFACE_TEMPERATURE_C,
    HAUL.GEAR_TEMPERATURE                                AS GEAR_TEMPERATURE_C,
    HAUL.WIRE_LENGTH                                     AS WIRE_LENGTH_M,
    HAUL.GEAR,
    HAUL.ACCESSORIES
FROM RACEBASE.HAUL HAUL
JOIN RACE_DATA.CRUISES CRUISES
    ON HAUL.CRUISEJOIN = CRUISES.RACEBASE_CRUISEJOIN
JOIN RACE_DATA.SURVEYS SURVEYS 
    ON SURVEYS.SURVEY_ID = CRUISES.SURVEY_ID
WHERE HAUL.ABUNDANCE_HAUL = 'Y' 
  AND SURVEYS.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78);


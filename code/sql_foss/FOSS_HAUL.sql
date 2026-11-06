-- Create View GAP_PRODUCTS.FOSS_HAUL
--
-- Query GAP_PRODUCTS.HAUL and joining information from GAP_PRODUCTS.CRUISE
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE VIEW GAP_PRODUCTS.FOSS_HAUL AS
SELECT
    cc.YEAR,
    CASE
        WHEN cc.SURVEY_DEFINITION_ID = 143 THEN 'NBS'
        WHEN cc.SURVEY_DEFINITION_ID = 98  THEN 'EBS'
        WHEN cc.SURVEY_DEFINITION_ID = 47  THEN 'GOA'
        WHEN cc.SURVEY_DEFINITION_ID = 52  THEN 'AI'
        WHEN cc.SURVEY_DEFINITION_ID = 78  THEN 'BSS'
        ELSE NULL
    END AS SRVY,
    CASE
        WHEN cc.SURVEY_DEFINITION_ID = 143 THEN 'northern Bering Sea'
        WHEN cc.SURVEY_DEFINITION_ID = 98  THEN 'eastern Bering Sea'
        WHEN cc.SURVEY_DEFINITION_ID = 47  THEN 'Gulf of Alaska'
        WHEN cc.SURVEY_DEFINITION_ID = 52  THEN 'Aleutian Islands'
        WHEN cc.SURVEY_DEFINITION_ID = 78  THEN 'Bering Sea Slope'
        ELSE NULL
    END AS SURVEY,
    cc.SURVEY_DEFINITION_ID,
    cc.SURVEY_NAME,
    cc.CRUISE,
    cc.CRUISEJOIN,
    hh.HAULJOIN,
    hh.HAUL,
    hh.STRATUM,
    hh.STATION,
    cc.VESSEL_ID,
    cc.VESSEL_NAME,
    hh.DATE_TIME_START AS DATE_TIME,
    hh.LATITUDE_DD_START,
    hh.LONGITUDE_DD_START,
    hh.LATITUDE_DD_END,
    hh.LONGITUDE_DD_END,
    hh.GEAR_TEMPERATURE_C AS BOTTOM_TEMPERATURE_C,
    hh.SURFACE_TEMPERATURE_C,
    hh.DEPTH_M,
    hh.DISTANCE_FISHED_KM,
    hh.DURATION_HR,
    hh.NET_WIDTH_M,
    hh.NET_HEIGHT_M,
    hh.DISTANCE_FISHED_KM * hh.NET_WIDTH_M /1000 AS AREA_SWEPT_KM2,
    hh.PERFORMANCE
FROM
    GAP_PRODUCTS.HAUL hh
LEFT JOIN GAP_PRODUCTS.CRUISE cc
    ON hh.CRUISEJOIN = cc.CRUISEJOIN
;

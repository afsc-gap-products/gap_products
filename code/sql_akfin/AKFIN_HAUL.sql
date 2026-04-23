-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_HAUL
--
-- Created by subsetting the RACEBASE.HAUL table to only hauls with 
-- ABUNDANCE_HAUL = 'Y' to a materialized view for AKFIN and does not have 
-- any other object dependencies. 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_HAUL AS
SELECT 
hh.CRUISEJOIN,
hh.HAULJOIN,
hh.HAUL,
hh.HAUL_TYPE,
-- hh.VESSEL VESSEL_ID, -- duplicated in AKFIN_CRUISE
hh.PERFORMANCE,
hh.START_TIME DATE_TIME_START,
hh.DURATION DURATION_HR,
hh.DISTANCE_FISHED DISTANCE_FISHED_KM,
hh.NET_WIDTH NET_WIDTH_M,
CASE
    WHEN hh.NET_MEASURED = 'Y' THEN 1
    WHEN hh.NET_MEASURED = 'N' THEN 0
    ELSE NULL
END AS NET_MEASURED, 
hh.NET_HEIGHT NET_HEIGHT_M,
hh.STRATUM,
hh.START_LATITUDE LATITUDE_DD_START,
hh.END_LATITUDE LATITUDE_DD_END,
hh.START_LONGITUDE LONGITUDE_DD_START,
hh.END_LONGITUDE LONGITUDE_DD_END,
hh.STATIONID STATION,
hh.GEAR_DEPTH DEPTH_GEAR_M,
hh.BOTTOM_DEPTH DEPTH_M,
hh.BOTTOM_TYPE,
hh.SURFACE_TEMPERATURE SURFACE_TEMPERATURE_C,
hh.GEAR_TEMPERATURE GEAR_TEMPERATURE_C,
hh.WIRE_LENGTH WIRE_LENGTH_M,
hh.GEAR,
hh.ACCESSORIES
--ABUNDANCE_HAUL, --recc removing this term since constrained to a single value
from RACEBASE.HAUL hh
LEFT JOIN GAP_PRODUCTS.AKFIN_CRUISE cr
ON hh.CRUISEJOIN = cr.CRUISEJOIN
where hh.ABUNDANCE_HAUL = 'Y' -- abundance haul implies temporal stanza by application
AND cr.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78)


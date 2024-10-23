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
SELECT CRUISEJOIN,
HAULJOIN,
HAUL,
HAUL_TYPE,
-- VESSEL VESSEL_ID, -- duplicated in AKFIN_CRUISE
PERFORMANCE,
START_TIME DATE_TIME_START,
DURATION DURATION_HR,
DISTANCE_FISHED DISTANCE_FISHED_KM,
NET_WIDTH NET_WIDTH_M,
CASE
    WHEN NET_MEASURED = 'Y' THEN 1
    WHEN NET_MEASURED = 'N' THEN 0
    ELSE NULL
END AS NET_MEASURED, 
NET_HEIGHT NET_HEIGHT_M,
STRATUM,
START_LATITUDE LATITUDE_DD_START,
END_LATITUDE LATITUDE_DD_END,
START_LONGITUDE LONGITUDE_DD_START,
END_LONGITUDE LONGITUDE_DD_END,
STATIONID STATION,
GEAR_DEPTH DEPTH_GEAR_M,
BOTTOM_DEPTH DEPTH_M,
BOTTOM_TYPE,
SURFACE_TEMPERATURE SURFACE_TEMPERATURE_C,
GEAR_TEMPERATURE GEAR_TEMPERATURE_C,
WIRE_LENGTH WIRE_LENGTH_M,
GEAR,
ACCESSORIES
--ABUNDANCE_HAUL, --recc removing this term since constrained to a single value
from RACEBASE.HAUL
where ABUNDANCE_HAUL = 'Y'
-- abundance haul implies temporal stanza by application

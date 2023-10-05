-- SQL Command to Create Materilized View GAP_PRODUCTS.FOSS_CPUE_PRESONLY
--
-- Created from FOSS_CATCH and FOSS_HAUL, but to replicate the tables that 
-- are currently available on FOSS, to assist (short term) with transition to 
-- the new tables
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.FOSS_CPUE_PRESONLY AS 
SELECT DISTINCT 
hh.YEAR,
hh.SRVY,                 
hh.SURVEY,
hh.SURVEY_DEFINITION_ID,
hh.SURVEY_NAME,
hh.CRUISE,
hh.CRUISEJOIN,           
hh.HAUL,
hh.HAULJOIN,
hh.STRATUM,
hh.STATION,
hh.VESSEL_ID,
hh.VESSEL_NAME,          
hh.DATE_TIME,
hh.LATITUDE_DD_START, 
hh.LONGITUDE_DD_START, 
hh.LATITUDE_DD_END,
hh.LONGITUDE_DD_END, 
hh.BOTTOM_TEMPERATURE_C,
hh.SURFACE_TEMPERATURE_C,
hh.DEPTH_M,
cc.SPECIES_CODE,
cc.ITIS,
cc.WORMS,
cc.COMMON_NAME,     
cc.SCIENTIFIC_NAME,
cc.ID_RANK,
cc.TAXON_CONFIDENCE,
cc.WEIGHT_KG,
cc.COUNT,
cc.CPUE_KGKM2,
cc.CPUE_NOKM2,
hh.AREA_SWEPT_KM2,       
hh.DISTANCE_FISHED_KM,
hh.DURATION_HR,          
hh.NET_WIDTH_M,
hh.NET_HEIGHT_M,
hh.PERFORMANCE 
FROM GAP_PRODUCTS.FOSS_CATCH cc
LEFT JOIN GAP_PRODUCTS.FOSS_HAUL hh
ON cc.HAULJOIN = hh.HAULJOIN

-- SQL Command to Create Materilized View GAP_PRODUCTS.FOSS_SURVEY_SPECIES
--
-- Created by querying records from GAP_PRODUCTS.FOSS_CATCH and 
-- GAP_PRODUCTS.FOSS_HAUL to obtain the full list of species to zero-fill by 
-- for each survey
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.FOSS_SURVEY_SPECIES AS
SELECT DISTINCT 
fc.SPECIES_CODE, 
fh.SURVEY_DEFINITION_ID
FROM GAP_PRODUCTS.FOSS_CATCH fc
LEFT JOIN GAP_PRODUCTS.FOSS_HAUL fh
ON fc.HAULJOIN = fh.HAULJOIN

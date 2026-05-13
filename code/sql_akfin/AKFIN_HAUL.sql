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
SELECT *
from GAP_PRODUCTS.HAUL

-- File slated to be will be removed by end of 2026 if not sooner


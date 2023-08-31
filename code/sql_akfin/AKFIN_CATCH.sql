-- SQL Command to Create Materilized View GAP_PRODUCTS.CATCH
--
-- Catch records from hauls in RACEBASE.HAULS where ABUNDANCE_HAUL = 'Y'.  
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.CATCH AS
select C.CRUISEJOIN, C.HAULJOIN, C.CATCHJOIN, SPECIES_CODE, WEIGHT WEIGHT_KG, NUMBER_FISH COUNT
from RACEBASE.HAUL H, RACEBASE.CATCH C
where C.HAULJOIN = H.HAULJOIN
and ( 
(C.REGION = 'AI' and H.ABUNDANCE_HAUL = 'Y')
or (C.REGION = 'BS' and H.ABUNDANCE_HAUL = 'Y')
or (C.REGION = 'GOA' and H.ABUNDANCE_HAUL = 'Y')
)

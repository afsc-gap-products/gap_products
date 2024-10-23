-- SQL Command to Create Materilized View GAP_PRODUCTS.FOSS_CATCH
--
-- Created by querying positive catch records from GAP_PRODUCTS.CPUE but only 
-- using hauls with ABUNDANCE_HAUL = 'Y' from the five survey areas w/ 
-- survey_definition_id: "AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.FOSS_CATCH AS
SELECT  
cp.HAULJOIN,
cp.SPECIES_CODE, 
cp.CPUE_KGKM2, 
cp.CPUE_NOKM2,
cp.COUNT, 
cp.WEIGHT_KG, 
tc.TAXON_CONFIDENCE

FROM GAP_PRODUCTS.CPUE cp

LEFT JOIN GAP_PRODUCTS.AKFIN_HAUL hh
ON cp.HAULJOIN = hh.HAULJOIN
LEFT JOIN GAP_PRODUCTS.AKFIN_CRUISE cc
ON hh.CRUISEJOIN = cc.CRUISEJOIN
LEFT JOIN GAP_PRODUCTS.TAXONOMIC_CONFIDENCE tc
ON cp.SPECIES_CODE = tc.SPECIES_CODE 
AND cc.SURVEY_DEFINITION_ID = tc.SURVEY_DEFINITION_ID
AND cc.YEAR = tc.YEAR

WHERE cp.WEIGHT_KG > 0
AND cc.SURVEY_DEFINITION_ID IN (143, 98, 47, 52, 78)

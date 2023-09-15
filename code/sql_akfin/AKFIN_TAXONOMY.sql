-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_TAXONOMY
--
-- [Enter description.]
-- (github.com/afsc-gap-products/gap_products). 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_TAXONOMY 
SELECT 
SPECIES_NAME, 
COMMON_NAME, 
SPECIES_CODE, 
ID_RANK, 
DATABASE_ID, 
DATABASE, 
GENUS_TAXON, 
SUBFAMILY_TAXON, 
FAMILY_TAXON, 
SUPERFAMILY_TAXON, 
SUBORDER_TAXON, 
ORDER_TAXON, 
SUPERORDER_TAXON, 
SUBCLASS_TAXON, 
CLASS_TAXON, 
SUPERCLASS_TAXON, 
SUBPHYLUM_TAXON, 
PHYLUM_TAXON, 
KINGDOM_TAXON
FROM SPECIES_CLASSIFICATION
WHERE SURVEY_SPECIES = 1

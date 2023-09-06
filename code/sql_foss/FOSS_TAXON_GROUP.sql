-- SQL Command to Create Materilized View GAP_PRODUCTS.FOSS_TAXON_GROUP
-- This reference table will allow for easier searching and sorting of species in FOSS
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

SELECT  
REPLACE(REPLACE(RANK_ID, '_TAXON', ''), 'SPECIES_NAME', 'SPECIES') AS RANK_ID, 
CLASSIFICATION, 
SPECIES_CODE 
FROM TEST_SPECIES_CLASSIFICATION 
UNPIVOT
(CLASSIFICATION FOR RANK_ID IN 
(SPECIES_NAME, 
GENUS_TAXON, 
SUBFAMILY_TAXON, 
FAMILY_TAXON, 
-- SUPERFAMILY_TAXON, 
-- SUBORDER_TAXON, 
ORDER_TAXON, 
-- SUPERORDER_TAXON, 
-- SUBCLASS_TAXON, 
CLASS_TAXON, 
-- SUPERCLASS_TAXON, 
-- SUBPHYLUM_TAXON, 
PHYLUM_TAXON, 
KINGDOM_TAXON)) 
WHERE CLASSIFICATION IS NOT NULL
ORDER BY ID_RANK, CLASSIFICATION, SPECIES_CODE


# ------------------------------------------------------------------------------
-- # Orig R code
-- 
-- TAXON_GROUPS <- gap_products_old_taxonomics_worms0 %>% 
--   dplyr::select(species_code, genus, family, order, class, phylum, kingdom) %>% 
--   tidyr::pivot_longer(data = ., 
--                       cols = c("genus", "family", "order", "class", "phylum", "kingdom"), 
--                       names_to = "id_rank", values_to = "classification") %>% 
--   dplyr::relocate(id_rank, classification, species_code) %>% 
--   dplyr::arrange(id_rank, classification, species_code) %>% 
--   dplyr::filter(!is.na(classification))
-- 
-- # only keep groups that have more than one member
-- TAXON_GROUPS <- TAXON_GROUPS[duplicated(x = TAXON_GROUPS$id_rank),]


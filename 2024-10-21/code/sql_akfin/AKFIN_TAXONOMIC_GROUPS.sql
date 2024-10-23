-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_TAXONOMIC_GROUPS
--
-- Mirror of GAP_PRODUCTS.TAXON_GROUPS.
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_TAXONOMIC_GROUPS AS 
SELECT * FROM GAP_PRODUCTS.TAXON_GROUPS

-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_METADATA_COLUMN
--
-- Created by copying GAP_PRODUCTS.METADATA_COLUMN table to a materialized view 
-- for AKFIN and does not have any other object dependencies. 
-- GAP_PRODUCTS.METADATA_COLUMN is maintained in the gap_products GitHub repo 
-- (github.com/afsc-gap-products/gap_products).
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_METADATA_COLUMN AS 
SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN

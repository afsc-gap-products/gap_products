-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_SIZECOMP
--
-- Created by copying GAP_PRODUCTS.SIZECOMP table to a materialized view 
-- for AKFIN and does not have any other object dependencies. 
-- GAP_PRODUCTS.SIZECOMP is generated in the gap_products GitHub repo 
-- (github.com/afsc-gap-products/gap_products) using the gapindex R package 
-- (github.com/afsc-gap-products/gapindex). 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_SIZECOMP AS 
SELECT * FROM GAP_PRODUCTS.SIZECOMP

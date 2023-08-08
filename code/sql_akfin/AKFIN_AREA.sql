-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_AREA
--
-- Created by copying GAP_PRODUCTS.AREA table to a materialized view 
-- for AKFIN and does not have any other object dependencies. GAP_PRODUCTS.AREA
-- houses the area and perimeter information for strata and subareas across 
-- regions and is maintained in the gap_products GitHub repo
-- (github.com/afsc-gap-products/gap_products). 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_AREA AS 
SELECT * FROM GAP_PRODUCTS.AREA

-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_STRATUM_GROUPS
--
-- Created by copying GAP_PRODUCTS.STRATUM_GROUPS table to a materialized view 
-- for AKFIN and does not have any other object dependencies. 
-- GAP_PRODUCTS.STRATUM_GROUPS contains the which strata are contained in 
-- the various subareas and regions across the Alaska bottom trawl survey 
-- regions and is maintained in the gap_products GitHub repo
-- (github.com/afsc-gap-products/gap_products). 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_STRATUM_GROUPS AS 
SELECT * FROM GAP_PRODUCTS.STRATUM_GROUPS

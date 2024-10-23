-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_SURVEY_DESIGN
--
-- Created by copying GAP_PRODUCTS.SURVEY_DESIGN table to a materialized view 
-- for AKFIN and does not have any other object dependencies. 
-- GAP_PRODUCTS.SURVEY_DESIGN contains the which strata are contained in 
-- the various subareas and regions across the Alaska bottom trawl survey 
-- regions and is maintained in the gap_products GitHub repo
-- (github.com/afsc-gap-products/gap_products). 
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_SURVEY_DESIGN AS 
SELECT * FROM GAP_PRODUCTS.SURVEY_DESIGN

-- SQL Command to Create Materilized View GAP_PRODUCTS.FOSS_SPECIES
--
-- Created by querying records from GAP_PRODUCTS.FOSS_CATCH and 
-- GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION to obtain the full list of 
-- species and species information to join with 
-- GAP_PRODUCTS.FOSS_CATCH and GAP_PRODUCTS.FOSS_HAUL
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.FOSS_SPECIES AS
SELECT DISTINCT 
cc.SPECIES_CODE, 
tt.SPECIES_NAME AS SCIENTIFIC_NAME,
tt.COMMON_NAME,
tt.ID_RANK,
ts.WORMS,
ts.ITIS
FROM GAP_PRODUCTS.FOSS_CATCH cc
LEFT JOIN GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION tt 
ON cc.SPECIES_CODE = tt.SPECIES_CODE
LEFT JOIN 
(
SELECT "SPECIES_CODE","'ITIS'" AS ITIS,"'WORMS'" AS WORMS
FROM (
SELECT SPECIES_CODE, DATABASE, DATABASE_ID
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
)
PIVOT
(
SUM(DATABASE_ID)
FOR DATABASE IN ('ITIS', 'WORMS')
) ) ts
ON cc.SPECIES_CODE = ts.SPECIES_CODE
WHERE tt.SURVEY_SPECIES = 1 -- only use the official and up to date species codes


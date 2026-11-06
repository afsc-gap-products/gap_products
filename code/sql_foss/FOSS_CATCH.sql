-- Create View GAP_PRODUCTS.FOSS_CATCH
--
-- Query to pull positive catch records from GAP_PRODUCTS.CPUE joined with 
-- taxonomic confidence level from GAP_TAXONOMY.TAXONOMIC_CONFIDENCE
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE VIEW GAP_PRODUCTS.FOSS_CATCH AS
SELECT
    cp.HAULJOIN,
    cp.SPECIES_CODE,
    cp.CPUE_KGKM2,
    cp.CPUE_NOKM2,
    cp.COUNT,
    cp.WEIGHT_KG,
    tc.TAXON_CONFIDENCE
FROM
    GAP_PRODUCTS.CPUE cp
    LEFT JOIN GAP_PRODUCTS.HAUL hh
        ON cp.HAULJOIN = hh.HAULJOIN
    LEFT JOIN GAP_PRODUCTS.CRUISE cc
        ON hh.CRUISEJOIN = cc.CRUISEJOIN
    LEFT JOIN GAP_TAXONOMY.TAXONOMIC_CONFIDENCE tc
        ON cp.SPECIES_CODE = tc.SPECIES_CODE
        AND cc.SURVEY_DEFINITION_ID = tc.SURVEY_DEFINITION_ID
        AND cc.YEAR = tc.YEAR
WHERE
    cp.WEIGHT_KG > 0;

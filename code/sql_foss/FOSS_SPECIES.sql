-- Create View GAP_PRODUCTS.FOSS_SPECIES
--
-- Query to attach taxonomic database information for GROUP_CODE values in 
-- GAP_TAXONOMY.TAXON_GROUP_STANZAS
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE VIEW GAP_PRODUCTS.FOSS_SPECIES AS
SELECT
    SPECIES_CODE,
    SCIENTIFIC_NAME,
    COMMON_NAME,
    ID_RANK,
    WORMS,
    ITIS,
    DATABASE_PREFERED
FROM (
    SELECT DISTINCT
        cc.GROUP_CODE AS SPECIES_CODE,
        tt.DATABASE,
        tt.DATABASE_ID,
        COALESCE(
            MAX(CASE WHEN tt.ACTIVE = 1 THEN tt.SPECIES_NAME END) 
                OVER (PARTITION BY cc.GROUP_CODE),
            MAX(tt.SPECIES_NAME) 
                OVER (PARTITION BY cc.GROUP_CODE)
        ) AS SCIENTIFIC_NAME,
        COALESCE(
            MAX(CASE WHEN tt.ACTIVE = 1 THEN tt.COMMON_NAME END) 
                OVER (PARTITION BY cc.GROUP_CODE),
            MAX(tt.COMMON_NAME) 
                OVER (PARTITION BY cc.GROUP_CODE)
        ) AS COMMON_NAME,
        COALESCE(
            MAX(CASE WHEN tt.ACTIVE = 1 THEN tt.ID_RANK END) 
                OVER (PARTITION BY cc.GROUP_CODE),
            MAX(tt.ID_RANK) 
                OVER (PARTITION BY cc.GROUP_CODE)
        ) AS ID_RANK,
        COALESCE(
            MAX(CASE WHEN tt.ACTIVE = 1 THEN tt.DATABASE END) 
                OVER (PARTITION BY cc.GROUP_CODE),
            'AFSC'
        ) AS DATABASE_PREFERED
    FROM
        GAP_TAXONOMY.TAXON_GROUP_STANZAS cc
        LEFT JOIN GAP_TAXONOMY.TAXONOMIC_CLASSIFICATION tt
            ON tt.SPECIES_CODE = cc.GROUP_CODE
) query
PIVOT (
    MAX(DATABASE_ID)
    FOR DATABASE IN ('ITIS' AS ITIS, 'WORMS' AS WORMS)
)
ORDER BY
    SPECIES_CODE;

GRANT SELECT ON GAP_PRODUCTS.FOSS_SPECIES TO PUBLIC;

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Comparison of GOA 2025 mock data
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare biomass estimates and CVs for a handful of species
##                between the GOA 2019 estimates and the mock 2025 data which
##                were produced using the GOA 2019 stations
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

library(gapindex)

sql_channel <- gapindex::get_connected()

species <- c(10110, 10120, 10130, 10180, 10200, 10261, 10262, 21720,
             21740, 30060)#, 30020, 30051, 30052, 30100, 30152, 30420)

biomass_region <- 
  RODBC::sqlQuery(channel = sql_channel, 
                  query = paste0(
                    "SELECT SPECIES_CODE, YEAR, 
                     ROUND(BIOMASS_MT, 0) BIOMASS_MT, 
                     ROUND(SQRT(BIOMASS_VAR) / BIOMASS_MT, 3) AS BIOMASS_CV
                     FROM GAP_PRODUCTS.BIOMASS
                     WHERE SPECIES_CODE IN ",
                    gapindex::stitch_entries(species),
                    "AND SURVEY_DEFINITION_ID = 47
                     AND YEAR IN (2019, 2025) 
                     AND AREA_ID IN (99903)--, 
                     --919, 929, 939, 949, 959,
                     --610, 620, 630, 640, 650)
                     ORDER BY SPECIES_CODE, YEAR"))

biomass_region$BIOMASS_PRINT <- with(biomass_region, 
                              paste0(BIOMASS_MT, " (", BIOMASS_CV, ")"))

tidyr::spread(data = biomass_region[, c("SPECIES_CODE", "YEAR", "BIOMASS_PRINT")],
              key = YEAR, value = BIOMASS_PRINT)

biomass_mgt <- 
  RODBC::sqlQuery(channel = sql_channel, 
                  query = paste0(
                    "SELECT 
                    CASE
                     WHEN FLOOR(AREA_ID / 100) = 9 THEN 'INPFC'
                     WHEN FLOOR(AREA_ID / 100) = 6 THEN 'NMFS'
                    END AS ORG,
                    CASE
                      WHEN AREA_ID = 919 THEN 'SHUMAGIN'
                      WHEN AREA_ID = 929 THEN 'CHIRIKOF'
                      WHEN AREA_ID = 939 THEN 'KODIAK'
                      WHEN AREA_ID = 949 THEN 'YAKUTAT'
                      WHEN AREA_ID = 959 THEN 'SE'
                    
                      WHEN AREA_ID = 610 THEN 'SHUMAGIN'
                      WHEN AREA_ID = 620 THEN 'CHIRIKOF'
                      WHEN AREA_ID = 630 THEN 'KODIAK'
                      WHEN AREA_ID = 640 THEN 'YAKUTAT'
                      WHEN AREA_ID = 650 THEN 'SE'
                    END AS AREA,
                    
                    SPECIES_CODE, YEAR, 
                     ROUND(BIOMASS_MT, 0) BIOMASS_MT
                     
                     FROM GAP_PRODUCTS.BIOMASS
                     WHERE SPECIES_CODE IN ",
                    gapindex::stitch_entries(species),
                    "AND SURVEY_DEFINITION_ID = 47
                     AND YEAR IN (2019, 2025) 
                     AND AREA_ID IN (919, 929, 939, 949, 959,
                     610, 620, 630, 640, 650)
                     ORDER BY SPECIES_CODE, YEAR"))

biomass_mgt$AREA <- 
  factor(x = biomass_mgt$AREA, 
         levels = c("SHUMAGIN", "CHIRIKOF","KODIAK", "YAKUTAT", "SE"))
tidyr::spread(data = biomass_mgt[, c("ORG", "SPECIES_CODE", "AREA", "BIOMASS_MT")],
              key = ORG, value = BIOMASS_MT)

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
             21740, 30060, 30020, 30051, 30052, 30100, 30152, 30420)

biomass <- 
  RODBC::sqlQuery(channel = sql_channel, 
                  query = paste0("SELECT AREA_ID, SPECIES_CODE, YEAR, 
                                  ROUND(BIOMASS_MT, 0) BIOMASS_MT, BIOMASS_VAR
                                  FROM GAP_PRODUCTS.BIOMASS
                                  WHERE SPECIES_CODE IN ",
                                 gapindex::stitch_entries(species),
                                 "AND SURVEY_DEFINITION_ID = 47
                                  AND YEAR IN (2019, 2025) 
                                  AND AREA_ID IN (99903, 
                                  919, 929, 939, 949, 959,
                                  610, 620, 630, 640, 650)
                                  ORDER BY SPECIES_CODE, AREA_ID, YEAR"))
biomass$CV <- round(x = sqrt(biomass$BIOMASS_VAR) / 
                      ifelse(test = biomass$BIOMASS_MT == 0, 1, biomass$BIOMASS_MT), 3)

RODBC::sqlQuery(channel = sql_channel, 
                query = "SELECT * FROM GAP_PRODUCTS.BIOMASS
                         WHERE SPECIES_CODE = 10110
                         AND SURVEY_DEFINITION_ID = 47
                         AND YEAR IN (2025)")

RODBC::sqlQuery(channel = sql_channel, 
                query = "SELECT * FROM GAP_PRODUCTS.AREA
                         WHERE SURVEY_DEFINITION_ID = 47
                         AND DESIGN_YEAR IN (2025)")

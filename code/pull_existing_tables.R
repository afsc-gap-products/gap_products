##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Pull Existing GAP_PRODUCTS production tables
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Pull existing CPUE, BIOMASS, SIZECOMP, and AGECOMP tables
##                from the GAP_PRODUCTS schema for comparison. Save to temp/
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import gapindex package
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Constants
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
regions <- c("AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143)
data_tables <- c("CPUE", "BIOMASS", "SIZECOMP", "AGECOMP")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull GAP_PRODUCTS tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (iregion in 1:length(x = regions)) { ## Loop over regions -- start
  for (idata in data_tables) { ## Loop over data types -- start
    
    if (!file.exists(paste0("temp/GAP_PRODUCTS_", idata, "_",
                            names(regions[iregion]), ".csv")))

    query <- paste0(
      "SELECT * FROM GAP_PRODUCTS.", idata, 
      ifelse(test = idata == "CPUE",
             no = paste0(" WHERE SURVEY_DEFINITION_ID = ", regions[iregion]),
             yes = paste0(" WHERE HAULJOIN in (SELECT HAULJOIN FROM ",
                          "RACEBASE.HAUL WHERE CRUISEJOIN IN ",
                          "(SELECT CRUISEJOIN FROM RACE_DATA.V_CRUISES WHERE ",
                          "SURVEY_DEFINITION_ID = ", regions[iregion], 
                          ")", ")"))
    )
    
    ## Query Oracle and write to csv in the temp folder
    write.csv(x = RODBC::sqlQuery(channel = sql_channel, query = query),
              file = paste0("temp/GAP_PRODUCTS_", idata, "_",
                            names(regions[iregion]), ".csv"),
              row.names = FALSE)
        
  } ## Loop over data types -- end
} ## Loop over regions -- end

rm(list = ls())

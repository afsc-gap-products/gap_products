##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Pull Existing GAP_PRODUCTS production tables
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Pull existing CPUE, BIOMASS, SIZECOMP, and AGECOMP tables
##                from the GAP_PRODUCTS schema for comparison. 
##                Save to temp/cloned_gp/
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import gapindex package
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
library(data.table)
chl <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Constants
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
regions <- c("AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143)
data_tables <- c("CPUE", "BIOMASS", "SIZECOMP", "AGECOMP")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull GAP_PRODUCTS data tables. Separate the data tables by region for 
##   the initial region-specific comparisons with the historical data. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (!dir.exists(paths = "temp/cloned_gp/")) 
  dir.create(path = "temp/cloned_gp/")
writeLines(text = paste("Accessed on", Sys.time()), 
           con = "temp/cloned_gp/date_accessed.txt")

for (iregion in 1:length(x = regions)) { ## Loop over regions -- start
  for (idata in data_tables) { ## Loop over data_tables -- start
    
    ## The query is to select all columns from the idata table in GAP_PRODUCTS
    ## filtering on the SURVEY_DEFINITION_ID of the iregion. For CPUE, since
    ## there is not a SURVEY_DEFINITION_ID column, we manually pull the 
    ## appropriate HAULJOIN values from the iregion.  
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
    data.table::fwrite(x = RODBC::sqlQuery(channel = chl, query = query),
              file = paste0("temp/cloned_gp/GAP_PRODUCTS_", idata, "_",
                            names(x = regions[iregion]), ".csv"))
    
  } ## Loop over data types -- end
} ## Loop over regions -- end


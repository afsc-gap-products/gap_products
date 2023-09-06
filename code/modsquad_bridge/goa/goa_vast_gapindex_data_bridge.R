##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Compare GOA VAST input to output from the gapindex R package
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Libraries, VAST data sources
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(googledrive)
library(gapindex)
library(readxl)

data_sources <- as.data.frame(readxl::read_xlsx(
  path = paste0("code_testing/VAST_bridging/GOA/",
                "2023_hindcast_datasources.xlsx")))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Connect to Oracle. Make sure you're on the VPN/network
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over species, pull in data, compare to gapindex
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (irow in 1:nrow(data_sources)) {
  
  ## Pull data from gapindex for a given species using gapindex
  species_code <- data_sources$species_code[irow]
  if (species_code == 30152) # For duskies, we add code 30150
    species_code <- data.frame(SPECIES_CODE = c(species_code, 30150), 
                               GROUP = 30152)
  
  gapindex_data <- 
    gapindex::get_data(survey_set = "GOA",
                       year_set = seq(from = data_sources$year_start[irow],
                                      to = data_sources$year_end[irow]),
                       spp_codes = species_code,
                       pull_lengths = FALSE,
                       sql_channel = sql_channel)
  
  ## Calculate and zero-fill CPUE using gapindex
  gapindex_cpue <- gapindex::calc_cpue(racebase_tables = gapindex_data)
  
  ## Find the location of the VAST input file
  goa_drive_id <- googledrive::as_id(x = data_sources$url[irow])
  file_id <- with(googledrive::drive_ls(path = goa_drive_id), 
                  id[name == data_sources$filename[irow]])
  
  ## Download VAST input dataset, save locally
  googledrive::drive_download(
    file = file_id,
    path = paste0("temp/", data_sources$filename[irow]), 
    overwrite = T)
  
  ## Read in VAST input dataset from local location
  imported_file <- 
    do.call(what = switch(data_sources$type[irow], 
                          "RDS" = "readRDS",
                          "CSV" = "read.csv"),
            args = list(paste0("temp/", data_sources$filename[irow]) ))
  
  names(imported_file) <- toupper(names(imported_file))
  
  ## Correct scale if the area swept values are not in KM2
  imported_file$AREASWEPT_KM2 <- 
    imported_file$AREASWEPT_KM2 * data_sources$area_units_correct[irow]
  
  ## If AREASWEPT_KM2 is not a column of ones, standardize so that it is. 
  if (!all(imported_file$AREASWEPT_KM2 == 1)) {
    imported_file$CATCH_KG <- 
      imported_file$CATCH_KG / imported_file$AREASWEPT_KM2 #* 1000
    
    imported_file$AREASWEPT_KM2 <- 1
  }
  
  # ## Compare number of stations across years
  # cat(paste0("\n\nNumber of stations across years (VAST Input) for ",
  #            data_sources$common_name[irow], "\n"))
  # print(table(imported_file$YEAR))
  # 
  # cat(paste0("\nNumber of stations across years (gapindex) for ",
  #            data_sources$common_name[irow], "\n"))
  # print(table(gapindex_cpue$YEAR))
  # 
  # ## Compare the summary statistics across years
  # cat(paste0("\nCPUE summary across years (VAST Input) for ",
  #            data_sources$common_name[irow], "\n"))
  # print(do.call(what = rbind,
  #               args = tapply(X = imported_file$CATCH_KG,
  #                             INDEX = imported_file$YEAR,
  #                             FUN = summary)))
  # 
  # cat(paste0("\nCPUE summary across years (gapindex) for ",
  #            data_sources$common_name[irow], "\n"))
  # print(do.call(what = rbind,
  #               args = tapply(X = gapindex_cpue$CPUE_KGKM2,
  #                             INDEX = gapindex_cpue$YEAR,
  #                             FUN = summary)))
  
  ## Merge the CPUE values from the imported file and the CPUE tables that
  ## come from gapindex::calc_cpue using latitude, longitude, and year as
  ## a composite key
  test <- 
    merge(x = imported_file, 
          by.x = c("LAT", "LON", "YEAR"),
          y = subset(x = gapindex_cpue,
                     select = c("LATITUDE_DD_START", "LONGITUDE_DD_START", 
                                "YEAR", "CPUE_KGKM2")), 
          by.y = c("LATITUDE_DD_START", "LONGITUDE_DD_START", "YEAR"),
          all = TRUE)
  
  ## Calculate differences between CPUE and print out any mismatches
  test$cpue_diff <- round(test$CPUE_KGKM2 - test$CATCH_KG, 6)
  print( subset(test, cpue_diff != 0 | is.na(cpue_diff)) )
}

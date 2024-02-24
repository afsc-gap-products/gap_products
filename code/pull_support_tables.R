##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Upload area_table, design_year, and stratum_grouping tables
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Packages
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
library(googledrive)
library(readxl)
library(RODBC)
library(usethis)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Authenticate google drive with your NOAA credentials
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
googledrive::drive_deauth()
googledrive::drive_auth()
1

sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Download spreadsheet where the tables currently exist (in the future,
##   these tables will live somewhere in Oracle). 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
data_url <- "https://docs.google.com/spreadsheets/d/1wgAJPPWif1CC01iT2S6ZtoYlhOM0RSGFXS9LUggdLLA/edit#gid=689332364"
data_id <- googledrive::as_id(x = data_url)

data_spreadsheet <- googledrive::drive_download(file = data_id,
                                                path = "temp/data.xlsx", 
                                                overwrite = TRUE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Extract tables from different sheets in data_spreadsheet
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SURVEY_DESIGN <- 
  as.data.frame(readxl::read_excel(path = "temp/data.xlsx", 
                                   sheet = "SURVEY_DESIGN"))

AREA <- 
  as.data.frame(readxl::read_excel(path = "temp/data.xlsx", 
                                   sheet = "AREA"))

STRATUM_GROUPS <- 
  as.data.frame(readxl::read_excel(path = "temp/data.xlsx", 
                                   sheet = "STRATUM_GROUPS"))

SPECIES_YEAR <- 
  as.data.frame(readxl::read_excel(path = "temp/data.xlsx", 
                                   sheet = "SPECIES_YEAR"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main_metadata_columns <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN")
main_metadata_columns <- 
  rbind(main_metadata_columns,
        data.frame(
          "METADATA_COLNAME" = "YEAR_STARTED", 
          "METADATA_COLNAME_LONG" = "Year Started", 
          "METADATA_UNITS" = "integer",
          "METADATA_DATATYPE" = "NUMBER(36, 0)",
          "METADATA_COLNAME_DESC" = "The starting year for a SPECIES_CODE in the time series." ))

for (idata in c("SURVEY_DESIGN", "AREA", "STRATUM_GROUPS", "SPECIES_YEAR")) {
  
  match_idx <- 
    match(x = names(x = get(x = idata)), 
          table = toupper(x = main_metadata_columns$METADATA_COLNAME))
  
  metadata_columns <- 
    with(main_metadata_columns,
         data.frame( colname = toupper(METADATA_COLNAME[match_idx]), 
                     colname_long = METADATA_COLNAME_LONG[match_idx], 
                     units = METADATA_UNITS[match_idx], 
                     datatype = METADATA_DATATYPE[match_idx], 
                     colname_desc = METADATA_COLNAME_DESC[match_idx]))
  
  gapindex::upload_oracle(
    channel = sql_channel,
    x = get(x = idata),
    schema = "GAP_PRODUCTS",
    table_name = idata,
    table_metadata = "This is a table",
    metadata_column = metadata_columns)
}


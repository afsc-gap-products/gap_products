##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Populate CTD lookup tables:
##   CTD_VARIABLE_CODES, CTD_INSTRUMENT_CODES, CTD_DIRECTION_CODES  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rm(list = ls())

library(readxl)
library(gapindex)

## Connect to Oracle
chl <- gapindex::get_connected(conn_type = "DBI", check_access = FALSE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Upload Lookup Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Loop over the lookup tables and append to the tables created in Oracle
for (itable in c("CTD_VARIABLE_CODES", "CTD_INSTRUMENT_CODES", 
                 "CTD_DIRECTION_CODES")) {
  lookup <- readxl::read_xlsx(path = "code/ctd_data/ctd_lookup_table_data.xlsx", 
                              sheet = itable)
  
  DBI::dbAppendTable(conn = chl, name = itable, value = lookup)
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Upload historical CTD data from 2021-2024
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ctd_data_2021_2024 <- 
  readRDS(file = "code/ctd_data/GAPCTD_all_casts_2021_2024.rds")
names(x = ctd_data_2021_2024) <- toupper(x = names(x = ctd_data_2021_2024))

DBI::dbAppendTable(conn = chl, 
                   name =  "CTD_DATA", 
                   value = ctd_data_2021_2024)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Upload Instrument Data
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ctd_instrument_data_2021_2024 <- 
  readRDS(file = "code/ctd_data/GAPCTD_instrument_2021_2024.rds")
names(x = ctd_instrument_data_2021_2024) <- 
  toupper(x = names(x = ctd_instrument_data_2021_2024))

DBI::dbAppendTable(conn = chl, 
                   name =  "CTD_HAUL_INSTRUMENT", 
                   value = ctd_instrument_data_2021_2024)

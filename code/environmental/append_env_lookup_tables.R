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
for (itable in c("VARIABLE_CODES", "INSTRUMENT_CODES", 
                 "DIRECTION_CODES")) {
  lookup <- readxl::read_xlsx(path = "code/environmental/env_lookup_table_data.xlsx", 
                              sheet = itable)
  
  DBI::dbAppendTable(conn = chl, name = itable, value = lookup)
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Upload historical CTD data from 2021-2024
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
env <- readRDS(file = "code/environmental/GAPCTD_all_casts_2021_2024.rds")
names(x = env) <- toupper(x = names(x = env))

instruments <- readRDS(file = "code/environmental/GAPCTD_instrument_2021_2024.rds")
names(x = instruments) <- toupper(x = names(x = instruments))

env <- merge(
  x = env, 
  y = instruments, 
  by = "HAULJOIN", 
  all.x = TRUE # Keeps all rows from environmental even if a hauljoin is missing in the instrument table
)
env <- env[, c("HAULJOIN", "DIRECTION", "DEPTH_M", "INSTRUMENT", "VARIABLE", "VALUE")]

DBI::dbAppendTable(conn = chl, 
                   name =  "ENVIRONMENTAL", 
                   value = env)

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ##  Upload Instrument Data
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ctd_instrument_data_2021_2024 <- 
#   readRDS(file = "code/environmental/GAPCTD_instrument_2021_2024.rds")
# names(x = ctd_instrument_data_2021_2024) <- 
#   toupper(x = names(x = ctd_instrument_data_2021_2024))
# 
# DBI::dbAppendTable(conn = chl, 
#                    name =  "HAUL_INSTRUMENT", 
#                    value = ctd_instrument_data_2021_2024)

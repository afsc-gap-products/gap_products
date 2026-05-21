##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Populate CTD lookup tables:
##   CTD_VARIABLE_CODES, CTD_INSTRUMENT_CODES, CTD_DIRECTION_CODES  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rm(list = ls())

library(readxl)
library(gapindex)

chl <- gapindex::get_connected(conn_type = "DBI", check_access = FALSE)

## Loop over the lookup tables and append to the tables created in Oracle
for (itable in c("CTD_VARIABLE_CODES", "CTD_INSTRUMENT_CODES", 
           "CTD_DIRECTION_CODES")) {
  lookup <- readxl::read_xlsx(path = "code/ctd_data/ctd_lookup_table_data.xlsx", 
                              sheet = itable)
  
  DBI::dbAppendTable(conn = chl, name = itable, value = lookup)
}


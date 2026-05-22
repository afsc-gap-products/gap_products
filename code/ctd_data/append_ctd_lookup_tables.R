##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Populate CTD lookup tables:
##   CTD_VARIABLE_CODES, CTD_INSTRUMENT_CODES, CTD_DIRECTION_CODES  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rm(list = ls())

## Connect to Oracle
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

## Upload historical CTD data from 2021-2024
ctd_data_2021_2024 <- 
  readRDS(file = "code/ctd_data/GAPCTD_all_casts_2021_2024.rds")
names(x = ctd_data_2021_2024) <- toupper(x = names(x = ctd_data_2021_2024))

DBI::dbAppendTable(conn = chl, 
                   name =  "CTD_DATA", 
                   value = subset(x = ctd_data_2021_2024,
                                  subset =  DEPTH_M >= 0))

# for(i in 1:nrow(ctd_data_2021_2024)) {
for (i in 1124001:1125000) {  
  tryCatch({
    DBI::dbAppendTable(conn = chl, 
                       name =  "CTD_DATA", 
                       value = ctd_data_2021_2024[i, ])
    
  }, error = function(e) {
    cat("Error occurred on row:", i, "\n")
    print(ctd_data_2021_2024[i, ])
  })
}

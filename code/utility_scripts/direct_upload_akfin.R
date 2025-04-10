##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Transfer AKFIN_* tables from AFSC GAP_PRODUCTS to 
##                AKFIN GAP_PRODUCTS_STAGE
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

# devtools::install_version("odbc", "1.3.4")
library(odbc); library(DBI)

## Connect to the AFSC GAP_PRODUCTS and AKFIN GAP_PRODUCTS_STAGE schemata
afsc_channel <- DBI::dbConnect(odbc::odbc(), dsn = "afsc", 
                               UID="GAP_PRODUCTS", 
                               PWD = getPass::getPass())
akfin_channel <- DBI::dbConnect(odbc::odbc(), dsn = "AKFIN", 
                                   UID="GAP_PRODUCTS_STAGE", 
                                   PWD = getPass::getPass())

## Query AKFIN_* table names from AFSC GAP_PRODUCTS to update
akfin_table_names <- 
  DBI::dbGetQuery(afsc_channel, 
                  "SELECT * FROM ALL_TABLES
                   WHERE OWNER = 'GAP_PRODUCTS'
                   AND TABLE_NAME LIKE 'AKFIN_%'")$TABLE_NAME

for (itable in akfin_table_names){ ## Loop over tables -- start
  
  cat(paste0("Currently Uploading ", itable, "... ") )
  start_time <- Sys.time()
  
  ## Query itable from AFSC GAP_PRDOUCTS and add AKFIN_LOAD_DATE date stamp
  temp_table <-
    DBI::dbGetQuery(afsc_channel,
                    paste0("SELECT GAP_PRODUCTS.", itable,
                           ".*, TRUNC(SYSDATE) AKFIN_LOAD_DATE ",
                           "FROM GAP_PRODUCTS.", itable))
  
  cat(paste0(nrow(x = temp_table), " records.\n"))
  
  ## Convert AKFIN_LOAD_DATE from Positct to character DATE
  if (any(grepl(pattern = "DATE", x = names(x = temp_table)) == TRUE)){
    date_fields <- grep(pattern = "DATE", x = names(x = temp_table))
    for (ifield in date_fields)
      temp_table[, ifield] <- format(temp_table[, ifield], "%Y-%m-%d ")
  }
  
  ## Truncate itable in AKFIN GAP_PRODUCTS_STAGE
  DBI::dbGetQuery(akfin_channel, paste0("TRUNCATE TABLE ", itable))
  
  ## Append to recently truncated itable in AKFIN GAP_PRODUCTS_STAGE
  DBI::dbAppendTable(conn = akfin_channel,
                     name = itable,
                     value = temp_table)
  
  ## Report how long it took to upload
  end_time <- Sys.time()
  cat(paste0("Finished Uploading ", nrow(x = temp_table), " records from ",
             itable, ". Time Elapsed: ",
             format(round(end_time - start_time)), "\n\n") )
} ## Loop over tables -- end

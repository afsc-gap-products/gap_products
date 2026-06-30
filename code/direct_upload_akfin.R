##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Transfer AKFIN_* tables from AFSC GAP_PRODUCTS to 
##                AKFIN GAP_PRODUCTS_STAGE
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Connect to Oracle using both AFSC GAP_PRODUCTS and AKFIN GAP_PRODUCT_STAGE 
## credentials
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

afsc_channel <- 
  gapindex::get_connected(db = "AFSC", conn_type = "DBI", check_access = F)
akfin_channel <- 
  gapindex::get_connected(db = "AKFIN", conn_type = "DBI", check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Loop over AKFIN tables, compile in R from AFSC GAP_PRODUCTS schema,
## Truncate the table in the AKFIN GAP_PRODUCTS_STAGE schema,
## Append the compiled table from R to AKFIN GAP_PRODUCTS_STAGE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Query AKFIN table names from AFSC GAP_PRODUCTS to update
akfin_table_names <- 
  dir("code/sql_akfin/") |> gsub(pattern = ".sql", replacement = "")

for (itable in rev(akfin_table_names)) { ## Loop over tables -- start
  
  ## Starting output message
  cat(paste0("Compiling ", itable, "...") )
  start_time <- Sys.time()
  
  ## Compile table in R
  temp_table <- 
    ## Read sql script for the creation of itable
    readLines(paste0("code/sql_akfin/", itable, ".sql")) |> 
    ## Remove lines starting with '--' or that are completely blank
    (\(lines) lines[!grepl("^\\s*(--|\\s*$)", lines)])() |> 
    # Collapse the remaining lines into a single string
    paste(collapse = " ") |> 
    ## Pass the clean SQL string directly into the query function
    (\(sql) DBI::dbGetQuery(conn = afsc_channel, statement = sql))()
  
  ## Convert any field with "DATE" in the name from Positct to character DATE
  if (any(grepl(pattern = "DATE", x = names(x = temp_table)) == TRUE)){
    date_fields <- grep(pattern = "DATE", x = names(x = temp_table))
    for (ifield in date_fields)
      temp_table[, ifield] <- format(temp_table[, ifield], "%Y-%m-%d")
  }
  
  ## Output time elapsed
  cat(paste0(nrow(x = temp_table), " records. Time Elapsed: ",
             format(round(Sys.time() - start_time)), "\n",
             "Transporting ", itable, " to AKFIN... ") )
  
  start_time <- Sys.time()
  ## Truncate itable in AKFIN GAP_PRODUCTS_STAGE
  DBI::dbGetQuery(akfin_channel, paste0("TRUNCATE TABLE ", itable))
  
  ## Append temp_table AKFIN GAP_PRODUCTS_STAGE
  DBI::dbAppendTable(conn = akfin_channel,
                     name = itable,
                     value = temp_table)
  
  ## Output time elapsed
  cat(paste0("Done. Time Elapsed: ",
             format(round(Sys.time() - start_time)), "\n\n") )
  
} ## Loop over tables -- end

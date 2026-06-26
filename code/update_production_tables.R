##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Update Production Tables in GAP_PRODUCTS
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##
## Description:   Once all the changes to the production tables have been 
##                accounted for, those updates are pushed to Oracle. Deleted 
##                records will be removed from the GAP_PRODUCTS tables, new 
##                will be inserted into the GAP_PRODUCTS tables, and modified 
##                records will first be removed from the GAP_PRODUCTS tables
##                and then the updated version of the records are inserted. 
##                
##                Any changes to the GAP_PRODUCTS.CPUE, GAP_PRODUCTS.BIOMASS,
##                GAP_PRODUCTS.SIZECOMP, and GAP_PRODUCTS.AGECOMP will initiate
##                a trigger that gets outputted to an audit table in the 
##                GAP_ARCHIVE schema labelled GAP_ARCHIVE.AUDIT_CPUE, 
##                GAP_ARCHIVE.AUDIT_BIOMASS, GAP_ARCHIVE.AUDIT_SIZECOMP, 
##                GAP_ARCHIVE.AUDIT_AGECOMP.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Load libraries and connect to Oracle. Make sure to connect using the 
##  GAP_PRODUCTS credentials. Import mismatches.RDS and constants
##
##  If you are a GAP_PRODUCTS proxy user, log into using username 
##  MYUSERNAME[GAP_PRODUCTS] and use your password
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex); library(data.table); library(rmarkdown)
gapproducts_channel <- gapindex::get_connected(check_access = F, 
                                               conn_type = "DBI")
stage_tables <- readRDS(file = "temp/stage_tables.RDS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Look at temp/mismatches.RDS and write a quick paragraph about the changes
##   in the data tables. Include your name and gapindex version used to produce
##   these data. In the next step, a summary of how many records were 
##   new/removed/modified are already provided so you don't need to tabulate 
##   these, just the reasons why these changes occurred (new data, new 
##   vouchered data, ad hoc decisions about taxon aggregations, updated stratum
##   areas, updated gapindex package, etc.) 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
detailed_notes <-
  "Run completed by: Zack Oyafuso

-- This run was conducted to test out a new way of updating the four main table (CPUE, BIOMASS, SIZECOMP, AGECOMP) using staging tables.

-- Incorporating new read ages for GOA arrowtooth flounder from 2025 and AI rougheye rockfish from 2024

"

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create report changelog
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gapindex_version <-
  subset(x = read.csv(file = "temp/installed_packages.csv"),
         subset = Package == "gapindex")$Version
timestamp <- readLines(con = "temp/timestamp.txt")
rmarkdown::render(input = "code/report_changes.RMD",
                  output_format = "html_document",
                  output_file = paste0("../temp/report_changes.html"),
                  params = list("detailed_notes" = detailed_notes,
                                "gapindex_version" = gapindex_version,
                                "timestamp" = timestamp))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Compile stage tables from the mismatches list 
##  Then, upload to Oracle stage tables, check on Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (itable in paste0("STAGE_", c("CPUE", "BIOMASS", "SIZECOMP", "AGECOMP"))) {
  gapindex::sql_query(channel = gapproducts_channel, 
                      query = paste0("TRUNCATE TABLE ", itable))
  DBI::dbAppendTable(conn = gapproducts_channel,
                     name = DBI::Id(schema = "GAP_PRODUCTS", table = itable),
                     value = stage_tables[[itable]])
  cat(nrow(x = stage_tables[[itable]]), "records uploaded to", itable, "\n")
}

## Check In SQL Developer that STAGE_* tables were updated

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Merge changes from the STAGE_* tables to the main tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (itable in c("cpue", "biomass", "sizecomp", "agecomp")) {
  n_recs <- nrow(x = stage_tables[[paste0("STAGE_", toupper(x = itable))]])
  
  if (n_recs > 0) {
    cat("Merging", n_recs, "changes into", toupper(x = itable), "\n") 
    
    ## Read the PL/SQL file as a single block of text
    plsql_script <- paste(readLines(con = paste0("code/sql_procedures/merge_", 
                                                 itable, "_changes.sql")), 
                          collapse = "\n")
    
    ## Execute the block safely inside an R tryCatch wrapper
    tryCatch({
      cat("Starting", itable, "merge...\n")
      
      ## dbExecute handles statements that don't return tabular records
      rows_affected <- DBI::dbExecute(gapproducts_channel, plsql_script)
      
      cat("Procedure completed successfully.\n")
    }, error = function(e) {
      cat("An error occurred during database execution:\n")
      print(e)
    })
    
  } else cat("No records to change for", toupper(x = itable), "\n")
  
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Use summarize_gp_updates to quickly check audit tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source("functions/summarize_gp_updates.R")
summarize_gp_updates(channel = gapproducts_channel,
                     time_start = "24-JUN-26 11.00.00 AM",
                     time_end = "26-JUN-26 11.59.00 PM" )

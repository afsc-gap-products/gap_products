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
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex); library(data.table); library(rmarkdown)
gapproducts_channel <- gapindex::get_connected(check_access = F)
updates <- readRDS(file = "temp/mismatches.RDS")
regions <- c("AI", "GOA", "EBS", "BSS", "NBS")
all_tables <- c("agecomp", "sizecomp", "biomass", "cpue")

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
  "Run completed by: Ned Laman, Zack Oyafuso

A development branch version of gapindex called [using_datatable](https://github.com/afsc-gap-products/gap_products/tree/using_datatable) uses the data.table package for many dataframe manipulations, which greatly decreased the computation time of many of the functions. There were no major changes in the calculations in this version of the gapindex package and thus the major changes listed below are not related to the gapindex package.

There was a minor issue with how the 9/4/2024 run uploaded records to Oracle from R that has been remedied. This run was a redo of the previous run and all changes in this run are summarized in the 9/4/2024 version of the changelog.

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
##   Import all field names to aid with uploading to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_field_names <- 
  RODBC::sqlQuery(
    channel = gapproducts_channel,
    query = paste0(
      "
SELECT cols.column_name, cols.table_name, 'KEY' AS FIELD_TYPE
FROM all_constraints cons
JOIN all_cons_columns cols
  ON cons.constraint_name = cols.constraint_name
JOIN all_tab_columns atc
  ON atc.table_name = cols.table_name
  AND atc.column_name = cols.column_name
  AND atc.owner = cols.owner
WHERE cons.constraint_type = 'P'
  AND cons.table_name in ", 
      gapindex::stitch_entries(toupper(x = all_tables)),
      " AND cons.owner = 'GAP_PRODUCTS'
  
UNION
  
SELECT atc.column_name, atc.table_name, 'RESPONSE' AS FIELD_TYPE
FROM all_tab_columns atc
WHERE atc.table_name in ('AGECOMP', 'CPUE', 'BIOMASS', 'SIZECOMP')
  AND atc.owner = 'GAP_PRODUCTS'     
  AND atc.column_name NOT IN (
    SELECT cols.column_name
    FROM all_constraints cons
    JOIN all_cons_columns cols
      ON cons.constraint_name = cols.constraint_name
    WHERE cons.constraint_type = 'P'
      AND cons.table_name in ", 
      gapindex::stitch_entries(toupper(x = all_tables)),
      " AND cons.owner = 'GAP_PRODUCTS'
  )
                                                          
ORDER BY TABLE_NAME, FIELD_TYPE, COLUMN_NAME
")
  )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over regions and table and upload updates
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (iregion in regions) {
  for (iquantity in all_tables) {
    
    ## Extract new, removed, and modified records
    modified_records <- updates[[iregion]][[iquantity]][["modified_records"]]
    removed_records <- updates[[iregion]][[iquantity]][["removed_records"]]
    new_records <- updates[[iregion]][[iquantity]][["new_records"]]
    
    key_fields <- subset(x = all_field_names,
                         subset = FIELD_TYPE == "KEY" & 
                           TABLE_NAME == toupper(iquantity))$COLUMN_NAME
    response_fields <- subset(x = all_field_names,
                              subset = FIELD_TYPE == "RESPONSE" & 
                                TABLE_NAME == toupper(iquantity))$COLUMN_NAME
    
    ## Extract field descriptions
    metadata_column <- 
      RODBC::sqlQuery(
        channel = gapproducts_channel,
        query = paste("SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                         WHERE METADATA_COLNAME IN",
                      gapindex::stitch_entries(c(key_fields, 
                                                 response_fields))))
    
    names(x = metadata_column) <- 
      gsub(x = tolower(x = names(x = metadata_column)), 
           pattern = "metadata_", 
           replacement = "")
    
    ## Remove records if they exist
    if (nrow(x = removed_records) > 0) {
      
      ## Extract the field descriptions of the table
      metadata_column <- 
        RODBC::sqlQuery(
          channel = gapproducts_channel,
          query = paste("SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                         WHERE METADATA_COLNAME IN",
                        gapindex::stitch_entries(key_fields)
          )
        )
      
      ## Change field names
      names(x = metadata_column) <- 
        gsub(x = tolower(x = names(x = metadata_column)), 
             pattern = "metadata_", 
             replacement = "")
      
      ## Upload a temporary table to GAP_PRODUCTS that holds the removed records
      gapindex::upload_oracle(
        x = removed_records[, keys[[iquantity]], with = F],
        table_name = "GAP_PRODUCTS_TEMP_REMOVED_RECORDS", 
        metadata_column = metadata_column, 
        table_metadata = paste(iquantity, "records to be removed from the", 
                               iregion, "region"), 
        channel = gapproducts_channel, 
        schema = "GAP_PRODUCTS", 
        share_with_all_users = F
      )
      
      ## Use the newly created temporary table to flag which records to 
      ## remove from the iquantity table. The fields that utilize the 
      RODBC::sqlQuery(
        channel = gapproducts_channel,
        query = 
          paste0(
            "DELETE FROM GAP_PRODUCTS.", toupper(x = iquantity), " ", 
            toupper(x = iquantity),
            " WHERE (", paste0(toupper(x = iquantity), ".", 
                               key_fields, 
                               collapse = ", "), ") 
          IN (SELECT ", paste0("REMOVE.", key_fields, 
                               collapse = ", "), 
            " FROM GAP_PRODUCTS.GAP_PRODUCTS_TEMP_REMOVED_RECORDS REMOVE)") )
      
      ## Drop temporary table
      RODBC::sqlDrop(channel = gapproducts_channel, 
                     sqtable = "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_REMOVED_RECORDS")
    }
    
    ## Add new records if they exist
    if (nrow(x = new_records) > 0) {
      
      ## Rbind both the new records and modified records
      new_records <- 
        new_records[, 
                    c(key_fields, paste0(response_fields, "_UPDATE")), 
                    with = F]
      names(x = new_records) <- c(key_fields, response_fields)
      
      ## Upload a temporary table to GAP_PRODUCTS that holds the new records
      gapindex::upload_oracle(
        x = new_records,
        table_name = "GAP_PRODUCTS_TEMP_NEW_RECORDS", 
        metadata_column = metadata_column, 
        table_metadata = paste(iquantity, "records to be added from the", 
                               iregion, "region"), 
        channel = gapproducts_channel, 
        schema = "GAP_PRODUCTS", 
        share_with_all_users = F)
      
      ## Append the new records to the 
      RODBC::sqlQuery(
        channel = gapproducts_channel,
        query = paste0("INSERT INTO GAP_PRODUCTS.", toupper(x = iquantity), 
                       " (", paste0(c(key_fields, response_fields), 
                                    collapse = ", "), ") 
                      SELECT ", paste0(c(key_fields, response_fields), 
                                       collapse = ", "), 
                       " FROM GAP_PRODUCTS.GAP_PRODUCTS_TEMP_NEW_RECORDS"))
      
      ## Drop temporary table
      RODBC::sqlDrop(channel = gapproducts_channel, 
                     sqtable = "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_NEW_RECORDS")
    }
    
    # Modify records if they exist
    if (nrow(x = modified_records) > 0) {
      
      ## Subset updated field records
      modified_records <- 
        modified_records[, 
                         c(key_fields, paste0(response_fields, "_UPDATE")), 
                         with = F]
      names(x = modified_records) <- c(key_fields, response_fields)
      
      ## Upload a temporary table to GAP_PRODUCTS that holds the new records
      gapindex::upload_oracle(
        x = new_records,
        table_name = "GAP_PRODUCTS_TEMP_MODIFIED_RECORDS", 
        metadata_column = metadata_column, 
        table_metadata = paste(iquantity, "records to be modified in the", 
                               iregion, "region"), 
        channel = gapproducts_channel, 
        schema = "GAP_PRODUCTS", 
        share_with_all_users = F)
      
      ## String together query to modify records
      modify_query <-
        paste0("UPDATE GAP_PRODUCTS.", toupper(x = iquantity), 
               " MAIN_TABLE\n\n SET(", 
               paste0(paste0("MAIN_TABLE.", response_fields), 
                      collapse = ", "),
               ") = (\n SELECT ",
               paste0(paste0("UPDATED_TABLE.", response_fields), 
                      collapse = ", "), "\n FROM ",
               "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_MODIFIED_RECORDS UPDATED_TABLE",
               "\n WHERE ",
               
               paste0(paste0("MAIN_TABLE.", key_fields), " = ", 
                      paste0("UPDATED_TABLE.", key_fields), 
                      collapse = "\n AND "), 
               
               "\n)\n WHERE EXISTS (\n SELECT 1 \n FROM ",
               "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_MODIFIED_RECORDS UPDATED_TABLE",
               "\n WHERE ",
               paste0(paste0("MAIN_TABLE.", key_fields), " = ", 
                      paste0("UPDATED_TABLE.", key_fields), 
                      collapse = "\n AND "), 
               
               "\n);"
        )
      
      ## Execute modify records query
      RODBC::sqlQuery(channel = gapproducts_channel,
                      query = modify_query)
      
      ## Drop temporary table
      RODBC::sqlDrop(channel = gapproducts_channel, 
                     sqtable = "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_MODIFIED_RECORDS")
      
    }
  }
}

## Commit changes
RODBC::sqlQuery(
  channel = gapproducts_channel,
  query = "commit;")

## Update Table Comments to reflect updated DDL timestamp
RODBC::sqlQuery(
  channel = gapproducts_channel,
  query = "BEGIN
	UPDATE_TABLE_COMMENTS;
	UPDATE_FIELD_COMMENTS;
END;")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Use summarize_gp_updates to quickly check audit tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# source("functions/summarize_gp_updates.R")
# summarize_gp_updates(channel = chl,
#                      time_start = "08-SEP-24 05.00.00 PM",
#                      time_end = "08-SEP-24 05.30.00 PM" )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update FOSS and AKFIN Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import AKFIN and FOSS table names and table descriptions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
views <- subset(x = read.csv(file = "data/table_comments.csv"),
                subset = table_type %in% c("akfin", "foss"))
source("functions/getSQL.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over SQL scripts, upload to Oracle, and add field and table comments
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (isql_script in 1:nrow(x = views)) { ## Loop over tables -- start
  start_time <- Sys.time()
  temp_table_name <- paste0("GAP_PRODUCTS.", views$table_name[isql_script])
  cat("Creating", temp_table_name, "...\n")
  
  ## Extract tables already in GAP_PRODUCTS
  available_views <- subset(x = RODBC::sqlTables(channel = channel, 
                                                 schema = "GAP_PRODUCTS"))
  
  ## If the temp_table_name already exists, drop before recreating
  if (views$table_name[isql_script] %in% available_views$TABLE_NAME)
    RODBC::sqlQuery(channel = channel, 
                    query = paste("DROP MATERIALIZED VIEW", temp_table_name))
  
  ## Run the SQL query for the materialized view. The AKFIN SQL scripts are
  ## in a folder called code/sql_akfin and the FOSS scripts are in a folder 
  ## caled code/sql_foss.
  RODBC::sqlQuery(
    channel = channel,
    query = getSQL(filepath = paste0("code/sql_", 
                                     views$table_type[isql_script], "/", 
                                     views$table_name[isql_script], ".sql")
    )
  )
  
  end_time <- Sys.time()
  cat(names(print(end_time - start_time)), "\n")
} ## Loop over tables -- end

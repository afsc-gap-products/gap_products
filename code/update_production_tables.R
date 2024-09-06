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
##  GAP_PRODUCTS credentials. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex); library(data.table)
gapproducts_channel <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Production Updates
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
updates <- readRDS(file = "temp/mismatches.RDS")
regions <- c("AI", "GOA", "EBS", "BSS", "NBS")
quantity <- c("agecomp", "sizecomp", "biomass", "cpue")

keys <- list(cpue = c("HAULJOIN", "SPECIES_CODE"),
             biomass = c("SURVEY_DEFINITION_ID", "YEAR", 
                         "SPECIES_CODE", "AREA_ID"),
             sizecomp = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID", 
                          "SPECIES_CODE", "SEX", "LENGTH_MM"),
             agecomp = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID", 
                         "SPECIES_CODE", "SEX", "AGE"))

for (iregion in regions) {
  for (iquantity in quantity) {
    
    ## Extract new, removed, and modified records
    modified_records <-
      updates[[iregion]][[iquantity]][["modified_records"]][, -"NOTE"]
    removed_records <- 
      updates[[iregion]][[iquantity]][["removed_records"]][, -"NOTE"]
    new_records <- 
      updates[[iregion]][[iquantity]][["new_records"]][, -"NOTE"]
    
    ## If there are records to be removed or modified ...
    if ((nrow(x = removed_records) + nrow(x = modified_records)) > 0) {
      
      ## Extract the field descriptions of the table
      metadata_column <- 
        RODBC::sqlQuery(
          channel = gapproducts_channel,
          query = paste("SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                         WHERE METADATA_COLNAME IN",
                        gapindex::stitch_entries(keys[[iquantity]])
          )
        )
      
      ## Change field names
      names(x = metadata_column) <- 
        gsub(x = tolower(x = names(x = metadata_column)), 
             pattern = "metadata_", 
             replacement = "")
      
      ## Upload a temporary table to GAP_PRODUCTS that holds the removed records
      gapindex::upload_oracle(
        x = rbind(
          modified_records[, keys[[iquantity]], with = F],
          removed_records[, keys[[iquantity]], with = F]
          ),
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
                               keys[[iquantity]], 
                               collapse = ", "), ") 
          IN (SELECT ", paste0("REMOVE.", keys[[iquantity]], 
                               collapse = ", "), 
            " FROM GAP_PRODUCTS.GAP_PRODUCTS_TEMP_REMOVED_RECORDS REMOVE)") )
      
      ## Drop the temporary table
      RODBC::sqlDrop(channel = gapproducts_channel, 
                     sqtable = "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_REMOVED_RECORDS")
    }
    
    ## If there are new or modified records ...
    if ((nrow(x = new_records) + nrow(x = modified_records)) > 0) {
      ## Extract field names of the table
      field_names <- c(keys[[iquantity]], 
                       gsub(x = grep(pattern = "_UPDATE", 
                                     x = names(x = new_records), 
                                     value = T), 
                            pattern = "_UPDATE", 
                            replacement = "") )
      
      ## Rbind both the new records and modified records
      new_records <- rbind(
        new_records[, c(keys[[iquantity]],
                        grep(pattern = "_UPDATE",
                             x = names(x = new_records),
                             value = T)), with = F],
        modified_records[, c(keys[[iquantity]], 
                             grep(pattern = "_UPDATE", 
                                  x = names(x = modified_records), 
                                  value = T)), with = F]
      )
      names(x = new_records) <- field_names
      
      ## Extract field descriptions
      metadata_column <- 
        RODBC::sqlQuery(
          channel = gapproducts_channel,
          query = paste("SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                         WHERE METADATA_COLNAME IN",
                        gapindex::stitch_entries(field_names)))
      
      names(x = metadata_column) <- 
        gsub(x = tolower(x = names(x = metadata_column)), 
             pattern = "metadata_", 
             replacement = "")
      
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
                       " (", paste0(field_names, collapse = ", "), ") 
                      SELECT ", paste0(field_names, collapse = ", "), 
                       " FROM GAP_PRODUCTS.GAP_PRODUCTS_TEMP_NEW_RECORDS"))
      
      RODBC::sqlDrop(channel = gapproducts_channel, 
                     sqtable = "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_NEW_RECORDS")
    }
  }
}

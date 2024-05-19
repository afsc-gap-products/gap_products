##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Update Production Tables in GAP_PRODUCTS
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Load libraries and connect to Oracle. Make sure to connect using the 
##  GAP_PRODUCTS credentials. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
gapproducts_channel <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Production Updates
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
updates <- readRDS(file = "temp/mismatches.RDS")
regions <- c("AI", "GOA", "EBS", "BSS", "NBS")
quantity <- c("agecomp", "sizecomp", "biomass", "cpue")

for (iregion in regions) {
  for (iquantity in quantity) {
    
    ## Extract new, removed, and modified records
    modified_records <-
      updates[[iregion]][[iquantity]][["modified_records"]][, -"NOTE"]
    removed_records <- updates[[iregion]][[iquantity]][["removed_records"]]
    
    ## If there are records to be removed ...
    if ((nrow(x = removed_records) + nrow(x = modified_records)) > 0) {
      metadata_column <- 
        RODBC::sqlQuery(
          channel = gapproducts_channel,
          query = paste("SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                         WHERE METADATA_COLNAME IN",
                        gapindex::stitch_entries(
                          data.table::key(removed_records)
                        )
          )
        )
      
      names(x = metadata_column) <- 
        gsub(x = tolower(x = names(x = metadata_column)), 
             pattern = "metadata_", 
             replacement = "")
      
      gapindex::upload_oracle(
        x = rbind(modified_records[, data.table::key(modified_records), with = F],
                  removed_records[, data.table::key(removed_records), with = F]),
        table_name = "GAP_PRODUCTS_TEMP_REMOVED_RECORDS", 
        metadata_column = metadata_column, 
        table_metadata = paste(iquantity, "records to be removed from the", 
                               iregion, "region"), 
        channel = gapproducts_channel, 
        schema = "GAP_PRODUCTS", share_with_all_users = F)
      
      RODBC::sqlQuery(
        channel = gapproducts_channel,
        query = 
          paste0(
            "DELETE FROM GAP_PRODUCTS.", toupper(x = iquantity), " ", 
            toupper(x = iquantity),
            " WHERE (", paste0(toupper(x = iquantity), ".", 
                               data.table::key(removed_records), 
                               collapse = ", "), ") 
          IN (SELECT ", paste0("REMOVE.", data.table::key(removed_records), 
                               collapse = ", "), 
            " FROM GAP_PRODUCTS.GAP_PRODUCTS_TEMP_REMOVED_RECORDS REMOVE)") )
      RODBC::sqlDrop(channel = gapproducts_channel, 
                     sqtable = "GAP_PRODUCTS.GAP_PRODUCTS_TEMP_REMOVED_RECORDS")
    }
    
    ## Extract New records
    new_records <- updates[[iregion]][[iquantity]][["new_records"]][, -"NOTE"]
    if ((nrow(x = new_records) + nrow(x = modified_records)) > 0) {
      
      field_names <- c(data.table::key(new_records), 
                       gsub(x = grep(pattern = "_UPDATE", 
                                     x = names(x = new_records), 
                                     value = T), 
                            pattern = "_UPDATE", 
                            replacement = "") )
      
      new_records <- rbind(
        new_records[, c(data.table::key(new_records),
                        grep(pattern = "_UPDATE",
                             x = names(x = new_records),
                             value = T)), with = F],
        modified_records[, c(data.table::key(new_records), 
                             grep(pattern = "_UPDATE", 
                                  x = names(x = modified_records), 
                                  value = T)), with = F]
        )
      names(x = new_records) <- field_names
      
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
      
      gapindex::upload_oracle(
        x = new_records,
        table_name = "GAP_PRODUCTS_TEMP_NEW_RECORDS", 
        metadata_column = metadata_column, 
        table_metadata = paste(iquantity, "records to be added from the", 
                               iregion, "region"), 
        channel = gapproducts_channel, 
        schema = "GAP_PRODUCTS", share_with_all_users = F)
      
      
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

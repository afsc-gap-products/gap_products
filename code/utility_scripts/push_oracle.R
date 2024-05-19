##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Upload Production Tables to GAP_PRODUCTS
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Load libraries and connect to Oracle. Make sure to connect using the 
##  GAP_PRODUCTS credentials. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
channel <- gapindex::get_connected(db = "AFSC", check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Constants and Table Descriptions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
regions <- c("AI", "GOA", "EBS", "BSS", "NBS")
quantity <- c("agecomp", "sizecomp", "biomass", "cpue")
source("code/functions.R")

table_comments <- subset(x = read.csv(file = "code/table_comments.csv"),
                         subset = table_type == "PRODUCTION")

legal_disclaimer <- create_disclaimer_text(channel = channel)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Upload Tables to GAP_PRODUCTS
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

for (idata in quantity) { ## Loop over data types -- start
  
  ## Import production tables for each region, append to data_table
  data_table <- data.frame()
  for (ireg in regions) { ## Loop over regions -- start
    temp_data <- read.csv(file = paste0("temp/production/production_", 
                                        idata, "_", ireg, ".csv"))
    data_table <- rbind(data_table, temp_data)
  } ## Loop over regions -- end
  
  ## Some final data column cleaning
  if (idata == "cpue") 
    data_table <- subset(x = data_table,
                         select = c(HAULJOIN, SPECIES_CODE, WEIGHT_KG, COUNT,
                                    AREA_SWEPT_KM2, CPUE_KGKM2, CPUE_NOKM2) )
  if (idata == "biomass") 
    data_table <- subset(x = data_table,
                         select = -SURVEY )
  ## Pull table description
  table_metadata <- table_comments$table_comment[
    table_comments$table_name == toupper(x = idata)
    ]
  
  ## Pull field descriptions from GAP_PRODUCTS.METADATA_COLUMN
  metadata_column <- 
    RODBC::sqlQuery(channel = channel,
                    query = paste(
                      "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                       WHERE METADATA_COLNAME IN",
                      gapindex::stitch_entries(names(x = data_table))))
  
  ## Clean up field names to be consistent with the data input format for 
  ## gapindex::upload_oracle
  names(x = metadata_column) <- 
    gsub(x = tolower(x = names(x = metadata_column)), 
         pattern = "metadata_", 
         replacement = "")
  
  ## Upload to Oracle
  gapindex::upload_oracle(channel = channel,
                          x = data_table,
                          schema = "GAP_PRODUCTS",
                          table_name = toupper(x = idata),
                          table_metadata = table_metadata,
                          metadata_column = metadata_column)
  
} ## Loop over data types -- start

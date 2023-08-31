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
sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Constants and Table Descriptions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
regions <- c("AI", "GOA", "EBS", "BSS", "NBS")
quantity <- c("agecomp", "sizecomp", "biomass", "cpue")
source("code/constants.R")
# source("code/functions.R")

table_metadata_info <- 
  RODBC::sqlQuery(channel = sql_channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.METADATA_TABLE")
table_metadata_bits <- table_metadata_info$METADATA_SENTENCE
names(x = table_metadata_bits) <- table_metadata_info$METADATA_SENTENCE_NAME

legal_disclaimer <- paste(table_metadata_bits["survey_institution"],
                          table_metadata_bits["legal_restrict"],
                          gsub(x = table_metadata_bits["github"],
                               pattern = "INSERT_REPO",
                               replacement = link_repo),
                          table_metadata_bits["codebook"],
                          gsub(x = table_metadata_bits["last_updated"],
                               pattern = "INSERT_DATE",
                               replacement = pretty_date))

table_comments <- data.frame(
  datatable = quantity,
  comment = c(paste("Region-level age compositions by sex/length bin.",
                    "This table was created", legal_disclaimer),
              paste("Stratum/subarea/region-level size compositions by sex.",
                    "This table was created ", legal_disclaimer),
              paste("Stratum/subarea/region-level mean CPUE (weight and",
                    "numbers), total biomass, and total abundance with",
                    "associated variances. This table was created", 
                    legal_disclaimer),
              paste("Haul-level zero-filled weight and numerical",
                    "catch-per-unit-effort.", "This table was created", 
                    legal_disclaimer))
  )

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
  if (idata %in%  c("agecomp", "biomass"))
    data_table <- subset(x = data_table, select = -SURVEY)
  if (idata == "cpue") 
    data_table <- subset(x = data_table,
                         select = c(HAULJOIN, SPECIES_CODE, WEIGHT_KG, COUNT,
                                    AREA_SWEPT_KM2, CPUE_KGKM2, CPUE_NOKM2) )
  
  ## Pull table description
  table_metadata <- table_comments$comment[table_comments$datatable == idata]
  
  ## Pull field descriptions from GAP_PRODUCTS.METADATA_COLUMN
  metadata_column <- 
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste("SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN",
                                  "WHERE METADATA_COLNAME IN",
                                  gapindex::stitch_entries(names(temp_data))))
  
  ## Clean up field names to be consistent with the data input format for 
  ## gapindex::upload_oracle
  names(x = metadata_column) <- 
    gsub(x = tolower(x = names(x = metadata_column)), 
         pattern = "metadata_", 
         replacement = "")
  
  ## Upload to Oracle
  gapindex::upload_oracle(channel = sql_channel,
                          x = data_table,
                          schema = "GAP_PRODUCTS",
                          table_name = toupper(x = idata),
                          table_metadata = table_metadata,
                          metadata_column = metadata_column)
  
} ## Loop over data types -- start

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Upload FOSS Materialized Views to GAP_PRODUCTS
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


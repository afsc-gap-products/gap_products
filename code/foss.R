##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Create FOSS Materialized Views Products
## Description:   Create the Materialized Views in GAP_PRODUCTS that are 
##                derivative of tables of tables in GAP_PRODUCTS, RACE_DATA,
##                RACEBASE, V_CRUISES, etc., for FOSS purposes. 
##                
##                Each materialized view has its own sql script in code/sql.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Set up which FOSS tables will be created based on which sql scripts are
##   in code/sql. Hard code descriptions of each table. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
sql_channel <- gapindex::get_connected()
source("code/constants.R")
source("code/functions.R")

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
metadata_fields <- 
  RODBC::sqlQuery(channel = sql_channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN")

for (isql_script in c("FOSS_HAUL", 
                      "FOSS_CATCH",
                      "FOSS_TAXON_GROUP", 
                      "FOSS_SPECIES", 
                      "FOSS_SURVEY_SPECIES",
                      "FOSS_CPUE_PRESONLY")) { ## Loop over foss sql -- start
  
  temp_table_name <- paste0("GAP_PRODUCTS.", isql_script)
  cat("Creating", temp_table_name, "...\n")
  
  ## Table Comment for Oracle upload
  if (isql_script == "FOSS_TAXON_GROUP") {
    metadata_table <- paste(
      "This reference dataset contains suggested search",
                            "groups for simplifying species selection in the FOSS",
                            "data platform so users can better search through",
                            "FOSS_CATCH. These tables were created", 
                            legal_disclaimer)
  } else if (isql_script == "FOSS_SURVEY_SPECIES") {
    metadata_table <- paste(
      "This reference dataset contains the full list of species by survey",
      "to be used to zero-fill FOSS_CATCH and FOSS_HAUL for each survey.",
      "These tables were created", 
      legal_disclaimer)      
  } else {
    metadata_table <- paste(
      "These datasets, FOSS_CATCH, FOSS_CPUE_PRESONLY, FOSS_HAUL, and",
          "FOSS_SPECIES, when full joined by the HAULJOIN variable,",
          "includes zero-filled (presence and absence)",
          "observations and catch-per-unit-effort (CPUE)",
          "estimates for all identified species at for index",
          "stations. These tables were created", legal_disclaimer)
  }
  
  ## If the view already exists, drop the view before creating
  available_views <- RODBC::sqlTables(channel = sql_channel, 
                                      schema = "GAP_PRODUCTS")
  
  if (isql_script %in% available_views$TABLE_NAME)
    RODBC::sqlQuery(channel = sql_channel, 
                    query = paste0("DROP MATERIALIZED VIEW GAP_PRODUCTS.",
                                   isql_script))
  
  ## Create View
  RODBC::sqlQuery(
    channel = sql_channel,
    query = getSQL(filepath = paste0("code/sql_foss/", isql_script, ".sql")))
  
  ## Upload column comments
  temp_field_metadata <- 
    subset(x = metadata_fields,
           subset =  METADATA_COLNAME %in% 
             RODBC::sqlColumns(channel = sql_channel,
                               sqtable = temp_table_name)$COLUMN_NAME)
  
  update_metadata(schema = "GAP_PRODUCTS", 
                  table_name = isql_script, 
                  table_type = "MATERIALIZED VIEW",
                  channel = sql_channel, 
                  metadata_column = temp_field_metadata, 
                  table_metadata = metadata_table)
  
} ## Loop over foss sql -- end


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Create AKFIN Materialized Views Products
## Description:   Create the Materialized Views in GAP_PRODUCTS that are 
##                derivative of tables of tables in GAP_PRODUCTS, RACE_DATA,
##                RACEBASE, V_CRUISES, etc., for AKFIN purposes. 
##                
##                Each materialized view has its own sql script in code/sql.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import libraries and connect to Oracle
##   Import metadata constants and commonly used functions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
channel <- gapindex::get_connected(check_access = F)
source("code/functions.R"); source("code/constants.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Set up which AKFIN tables will be created based on which sql scripts are
##   in code/sql. Hard code descritions of each table. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
akfin_views <- data.frame(
  table_name = gsub(x = grep(x = dir(path = "code/sql_akfin/"), 
                             pattern = ".sql", 
                             value = TRUE),
                    pattern = ".sql",
                    replacement = ""),
  desc = NA)

akfin_views$desc[akfin_views$table_name == "AKFIN_AGECOMP"] <-
  paste0("This table is a copy of GAP_PRODUCTS.AGECOMP ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_AREA"] <-
  paste0("This table is a copy of GAP_PRODUCTS.AREA ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_BIOMASS"] <-
  paste0("This table is a copy of GAP_PRODUCTS.BIOMASS ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_CATCH"] <-
  paste0("Catch records from hauls in RACEBASE.HAULS ",
         "where ABUNDANCE_HAUL = 'Y'. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_CPUE"] <-
  paste0("This table is a copy of GAP_PRODUCTS.CPUE ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_CRUISE"] <-
  paste0("This is the cruise data table. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_HAUL"] <-
  paste0("This table is created by subsetting the RACEBASE.HAUL table to ",
         "only hauls with ABUNDANCE_HAUL = 'Y'. These are the hauls that ",
         "are used for the standard production tables in GAP_PRODUCTS. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_LENGTH"] <-
  paste0("This table is created by subsetting the RACEBASE.LENGTH table to ",
         "only hauls with ABUNDANCE_HAUL = 'Y' from the five survey areas ",
         "with survey_definition_id: 'AI' = 52, 'GOA' = 47, 'EBS' = 98, ",
         "'BSS' = 78, 'NBS' = 143. These are the hauls that ",
         "are used for the standard production tables in GAP_PRODUCTS. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_METADATA_COLUMN"] <-
  paste0("This table is a copy of GAP_PRODUCTS.METADATA_COLUMN ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_SIZECOMP"] <-
  paste0("This table is a copy of GAP_PRODUCTS.SIZECOMP ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_SPECIMEN"] <-
  paste0("This table is created by subsetting the RACEBASE.SPECIMEN table to ",
         "only hauls with ABUNDANCE_HAUL = 'Y' from the five survey areas ",
         "with survey_definition_id: 'AI' = 52, 'GOA' = 47, 'EBS' = 98, ",
         "'BSS' = 78, 'NBS' = 143. These are the hauls that ",
         "are used for the standard production tables in GAP_PRODUCTS. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_STRATUM_GROUPS"] <-
  paste0("This table is a copy of GAP_PRODUCTS.STRATUM_GROUPS ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_SURVEY_DESIGN"] <-
  paste0("This table is a copy of GAP_PRODUCTS.SURVEY_DESIGN ",
         "and does not have any other object dependencies. ")
akfin_views$desc[akfin_views$table_name == "AKFIN_TAXONOMY"] <-
  paste0("This table is a copy of GAP_PRODUCTS.SPECIES_CLASSIFICATION ",
         "filtered for values where SURVEY_SPECIES = 1 ",
         "and does not have any other object dependencies. ")
# akfin_views$desc[akfin_views$table_name == "AKFIN_TAXONOMIC_GROUPS"] <-
#   paste0("This table is a copy of GAP_PRODUCTS.TAXONOMIC_GROUPS ",
#          "filtered for values where SURVEY_SPECIES = 1 ",
#          "and does not have any other object dependencies. ")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Assemble the basic text that states that GAP produced the tables, the
##   repo that houses the code to maintain the tables, and the data the 
##   table was created. This will be appended to each table description.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
metadata_table <- 
  RODBC::sqlQuery(channel = channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.METADATA_TABLE")

table_metadata_text <- 
  with(metadata_table,
       paste(
         "These data are produced",
         METADATA_SENTENCE[METADATA_SENTENCE_NAME  == "survey_institution"],
         METADATA_SENTENCE[METADATA_SENTENCE_NAME  == "legal_restrict"],
         gsub(x = METADATA_SENTENCE[METADATA_SENTENCE_NAME  == "github"], 
              pattern = "INSERT_REPO", 
              replacement = link_repo),
         gsub(x = METADATA_SENTENCE[METADATA_SENTENCE_NAME == "last_updated"], 
              pattern = "INSERT_DATE", 
              replacement = pretty_date),
         collapse = " ", sep = " ")
  )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over sql scripts, upload to Oracle, then append table and filed 
##   metadata. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

metadata_fields <- 
  RODBC::sqlQuery(channel = channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN")

for (isql_script in 1:nrow(x = akfin_views))  {
  start_time <- Sys.time()
  temp_table_name <- paste0("GAP_PRODUCTS.",
                            akfin_views$table_name[isql_script])
  cat("Creating", temp_table_name, "...")
  
  available_views <-
    subset(x = RODBC::sqlTables(channel = channel, 
                                schema = "GAP_PRODUCTS"))
  
  if (akfin_views$table_name[isql_script] %in% available_views$TABLE_NAME)
    RODBC::sqlQuery(channel = channel, 
                    query = paste("DROP MATERIALIZED VIEW", temp_table_name))
  
  RODBC::sqlQuery(channel = channel,
                  query = getSQL(filepath = paste0(
                    "code/sql_akfin/",
                    akfin_views$table_name[isql_script],
                    ".sql")))
  
  temp_field_metadata <- 
    subset(x = metadata_fields,
           subset =  METADATA_COLNAME %in% 
             RODBC::sqlColumns(channel = channel,
                               sqtable = temp_table_name)$COLUMN_NAME)
  
  update_metadata(schema = "GAP_PRODUCTS", 
                  table_name = akfin_views$table_name[isql_script], 
                  table_type = "MATERIALIZED VIEW",
                  channel = channel, 
                  metadata_column = temp_field_metadata, 
                  table_metadata = paste0(akfin_views$desc[isql_script], 
                                          table_metadata_text))
  
  end_time <- Sys.time()
  cat(names(print(end_time - start_time)), "\n")
  
}

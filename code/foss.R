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
##   in code/sql. Hard code descritions of each table. 
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

metadata_table <- 
  paste("These datasets, FOSS_CATCH and FOSS_HAUL, when full joined by",
        "the HAULJOIN variable, includes zero-filled (presence and absence)",
        "observations and catch-per-unit-effort (CPUE) estimates for all",
        "identified species at for index stations. These tables were created", 
        legal_disclaimer)

for (isql_script in c("FOSS_HAUL", "FOSS_CATCH")) {
  
  temp_table_name <- paste0("GAP_PRODUCTS.", isql_script)
  cat("Creating", temp_table_name, "...\n")
  
  available_views <-
    subset(x = RODBC::sqlTables(channel = sql_channel, 
                                schema = "GAP_PRODUCTS"),
           subset = TABLE_TYPE == "VIEW")
  
  
  if (isql_script %in% available_views$TABLE_NAME)
    RODBC::sqlQuery(channel = sql_channel, 
                    query = paste("DROP VIEW", temp_table_name))
  
  RODBC::sqlQuery(
    channel = sql_channel,
    query = getSQL(filepath = paste0("code/sql_foss/", isql_script, ".sql")))
  
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
  
}

### FOSS_CATCH -----------------------------------------------------------------

metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table,
  name0 = "FOSS_CATCH",
  dir_out = dir_out)

update_metadata(
  schema = "GAP_PRODUCTS", 
  table_name = "FOSS_CATCH", 
  channel = channel, 
  metadata_column = metadata_column, 
  table_metadata = metadata_table)

### FOSS_HAUL ------------------------------------------------------------------

metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table,
  name0 = "FOSS_HAUL",
  dir_out = dir_out)

update_metadata(
  schema = "GAP_PRODUCTS", 
  table_name = "FOSS_HAUL", 
  channel = channel, 
  metadata_column = metadata_column, 
  table_metadata = metadata_table)

## Make Taxonomic grouping searching table -----------------------------------------------

TAXON_GROUPS <- NEW_TAXONOMICS_ITIS %>%
  dplyr::select(species_code, genus, family, order, class, phylum, kingdom) %>%
  tidyr::pivot_longer(data = .,
                      cols = c("genus", "family", "order", "class", "phylum", "kingdom"),
                      names_to = "id_rank", values_to = "classification") %>%
  dplyr::relocate(id_rank, classification, species_code) %>%
  dplyr::arrange(id_rank, classification, species_code) %>%
  dplyr::filter(!is.na(classification))

# only keep groups that have more than one member
NEW_TAXON_GROUPS <- TAXON_GROUPS[duplicated(x = TAXON_GROUPS$id_rank),]

NEW_TAXON_GROUPS_COMMENT <- paste(
  "This dataset contains suggested search groups for simplifying species selection in the FOSS data platform. This was developed ", 
  metadata_sentence_survey_institution,
  metadata_sentence_legal_restrict_none, 
  metadata_sentence_foss, 
  metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated, 
  collapse = " ", sep = " ")

# NEW_TAXON_GROUPS_TABLE <- fix_metadata_table(
#   metadata_table0 = NEW_METADATA_TABLE,
#   name0 = "TAXON_GROUPS",
#   dir_out = dir_out)


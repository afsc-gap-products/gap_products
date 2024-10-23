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
sql_channel <- gapindex::get_connected()
source("code/functions.R"); source("code/constants.R")

table_description <- "This view creates a table of sample sizes in units of hauls and individuals for our standard length and otolith core collections."

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Assemble the basic text that states that GAP produced the tables, the
##   repo that houses the code to maintain the tables, and the data the 
##   table was created. This will be appended to each table description.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
metadata_table <- 
  RODBC::sqlQuery(channel = sql_channel, 
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

metadata_fields <- RODBC::sqlQuery(channel = sql_channel, 
                                   query = "SELECT *
                                            FROM GAP_PRODUCTS.METADATA_COLUMN")

if ("SAMPLESIZE" %in% available_views$TABLE_NAME)
  RODBC::sqlQuery(channel = sql_channel, 
                  query = "DROP VIEW GAP_PRODUCTS.SAMPLESIZE")

RODBC::sqlQuery(channel = sql_channel,
                query = getSQL(filepath = paste0("code/sql_other_views/",
                                                 "specimen_summary.sql")))

temp_field_metadata <- 
  subset(x = metadata_fields,
         subset =  METADATA_COLNAME %in% 
           RODBC::sqlColumns(channel = sql_channel,
                             sqtable = "GAP_PRODUCTS.SAMPLESIZE")$COLUMN_NAME)

update_metadata(schema = "GAP_PRODUCTS", 
                table_name = "SAMPLESIZE", 
                table_type = "VIEW",
                channel = sql_channel, 
                metadata_column = temp_field_metadata, 
                table_metadata = table_description)


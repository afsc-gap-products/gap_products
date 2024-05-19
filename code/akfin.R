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
channel <- gapindex::get_connected(db = "AFSC", check_access = F)
source("code/functions.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Set up which AKFIN tables will be created based on which sql scripts are
##   in code/sql.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
akfin_views <- subset(x = read.csv(file = "code/table_comments.csv"),
                      subset = table_type == "AKFIN")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Assemble the basic text that states that GAP produced the tables, the
##   repo that houses the code to maintain the tables, and the data the 
##   table was created. This will be appended to each table description.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
disclaimer_text <- create_disclaimer_text(channel = channel)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over SQL scripts, upload to Oracle, and add field and table comments
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Pull metadata fields from GAP_PRODUCTS
metadata_fields <- 
  RODBC::sqlQuery(channel = channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN")

for (isql_script in 1:nrow(x = akfin_views)) { ## Loop over tables -- start
  start_time <- Sys.time()
  temp_table_name <- paste0("GAP_PRODUCTS.", 
                            akfin_views$table_name[isql_script])
  cat("Creating", temp_table_name, "...\n")
  
  ## Extract tables already in GAP_PRODUCTS
  available_views <- subset(x = RODBC::sqlTables(channel = channel, 
                                                 schema = "GAP_PRODUCTS"))
  
  ## If the temp_table_name already exists, drop before recreating
  if (akfin_views$table_name[isql_script] %in% available_views$TABLE_NAME)
    RODBC::sqlQuery(channel = channel, 
                    query = paste("DROP MATERIALIZED VIEW", temp_table_name))
  
  ## Run the SQL query for the materialized view
  RODBC::sqlQuery(channel = channel,
                  query = getSQL(filepath = paste0(
                    "code/sql_akfin/",
                    akfin_views$table_name[isql_script],
                    ".sql")))
  
  ## Subset field information for the fields in temp_table_name
  temp_field_metadata <- 
    subset(x = metadata_fields,
           subset =  METADATA_COLNAME %in% 
             RODBC::sqlColumns(channel = channel,
                               sqtable = temp_table_name)$COLUMN_NAME)
  
  ## Add Field and Table Comments 
  update_metadata(schema = "GAP_PRODUCTS", 
                  table_name = akfin_views$table_name[isql_script],
                  channel = channel, 
                  metadata_column = temp_field_metadata, 
                  table_metadata = paste0(akfin_views$table_comment[isql_script], 
                                          disclaimer_text))
  
  end_time <- Sys.time()
  cat(names(print(end_time - start_time)), "\n")
  
} ## Loop over tables -- end

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
##   Import AKFIN and FOSS table names and table descriptions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
views <- subset(x = read.csv(file = "data/table_comments.csv"),
                subset = table_type %in% c("akfin", "foss")[1])

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

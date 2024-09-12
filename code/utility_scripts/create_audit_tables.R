##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Set up audit tables and triggers for GAP_PRODUCTS Tables
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Use this in case you need to set up again
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Make two Oracle connections using credentials for USERNAMES
##   GAP_PRODUCTS and GAP_ARCHIVE.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
gapproducts_channel <- gapindex::get_connected(db = "AFSC", check_access = F)
gaparchive_channel <- gapindex::get_connected(db = "AFSC", check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   For each table, string together the text that sets up the audit table
##   as well as the associated insert/delete/update trigger. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

for (itable in c("AGECOMP", "AREA", "BIOMASS", "CPUE", "SIZECOMP",
                 "SPECIES_YEAR", "SURVEY_DESIGN", "STRATUM_GROUPS",
                 "METADATA_COLUMN"
                 )) { ## Loop over table -- start
  
  ## Retrieve the primary key columns that make up the itable.
  key_columns <- RODBC::sqlQuery(channel = gaparchive_channel,
                                 query = paste0("
SELECT cols.column_name,
       CASE
         WHEN atc.data_type IN ('VARCHAR2', 'CHAR') THEN 
            atc.data_type || '(' || atc.data_length || ')'
         WHEN atc.data_type = 'NUMBER' THEN 
            atc.data_type ||
            '(' || NVL(atc.data_precision, atc.data_length) || 
            CASE 
               WHEN atc.data_scale IS NOT NULL THEN ',' || atc.data_scale 
               ELSE '' 
            END || ')'
         ELSE atc.data_type
       END AS data_type
FROM all_constraints cons
JOIN all_cons_columns cols
  ON cons.constraint_name = cols.constraint_name
JOIN all_tab_columns atc
  ON atc.table_name = cols.table_name
  AND atc.column_name = cols.column_name
  AND atc.owner = cols.owner
WHERE cons.constraint_type = 'P'
  AND cons.table_name = UPPER('", itable, "')  -- Replace with table name
  AND cons.owner = UPPER('GAP_PRODUCTS')     -- Replace with schema name
                "))
  
  ## Retrieve the non-primary key (response) columns of the itable.
  response_column_names <- RODBC::sqlQuery(channel = gaparchive_channel,
                                           query = paste0("
SELECT atc.column_name,
       CASE
         WHEN atc.data_type IN ('VARCHAR2', 'CHAR') THEN 
            atc.data_type || '(' || atc.data_length || ')'
         WHEN atc.data_type = 'NUMBER' THEN 
            atc.data_type || 
            '(' || NVL(atc.data_precision, atc.data_length) || 
            CASE 
               WHEN atc.data_scale IS NOT NULL THEN ',' || atc.data_scale 
               ELSE '' 
            END || ')'
         ELSE atc.data_type
       END AS data_type
FROM all_tab_columns atc
WHERE atc.table_name = UPPER('", itable, "')  
  AND atc.owner = UPPER('GAP_PRODUCTS')      
  AND atc.column_name NOT IN (
    SELECT cols.column_name
    FROM all_constraints cons
    JOIN all_cons_columns cols
      ON cons.constraint_name = cols.constraint_name
    WHERE cons.constraint_type = 'P'
      AND cons.table_name = UPPER('", itable, "') 
      AND cons.owner = UPPER('GAP_PRODUCTS')
  )
                                                          
ORDER BY COLUMN_NAME;"))
  
  ## add _CURRENT and _UPDATE to the response fields for the audit table
  response_columns <-  
    merge(x = expand.grid(COLUMN_NAME = response_column_names$COLUMN_NAME, 
                          COLUMN_TYPE = c("_CURRENT", "_UPDATE")),
          y = response_column_names,
          by = "COLUMN_NAME")
  response_columns$COLUMN_NAME <- paste0(response_columns$COLUMN_NAME,
                                         response_columns$COLUMN_TYPE)
  
  ## Rbind the key and response field names into one dataframe
  all_columns <- rbind(key_columns,
                       subset(x = response_columns, 
                              select = c(COLUMN_NAME, DATA_TYPE)))
  
  ## String together the string to set up the audit table
  audit_table_creation_query <-
    paste0(
      "CREATE OR REPLACE TABLE GAP_ARCHIVE.AUDIT_", itable, " (\n", 
      "OPERATION_TYPE VARCHAR2(10),\nOPERATION_TIMESTAMP TIMESTAMP,\n",
      "USER_NAME VARCHAR2(100),\n", paste0(paste(all_columns$COLUMN_NAME, 
                                                 all_columns$DATA_TYPE), 
                                           collapse = ", \n"),
      "\n);\n")
  
  ## Execute audit_table creation
  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = audit_table_creation_query)
  
  ## Grant select on the audit table to all
  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = paste0("GRANT SELECT ON GAP_ARCHIVE.AUDIT_",
                                 itable, " TO PUBLIC;"))
  
  ## Grant insert/delete/update on the audit table only to GAP_PRODUCTS
  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = paste0('GRANT INSERT ON GAP_ARCHIVE.AUDIT_',
                                 itable, ' TO GAP_PRODUCTS;'))
  
  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = paste0('GRANT DELETE ON GAP_ARCHIVE.AUDIT_',
                                 itable, ' TO GAP_PRODUCTS;'))
  
  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = paste0('GRANT UPDATE ON GAP_ARCHIVE.AUDIT_',
                                 itable, ' TO GAP_PRODUCTS;'))
  
  ## String together the string to set up the trigger
  audit_table_trigger_creation_query <-
    paste0(
      "CREATE OR REPLACE TRIGGER GAP_PRODUCTS.AUDIT_", itable, 
      "\nAFTER INSERT OR DELETE OR UPDATE ON GAP_PRODUCTS.", itable,
      "\nFOR EACH ROW\nBEGIN\n", 
      "\n  IF INSERTING THEN\n    INSERT INTO GAP_ARCHIVE.AUDIT_", 
      itable, "\n      (OPERATION_TYPE, OPERATION_TIMESTAMP, USER_NAME, ", 
      paste0(c(key_columns$COLUMN_NAME, 
               response_columns$COLUMN_NAME[
                 response_columns$COLUMN_TYPE == "_UPDATE"
               ]), 
             collapse = ", "), ")\n",
      "    VALUES (", "'INSERT', SYSTIMESTAMP, USER, ", 
      
      paste0(as.vector(sapply(X = c(key_columns$COLUMN_NAME, 
                                    response_column_names$COLUMN_NAME), 
                              FUN = function(x) paste0(c(":NEW."), x))), 
             collapse = ", "), ");\n\n", 
      
      "  ELSIF DELETING THEN\n    INSERT INTO GAP_ARCHIVE.AUDIT_", 
      itable, "\n      (OPERATION_TYPE, OPERATION_TIMESTAMP, USER_NAME, ", 
      paste0(c(key_columns$COLUMN_NAME, 
               response_columns$COLUMN_NAME[
                 response_columns$COLUMN_TYPE == "_CURRENT"
                 ]), 
             collapse = ", "), ")\n",
      "    VALUES (", "'DELETE', SYSTIMESTAMP, USER, ", 
      
      paste0(as.vector(sapply(X = c(key_columns$COLUMN_NAME, 
                                    response_column_names$COLUMN_NAME), 
                              FUN = function(x) paste0(c(":OLD."), x))), 
             collapse = ", "), ");\n\n", 
      
      "  ELSIF UPDATING THEN\n    INSERT INTO GAP_ARCHIVE.AUDIT_", itable, 
      "\n      (OPERATION_TYPE, OPERATION_TIMESTAMP, USER_NAME, ", 
      paste0(all_columns$COLUMN_NAME, collapse = ", "), ")\n",
      "    VALUES (", "'UPDATE', SYSTIMESTAMP, USER, ", 
      paste0(paste0(":NEW.", key_columns$COLUMN_NAME, collapse = ", ")), 
      
      ifelse(test = nrow(x = response_column_names) > 0,
             no = ");\n",
             yes = paste0(
               ", ", 
               paste0(as.vector(sapply(X = response_column_names$COLUMN_NAME, 
                                             FUN = function(x) 
                                               paste0(c(":OLD.", ":NEW."), x))), 
                            collapse = ", "), ");\n")),
      
      "\n  END IF;\nEND;\n")
  
  ## Execute trigger creation
  RODBC::sqlQuery(channel = gapproducts_channel,
                  query = audit_table_trigger_creation_query)
} ## Loop over table -- end

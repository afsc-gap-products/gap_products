## @Ned: can you review this sandbox example of how we could set up key constraints
## and audit table triggers for GAP_PRODUCTS tables. 
## 
### Context
## The current way I have been creating GAP_PRODUCTS.CPUE, GAP_PRODUCTS.BIOMASS, GAP_PRODUCTS.SIZECOMP, and GAP_PRODUCTS.AGECOMP has been to recreate the tables in their entirety in R via the gapindex package and then and drop/upload those tables to the GAP_PRODUCTS schema. This has the advantage of making sure we are consistenly using the most updated data in RACEBASE and a consistent version of gapindex. 

### Issues
## Every time these data tables are made, the entire table in GAP_PRODUCTS need to be dropped and reuploaded. This prevents any versioning of the data tables that could be captured in an audit table. This process also takes some time (less than a day, but this is less of an issue). Given only a small percentage of the data actually change after each production iteration, efficiencies could be gained by being more precise with how records in the GAP_PRODUCTS CPUE/BIOMASS/SIZECOMP/AGECOMP tables are updated and capturing those changes automatically in Oracle.

## Exercise to play around with audit tables, triggers, and update workflows

## Import gapindex package
library(gapindex)

## Connect to Oracle using personal (i.e., GAP_PRODUCTS) 
chl <- gapindex::get_connected()

## Create dummy catch table where the field `KEY_ID` is the primary key, 
## and WEIGHT_KG and and NUMBER_COUNT are data fields 
set.seed(100)
dummy_catch <- data.frame(KEY_ID = 1:10, 
                          WEIGHT_KG = rpois(n = 10, lambda = 100), 
                          NUMBER_COUNT = rpois(n = 10, lambda = 30))
catch_tbl_structure <- data.frame(colname = c("KEY_ID", 'WEIGHT_KG', "NUMBER_COUNT"),
                            colname_long = c("KEY_ID", 'WEIGHT_KG', "NUMBER_COUNT"),
                            datatype = c("NUMBER (36,0)","NUMBER (36,0)","NUMBER (36,0)"), 
                            units = c("integer", "integer", "integer"),
                            colname_desc = c("KEY_ID", 'WEIGHT_KG', "NUMBER_COUNT"))

## Upload dummy catch and effort table to Oracle under your personal schema
gapindex::upload_oracle(x = dummy_catch, 
                        table_name = "DUMMY_CATCH", 
                        channel = chl, schema = "OYAFUSOZ", 
                        metadata_column = catch_tbl_structure,
                        table_metadata = "This is a table")

## Set the primary key field
RODBC::sqlQuery(channel = chl,
                query = "ALTER TABLE DUMMY_CATCH 
                ADD CONSTRAINT ID_CONTRAINT 
                PRIMARY KEY (KEY_ID); ")
## Create audit table. Essentially, we want to 
RODBC::sqlQuery(channel = chl,
                query = "
                CREATE TABLE catch_audit_table (
    operation_type VARCHAR2(10),
    operation_timestamp TIMESTAMP,
    user_name VARCHAR2(100),
    table_name VARCHAR2(100),
    key_id NUMBER(36,0),
    WEIGHT_KG NUMBER(36,0),
    NUMBER_COUNT NUMBER(36,0)
);")

## Create a trigger where if any deletion of insertion in the DUMMY_CATCH table
## occurs, create a record in the audit table that has the: timestamp, user, 
## table name affected, key_id, action (deletion or insertion), data fields 
## that were affected and their values.
RODBC::sqlQuery(channel = chl,
                query = "
                CREATE OR REPLACE TRIGGER insert_audit_trigger
AFTER INSERT ON dummy_catch
FOR EACH ROW
BEGIN
    INSERT INTO catch_audit_table (operation_type, operation_timestamp, user_name, table_name, key_id, WEIGHT_KG, NUMBER_COUNT)
    VALUES ('INSERT', SYSTIMESTAMP, USER, 'dummy_catch', :NEW.key_id, :NEW.WEIGHT_KG, :NEW.NUMBER_COUNT);
END;
")

RODBC::sqlQuery(channel = chl,
                query = "
                CREATE OR REPLACE TRIGGER delete_audit_trigger
AFTER DELETE ON dummy_catch
FOR EACH ROW
BEGIN
    INSERT INTO catch_audit_table (operation_type, operation_timestamp, user_name, table_name, key_id, WEIGHT_KG, NUMBER_COUNT)
    VALUES ('DELETE', SYSTIMESTAMP, USER, 'dummy_catch', :OLD.key_id, :OLD.WEIGHT_KG, :OLD.NUMBER_COUNT);
END;
")

## Crate a mock action: delete the record associated with KEY_ID = 10
delete_catch <- subset(dummy_catch, KEY_ID == 10)
delete_effort <- subset(dummy_effort, KEY_ID == 10)

## Create a temp table that holds the values of key_id that will be deleted
gapindex::upload_oracle(x = delete_catch, 
                        table_name = "TEMP_DELETE", 
                        channel = chl, schema = "OYAFUSOZ", 
                        metadata_column = catch_tbl_structure,
                        table_metadata = "This is a table")
RODBC::sqlQuery(channel = chl,
                query = "DELETE FROM dummy_catch
WHERE (key_id) IN (
    SELECT key_id
    FROM temp_delete
);")


## Create another mock action: insert a new record with KEY_ID 11
new_catch <- data.frame(KEY_ID = 11:12, 
                        WEIGHT_KG = rpois(n = 2, lambda = 100), 
                        NUMBER_COUNT = rpois(n = 2, lambda = 30))
new_effort <- data.frame(KEY_ID = 11:12, 
                         EFFORT = rpois(n = 2, lambda = 3))

## Create a temp table that holds the values of key_id that will be inserted
gapindex::upload_oracle(x = new_catch, 
                        table_name = "TEMP_INSERT", 
                        metadata_column = catch_tbl_structure,
                        table_metadata = "This is a table",
                        channel = chl, schema = "OYAFUSOZ")
RODBC::sqlQuery(channel = chl,
                query = "INSERT INTO DUMMY_CATCH
                         SELECT * FROM TEMP_INSERT")

## Create another mock action: modify records #1 and #2 to the dummy_catch table
modified_catch <- data.frame(KEY_ID = 1:2, 
                             WEIGHT_KG = rpois(n = 2, lambda = 100), 
                             NUMBER_COUNT = rpois(n = 2, lambda = 30))
gapindex::upload_oracle(x = modified_catch, 
                        table_name = "TEMP_MODIFY", 
                        metadata_column = catch_tbl_structure,
                        table_metadata = "This is a table.",
                        channel = chl, schema = "OYAFUSOZ")
RODBC::sqlQuery(channel = chl,
                query = "DELETE FROM dummy_catch 
                         WHERE (key_id) IN (SELECT key_id FROM TEMP_MODIFY);")
RODBC::sqlQuery(channel = chl,
                query = "INSERT INTO DUMMY_CATCH
                         SELECT * FROM TEMP_MODIFY")

## Try to insert a duplicate
duplicate_catch <- dummy_catch[5, ]
gapindex::upload_oracle(x = duplicate_catch, 
                        table_name = "TEMP_DUPLICATE", 
                        metadata_column = catch_tbl_structure,
                        table_metadata = "This is a table.",
                        channel = chl, schema = "OYAFUSOZ")
RODBC::sqlQuery(channel = chl,
                query = "INSERT INTO DUMMY_CATCH
                         SELECT * FROM TEMP_DUPLICATE")

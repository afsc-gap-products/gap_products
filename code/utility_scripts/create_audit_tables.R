##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Set up primary keys, audit tables, triggers
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Set up primary keys, audit tables, and triggers for
##                GAP_PRODUCTS.SURVEY_DESIGN
##                GAP_PRODUCTS.SPECIES_YEAR
##                GAP_PRODUCTS.STRATUM_GROUPS
##                
##                GAP_PRODUCTS.CPUE
##                GAP_PRODUCTS.BIOMASS
##                GAP_PRODUCTS.SIZECOMP
##                GAP_PRODUCTS.AGECOMP
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

## Connect to Oracle using GAP_PROUDCTS credentials. Make sure to connect to 
## the NOAA Internal or VPN
library(gapindex)
gapproducts_channel <- gapindex::get_connected(db = "AFSC", check_access = F)
gaparchive_channel <- gapindex::get_connected(db = "AFSC", check_access = F)

quantity <- c("agecomp", "sizecomp", "biomass", "cpue")[]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Set up constraints
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Set up stratum groups constraints
RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
ALTER TABLE GAP_PRODUCTS.STRATUM_GROUPS
ADD CONSTRAINT STRATUM_GROUPS_CONTRAINT
PRIMARY KEY (SURVEY_DEFINITION_ID, DESIGN_YEAR, AREA_ID, STRATUM);
")

## Set up GAP_PRODUCTS.SPECIES_YEAR constraints
RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
ALTER TABLE SPECIES_YEAR
ADD CONSTRAINT SPECIES_YEAR_CONTRAINT
PRIMARY KEY (SPECIES_CODE, YEAR_STARTED);
")

## Set up GAP_PRODUCTS.SURVEY_DESIGN constraints
RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
ALTER TABLE SURVEY_DESIGN
ADD CONSTRAINT SURVEY_DESIGN_CONTRAINT
PRIMARY KEY (SURVEY_DEFINITION_ID, YEAR);
")

## Set up GAP_PRODUCTS.CPUE constraint
RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
ALTER TABLE GAP_PRODUCTS.CPUE 
ADD CONSTRAINT CPUE_CONTRAINT 
PRIMARY KEY (HAULJOIN, SPECIES_CODE)
")

## Set up GAP_PRODUCTS.BIOMASS constraint
RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
ALTER TABLE GAP_PRODUCTS.BIOMASS
ADD CONSTRAINT BIOMASS_CONTRAINT 
PRIMARY KEY (SURVEY_DEFINITION_ID, YEAR, AREA_ID, SPECIES_CODE);
")

## Set up GAP_PRODUCTS.SIZECOMP constraints
RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
ALTER TABLE GAP_PRODUCTS.SIZECOMP
ADD CONSTRAINT SIZECOMP_CONTRAINT 
PRIMARY KEY (SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
                SPECIES_CODE, SEX, LENGTH_MM)")

## Set up GAP_PRODUCTS.AGECOMP constraint
RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
ALTER TABLE GAP_PRODUCTS.AGECOMP
ADD CONSTRAINT AGECOMP_CONTRAINT 
PRIMARY KEY (SURVEY_DEFINITION_ID, AREA_ID_FOOTPRINT, 
YEAR, AREA_ID, SPECIES_CODE, SEX, AGE)")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create Audit Tables in the GAP_ARCHIVE schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ## Set up stratum groups audit table
# RODBC::sqlQuery(channel = gaparchive_channel, 
#                 query = 
#                   "
# CREATE TABLE GAP_ARCHIVE.AUDIT_STRATUM_GROUPS (
#   operation_type VARCHAR2(10),
#   operation_timestamp TIMESTAMP,
#   user_name VARCHAR2(100),
#   SURVEY_DEFINITION_ID NUMBER(38,0),
#   DESIGN_YEAR NUMBER(10,0), 
#   AREA_ID NUMBER(38,0), 
#   STRATUM NUMBER(10,0)
# )")

## Set up cpue audit table
RODBC::sqlQuery(channel = gaparchive_channel, 
                query = 
                  "
CREATE TABLE GAP_ARCHIVE.AUDIT_CPUE (
  operation_type VARCHAR2(10),
  operation_timestamp TIMESTAMP,
  user_name VARCHAR2(100),
  HAULJOIN NUMBER(38,0), 
  SPECIES_CODE NUMBER(38,0), 
  WEIGHT_KG NUMBER(38,3), 
  COUNT NUMBER(38,0), 
  AREA_SWEPT_KM2 NUMBER(38,6), 
  CPUE_KGKM2 NUMBER(38,6), 
  CPUE_NOKM2 NUMBER(38,6)
)")

## Set up biomass audit table
RODBC::sqlQuery(channel = gaparchive_channel, 
                query = 
                  "
CREATE TABLE GAP_ARCHIVE.AUDIT_BIOMASS (
  operation_type VARCHAR2(10),
  operation_timestamp TIMESTAMP,
  user_name VARCHAR2(100),
  SURVEY_DEFINITION_ID NUMBER(38,0), 
  YEAR NUMBER(10,0), 
  SPECIES_CODE NUMBER(38,0), 
  AREA_ID NUMBER(38,0), 
  N_HAUL NUMBER(38,0),
  N_COUNT NUMBER(38,0),
  N_LENGTH NUMBER(38,0), 
  N_WEIGHT NUMBER(38,0), 
  CPUE_KGKM2_MEAN NUMBER(38,6),
  CPUE_KGKM2_VAR NUMBER(38,6),
  CPUE_NOKM2_MEAN NUMBER(38,6),
  CPUE_NOKM2_VAR NUMBER(38,6),
  BIOMASS_MT NUMBER(38,6),
  BIOMASS_VAR NUMBER(38,6),
  POPULATION_COUNT NUMBER(38,0),
  POPULATION_VAR NUMBER(38,6)
)")

## Set up sizecomp audit table
RODBC::sqlQuery(channel = gaparchive_channel, 
                query = 
                  "
CREATE TABLE GAP_ARCHIVE.AUDIT_SIZECOMP (
  operation_type VARCHAR2(10),
  operation_timestamp TIMESTAMP,
  user_name VARCHAR2(100),
  SURVEY_DEFINITION_ID NUMBER(38,0), 
  YEAR NUMBER(10,0), 
  SPECIES_CODE NUMBER(38,0), 
  AREA_ID NUMBER(38,0), 
  SEX NUMBER(38,0),
  LENGTH_MM NUMBER(10,0),
  POPULATION_COUNT NUMBER(38,0)
)")

## Set up agecomp audit table
RODBC::sqlQuery(channel = gaparchive_channel, 
                query = 
                  "
CREATE TABLE GAP_ARCHIVE.AUDIT_AGECOMP (
  operation_type VARCHAR2(10),
  operation_timestamp TIMESTAMP,
  user_name VARCHAR2(100),
  SURVEY_DEFINITION_ID NUMBER(38,0), 
  AREA_ID_FOOTPRINT VARCHAR2(255),
  YEAR NUMBER(10,0), 
  SPECIES_CODE NUMBER(38,0), 
  AREA_ID NUMBER(38,0), 
  SEX NUMBER(38,0),
  AGE NUMBER(38,0),
  POPULATION_COUNT NUMBER(38,0),
  LENGTH_MM_MEAN NUMBER(38,3),
  LENGTH_MM_SD NUMBER(38,3)
)
")

## Grant access of these new audit tables to everyone
all_schemas <- RODBC::sqlQuery(channel = gapproducts_channel,
                               query = paste0('SELECT * FROM all_users;'))

for (iquantity in quantity) {
  for (iname in sort(all_schemas$USERNAME)) {
    RODBC::sqlQuery(channel = gaparchive_channel,
                    query = paste0('GRANT SELECT ON GAP_ARCHIVES.AUDIT_',
                                   toupper(iquantity), ' TO ', iname, ';'))
  }

  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = paste0('GRANT INSERT ON GAP_ARCHIVE.AUDIT_',
                                 toupper(iquantity), ' TO GAP_PRODUCTS;'))

  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = paste0('GRANT DELETE ON GAP_ARCHIVE.AUDIT_',
                                 toupper(iquantity), ' TO GAP_PRODUCTS;'))

  RODBC::sqlQuery(channel = gaparchive_channel,
                  query = paste0('GRANT UPDATE ON GAP_ARCHIVE.AUDIT_',
                                 toupper(iquantity), ' TO GAP_PRODUCTS;'))
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create Triggers for Audit Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  

# CREATE OR REPLACE TRIGGER INSERT_TRIGGER
# AFTER INSERT ON GAP_PRODUCTS.STRATUM_GROUPS
# FOR EACH ROW
# BEGIN
# INSERT INTO GAP_ARCHIVE.AUDIT_STRATUM_GROUPS (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, DESIGN_YEAR, AREA_ID, STRATUM)
# VALUES ('INSERT', SYSTIMESTAMP, USER, :NEW.SURVEY_DEFINITION_ID, :NEW.DESIGN_YEAR, :NEW.AREA_ID, :NEW.STRATUM);
# END;
# 
# CREATE OR REPLACE TRIGGER DELETE_TRIGGER
# AFTER DELETE ON GAP_PRODUCTS.STRATUM_GROUPS
# FOR EACH ROW
# BEGIN
# INSERT INTO GAP_ARCHIVE.AUDIT_STRATUM_GROUPS (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, DESIGN_YEAR, AREA_ID, STRATUM)
# VALUES ('DELETE', SYSTIMESTAMP, USER, :OLD.SURVEY_DEFINITION_ID, :OLD.DESIGN_YEAR, :OLD.AREA_ID, :OLD.STRATUM);
# END;
# 
# 
# 
# CREATE TABLE GAP_ARCHIVE.AUDIT_SURVEY_DESIGN (
#   operation_type VARCHAR2(10),
#   operation_timestamp TIMESTAMP,
#   user_name VARCHAR2(100),
#   SURVEY_DEFINITION_ID NUMBER(38,0) 
#   YEAR NUMBER(10,0),
#   DESIGN_YEAR NUMBER(10,0)
# );
# 
# CREATE OR REPLACE TRIGGER INSERT_TRIGGER
# AFTER INSERT ON GAP_PRODUCTS.SURVEY_DESIGN
# FOR EACH ROW
# BEGIN
# INSERT INTO GAP_ARCHIVE.AUDIT_SURVEY_DESIGN (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, YEAR, DESIGN_YEAR)
# VALUES ('INSERT', SYSTIMESTAMP, USER, :NEW.SURVEY_DEFINITION_ID, :NEW.YEAR, :NEW.DESIGN_YEAR);
# END;
# 
# CREATE OR REPLACE TRIGGER DELETE_TRIGGER
# AFTER DELETE ON GAP_PRODUCTS.SURVEY_DESIGN
# FOR EACH ROW
# BEGIN
# INSERT INTO GAP_ARCHIVE.AUDIT_SURVEY_DESIGN (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, YEAR, DESIGN_YEAR)
# VALUES ('DELETE', SYSTIMESTAMP, USER, :OLD.SURVEY_DEFINITION_ID, :OLD.YEAR, :OLD.DESIGN_YEAR);
# END;
# 
# 
# 
# CREATE TABLE GAP_ARCHIVE.AUDIT_SPECIES_YEAR (
#   operation_type VARCHAR2(10),
#   operation_timestamp TIMESTAMP,
#   user_name VARCHAR2(100),
#   SPECIES_CODE NUMBER(38,0) 
#   YEAR_STARTED NUMBER(36,0)
# );
# 
# CREATE OR REPLACE TRIGGER INSERT_TRIGGER
# AFTER INSERT ON GAP_PRODUCTS.SPECIES_YEAR
# FOR EACH ROW
# BEGIN
# INSERT INTO GAP_ARCHIVE.AUDIT_SPECIES_YEAR (operation_type, operation_timestamp, user_name, SPECIES_CODE, YEAR_STARTED)
# VALUES ('INSERT', SYSTIMESTAMP, USER, :NEW.SPECIES_CODE, :NEW.YEAR_STARTED);
# END;
# 
# CREATE OR REPLACE TRIGGER DELETE_TRIGGER
# AFTER DELETE ON GAP_PRODUCTS.SPECIES_YEAR
# FOR EACH ROW
# BEGIN
# INSERT INTO GAP_ARCHIVE.AUDIT_SPECIES_YEAR (operation_type, operation_timestamp, user_name, SPECIES_CODE, YEAR_STARTED)
# VALUES ('DELETE', SYSTIMESTAMP, USER, :OLD.SPECIES_CODE, :OLD.YEAR_STARTED);
# END;

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER CPUE_INSERT_TRIGGER
AFTER INSERT ON GAP_PRODUCTS.CPUE
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_CPUE (operation_type, operation_timestamp, user_name, HAULJOIN, SPECIES_CODE, WEIGHT_KG, COUNT, AREA_SWEPT_KM2, CPUE_KGKM2, CPUE_NOKM2)
VALUES ('INSERT', SYSTIMESTAMP, USER, :NEW.HAULJOIN, :NEW.SPECIES_CODE, :NEW.WEIGHT_KG, :NEW.COUNT, :NEW.AREA_SWEPT_KM2, :NEW.CPUE_KGKM2, :NEW.CPUE_NOKM2);
END;")

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER CPUE_DELETE_TRIGGER
AFTER DELETE ON GAP_PRODUCTS.CPUE
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_CPUE (operation_type, operation_timestamp, user_name, HAULJOIN, SPECIES_CODE, WEIGHT_KG, COUNT, AREA_SWEPT_KM2, CPUE_KGKM2, CPUE_NOKM2)
VALUES ('DELETE', SYSTIMESTAMP, USER, :OLD.HAULJOIN, :OLD.SPECIES_CODE, :OLD.WEIGHT_KG, :OLD.COUNT, :OLD.AREA_SWEPT_KM2, :OLD.CPUE_KGKM2, :OLD.CPUE_NOKM2);
END;")

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER BIOMASS_INSERT_TRIGGER
AFTER INSERT ON GAP_PRODUCTS.BIOMASS
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_BIOMASS (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, AREA_ID, N_HAUL,N_COUNT,N_LENGTH, N_WEIGHT, CPUE_KGKM2_MEAN, CPUE_KGKM2_VAR, CPUE_NOKM2_MEAN, CPUE_NOKM2_VAR, BIOMASS_MT, BIOMASS_VAR, POPULATION_COUNT, POPULATION_VAR)
VALUES ('INSERT', SYSTIMESTAMP, USER, :NEW.SURVEY_DEFINITION_ID, :NEW.YEAR, :NEW.SPECIES_CODE, :NEW.AREA_ID, :NEW.N_HAUL, :NEW.N_COUNT, :NEW.N_LENGTH, :NEW.N_WEIGHT, :NEW.CPUE_KGKM2_MEAN, :NEW.CPUE_KGKM2_VAR, :NEW.CPUE_NOKM2_MEAN, :NEW.CPUE_NOKM2_VAR, :NEW.BIOMASS_MT, :NEW.BIOMASS_VAR, :NEW.POPULATION_COUNT, :NEW.POPULATION_VAR);
END;")

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER BIOMASS_DELETE_TRIGGER
AFTER DELETE ON GAP_PRODUCTS.BIOMASS
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_BIOMASS (operation_type, operation_timestamp, user_name, HAULJOIN, SPECIES_CODE, WEIGHT_KG, COUNT, AREA_SWEPT_KM2, CPUE_KGKM2, CPUE_NOKM2)
VALUES ('DELETE', SYSTIMESTAMP, USER, :OLD.SURVEY_DEFINITION_ID, :OLD.YEAR, :OLD.SPECIES_CODE, :OLD.AREA_ID, :OLD.N_HAUL, :OLD.N_COUNT, :OLD.N_LENGTH, :OLD.N_WEIGHT, :OLD.CPUE_KGKM2_MEAN, :OLD.CPUE_KGKM2_VAR, :OLD.CPUE_NOKM2_MEAN, :OLD.CPUE_NOKM2_VAR, :OLD.BIOMASS_MT, :OLD.BIOMASS_VAR, :OLD.POPULATION_COUNT, :OLD.POPULATION_VAR);
END;")

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER SIZECOMP_INSERT_TRIGGER
AFTER INSERT ON GAP_PRODUCTS.SIZECOMP
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_SIZECOMP (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, AREA_ID, SEX, LENGTH_MM, POPULATION_COUNT)
VALUES ('INSERT', SYSTIMESTAMP, USER, :NEW.SURVEY_DEFINITION_ID, :NEW.YEAR, :NEW.SPECIES_CODE, :NEW.AREA_ID, :NEW.SEX, :NEW.LENGTH_MM, :NEW.POPULATION_COUNT);
END;")

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER SIZECOMP_DELETE_TRIGGER
AFTER DELETE ON GAP_PRODUCTS.SIZECOMP
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_SIZECOMP (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, AREA_ID, SEX, LENGTH_MM, POPULATION_COUNT)
VALUES ('DELETE', SYSTIMESTAMP, USER, :OLD.SURVEY_DEFINITION_ID, :OLD.YEAR, :OLD.SPECIES_CODE, :OLD.AREA_ID, :OLD.SEX, :OLD.LENGTH_MM, :OLD.POPULATION_COUNT);
END;")

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER AGECOMP_INSERT_TRIGGER
AFTER INSERT ON GAP_PRODUCTS.AGECOMP
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_AGECOMP (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, AREA_ID_FOOTPRINT, YEAR, SPECIES_CODE, AREA_ID, SEX, AGE, POPULATION_COUNT, LENGTH_MM_MEAN, LENGTH_MM_SD)
VALUES ('INSERT', SYSTIMESTAMP, USER, :NEW.SURVEY_DEFINITION_ID, :NEW.AREA_ID_FOOTPRINT, :NEW.YEAR, :NEW.SPECIES_CODE, :NEW.AREA_ID, :NEW.SEX, :NEW.AGE, :NEW.POPULATION_COUNT, :NEW.LENGTH_MM_MEAN, :NEW.LENGTH_MM_SD);
END;")

RODBC::sqlQuery(channel = gapproducts_channel, 
                query = 
                  "
CREATE OR REPLACE TRIGGER AGECOMP_DELETE_TRIGGER
AFTER DELETE ON GAP_PRODUCTS.AGECOMP
FOR EACH ROW
BEGIN
INSERT INTO GAP_ARCHIVE.AUDIT_AGECOMP (operation_type, operation_timestamp, user_name, SURVEY_DEFINITION_ID, AREA_ID_FOOTPRINT, YEAR, SPECIES_CODE, AREA_ID, SEX, AGE, POPULATION_COUNT, LENGTH_MM_MEAN, LENGTH_MM_SD)
VALUES ('DELETE', SYSTIMESTAMP, USER, :OLD.SURVEY_DEFINITION_ID, :OLD.AREA_ID_FOOTPRINT, :OLD.YEAR, :OLD.SPECIES_CODE, :OLD.AREA_ID, :OLD.SEX, :OLD.AGE, :OLD.POPULATION_COUNT, :OLD.LENGTH_MM_MEAN, :OLD.LENGTH_MM_SD);
END;")

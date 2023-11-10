##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare EBS+PLUSNW and NBS historical data product tables 
##                in the HAEHNR schema with those tables produced in the 
##                GAP_PRODUCTS schema.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import packages, connect to Oracle ---------------------------------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
library(reshape2)

if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
  sql_channel <- channel_products
} else {
  sql_channel <- gapindex::get_connected()
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import helper functions -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source(file = "functions/calc_diff.R")
source(file = "functions/compare_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare CPUE Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 
                           cc.YEAR, cc.SURVEY_DEFINITION_ID, HAULJOIN, 
                           SPECIES_CODE, WEIGHT_KG, COUNT,
                           ROUND(cp.CPUE_KGKM2, 2) CPUE_KGKM2, 
                           ROUND(cp.CPUE_NOKM2, 2) CPUE_NOKM2
                           FROM GAP_PRODUCTS.CPUE cp

                           -- Use HAUL data to connect to cruisejoin
                           LEFT JOIN RACEBASE.HAUL hh
                           USING (HAULJOIN)

                           -- Use CRUISES data to obtain YEAR and 
                           -- SURVEY_DEFINITION_ID
                           LEFT JOIN GAP_PRODUCTS.AKFIN_CRUISE cc
                           ON hh.CRUISEJOIN = cc.CRUISEJOIN

                           WHERE cc.SURVEY_DEFINITION_ID in (98, 143) 
                           AND hh.ABUNDANCE_HAUL = 'Y'")

historical_cpue <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 98 AS SURVEY_DEFINITION_ID, YEAR,
                           HAULJOIN, SPECIES_CODE, 
                           ROUND(CPUE_KGHA * 100, 2) AS CPUE_KGKM2,
                           ROUND(CPUE_NOHA * 100, 2) AS CPUE_NOKM2 
                           FROM HAEHNR.CPUE_EBS_PLUSNW"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 143 AS SURVEY_DEFINITION_ID, YEAR, 
                           HAULJOIN, SPECIES_CODE, 
                           ROUND(CPUE_KGHA * 100, 2) AS CPUE_KGKM2,
                           ROUND(CPUE_NOHA * 100, 2) AS CPUE_NOKM2 
                           FROM HAEHNR.CPUE_NBS")
)

## Full join CPUE tables using "SURVEY_DEFINITION_ID, YEAR, HAULJOIN and 
## SPECIES_CODE as a composite key. 
test_cpue <- merge(x = production_cpue, 
                   y = historical_cpue,
                   all = TRUE,
                   by = c("SURVEY_DEFINITION_ID", "YEAR","HAULJOIN", 
                          "SPECIES_CODE"),
                   suffixes = c("_GP", "_HAEHNR"))

eval_cpue <-     
  compare_tables(
    x = test_cpue,
    cols_to_check = data.frame(
      colname = c("CPUE_KGKM2", "CPUE_NOKM2"),
      percent = c(F, F),
      decplaces = c(2, 2)),
    base_table_suffix = "_HAEHNR",
    update_table_suffix = "_GP",
    key_columns = c("SURVEY_DEFINITION_ID", "YEAR", "HAULJOIN", "SPECIES_CODE"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Biomass Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, AREA_ID, SPECIES_CODE, 
                           YEAR, N_HAUL, N_WEIGHT, N_COUNT, 
                           ROUND(CPUE_KGKM2_MEAN, 2) AS CPUE_KGKM2_MEAN,
                           CPUE_KGKM2_VAR,
                           ROUND(CPUE_NOKM2_MEAN, 2) AS CPUE_NOKM2_MEAN,
                           CPUE_NOKM2_VAR,
                           ROUND(BIOMASS_MT, 2) AS BIOMASS_MT,
                           ROUND(BIOMASS_VAR, 4) AS BIOMASS_VAR,
                           ROUND(POPULATION_COUNT) AS POPULATION_COUNT,
                           POPULATION_VAR FROM GAP_prodUCTS.BIOMASS 
                           WHERE SURVEY_DEFINITION_ID in (98, 143)
                           AND YEAR > 1987
                           AND AREA_ID NOT IN (101, 201, 301, 99901)")

historical_biomass <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 98 AS SURVEY_DEFINITION_ID, YEAR, 
                           SPECIES_CODE, 
                           CASE 
                              WHEN STRATUM = 999 THEN 99900
                              ELSE STRATUM
                              END AS AREA_ID,
                           HAULCOUNT as N_HAUL, 
                           CATCOUNT AS N_WEIGHT, 
                           NUMCOUNT AS N_COUNT,
                           100 * MEANWGTCPUE AS CPUE_KGKM2_MEAN,
                           10000 * VARMNWGTCPUE AS CPUE_KGKM2_VAR,
                           100 * MEANNUMCPUE AS CPUE_NOKM2_MEAN,
                           10000 * VARMNNUMCPUE AS CPUE_NOKM2_VAR,
                           BIOMASS AS BIOMASS_MT, 
                           VARBIO AS BIOMASS_VAR, 
                           POPULATION AS POPULATION_COUNT, 
                           VARPOP AS POPULATION_VAR
                    
                           FROM HAEHNR.BIOMASS_EBS_PLUSNW
                           WHERE YEAR > 1987"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 143 AS SURVEY_DEFINITION_ID, YEAR, 
                           SPECIES_CODE, 
                           CASE 
                             WHEN STRATUM = 999 THEN 99902
                             ELSE STRATUM
                           END AS AREA_ID,
                           HAUL_COUNT as N_HAUL, 
                           CATCH_COUNT AS N_WEIGHT, 
                           NUMBER_COUNT AS N_COUNT,
                           MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN,
                           VAR_WGT_CPUE AS CPUE_KGKM2_VAR, 
                           MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN,
                           VAR_NUM_CPUE AS CPUE_NOKM2_VAR, 
                           STRATUM_BIOMASS AS BIOMASS_MT, 
                           BIOMASS_VAR AS BIOMASS_VAR,
                           STRATUM_POP AS POPULATION_COUNT,
                           POP_VAR AS POPULATION_VAR 
                    
                           FROM HAEHNR.BIOMASS_NBS_AKFIN 
                           WHERE YEAR > 1987")
)

## FUll join the two tables using YEAR, AREA_ID, and SPECIES_CODE as 
## a composite key.
test_biomass <- merge(x = production_biomass,
                      y = historical_biomass,
                      by = c("SURVEY_DEFINITION_ID", "YEAR", 
                             "AREA_ID", "SPECIES_CODE"),
                      all = TRUE, 
                      suffixes = c("_GP", "_HAEHNR"))

eval_biomass <- 
  compare_tables(
    x = test_biomass,
    cols_to_check = data.frame(
      colname = c("N_HAUL", "N_WEIGHT", "N_COUNT",
                  "CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                  "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR", 
                  "BIOMASS_MT", "BIOMASS_VAR", 
                  "POPULATION_COUNT", "POPULATION_VAR"),
      percent = c(F, F, F, T, T, T, T, T, T, T, T),
      decplaces = c(0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2)),
    base_table_suffix = "_HAEHNR",
    update_table_suffix = "_GP",
    key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', 
                    "SPECIES_CODE", "YEAR"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Size Composition Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT YEAR, SPECIES_CODE, AREA_ID, SEX,
                           LENGTH_MM, POPULATION_COUNT 
                           FROM GAP_PRODUCTS.SIZECOMP 
                           WHERE SURVEY_DEFINITION_ID in (98, 143) 
                           AND YEAR >= 1987 
                           AND AREA_ID NOT IN (99901, 101, 201, 301)")

historical_sizecomp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT YEAR, SPECIES_CODE, 
                           CASE 
                             WHEN STRATUM = 999999 THEN 99900
                             ELSE STRATUM
                           END AS AREA_ID,
                           LENGTH as LENGTH_MM, 
                           MALES, FEMALES, UNSEXED, TOTAL
                           FROM HAEHNR.SIZECOMP_EBS_PLUSNW_STRATUM"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT YEAR, SPECIES_CODE, 
                           CASE 
                             WHEN STRATUM = 999999 THEN 99902
                             ELSE STRATUM
                           END AS AREA_ID,
                           LENGTH as LENGTH_MM, 
                           MALES, FEMALES, UNSEXED, TOTAL
                           FROM HAEHNR.SIZECOMP_NBS_STRATUM")
)
historical_sizecomp$UNSEXED[historical_sizecomp$LENGTH_MM == -9] <- 
  historical_sizecomp$TOTAL[historical_sizecomp$LENGTH_MM == -9]

historical_sizecomp <- 
  reshape2::melt(data = subset(x = historical_sizecomp,
                               select = -TOTAL),
                 measure.vars = c("MALES", "FEMALES", "UNSEXED"),
                 variable.name = "SEX",
                 value.name = "POPULATION_COUNT")
historical_sizecomp$SEX <- 
  ifelse(test = historical_sizecomp$SEX == "MALES",
         yes = 1,
         no = ifelse(test = historical_sizecomp$SEX == "FEMALES",
                     yes = 2, no = 3))

## Full join the sizecomp tables using YEAR, AREA_ID, SPECIES_CODE, LENGTH_MM,
## and SEX as a composite key.
test_sizecomp <- 
  merge(x = historical_sizecomp,
        y = production_sizecomp,
        by = c("YEAR", "AREA_ID", "SPECIES_CODE", "LENGTH_MM", "SEX"),
        all = TRUE, 
        suffixes = c("_HAEHNR", "_GP"))

eval_sizecomp <-   
  compare_tables(
    x = test_sizecomp,
    cols_to_check = data.frame(
      colname = "POPULATION_COUNT",
      percent = T,
      decplaces = 2),
    base_table_suffix = "_HAEHNR",
    update_table_suffix = "_GP",
    key_columns = c("AREA_ID", "YEAR", "SPECIES_CODE", "SEX", "LENGTH_MM"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Age Composition Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT YEAR, SPECIES_CODE, AREA_ID, SEX, AGE, 
                           POPULATION_COUNT, LENGTH_MM_MEAN, LENGTH_MM_SD 
                           FROM GAP_PRODUCTS.AGECOMP 
                           WHERE SURVEY_DEFINITION_ID in (98, 143)
                           AND AREA_ID != 99901")

historical_agecomp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT YEAR, SPECIES_CODE, 
                           CASE 
                              WHEN STRATUM = 999999 THEN 99900
                              ELSE STRATUM
                           END AS AREA_ID, SEX, AGE,
                           ROUND(AGEPOP) as POPULATION_COUNT,
                           ROUND(MEANLEN, 2) AS LENGTH_MM_MEAN,
                           ROUND(SDEV, 2) AS LENGTH_MM_SD 
                           FROM HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT YEAR, SPECIES_CODE, 
                           CASE 
                              WHEN STRATUM = 999999 THEN 99902
                              ELSE STRATUM
                           END AS AREA_ID, SEX, AGE,
                           ROUND(AGEPOP) as POPULATION_COUNT,
                           ROUND(MEANLEN, 2) AS LENGTH_MM_MEAN,
                           ROUND(SDEV, 2) AS LENGTH_MM_SD 
                           FROM HAEHNR.AGECOMP_NBS_STRATUM")
)

## Full join the agecomp tables using YEAR, AREA_ID, SPECIES_CODE, AGE, 
## and SEX as a composite key.

test_agecomp <- merge(x = historical_agecomp, 
                      y = production_agecomp,
                      all = TRUE, 
                      by = c("YEAR", "AREA_ID", "SPECIES_CODE", "AGE", "SEX"),
                      suffixes = c("_HAEHNR", "_GP"))

eval_agecomp <- 
  compare_tables(
    x = test_agecomp,
    cols_to_check = data.frame(
      colname = c("POPULATION_COUNT", "LENGTH_MM_MEAN", "LENGTH_MM_SD"),
      percent = c(F, T, T),
      decplaces = c(0, 2, 2)),
    base_table_suffix = "_HAEHNR",
    update_table_suffix = "_GP",
    key_columns = c('AREA_ID', "YEAR", "SPECIES_CODE", "SEX", "AGE"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Taxonomic Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_taxon <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SPECIES_CODE, COMMON_NAME, SPECIES_NAME 
                           FROM GAP_PRODUCTS.AKFIN_TAXONOMIC_CLASSIFICATION")

historical_taxon <- 
  unique(x = rbind(
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT DISTINCT SPECIES_CODE, 
                                      COMMON_NAME, SPECIES_NAME
                                      FROM HAEHNR.CPUE_EBS_PLUSNW"),
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT DISTINCT SPECIES_CODE, 
                                      COMMON_NAME, SPECIES_NAME 
                                      FROM HAEHNR.CPUE_NBS")
  ))

## Full join the taxonomic tables using SPECIES_CODE as the key. 
test_taxon <-
  merge(x = subset(x = production_taxon,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE)), 
        y = unique(historical_taxon),
        all = TRUE,
        by = "SPECIES_CODE", 
        suffixes = c("_GP", "_HAEHNR"))

## The compare_tables function currently only compares tables with numeric
## columns, so for these character comparisons, evaluate diffs explicitly.  
test_taxon$SPECIES_NAME_DIFF <- 
  test_taxon$SPECIES_NAME_GP != test_taxon$SPECIES_NAME_HAEHNR
test_taxon$SPECIES_NAME_DIFF <- 
  ifelse(test = is.na(x = test_taxon$SPECIES_NAME_DIFF), 
         yes = FALSE, 
         no = test_taxon$SPECIES_NAME_DIFF)
test_taxon$COMMON_NAME_DIFF <- 
  test_taxon$COMMON_NAME_GP != test_taxon$COMMON_NAME_HAEHNR
test_taxon$COMMON_NAME_DIFF <- 
  ifelse(test = is.na(x = test_taxon$COMMON_NAME_DIFF), 
         yes = FALSE, 
         no = test_taxon$COMMON_NAME_DIFF)

eval_taxon <- 
  subset(x = test_taxon,
         subset = (SPECIES_NAME_DIFF | COMMON_NAME_DIFF) )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Save Comparison Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bs_table_comparisons <- 
  list(cpue = eval_cpue,
       biomas = eval_biomass,
       sizecomp = eval_sizecomp,
       agecomp = eval_agecomp,
       taxon = eval_taxon)

saveRDS(object = bs_table_comparisons, 
        file = "code/historical_comparisons/bs_table_comparisons.RDS")

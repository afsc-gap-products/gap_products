##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare NBS historical data product tables with those 
##                produced with the most recent run production tables currently 
##                in the temp/ folder. As of 28 September 2023
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import packages, connect to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(readxl)
library(gapindex)
library(reshape2)

sql_channel <- gapindex::get_connected()

options(scipen = 999)
decimalplaces <- function(x) {
  # split each number by the decimal point
  x_split <- strsplit(x = as.character(x = x), split = ".", fixed = TRUE)
  
  # count the number of characters after the decimal point
  x_digits <- sapply(X = x_split, 
                     FUN = function(x) ifelse(test = length(x) > 1, 
                                              yes = nchar(x[[2]]), 
                                              no = 0))
  
  # print the number of digits after the decimal point for each number
  return(x_digits)
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import production tables from GAP_PRODUCTS Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## CPUE
hauljoins_2023 <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT DISTINCT HAULJOIN FROM 
                                 HAEHNR.CPUE_NBS 
                                 WHERE YEAR = 2023"))$HAULJOIN
production_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.CPUE ",
                                 "WHERE HAULJOIN IN ",
                                 gapindex::stitch_entries(hauljoins_2023)))
production_cpue$CPUE_KGKM2 <- round(x = production_cpue$CPUE_KGKM2, digits = 2)
production_cpue$CPUE_NOKM2 <- round(x = production_cpue$CPUE_NOKM2, digits = 2)

## Biomass
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.BIOMASS ",
                                 "WHERE SURVEY_DEFINITION_ID = 143 ",
                                 "AND YEAR = 2023"))

## Size composition
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.SIZECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID = 143 ",
                                 "AND YEAR = 2023"))

## Age composition
production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, AREA_ID, SEX, ",
                                 "AGE, POPULATION_COUNT, LENGTH_MM_MEAN, ",
                                 "LENGTH_MM_SD FROM GAP_PRODUCTS.AGECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID = 143 ",
                                 "AND YEAR = 2022"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables from HAEHNR Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## CPUE
historical_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT HAULJOIN, SPECIES_CODE, 
                     CPUE_KGHA * 100 AS CPUE_KGKM2,
                     CPUE_NOHA * 100 AS CPUE_NOKM2 
                     FROM HAEHNR.CPUE_NBS WHERE YEAR = 2023"))

## Biomass
historical_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                    "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                    "NUMBER_COUNT AS N_COUNT, ",
                    "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                    "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                    "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                    "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                    "STRATUM_BIOMASS AS BIOMASS_MT, ",
                    "BIOMASS_VAR AS BIOMASS_VAR, ",
                    "STRATUM_POP AS POPULATION_COUNT, ",
                    "POP_VAR AS POPULATION_VAR ",
                    "FROM HAEHNR.BIOMASS_NBS_AKFIN WHERE YEAR = 2023"))
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 999] <- 99902

## Size composition 
historical_sizecomp <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                    "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                    "FROM HAEHNR.SIZECOMP_NBS_STRATUM ",
                    "WHERE YEAR = 2023"))
historical_sizecomp$AREA_ID[historical_sizecomp$AREA_ID == 999999] <- 99902
historical_sizecomp <- 
  reshape2::melt(data = historical_sizecomp,
                 measure.vars = c("MALES", "FEMALES", "UNSEXED"),
                 variable.name = "SEX",
                 value.name = "POPULATION_COUNT")
historical_sizecomp$SEX <- 
  ifelse(test = historical_sizecomp$SEX == "MALES",
         yes = 1,
         no = ifelse(test = historical_sizecomp$SEX == "FEMALES",
                     yes = 2, no = 3))

## Age composition
historical_agecomp <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, ",
                                 "STRATUM AS AREA_ID, SEX, AGE, ",
                                 "AGEPOP as POPULATION_COUNT, ",
                                 "MEANLEN AS LENGTH_MM_MEAN , ",
                                 "SDEV AS LENGTH_MM_SD FROM ",
                                 "HAEHNR.AGECOMP_NBS_STRATUM ",
                                 "WHERE YEAR = 2022"))

historical_agecomp$AREA_ID[historical_agecomp$AREA_ID == 999999] <- 99902
historical_agecomp$LENGTH_MM_MEAN <- 
  round(x = historical_agecomp$LENGTH_MM_MEAN, digits = 2)
historical_agecomp$LENGTH_MM_SD <- 
  round(x = historical_agecomp$LENGTH_MM_SD, digits = 2)
historical_agecomp$POPULATION_COUNT <-
  round(x = historical_agecomp$POPULATION_COUNT, digits = 0)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare CPUE Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Merge CPUE tables using HAULJOIN and SPECIES_CODE as a composite key. 
test_cpue <-
  merge(x = subset(x = production_cpue,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE)), 
        y = historical_cpue,
        by = c("HAULJOIN", "SPECIES_CODE"),
        all = TRUE, suffixes = c("_prod", "_hist"))

test_cpue$CPUE_KGKM2 <- test_cpue$CPUE_KGKM2_prod - test_cpue$CPUE_KGKM2_hist
test_cpue$CPUE_NOKM2 <- test_cpue$CPUE_NOKM2_prod - test_cpue$CPUE_NOKM2_hist

mismatch_cpue <- subset(x = test_cpue, 
                        subset = CPUE_KGKM2 != 0 | is.na(x = CPUE_KGKM2) |
                          CPUE_NOKM2 != 0 | is.na(x = CPUE_NOKM2))

mismatch_cpue <- subset(x = mismatch_cpue,
                        subset = !(is.na(x = CPUE_NOKM2_prod) & 
                                     is.na(x = CPUE_NOKM2_hist)))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Biomass Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
historical_biomass <- 
  subset(x = historical_biomass,
         subset = SPECIES_CODE %in% 
           unique(x = production_biomass$SPECIES_CODE))

## Merge BIOMASS tables using YEAR, STRATUM, AND SPECIES_CODE as composite key. 
test_biomass <- merge(x = subset(x = production_biomass,
                                 subset = SPECIES_CODE %in% 
                                   unique(x = historical_biomass$SPECIES_CODE)), 
                      y = historical_biomass,
                      by = c("YEAR", "AREA_ID", "SPECIES_CODE"),
                      all = TRUE, suffixes = c("_PROD", "_HIST"))

test_biomass$CPUE_KGKM2_MEAN_PROD <- round(test_biomass$CPUE_KGKM2_MEAN_PROD, 2)
test_biomass$CPUE_NOKM2_MEAN_PROD <- round(test_biomass$CPUE_NOKM2_MEAN_PROD, 2)
test_biomass$CPUE_KGKM2_VAR_PROD <- round(test_biomass$CPUE_KGKM2_VAR_PROD, 6)
test_biomass$BIOMASS_MT_PROD <- round(test_biomass$BIOMASS_MT_PROD, 2)
test_biomass$BIOMASS_VAR_PROD <- round(test_biomass$BIOMASS_VAR_PROD, 4)

test_biomass$CPUE_NOKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_VAR_PROD - CPUE_NOKM2_VAR_HIST) / ifelse(CPUE_NOKM2_VAR_HIST == 0, 1, CPUE_NOKM2_VAR_HIST) ))
test_biomass$CPUE_NOKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_MEAN_PROD - CPUE_NOKM2_MEAN_HIST) / ifelse(CPUE_NOKM2_MEAN_HIST == 0, 1, CPUE_NOKM2_MEAN_HIST) ))

test_biomass$CPUE_KGKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_VAR_PROD - CPUE_KGKM2_VAR_HIST) / ifelse(CPUE_KGKM2_VAR_HIST == 0, 1, CPUE_KGKM2_VAR_HIST) ))
test_biomass$CPUE_KGKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_MEAN_PROD - CPUE_KGKM2_MEAN_HIST) / ifelse(CPUE_KGKM2_MEAN_HIST == 0, 1, CPUE_KGKM2_MEAN_HIST) ))

test_biomass$N_HAUL <- 
  with(test_biomass, N_HAUL_PROD - N_HAUL_HIST)
test_biomass$N_WEIGHT <- 
  with(test_biomass, N_WEIGHT_PROD - N_WEIGHT_HIST)


test_biomass$BIOMASS_MT <- 
  with(test_biomass, round((BIOMASS_MT_PROD - BIOMASS_MT_HIST)/ifelse(BIOMASS_MT_HIST == 0, 1, BIOMASS_MT_HIST), 2) ) 

test_biomass$POPULATION_COUNT <- 
  with(test_biomass, round((POPULATION_COUNT_PROD - POPULATION_COUNT_HIST)/ifelse(POPULATION_COUNT_HIST == 0, 1, POPULATION_COUNT_HIST), 2) ) 

test_biomass$BIOMASS_VAR <- 
  with(test_biomass, round((BIOMASS_VAR_PROD - BIOMASS_VAR_HIST)/ifelse(BIOMASS_VAR_HIST == 0, 1, BIOMASS_VAR_HIST), 2) ) 
test_biomass$POPULATION_VAR <- 
  with(test_biomass, round((POPULATION_VAR_PROD - POPULATION_VAR_HIST)/ifelse(POPULATION_VAR_HIST == 0, 1, POPULATION_VAR_HIST), 2) ) 


## Subset mismatched records
mismatched_biomass <- 
  subset(x = test_biomass, 
         subset = CPUE_NOKM2_MEAN != 0 | is.na(x = CPUE_NOKM2_MEAN) |
           CPUE_NOKM2_VAR != 0 | is.na(x = CPUE_NOKM2_VAR) |
           CPUE_KGKM2_MEAN != 0 | is.na(x = CPUE_KGKM2_MEAN) |
           CPUE_KGKM2_VAR != 0 | is.na(x = CPUE_KGKM2_VAR) | 
           BIOMASS_MT != 0 | is.na(x = BIOMASS_MT) |
           POPULATION_COUNT != 0 | is.na(x = POPULATION_COUNT) | 
           BIOMASS_VAR != 0 | is.na(x = BIOMASS_VAR) |
           POPULATION_VAR != 0 | is.na(x = POPULATION_VAR) #|
         # N_HAUL != 0 | is.na(x = N_HAUL) |
         # N_WEIGHT != 0 | is.na(x = N_WEIGHT) 
  )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Sizecomp tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

length(x = unique(x = production_sizecomp$SPECIES_CODE))
length(x = unique(x = historical_sizecomp$SPECIES_CODE))

## Merge SIZECOMP tables using YEAR, STRATUM, SPECIES_CODE, and LENGTH_MM
## as a composite key. 
test_sizecomp <- merge(x = historical_sizecomp,
                       y = production_sizecomp,
                       by = c("YEAR", "AREA_ID", "SPECIES_CODE", 
                              "LENGTH_MM", "SEX"),
                       suffixes = c("_hist", "_prod"))

## Calculate difference between size comps
test_sizecomp$DIFF <- 
  with(test_sizecomp, POPULATION_COUNT_hist - POPULATION_COUNT_prod)

## Subset mismatched records
mismatched_sizecomp <- subset(test_sizecomp, abs(DIFF) > 1 | is.na(x = DIFF))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Age comps
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
length(x = unique(x = production_agecomp$SPECIES_CODE))
length(x = unique(x = historical_agecomp$SPECIES_CODE))

test_agecomp <- merge(x = historical_agecomp,
                      y = production_agecomp,
                      by = c("YEAR", "AREA_ID", "SPECIES_CODE", "AGE", "SEX"),
                      suffixes = c("_hist", "_prod"))

test_agecomp$POPULATION_COUNT <- 
  with(test_agecomp, POPULATION_COUNT_prod - POPULATION_COUNT_hist)
test_agecomp$LENGTH_MM_MEAN <- 
  with(test_agecomp, 
       round(x = 100 * (LENGTH_MM_MEAN_prod - LENGTH_MM_MEAN_hist) / 
               LENGTH_MM_MEAN_prod, 
             digits = 2))
test_agecomp$LENGTH_MM_SD <- 
  with(test_agecomp, 
       round(x = 100 * (LENGTH_MM_SD_prod - LENGTH_MM_SD_hist) / 
               ifelse(test = LENGTH_MM_SD_prod == 0, 1, LENGTH_MM_SD_prod), 
             digits = 2))

mismatched_age <- 
  subset(x = test_agecomp, 
         subset =  abs(POPULATION_COUNT) > 3 | is.na(x = POPULATION_COUNT) |
           LENGTH_MM_MEAN != 0 | is.na(x = LENGTH_MM_MEAN) |
           LENGTH_MM_SD != 0 | is.na(x = LENGTH_MM_SD))


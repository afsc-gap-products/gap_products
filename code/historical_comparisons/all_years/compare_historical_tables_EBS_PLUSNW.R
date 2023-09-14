##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare EBS+PLUSNW historical data product tables with those 
##                produced with the most recent run production tables currently 
##                in the temp/ folder. As of 2 September 2023
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

calc_diff <- function(v1, v2, percent = T) {
  difference <- v1 - v2
  if (percent)
    difference <- 100 * difference / 
      ifelse(test = v2 == 0, 
             yes = 1,
             no = v2)
  
  return(difference)
}

spp_year <- RODBC::sqlQuery(channel = sql_channel,
                            query = "SELECT * FROM GAP_PRODUCTS.SPECIES_YEAR")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import production tables from GAP_PRODUCTS Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## CPUE
production_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.CPUE cpue
                                 INNER JOIN (
                                 SELECT DISTINCT HAULJOIN 
                                 FROM STEVENSD.EBS_CPUE_PLUSNW_KM2) 
                                 haul ON cpue.HAULJOIN = haul.HAULJOIN; "))

## Biomass
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.BIOMASS ",
                                 "WHERE SURVEY_DEFINITION_ID = 98 ",
                                 "AND YEAR >= 1987 ",
                                 "AND AREA_ID NOT IN (101, 201, 301, 99901)"))

## Size composition
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.SIZECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID = 98 ",
                                 "AND YEAR >= 1987 ",
                                 "AND AREA_ID NOT IN (99901, 101, 201, 301)"))

## Age composition
production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, AREA_ID, SEX, ",
                                 "AGE, POPULATION_COUNT, LENGTH_MM_MEAN, ",
                                 "LENGTH_MM_SD FROM GAP_PRODUCTS.AGECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID = 98 ",
                                 "AND AREA_ID != 99901 ",
                                 "AND YEAR >= 1987 "))

production_data <- 
  readRDS(file = "temp/production/production_data_EBS.RDS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables from HAEHNR Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## CPUE
historical_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, HAULJOIN, SPECIES_CODE, ",
                    "CPUE_KGKM AS CPUE_KGKM2, CPUE_NOKM AS CPUE_NOKM2 ",
                    "FROM STEVENSD.EBS_CPUE_PLUSNW_KM2"))

## Biomass
historical_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                    "HAULCOUNT as N_HAUL, CATCOUNT AS N_WEIGHT, ",
                    "100 * MEANWGTCPUE AS CPUE_KGKM2_MEAN, ",
                    "10000 * VARMNWGTCPUE AS CPUE_KGKM2_VAR, ",
                    "100 * MEANNUMCPUE AS CPUE_NOKM2_MEAN, ",
                    "10000 * VARMNNUMCPUE AS CPUE_NOKM2_VAR, ",
                    "BIOMASS AS BIOMASS_MT, ",
                    "VARBIO AS BIOMASS_VAR, ",
                    "POPULATION AS POPULATION_COUNT, ",
                    "VARPOP AS POPULATION_VAR ",
                    "FROM HAEHNR.BIOMASS_EBS_PLUSNW"))
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 999] <- 99900

non_obs_taxa <- subset(x = stats::aggregate(N_WEIGHT ~ SPECIES_CODE, 
                                            data = historical_biomass, 
                                            FUN = sum),
                       subset = N_WEIGHT == 0)$SPECIES_CODE

historical_biomass <- subset(x = historical_biomass, 
                             subset = !(SPECIES_CODE %in% non_obs_taxa))

## Size composition 
historical_sizecomp <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                    "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                    "FROM HAEHNR.SIZECOMP_EBS_PLUSNW_STRATUM "))
historical_sizecomp$AREA_ID[historical_sizecomp$AREA_ID == 999999] <- 99900
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

for (irow in 1:nrow(x = spp_year)) {
  
  historical_cpue <- 
    subset(x = historical_cpue,
           subset = !(SPECIES_CODE == spp_year$SPECIES_CODE[irow] & 
                        YEAR < spp_year$YEAR_STARTED[irow]))  
  historical_biomass <- 
    subset(x = historical_biomass,
           subset = !(SPECIES_CODE == spp_year$SPECIES_CODE[irow] & 
                        YEAR < spp_year$YEAR_STARTED[irow]))
  historical_sizecomp <- 
    subset(x = historical_sizecomp,
           subset = !(SPECIES_CODE == spp_year$SPECIES_CODE[irow] & 
                        YEAR < spp_year$YEAR_STARTED[irow]))
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare CPUE Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Merge CPUE tables using HAULJOIN and SPECIES_CODE as a composite key. 
test_cpue <- merge(x = subset(x = production_cpue,
                              subset = SPECIES_CODE %in% 
                                unique(x = historical_cpue$SPECIES_CODE),
                              select = -HAULJOIN.1), 
                   y = historical_cpue,
                   by = c("HAULJOIN", "SPECIES_CODE"),
                   all = TRUE, suffixes = c("_prod", "_hist"))

test_cpue$CPUE_KGKM2 <- 
  round(x = with(test_cpue, calc_diff(CPUE_KGKM2_prod,
                                      CPUE_KGKM2_hist)),
        digits = 2)

test_cpue$CPUE_NOKM2 <- 
  round(x = with(test_cpue, calc_diff(CPUE_NOKM2_prod,
                                      CPUE_NOKM2_hist)),
        digits = 2)

mismatch_cpue <- subset(x = test_cpue, 
                        subset = (CPUE_KGKM2 != 0 | is.na(x = CPUE_KGKM2) |
                                    CPUE_NOKM2 != 0 | is.na(x = CPUE_NOKM2)) & 
                          SPECIES_CODE != 10260 & 
                          (CPUE_NOKM2_prod != CPUE_NOKM2_hist))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Biomass Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# historical_biomass <- 
#   subset(x = historical_biomass,
#          subset = SPECIES_CODE %in% 
#            unique(x = production_biomass$SPECIES_CODE))

## Merge BIOMASS tables using YEAR, STRATUM, AND SPECIES_CODE as composite key. 
test_biomass <- merge(x = subset(x = production_biomass,
                                 subset = SPECIES_CODE %in% 
                                   unique(x = historical_biomass$SPECIES_CODE)), 
                      y = historical_biomass,
                      by = c("YEAR", "AREA_ID", "SPECIES_CODE"),
                      all = TRUE, suffixes = c("_PROD", "_HIST"))

test_biomass$CPUE_KGKM2_MEAN_PROD <-
  round(x = test_biomass$CPUE_KGKM2_MEAN_PROD, digits = 2)
test_biomass$CPUE_NOKM2_MEAN_PROD <-
  round(x = test_biomass$CPUE_NOKM2_MEAN_PROD, digits = 2)
test_biomass$CPUE_KGKM2_VAR_PROD <- 
  round(x = test_biomass$CPUE_KGKM2_VAR_PROD, digits = 6)
test_biomass$BIOMASS_MT_PROD <- 
  round(x = test_biomass$BIOMASS_MT_PROD, digits = 2)
test_biomass$BIOMASS_VAR_PROD <-
  round(x = test_biomass$BIOMASS_VAR_PROD, digits = 4)

test_biomass$CPUE_NOKM2_VAR <- 
  round(with(test_biomass, calc_diff(v1 = CPUE_NOKM2_VAR_PROD, 
                                     v2 = CPUE_NOKM2_VAR_HIST)))

test_biomass$CPUE_NOKM2_MEAN <- 
  round(with(test_biomass, calc_diff(v1 = CPUE_NOKM2_MEAN_PROD, 
                                     v2 = CPUE_NOKM2_MEAN_HIST)))

test_biomass$CPUE_KGKM2_VAR <- 
  round(with(test_biomass, calc_diff(v1 = CPUE_KGKM2_VAR_PROD, 
                                     v2 = CPUE_KGKM2_VAR_HIST)))

test_biomass$CPUE_KGKM2_MEAN <-
  round(with(test_biomass, calc_diff(v1 = CPUE_KGKM2_MEAN_PROD, 
                                     v2 = CPUE_KGKM2_MEAN_HIST)))

test_biomass$N_HAUL <- 
  with(test_biomass, N_HAUL_PROD - N_HAUL_HIST)
test_biomass$N_WEIGHT <- 
  with(test_biomass, N_WEIGHT_PROD - N_WEIGHT_HIST)
test_biomass$N_LENGTH <- 
  with(test_biomass, N_LENGTH_PROD - N_LENGTH_HIST)
test_biomass$N_COUNT <- 
  with(test_biomass, N_COUNT_PROD - N_COUNT_HIST)

test_biomass$BIOMASS_MT <- 
  round(x = with(test_biomass, calc_diff(v1 = BIOMASS_MT_PROD, 
                                         v2 = BIOMASS_MT_HIST)),
        digits = 2)

test_biomass$POPULATION_COUNT <- 
  round(x = with(test_biomass, calc_diff(v1 = POPULATION_COUNT_PROD, 
                                         v2 = POPULATION_COUNT_HIST)),
        digits = 2)

test_biomass$BIOMASS_VAR <- 
  round(x = with(test_biomass, calc_diff(v1 = BIOMASS_VAR_PROD, 
                                         v2 = BIOMASS_VAR_HIST)),
        digits = 2)

test_biomass$POPULATION_VAR <- 
  round(x = with(test_biomass, calc_diff(v1 = POPULATION_VAR_PROD, 
                                         v2 = POPULATION_VAR_HIST)),
        digits = 2)

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
           POPULATION_VAR != 0 | is.na(x = POPULATION_VAR) |
           N_HAUL != 0 | is.na(x = N_HAUL) |
           N_WEIGHT != 0 | is.na(x = N_WEIGHT)
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
  with(test_sizecomp, calc_diff(POPULATION_COUNT_hist,
                                POPULATION_COUNT_prod, 
                                percent = F) )

## Subset mismatched records
mismatched_sizecomp <- 
  subset(x = test_sizecomp, 
         subset = abs(DIFF) > 10 & 
           !(LENGTH_MM == -9 & SEX == 3 & 
               POPULATION_COUNT_hist == 0 & POPULATION_COUNT_prod != 0) )


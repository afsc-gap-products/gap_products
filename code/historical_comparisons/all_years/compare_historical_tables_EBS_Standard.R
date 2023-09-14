##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare EBS Standard historical data product tables with those produced
##                with the most recent run production tables currently in the 
##                temp/ folder. As of 2 September 2023
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
##   Import historical tables from HAEHNR Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Biomass
historical_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                    "HAULCOUNT as N_HAUL, CATCOUNT AS N_WEIGHT, ",
                    "NUMCOUNT AS N_COUNT, LENCOUNT AS N_LENGTH, ",
                    "100 * MEANWGTCPUE AS CPUE_KGKM2_MEAN, ",
                    "10000 * VARMNWGTCPUE AS CPUE_KGKM2_VAR, ",
                    "100 * MEANNUMCPUE AS CPUE_NOKM2_MEAN, ",
                    "10000 * VARMNNUMCPUE AS CPUE_NOKM2_VAR, ",
                    "BIOMASS AS BIOMASS_MT, ",
                    "VARBIO AS BIOMASS_VAR, ",
                    "POPULATION AS POPULATION_COUNT, ",
                    "VARPOP AS POPULATION_VAR ",
                    "FROM HAEHNR.BIOMASS_EBS_STANDARD"))
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 999] <- 99901
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 100] <- 101
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 200] <- 201
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 300] <- 301

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
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                    LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED
                    FROM HAEHNR.SIZECOMP_EBS_STANDARD_STRATUM
                    WHERE STRATUM NOT IN (82, 90)
                    AND SPECIES_CODE NOT IN ", 
                    gapindex::stitch_entries(stitch_what = non_obs_taxa)))
historical_sizecomp$AREA_ID[historical_sizecomp$AREA_ID == 999999] <- 99901

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
##   Import production tables from GAP_PRODUCTS Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Biomass
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.BIOMASS 
                                 WHERE SURVEY_DEFINITION_ID = 98 
                                 AND AREA_ID NOT IN (8, 9, 82, 90,
                                 100, 200, 300, 99900)"))

## Size composition
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.SIZECOMP
                                 WHERE SURVEY_DEFINITION_ID = 98 
                                 AND AREA_ID NOT IN (82, 90, 
                                 8, 9, 100, 200, 300, 
                                 99900)"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Biomass Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
##   Import sizecomp tables. For the sizecomp comparison, we will only compare
##   the total sex-aggregated size compositions at the stratum-level. 
##   In some regions, there are some subareas that are just single strata with 
##   the same ID (e.g., 793 is an AI stratum and a subarea). Thus, when 
##   importing the production table, only unique record are imported. 
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

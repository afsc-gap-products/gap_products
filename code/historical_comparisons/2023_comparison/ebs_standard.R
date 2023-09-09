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

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import production tables from GAP_PRODUCTS Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Biomass
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.BIOMASS ",
                                 "WHERE SURVEY_DEFINITION_ID = 98 ",
                                 "AND YEAR = 2023 AND ",
                                 "AREA_ID NOT IN (100, 200, 300, 99900)"))

## Size composition
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_PRODUCTS.SIZECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID = 98 ",
                                 "AND YEAR = 2023 AND ",
                                 "AREA_ID NOT IN (82,90,100,200,300,99900)"))

## Age composition
production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, SEX, AGE, ",
                                 "POPULATION_COUNT, LENGTH_MM_MEAN, ",
                                 "LENGTH_MM_SD FROM GAP_PRODUCTS.AGECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID = 98 ",
                                 "AND YEAR = 2022 AND AREA_ID != 99900"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables from HAEHNR Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
                    "FROM HAEHNR.BIOMASS_EBS_STANDARD WHERE YEAR = 2023"))
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 999] <- 99901
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 100] <- 101
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 200] <- 201
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 300] <- 301
historical_biomass <- 
  subset(x = historical_biomass,
         subset = SPECIES_CODE %in% 
           unique(x = production_biomass$SPECIES_CODE))

## Size composition
historical_sizecomp <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                    "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                    " FROM HAEHNR.SIZECOMP_EBS_STANDARD_STRATUM ",
                    "WHERE YEAR = 2023 and STRATUM NOT IN (82, 90)"))
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

## Age composition
historical_agecomp <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, ",
                                 "STRATUM AS AREA_ID, SEX, AGE, ",
                                 "AGEPOP as POPULATION_COUNT, ",
                                 "MEANLEN AS LENGTH_MM_MEAN , ",
                                 "SDEV AS LENGTH_MM_SD FROM ",
                                 "HAEHNR.AGECOMP_EBS_STANDARD_STRATUM ",
                                 "WHERE YEAR = 2022"))

historical_agecomp$AREA_ID[historical_agecomp$AREA_ID == 999999] <- 99901
historical_agecomp$LENGTH_MM_MEAN <- 
  round(x = historical_agecomp$LENGTH_MM_MEAN, digits = 2)
historical_agecomp$LENGTH_MM_SD <- 
  round(x = historical_agecomp$LENGTH_MM_SD, digits = 2)
historical_agecomp$POPULATION_COUNT <- 
  round(x = historical_agecomp$POPULATION_COUNT, digits = 0)

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
  with(test_sizecomp, POPULATION_COUNT_hist - POPULATION_COUNT_prod)

## Subset mismatched records
mismatched_sizecomp <- subset(test_sizecomp, abs(DIFF) > 3)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Age comps
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
  with(test_agecomp, round(x = (LENGTH_MM_MEAN_prod - LENGTH_MM_MEAN_hist) / LENGTH_MM_MEAN_prod, 2))
test_agecomp$LENGTH_MM_SD <- 
  with(test_agecomp, round(x = (LENGTH_MM_SD_prod - LENGTH_MM_SD_hist) / ifelse(test = LENGTH_MM_SD_prod == 0, 1, LENGTH_MM_SD_prod), 2))

mismatched_age <- 
  subset(x = test_agecomp, 
         subset =  abs(POPULATION_COUNT) > 100 | is.na(x = POPULATION_COUNT) |
           LENGTH_MM_MEAN != 0 | is.na(x = LENGTH_MM_MEAN) |
           LENGTH_MM_SD != 0 | is.na(x = LENGTH_MM_SD))
table(mismatched_age$AREA_ID)

tail(mismatched_age)
test <- merge(x = subset(production_alk, 
                         YEAR == 2022 & SPECIES_CODE == 10210 & AGE %in% 10 & SEX == 1),
              y = subset(historical_sizecomp, 
                         subset = AREA_ID == 99901 & YEAR == 2022 &
                           SPECIES_CODE %in% unique(x = historical_agecomp$SPECIES_CODE)),
              by = c("YEAR", "SPECIES_CODE", "SEX", "LENGTH_MM"))
subset(test_agecomp, SPECIES_CODE == 10210 & AGE == 10 & SEX == 1 & AREA_ID == 99901)
weighted.mean(as.numeric(test$LENGTH_MM), test$POPULATION_COUNT)

# all_specimen <- 
#   RODBC::sqlQuery(channel = sql_channel,
#                   query = paste0("SELECT * FROM RACEBASE.SPECIMEN ",
#                                  "WHERE REGION = 'GOA' ",
#                                  "AND AGE IS NOT NULL and ",
#                                  "hauljoin in (select hauljoin from ",
#                                  "racebase.haul where region = 'GOA' ",
#                                  "and haul_type = 3)"))
# all_specimen$YEAR <- as.integer(x = substr(x = all_specimen$CRUISE, 
#                                            start = 1, 
#                                            stop = 4))
# all_specimen <- subset(x = all_specimen,
#                        subset = YEAR >= min(production_agecomp$YEAR) & 
#                          SPECIES_CODE %in% unique(x = historical_agecomp$SPECIES_CODE))
# 
# all_specimen_good_hauls <- 
#   production_data$specimen
# 
# all_specimen_good_hauls$YEAR <- 
#   as.integer(x = substr(x = all_specimen_good_hauls$CRUISE, 
#                         start = 1, 
#                         stop = 4))
# 
# length(x = sort(unique(x = historical_agecomp$SPECIES_CODE)))
# length(x = sort(unique(x = production_alk$SPECIES_CODE)))
# 
# sample_size_all <- 
#   stats::aggregate(HAULJOIN ~ YEAR + SPECIES_CODE,
#                    data = all_specimen,
#                    FUN = function(x) length(x = unique(x = x)))
# sample_size_good_hauls <- 
#   stats::aggregate(HAULJOIN ~ YEAR + SPECIES_CODE,
#                    data = all_specimen_good_hauls,
#                    FUN = function(x) length(x = unique(x = x)))
# sample_size_all <- merge(x = sample_size_all,
#                          y = sample_size_good_hauls,
#                          by = c("YEAR", "SPECIES_CODE"),
#                          suffixes = c("_all", "_good_hauls"))
# sample_size_all$HAULJOIN <- 
#   sample_size_all$HAULJOIN_all - sample_size_all$HAULJOIN_good_hauls
# sample_size_all <- subset(x = sample_size_all,
#                           subset = HAULJOIN != 0)
# 
# test_agecomp <- 
#   merge(x = subset(x = production_agecomp,
#                    subset = YEAR < 2021 & 
#                      SPECIES_CODE %in% 
#                      unique(x = historical_agecomp$SPECIES_CODE)), 
#         y = subset(x = historical_agecomp, YEAR < 2021),
#         by = c("YEAR", "SPECIES_CODE", "SEX", "AGE"),
#         all.x = TRUE, all.y = TRUE, 
#         suffixes = c("_prod", "_hist"))
# 
# test_agecomp$POPULATION_COUNT <- 
#   with(test_agecomp, abs(POPULATION_COUNT_prod - POPULATION_COUNT_hist))
# nrow(test_agecomp)
# 
# ## Filter out rows where we expect there to be a difference in the age 
# ## composition because of the inclusion of specimen data from hauls with 
# ## negative performance.
# for (irow in 1:nrow(x = sample_size_all)) {
#   test_agecomp <- 
#     subset(x = test_agecomp,
#            subset = !(YEAR == sample_size_all$YEAR[irow] &
#                         SPECIES_CODE == sample_size_all$SPECIES_CODE[irow]))
# }
# 
# ## Filter mismatches
# mismatched_agecomp <- 
#   subset(x = test_agecomp, POPULATION_COUNT != 0 | is.na(POPULATION_COUNT))
# mismatched_agecomp$PERC_DIFF <- round(100 * mismatched_agecomp$POPULATION_COUNT /
#                                         mismatched_agecomp$POPULATION_COUNT_hist)
# mismatched_agecomp <- 
#   subset(x = mismatched_agecomp, PERC_DIFF != 0 | is.na(PERC_DIFF))
# 
# nrow(mismatched_agecomp)
# mismatched_agecomp$NOTES <- NA
# 
# spp_yr_wo_age <- 
#   subset(x = stats::aggregate(formula = AGE_FRAC ~ YEAR + SPECIES_CODE, 
#                               data = production_alk, 
#                               FUN = length, 
#                               drop = FALSE), 
#          subset = is.na(x = AGE_FRAC))
# 
# for (irow in 1:nrow(x = spp_yr_wo_age)) {
#   mismatched_agecomp$NOTES[
#     mismatched_agecomp$YEAR == spp_yr_wo_age$YEAR[irow] &
#       mismatched_agecomp$SPECIES_CODE == spp_yr_wo_age$SPECIES_CODE[irow] 
#   ] <- "no_age_data"
# }
# 
# table(mismatched_agecomp$NOTES)
# 
# unique_mismatched_biomass <-  
#   unique(x = subset(x = mismatched_biomass,
#                     subset = SPECIES_CODE %in% 
#                       unique(x = historical_agecomp$SPECIES_CODE),
#                     select = c(YEAR, STRATUM, SPECIES_CODE)))
# 
# for (irow in 1:nrow(x = unique_mismatched_biomass)) {
#   mismatched_agecomp$NOTES[
#     mismatched_agecomp$YEAR == unique_mismatched_biomass$YEAR[irow] &
#       mismatched_agecomp$SPECIES_CODE == unique_mismatched_biomass$SPECIES_CODE[irow] &
#       is.na(mismatched_agecomp$NOTES)
#   ] <- "different_pop_est"
# }
# 
# 
# table(mismatched_agecomp$NOTES)
# sum(is.na(mismatched_agecomp$NOTES))
# 
# ## 
# unique_mismatched_agecomp <- unique(x = subset(x = mismatched_agecomp,
#                                                subset = is.na(NOTES),
#                                                select = c(YEAR, SPECIES_CODE)))
# unique_mismatched_agecomp$NOTES <- NA
# 
# for (irow in 1:nrow(x = unique_mismatched_agecomp) ) {
#   temp <- 
#     subset(x = historical_agecomp, 
#            subset = SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow] & 
#              YEAR == unique_mismatched_agecomp$YEAR[irow])
#   temp2 <- 
#     subset(x = production_agecomp, 
#            subset = SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow] & 
#              YEAR == unique_mismatched_agecomp$YEAR[irow])
#   
#   sex_table <- rbind(tabulate(temp$SEX, nbins = 3),
#                      tabulate(temp2$SEX, nbins = 3))
#   if (sex_table[1,3] == 0 & sex_table[2, 3] != 0) {
#     unique_mismatched_agecomp$NOTES[irow] <- "missing_unsexed"
#   } else {
#     if (diff(sex_table[, 3]) != 0)
#       unique_mismatched_agecomp$NOTES[irow] <- "diff_num_ages"
#   }
#   
#   
#   if (!all(apply(X = sex_table[, -3], MARGIN = 2, diff) == 0))
#     unique_mismatched_agecomp$NOTES[irow] <- "diff_num_ages"
#   
#   
# }
# 
# table(unique_mismatched_agecomp$NOTES)
# sum(is.na(unique_mismatched_agecomp$NOTES))
# 
# for (irow in 1:nrow(x = unique_mismatched_agecomp)) {
#   mismatched_agecomp$NOTES[
#     mismatched_agecomp$YEAR == unique_mismatched_agecomp$YEAR[irow] &
#       mismatched_agecomp$SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow]
#   ] <- unique_mismatched_agecomp$NOTES[irow]
# }
# 
# table(mismatched_agecomp$NOTES)
# subset(mismatched_agecomp, is.na(NOTES))
# 
# subset(test_agecomp,
#        SPECIES_CODE == 30576    & YEAR == 2006        )

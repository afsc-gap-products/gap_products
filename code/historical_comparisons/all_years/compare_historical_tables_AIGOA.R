##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare historical data product tables with those produced
##                with the most recent run production tables currently in the 
##                temp/ folder
##                21 July 2023
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
##   Import metric fields lookup tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ireg = "GOA"

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import CPUE tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_data <- readRDS(file = paste0("temp/production_data_", ireg, ".RDS"))
production_cpue <- 
  read.csv(file = paste0("temp/production_cpue_", ireg, ".csv"))

historical_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT HAULJOIN, SPECIES_CODE, WEIGHT, ",
                                 "NUMBER_FISH, WGTCPUE, NUMCPUE FROM ", 
                                 ireg, ".CPUE"))

## Change field names of the historical tables to match the GAP_PRODUCTS tables
names(x = historical_cpue)[names(x = historical_cpue) %in% 
                             metric_fields$old_name] <-
  metric_fields$new_name[
    na.omit(object = match(x = names(historical_cpue),
                           table = metric_fields$old_name))
  ]

nrow(historical_cpue)
nrow(production_cpue)

length(unique(historical_cpue$SPECIES_CODE))
length(unique(production_cpue$SPECIES_CODE))

## Query any taxa not observed in the historical dataset. These would not
## be in the production dataset. 
hist_non_obs_taxa <- subset(x = stats::aggregate(WEIGHT_KG ~ SPECIES_CODE, 
                                                 FUN = sum, 
                                                 data = historical_cpue), 
                            subset = WEIGHT_KG == 0)$SPECIES_CODE

## Merge CPUE tables using HAULJOIN and SPECIES_CODE as a composite key. 
test_cpue <-
  merge(x = subset(x = production_cpue,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE)), 
        y = subset(x = historical_cpue,
                   subset = !SPECIES_CODE %in% hist_non_obs_taxa),
        by = c("HAULJOIN", "SPECIES_CODE"),
        all.x = TRUE, all.y = TRUE, suffixes = c("_prod", "_hist"))

## Calculate difference between reported weight and count. If these are 
## different then the CPUE values will also be different. 
test_cpue$WEIGHT_KG <- 
  with(test_cpue, 
       WEIGHT_KG_prod - round(x = WEIGHT_KG_hist, 
                              digits = decimalplaces(WEIGHT_KG_prod)) )
test_cpue$COUNT <- with(test_cpue, COUNT_prod - COUNT_hist )

## Subset mismatched records
mismatch_cpue <- subset(x = test_cpue, 
                        subset = is.na(COUNT) | COUNT != 0 | 
                          WEIGHT_KG != 0 | is.na(WEIGHT_KG))

## First, we want to check whether there was an update to RACEBASE.CATCH
## that was not updated in the historical tables. To do this we merge 
## RACEBASE.CATCH to `mismatch_cpue` using HAULJOIN and SPECIES_CODE as a 
## composite key. 
mismatch_cpue <- 
  merge(x = mismatch_cpue,
        y = RODBC::sqlQuery(channel = sql_channel, 
                            query = paste0("SELECT HAULJOIN, SPECIES_CODE, ",
                                           "WEIGHT, NUMBER_FISH ",
                                           "FROM RACEBASE.CATCH")),
        by = c("HAULJOIN", "SPECIES_CODE"),
        all.x = TRUE)

## Take note of those records where there was an observed catch record in the 
## historical tables but does not exist in RACEBASE.CATCH anymore
mismatch_cpue$NOTES[is.na(x = mismatch_cpue$NUMBER_FISH) & 
                      !is.na(x = mismatch_cpue$COUNT_hist)] <- "record removed"

mismatch_cpue$NOTES[mismatch_cpue$COUNT_hist != mismatch_cpue$NUMBER_FISH] <-
  "record modified"

##
mismatch_cpue$NOTES[is.na(x = mismatch_cpue$NUMBER_FISH) & 
                      mismatch_cpue$COUNT_prod == 0] <- "taxon_switch"

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Strata information and biomass tables. For the biomass comparison
##   only stratum-level estimates are being tested. However, in some regions,
##   there are some subareas that are just single strata with the same ID 
##   (e.g., 793 is an AI stratum and a subarea). Thus, when importing the 
##   production table, only unique record are imported.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_strata <- 
  read.csv(file = paste0("temp/production_strata_", ireg, ".csv"))
production_subarea <- 
  read.csv(file = paste0("temp/production_subarea_", ireg, ".csv"))
production_biomass <- 
  unique(x = subset(x = read.csv(file = paste0("temp/production_biomass_", 
                                               ireg, ".csv")),
                    subset = AREA_ID %in% production_strata$STRATUM))
## Change AREA_ID field name to STRATUM
names(production_biomass)[names(production_biomass) == "AREA_ID"] <- "STRATUM" 

production_biomass$CPUE_NOKM2_MEAN <- round(production_biomass$CPUE_NOKM2_MEAN, 1)
production_biomass$CPUE_NOKM2_MEAN <- round(production_biomass$CPUE_NOKM2_MEAN, 1)

historical_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, STRATUM, SPECIES_CODE, ",
                                 "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                                 "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                                 "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                                 "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                                 "VAR_NUM_CPUE AS CPUE_NOKM2_VAR ",
                                 " FROM ", 
                                 ireg, ".BIOMASS_STRATUM"))
## Change field names of the historical tables to match the GAP_PRODUCTS tables
# names(x = historical_biomass)[names(x = historical_biomass) %in% 
#                                 metric_fields$old_name] <-
#   metric_fields$new_name[
#     na.omit(object = match(x = names(historical_biomass),
#                            table = metric_fields$old_name))
#   ]

nrow(historical_biomass)
nrow(production_biomass)

length(unique(historical_biomass$SPECIES_CODE))
length(unique(production_biomass$SPECIES_CODE))

hist_non_obs_taxa <- 
  subset(x = stats::aggregate(CPUE_KGKM2_MEAN  ~ SPECIES_CODE, 
                              FUN = sum, 
                              data = historical_biomass), 
         subset = CPUE_KGKM2_MEAN  == 0)$SPECIES_CODE

long_historical_biomass <- 
  reshape2::melt(
    data = subset(x = historical_biomass,
                  subset = !SPECIES_CODE %in% hist_non_obs_taxa), 
    id.vars = c("YEAR", "STRATUM", "SPECIES_CODE"),
    measure.vars = c("N_HAUL", "N_WEIGHT", 
                     "CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                     "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR"), 
    variable.name = "METRIC", value.name = "VALUE")

long_production_biomass <- 
  reshape2::melt(
    data = subset(x = production_biomass,
                  subset = SPECIES_CODE %in% 
                    unique(x = historical_biomass$SPECIES_CODE)), 
    id.vars = c("YEAR", "STRATUM", "SPECIES_CODE"),
    measure.vars = c("N_HAUL", "N_WEIGHT", 
                     "CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                     "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR"), 
    variable.name = "METRIC", value.name = "VALUE")

## Merge BIOMASS tables using YEAR, STRATUM, AND SPECIES_CODE as composite key. 
test_biomass <- 
  merge(x = long_production_biomass, 
        y = long_historical_biomass,
        by = c("YEAR", "STRATUM", "SPECIES_CODE", "METRIC"),
        all.x = TRUE, all.y = TRUE, suffixes = c("_PROD", "_HIST"))

test_biomass$DIFF <- test_biomass$VALUE_PROD - test_biomass$VALUE_HIST
mismatched_biomass <- subset(x = test_biomass,
                             subset = is.na(DIFF) | DIFF != 0)
mismatched_biomass$PERC_DIFF <- round(x = 100 * mismatched_biomass$DIFF / mismatched_biomass$VALUE_PROD)
mismatched_biomass <- subset(x = mismatched_biomass,
                             subset = is.na(PERC_DIFF) | PERC_DIFF != 0)

# unique_mismatched_biomass <- 
#   unique(x = subset(x = mismatched_biomass,
#                     select = c(YEAR, STRATUM, SPECIES_CODE)))
# unique_mismatched_biomass$NOTES <- NA

split_taxon <- 
  subset(x = mismatched_biomass, 
         subset = (METRIC == "N_WEIGHT" & 
                     VALUE_PROD == 0 & 
                     is.na(x = VALUE_HIST)),
         select = c(YEAR, STRATUM, SPECIES_CODE))

for (irow in 1:nrow(x = split_taxon)) {
  mismatched_biomass <-   
    subset(x = mismatched_biomass, 
           subset = !(YEAR == split_taxon$YEAR[irow] & 
                        SPECIES_CODE == split_taxon$SPECIES_CODE[irow] &
                        STRATUM == split_taxon$STRATUM[irow]))
}

## Calculate difference between total number of hauls and the total number of
## hauls with positive weights. If these are different then the biomass values
## will also be different. 
test_biomass$N_WEIGHT <- with(test_biomass, N_WEIGHT_hist - N_WEIGHT_prod)
test_biomass$N_HAUL <- with(test_biomass, N_HAUL_hist - N_HAUL_prod)
test_biomass$BIOMASS_MT <- with(test_biomass, BIOMASS_MT_hist - BIOMASS_MT_prod)
test_biomass$N_HAUL <- with(test_biomass, N_HAUL_hist - N_HAUL_prod)

## Subset mismatched records
mismatched_biomass <- subset(x = test_biomass,
                             subset = is.na(N_HAUL) | N_HAUL != 0 |
                               is.na(N_WEIGHT) | N_WEIGHT != 0)

## Note those records of new species_code values. e.g., rock soles were lumped
## together with one species code prior to 1996 and then split into two
## distinct species codes. So prior to 1996 there will not be records for the 
## two rock soles and after 1996, there will not be records for rock soles unid 
mismatched_biomass$NOTES[is.na(x = mismatched_biomass$N_HAUL) | 
                           is.na(x = mismatched_biomass$N_WEIGHT)] <- 
  "split_taxon"

## Query whether the remaining mismatched biomass records are becuase of a 
## mismatched cpue record. 
for (irow in which(x = is.na(x = mismatched_biomass$NOTES)) ) {
  
  if (nrow(x = subset(x = mismatch_cpue, 
                      subset = SPECIES_CODE == mismatched_biomass$SPECIES_CODE[irow] &
                      YEAR == mismatched_biomass$YEAR[irow] & 
                      STRATUM == mismatched_biomass$STRATUM[irow])) != 0)
    mismatched_biomass$NOTES[irow] <- "mismatched_cpue"
  
  if (irow%%100 == 0) print(irow)
} 

## Lastly, calculate whether the mismatch was due to a different number of 
## hauls included in the strata.
mismatched_biomass$NOTES[mismatched_biomass$N_HAUL != 0 & 
                           is.na(x = mismatched_biomass$NOTES)] <- 
  "diff_n_hauls"

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import sizecomp tables. For the sizecomp comparison, we will only compare
##   the total sex-aggregated size compositions at the stratum-level. 
##   In some regions, there are some subareas that are just single strata with 
##   the same ID (e.g., 793 is an AI stratum and a subarea). Thus, when 
##   importing the production table, only unique record are imported. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_sizecomp0 <- 
  unique(x = subset(x = read.csv(file = paste0("temp/production_sizecomp_", 
                                               ireg, ".csv")),
                    subset = AREA_ID %in% production_strata$STRATUM))
## Change AREA_ID field name to STRATUM
names(x = production_sizecomp0)[names(x = production_sizecomp0) == "AREA_ID"] <- 
  "STRATUM" 
production_sizecomp <- 
  stats::aggregate(POPULATION_COUNT ~ YEAR + STRATUM + SPECIES_CODE + LENGTH_MM, 
                   FUN = sum, 
                   data = production_sizecomp0)



historical_sizecomp0 <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, STRATUM, SPECIES_CODE, LENGTH,",
                                 " MALES, FEMALES, UNSEXED,  TOTAL FROM ", 
                                 ireg, ".SIZECOMP_STRATUM"))

## Change field names of the historical tables to match the GAP_PRODUCTS tables
names(historical_sizecomp0)[names(historical_sizecomp0) %in% metric_fields$old_name] <-
  metric_fields$new_name[
    na.omit(object = match(x = names(historical_sizecomp0),
                           table = metric_fields$old_name))
  ]

historical_sizecomp <- subset(historical_sizecomp0,
                              select = -c(MALES, FEMALES, UNSEXED))

## Merge SIZECOMP tables using YEAR, STRATUM, SPECIES_CODE, and LENGTH_MM
## as a composite key. 
test_sizecomp <- merge(x = production_sizecomp,
                       y = historical_sizecomp,
                       by = c("YEAR", "STRATUM", "SPECIES_CODE", "LENGTH_MM"),
                       all.x = TRUE, all.y = TRUE)

## Calculate difference between size comps
test_sizecomp$DIFF <- with(test_sizecomp, TOTAL - POPULATION_COUNT)

## Subset mismatched records and then calculate the percent difference. 
## Size comps can be really big and so values may be slightly different just
## due to truncation errors. Thus we subset values with >0.5% difference. 
mismatched_sizecomp <- subset(test_sizecomp, DIFF != 0)
mismatched_sizecomp$PERC_DIFF <- round(x = 100 * mismatched_sizecomp$DIFF / 
                                         mismatched_sizecomp$TOTAL)
mismatched_sizecomp <- subset(x = mismatched_sizecomp, 
                              PERC_DIFF != 0)

## Any record with a known difference in the biomass tables will have 
## a difference in the sizecomp
mismatched_sizecomp$NOTES <- NA

for (irow in 1:nrow(x = mismatched_biomass)) {
  if (nrow(x = subset(x = mismatched_sizecomp, 
                      subset = SPECIES_CODE == mismatched_biomass$SPECIES_CODE[irow] &
                      YEAR == mismatched_biomass$YEAR[irow] & 
                      STRATUM == mismatched_biomass$STRATUM[irow])) != 0) {
    
    mismatched_sizecomp$NOTES[
      which(
        mismatched_sizecomp$YEAR == 
          mismatched_biomass$YEAR[irow] &
          
          mismatched_sizecomp$SPECIES_CODE == 
          mismatched_biomass$SPECIES_CODE[irow] &
          
          mismatched_sizecomp$STRATUM == 
          mismatched_biomass$STRATUM[irow]
      )
    ] <- "mismatched_abundance"
    
  }
  
  
  if (irow%%100 == 0) print(irow)
}

unique_mismatched_sizecomp <-
  unique(subset(x = mismatched_sizecomp,
                PERC_DIFF != 0,
                select = c(YEAR, STRATUM, SPECIES_CODE)))

test <- merge(x = unique_mismatched_sizecomp,
              y = test_biomass[, c("YEAR", "STRATUM", "SPECIES_CODE",
                                   "POPULATION_COUNT_prod",
                                   "POPULATION_COUNT_hist")],
              by = c("YEAR", "STRATUM", "SPECIES_CODE"),
              all.x = TRUE)

test$DIFF <- abs(floor(100 * abs(test$POPULATION_COUNT_prod - test$POPULATION_COUNT_hist) /
                         test$POPULATION_COUNT_hist))
# nrow(subset(test, DIFF != 0))
# test <- subset(test, DIFF == 0)

for (irow in 1:nrow(test)) {
  temp_sizecomp <-
    colSums(subset(test_sizecomp,
                   YEAR == test$YEAR[irow] & 
                     SPECIES_CODE == test$SPECIES_CODE[irow] & 
                     STRATUM == test$STRATUM[irow]), 
            na.rm = TRUE)
  
  temp_bio <-
    subset(test_biomass,
           YEAR == test$YEAR[irow] & SPECIES_CODE == test$SPECIES_CODE[irow] & STRATUM == test$STRATUM[irow])
  
  temp_bio$POPULATION_COUNT <- floor(100 * abs(temp_bio$POPULATION_COUNT_hist -
                                                 temp_bio$POPULATION_COUNT_prod) / 
                                       temp_bio$POPULATION_COUNT_prod)
  
  match_with_count <- floor(100 * abs(temp_sizecomp[ c("POPULATION_COUNT", "TOTAL")] - temp_bio[, c("POPULATION_COUNT_prod", "POPULATION_COUNT_hist")]) / temp_bio[, c("POPULATION_COUNT_prod", "POPULATION_COUNT_hist")])
  
  test[irow, c("summed_lengths_prod", "summed_lengths_hist")] <- match_with_count
  
  if (match_with_count$POPULATION_COUNT_prod == 0 &
      match_with_count$POPULATION_COUNT_hist != 0) {
    mismatched_sizecomp$NOTES[
      which(
        mismatched_sizecomp$YEAR == test$YEAR[irow] &
          mismatched_sizecomp$SPECIES_CODE == test$SPECIES_CODE[irow] &
          mismatched_sizecomp$STRATUM == test$STRATUM[irow]
      )
    ] <- "sizecomp_doesnt_addup"
  }
  
  if (temp_bio$POPULATION_COUNT != 0) {
    mismatched_sizecomp$NOTES[
      which(
        mismatched_sizecomp$YEAR == test$YEAR[irow] &
          mismatched_sizecomp$SPECIES_CODE == test$SPECIES_CODE[irow] &
          mismatched_sizecomp$STRATUM == test$STRATUM[irow]
      )
    ] <- "mismatched_abundance"
  }
  
}

with(subset(mismatched_sizecomp, is.na(NOTES)),
     table(YEAR, SPECIES_CODE, STRATUM))

subset(historical_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)
sum(subset(historical_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)$TOTAL)

subset(production_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)
sum(subset(production_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)$POP)


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Age comps
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_alk <- read.csv(file = paste0("temp/production_alk_", ireg, ".csv"))
production_agecomp_stratum <- 
  subset(x = read.csv(file = paste0("temp/production_agecomp_", 
                                    ireg, ".csv")),
         subset = AREA_ID %in% production_strata$STRATUM,
         select = -c(AREA_ID, SURVEY, SURVEY_DEFINITION_ID))

production_agecomp <- 
  unique(x = subset(x = read.csv(file = paste0("temp/production_agecomp_", 
                                               ireg, ".csv")),
                    subset = AREA_ID %in% production_subarea$AREA_ID[production_subarea$TYPE == "REGION"],
                    select = -c(AREA_ID, SURVEY, SURVEY_DEFINITION_ID)))

historical_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT SURVEY_YEAR as YEAR, SPECIES_CODE, ",
                                 "SEX, AGE, AGEPOP as POPULATION_COUNT FROM ", ireg, 
                                 ".AGECOMP_TOTAL"))

all_specimen <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM RACEBASE.SPECIMEN ",
                                 "WHERE REGION = '", ireg, "' ",
                                 "AND AGE IS NOT NULL and ",
                                 "hauljoin in (select hauljoin from ",
                                 "racebase.haul where region = '", ireg, "' ",
                                 "and haul_type = 3)"))
all_specimen$YEAR <- as.integer(x = substr(x = all_specimen$CRUISE, 
                                           start = 1, 
                                           stop = 4))
all_specimen <- subset(x = all_specimen,
                       subset = YEAR >= min(production_agecomp$YEAR) & 
                         SPECIES_CODE %in% unique(x = historical_agecomp$SPECIES_CODE))

all_specimen_good_hauls <- 
  production_data$specimen

all_specimen_good_hauls$YEAR <- 
  as.integer(x = substr(x = all_specimen_good_hauls$CRUISE, 
                        start = 1, 
                        stop = 4))

length(x = sort(unique(x = historical_agecomp$SPECIES_CODE)))
length(x = sort(unique(x = production_alk$SPECIES_CODE)))

sample_size_all <- 
  stats::aggregate(HAULJOIN ~ YEAR + SPECIES_CODE,
                   data = all_specimen,
                   FUN = function(x) length(x = unique(x = x)))
sample_size_good_hauls <- 
  stats::aggregate(HAULJOIN ~ YEAR + SPECIES_CODE,
                   data = all_specimen_good_hauls,
                   FUN = function(x) length(x = unique(x = x)))
sample_size_all <- merge(x = sample_size_all,
                         y = sample_size_good_hauls,
                         by = c("YEAR", "SPECIES_CODE"),
                         suffixes = c("_all", "_good_hauls"))
sample_size_all$HAULJOIN <- 
  sample_size_all$HAULJOIN_all - sample_size_all$HAULJOIN_good_hauls
sample_size_all <- subset(x = sample_size_all,
                          subset = HAULJOIN != 0)

test_agecomp <- 
  merge(x = subset(x = production_agecomp,
                   SPECIES_CODE %in% 
                     unique(x = historical_agecomp$SPECIES_CODE)), 
        y = historical_agecomp,
        by = c("YEAR", "SPECIES_CODE", "SEX", "AGE"),
        all.x = TRUE, all.y = TRUE, 
        suffixes = c("_prod", "_hist"))

test_agecomp$POPULATION_COUNT <- 
  with(test_agecomp, abs(POPULATION_COUNT_prod - POPULATION_COUNT_hist))

## Filter out rows where we expect there to be a difference in the age 
## composition because of the inclusion of specimen data from hauls with 
## negative performance.

for (irow in 1:nrow(x = sample_size_all)) {
  test_agecomp <- 
    subset(x = test_agecomp,
           subset = !(YEAR == sample_size_all$YEAR[irow] &
                        SPECIES_CODE == sample_size_all$SPECIES_CODE[irow]))
}

mismatched_agecomp <- 
  subset(x = test_agecomp, POPULATION_COUNT != 0 | is.na(POPULATION_COUNT))
mismatched_agecomp$PERC_DIFF <- round(100 * mismatched_agecomp$POPULATION_COUNT /
                                        mismatched_agecomp$POPULATION_COUNT_hist)
mismatched_agecomp <- 
  subset(x = mismatched_agecomp, PERC_DIFF != 0 | is.na(PERC_DIFF))

nrow(mismatched_agecomp)

spp_yr_wo_age <- 
  subset(x = stats::aggregate(formula = AGE_FRAC ~ YEAR + SPECIES_CODE, 
                              data = production_alk, 
                              FUN = length, 
                              drop = FALSE), 
         subset = is.na(x = AGE_FRAC))

for (irow in 1:nrow(x = spp_yr_wo_age)) {
  mismatched_agecomp$NOTES[
    mismatched_agecomp$YEAR == spp_yr_wo_age$YEAR[irow] &
      mismatched_agecomp$SPECIES_CODE == spp_yr_wo_age$SPECIES_CODE[irow] 
  ] <- "no_age_data"
}

unique_mismatched_biomass <-  
  unique(x = subset(x = mismatched_biomass,
                    subset = SPECIES_CODE %in% 
                      unique(x = historical_agecomp$SPECIES_CODE),
                    select = c(YEAR, STRATUM, SPECIES_CODE)))

for (irow in 1:nrow(x = unique_mismatched_biomass)) {
  mismatched_agecomp$NOTES[
    mismatched_agecomp$YEAR == unique_mismatched_biomass$YEAR[irow] &
      mismatched_agecomp$SPECIES_CODE == unique_mismatched_biomass$SPECIES_CODE[irow] 
  ] <- "different_pop_est"
}


table(mismatched_agecomp$NOTES)
sum(is.na(mismatched_agecomp$NOTES))

# production_biomass_region <- 
#   subset(x = read.csv(file = paste0("temp/production_biomass_", 
#                                     ireg, ".csv")),
#          subset = AREA_ID %in% production_subarea$AREA_ID[production_subarea$TYPE == 'REGION'] & 
#            SPECIES_CODE %in% unique(x = historical_agecomp$SPECIES_CODE))
# 
# historical_biomass_region <- 
#   RODBC::sqlQuery(channel = sql_channel,
#                   query = paste0("SELECT * FROM ", ireg, 
#                                  ".BIOMASS_TOTAL"))
# 
unique_mismatched_agecomp <- unique(x = subset(x = mismatched_agecomp,
                                               subset = is.na(NOTES),
                                               select = c(YEAR, SPECIES_CODE)))
unique_mismatched_agecomp$NOTES <- NA
for (irow in 1:nrow(x = unique_mismatched_agecomp) ) {
  temp <- 
    subset(x = historical_agecomp, 
           subset = SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow] & 
             YEAR == unique_mismatched_agecomp$YEAR[irow])
  temp2 <- 
    subset(x = production_agecomp, 
           subset = SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow] & 
             YEAR == unique_mismatched_agecomp$YEAR[irow])
  
  sex_table <- rbind(tabulate(temp$SEX, nbins = 3),
                     tabulate(temp2$SEX, nbins = 3))
  if (sex_table[1,3] == 0 & sex_table[2, 3] != 0) {
    unique_mismatched_agecomp$NOTES[irow] <- "missing_unsexed"
  } else {
    if (diff(sex_table[, 3]) != 0)
      unique_mismatched_agecomp$NOTES[irow] <- "diff_num_ages"
  }
  
  
  if (!all(apply(X = sex_table[, -3], MARGIN = 2, diff) == 0))
    unique_mismatched_agecomp$NOTES[irow] <- "diff_num_ages"
  # temp_bio <-
  #   subset(x = production_biomass_region,
  #          subset = SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow] &
  #            YEAR == unique_mismatched_agecomp$YEAR[irow])
  # temp_bio_hist <- subset(x = historical_biomass_region,
  #                         subset = SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow] &
  #                           YEAR == unique_mismatched_agecomp$YEAR[irow])
  # temp_bio$POPULATION_COUNT_AGE <- sum(temp$POPULATION_COUNT)
  # 
  # temp_bio$PERC_DIFF <- floor(with(temp_bio, 100 * abs(POPULATION_COUNT - POPULATION_COUNT_AGE) / POPULATION_COUNT_AGE ))
  # 
  # if (temp_bio$PERC_DIFF != 0) unique_mismatched_agecomp$NOTES[irow] <- "does_not_add_up"
  
}

table(unique_mismatched_agecomp$NOTES)
sum(is.na(unique_mismatched_agecomp$NOTES))
subset(unique_mismatched_agecomp, is.na(NOTES))

subset(test_agecomp,
       SPECIES_CODE == 21720 & YEAR == 2000)

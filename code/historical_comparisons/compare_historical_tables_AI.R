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
##   Import production tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## gapindex data object
production_data <- readRDS(file = "temp/production_data_AI.RDS")

## CPUE
production_cpue <- read.csv(file = "temp/production_cpue_AI.csv")

## strata information
production_strata <- read.csv(file = paste0("temp/production_strata_AI.csv"))

## subarea information
production_subarea <- read.csv(file = paste0("temp/production_subarea_AI.csv"))

## stratum biomass
production_biomass <- 
  unique(x = subset(x = read.csv(file = "temp/production_biomass_AI.csv"),
                    subset = AREA_ID %in% production_strata$STRATUM))
## Change AREA_ID field name to STRATUM
names(production_biomass)[names(production_biomass) == "AREA_ID"] <- "STRATUM" 

## stratum size composition
production_sizecomp0 <- 
  unique(x = subset(x = read.csv(file = "temp/production_sizecomp_AI.csv"),
                    subset = AREA_ID %in% production_strata$STRATUM))
## Change AREA_ID field name to STRATUM
names(x = production_sizecomp0)[names(x = production_sizecomp0) == "AREA_ID"] <- 
  "STRATUM" 
## Age-length key
production_alk <- read.csv(file = paste0("temp/production_alk_AI.csv"))
# age composition
production_agecomp <- 
  unique(x = subset(x = read.csv(file = "temp/production_agecomp_AI.csv"),
                    subset = AREA_ID %in% production_subarea$AREA_ID[production_subarea$TYPE == "REGION"],
                    select = -c(AREA_ID, SURVEY, SURVEY_DEFINITION_ID)))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
historical_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT HAULJOIN, SPECIES_CODE, ",
                    "WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT, ",
                    "WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2 ",
                    "FROM AI.CPUE"))

historical_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM, SPECIES_CODE, ",
                    "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                    "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                    "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                    "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                    "VAR_NUM_CPUE AS CPUE_NOKM2_VAR ",
                    " FROM AI.BIOMASS_STRATUM"))

historical_sizecomp0 <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, STRATUM, SPECIES_CODE, ",
                                 "LENGTH AS LENGTH_MM, TOTAL FROM ", 
                                 "AI.SIZECOMP_STRATUM"))

historical_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT SURVEY_YEAR as YEAR, SPECIES_CODE, ",
                                 "SEX, AGE, AGEPOP as POPULATION_COUNT FROM ",
                                 "AI.AGECOMP_TOTAL"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   CPUE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
       WEIGHT_KG_prod - WEIGHT_KG_hist )
test_cpue$COUNT <- with(test_cpue, COUNT_prod - COUNT_hist )

## Subset mismatched records
mismatch_cpue <- subset(x = test_cpue, 
                        subset = is.na(COUNT) | COUNT != 0 | 
                          WEIGHT_KG != 0 | is.na(WEIGHT_KG) )

mismatch_cpue$NOTES <- NA

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

mismatch_cpue$NOTES[mismatch_cpue$COUNT_hist != mismatch_cpue$NUMBER_FISH &
                      is.na(x = mismatch_cpue$NOTES)] <-
  "record modified"

##
mismatch_cpue$NOTES[is.na(x = mismatch_cpue$NUMBER_FISH) & 
                      is.na(x = mismatch_cpue$NOTES) &
                      mismatch_cpue$COUNT_prod == 0] <- "taxon_switch"

table(mismatch_cpue$NOTES)
sum(is.na(mismatch_cpue$NOTES))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Strata information and biomass tables. For the biomass comparison
##   only stratum-level estimates are being tested. However, in some regions,
##   there are some subareas that are just single strata with the same ID 
##   (e.g., 793 is an AI stratum and a subarea). Thus, when importing the 
##   production table, only unique record are imported.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

nrow(historical_biomass)
nrow(production_biomass)

length(unique(historical_biomass$SPECIES_CODE))
length(unique(production_biomass$SPECIES_CODE))

hist_non_obs_taxa <- 
  subset(x = stats::aggregate(CPUE_KGKM2_MEAN  ~ SPECIES_CODE, 
                              FUN = sum, 
                              data = historical_biomass), 
         subset = CPUE_KGKM2_MEAN  == 0)$SPECIES_CODE

historical_biomass <- subset(x = historical_biomass,
                             subset = !(SPECIES_CODE %in% hist_non_obs_taxa))

## Merge BIOMASS tables using YEAR, STRATUM, AND SPECIES_CODE as composite key. 
test_biomass <- 
  merge(x = subset(x = production_biomass,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_biomass$SPECIES_CODE)), 
        y = subset(x = historical_biomass,
                   subset = !SPECIES_CODE %in% hist_non_obs_taxa),
        by = c("YEAR", "STRATUM", "SPECIES_CODE"),
        all.x = TRUE, all.y = TRUE, suffixes = c("_PROD", "_HIST"))

test_biomass$CPUE_NOKM2_MEAN_PROD <-
  round(x = test_biomass$CPUE_NOKM2_MEAN_PROD,
        digits = 1)
test_biomass$CPUE_KGKM2_MEAN_PROD <-
  round(x = test_biomass$CPUE_KGKM2_MEAN_PROD,
        digits = 1)


test_biomass$CPUE_NOKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_VAR_PROD - CPUE_NOKM2_VAR_HIST) / ifelse(CPUE_NOKM2_VAR_HIST == 0, 1, CPUE_NOKM2_VAR_HIST) ))
test_biomass$CPUE_NOKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_MEAN_PROD - CPUE_NOKM2_MEAN_HIST) / ifelse(CPUE_NOKM2_MEAN_HIST == 0, 1, CPUE_NOKM2_MEAN_HIST) ))

test_biomass$CPUE_KGKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_VAR_PROD - CPUE_KGKM2_VAR_HIST) / ifelse(CPUE_KGKM2_VAR_HIST == 0, 1, CPUE_KGKM2_VAR_HIST) ))
test_biomass$CPUE_KGKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_MEAN_PROD - CPUE_KGKM2_MEAN_HIST) / ifelse(CPUE_KGKM2_MEAN_HIST == 0, 1, CPUE_KGKM2_MEAN_HIST) ))

test_biomass$N_HAUL <- with(test_biomass, N_HAUL_PROD - N_HAUL_HIST)

## Subset mismatched records
mismatched_biomass <- 
  subset(x = test_biomass, 
         subset = CPUE_NOKM2_MEAN != 0 | is.na(x = CPUE_NOKM2_MEAN) |
           CPUE_NOKM2_VAR != 0 | is.na(x = CPUE_NOKM2_VAR) |
           CPUE_KGKM2_MEAN != 0 | is.na(x = CPUE_KGKM2_MEAN) |
           CPUE_KGKM2_VAR != 0 | is.na(x = CPUE_KGKM2_VAR) )
mismatched_biomass <- 
  subset(x = mismatched_biomass, 
         subset = !(N_HAUL_HIST == 1 & CPUE_NOKM2_MEAN == 0 & 
                      CPUE_NOKM2_MEAN_HIST == 0 & 
                      is.na(x = CPUE_KGKM2_VAR) & 
                      is.na(x = CPUE_NOKM2_VAR)) )
mismatched_biomass <- 
  subset(x = mismatched_biomass, 
         subset = !(N_HAUL_HIST == 1 & CPUE_NOKM2_MEAN == 0 & 
                      CPUE_KGKM2_MEAN == 0 & 
                      is.na(x = CPUE_KGKM2_VAR) & 
                      is.na(x = CPUE_NOKM2_VAR)) )
mismatched_biomass$NOTES <- NA

## Note those records of new species_code values. e.g., rock soles were lumped
## together with one species code prior to 1996 and then split into two
## distinct species codes. So prior to 1996 there will not be records for the 
## two rock soles and after 1996, there will not be records for rock soles unid 
mismatched_biomass$NOTES[!is.na(x = mismatched_biomass$N_HAUL_PROD) & 
                           is.na(x = mismatched_biomass$N_HAUL_HIST)] <- 
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

table(mismatched_biomass$NOTES)
subset(mismatched_biomass, is.na(NOTES))

with(subset(mismatched_biomass, is.na(NOTES)), 
     round(100 * (CPUE_KGKM2_MEAN_HIST - round(CPUE_KGKM2_MEAN_PROD))/round(CPUE_KGKM2_MEAN_PROD) ))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import sizecomp tables. For the sizecomp comparison, we will only compare
##   the total sex-aggregated size compositions at the stratum-level. 
##   In some regions, there are some subareas that are just single strata with 
##   the same ID (e.g., 793 is an AI stratum and a subarea). Thus, when 
##   importing the production table, only unique record are imported. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

length(x = unique(x = production_sizecomp$SPECIES_CODE))
length(x = unique(x = historical_sizecomp$SPECIES_CODE))

nrow(historical_sizecomp)
nrow(production_sizecomp)

production_sizecomp <- 
  stats::aggregate(POPULATION_COUNT ~ YEAR + STRATUM + SPECIES_CODE + LENGTH_MM, 
                   FUN = sum, 
                   data = production_sizecomp0)

historical_sizecomp <- historical_sizecomp0

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
                PERC_DIFF != 0 & is.na(NOTES),
                select = c(YEAR, STRATUM, SPECIES_CODE)))

unique_mismatched_sizecomp <- 
  merge(x = unique_mismatched_sizecomp,
        y = test_biomass[, c("YEAR", "STRATUM", "SPECIES_CODE",
                             "POPULATION_COUNT")],
        by = c("YEAR", "STRATUM", "SPECIES_CODE"),
        all.x = TRUE)

for (irow in 1:nrow(unique_mismatched_sizecomp)) {
  temp_sizecomp <-
    colSums(subset(test_sizecomp,
                   YEAR == unique_mismatched_sizecomp$YEAR[irow] & 
                     SPECIES_CODE == unique_mismatched_sizecomp$SPECIES_CODE[irow] & 
                     STRATUM == unique_mismatched_sizecomp$STRATUM[irow]), 
            na.rm = TRUE)
  
  match_with_count <- 
    round(100 * abs(temp_sizecomp[c("TOTAL", "POPULATION_COUNT")] - 
                      unique_mismatched_sizecomp$POPULATION_COUNT[irow]) / 
            unique_mismatched_sizecomp$POPULATION_COUNT[irow], 0)
  
  unique_mismatched_sizecomp[irow, c("summed_lengths_prod", 
                                     "summed_lengths_hist")] <- match_with_count
  
  if (match_with_count["POPULATION_COUNT"] == 0 &
      match_with_count["TOTAL"] != 0) {
    mismatched_sizecomp$NOTES[
      which(
        mismatched_sizecomp$YEAR == unique_mismatched_sizecomp$YEAR[irow] &
          mismatched_sizecomp$SPECIES_CODE == unique_mismatched_sizecomp$SPECIES_CODE[irow] &
          mismatched_sizecomp$STRATUM == unique_mismatched_sizecomp$STRATUM[irow]
      )
    ] <- "sizecomp_doesnt_addup"
  }
  
  # if (temp_bio$POPULATION_COUNT != 0) {
  #   mismatched_sizecomp$NOTES[
  #     which(
  #       mismatched_sizecomp$YEAR == test$YEAR[irow] &
  #         mismatched_sizecomp$SPECIES_CODE == test$SPECIES_CODE[irow] &
  #         mismatched_sizecomp$STRATUM == test$STRATUM[irow]
  #     )
  #   ] <- "mismatched_abundance"
  # }
  
}

sum(table(mismatched_sizecomp$NOTES))
nrow(mismatched_sizecomp)

with(subset(mismatched_sizecomp, is.na(NOTES)), table(STRATUM, YEAR, SPECIES_CODE) )



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Age comps
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_specimen <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM RACEBASE.SPECIMEN ",
                                 "WHERE REGION = 'AI' ",
                                 "AND AGE IS NOT NULL and ",
                                 "hauljoin in (select hauljoin from ",
                                 "racebase.haul where region = 'AI' ",
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
                   subset = YEAR < 2022 & 
                     SPECIES_CODE %in% 
                     unique(x = historical_agecomp$SPECIES_CODE)), 
        y = historical_agecomp,
        by = c("YEAR", "SPECIES_CODE", "SEX", "AGE"),
        all.x = TRUE, all.y = TRUE, 
        suffixes = c("_prod", "_hist"))

test_agecomp$POPULATION_COUNT <- 
  with(test_agecomp, abs(POPULATION_COUNT_prod - POPULATION_COUNT_hist))
nrow(test_agecomp)

## Filter out rows where we expect there to be a difference in the age 
## composition because of the inclusion of specimen data from hauls with 
## negative performance.
for (irow in 1:nrow(x = sample_size_all)) {
  test_agecomp <- 
    subset(x = test_agecomp,
           subset = !(YEAR == sample_size_all$YEAR[irow] &
                        SPECIES_CODE == sample_size_all$SPECIES_CODE[irow]))
}

## Filter mismatches
mismatched_agecomp <- 
  subset(x = test_agecomp, POPULATION_COUNT != 0 | is.na(POPULATION_COUNT))
mismatched_agecomp$PERC_DIFF <- round(100 * mismatched_agecomp$POPULATION_COUNT /
                                        mismatched_agecomp$POPULATION_COUNT_hist)
mismatched_agecomp <- 
  subset(x = mismatched_agecomp, PERC_DIFF != 0 | is.na(PERC_DIFF))

nrow(mismatched_agecomp)
mismatched_agecomp$NOTES <- NA

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

table(mismatched_agecomp$NOTES)

unique_mismatched_biomass <-  
  unique(x = subset(x = mismatched_biomass,
                    subset = SPECIES_CODE %in% 
                      unique(x = historical_agecomp$SPECIES_CODE),
                    select = c(YEAR, STRATUM, SPECIES_CODE)))

for (irow in 1:nrow(x = unique_mismatched_biomass)) {
  mismatched_agecomp$NOTES[
    mismatched_agecomp$YEAR == unique_mismatched_biomass$YEAR[irow] &
      mismatched_agecomp$SPECIES_CODE == unique_mismatched_biomass$SPECIES_CODE[irow] &
      is.na(mismatched_agecomp$NOTES)
  ] <- "different_pop_est"
}


table(mismatched_agecomp$NOTES)
sum(is.na(mismatched_agecomp$NOTES))

## 
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
  
}

table(unique_mismatched_agecomp$NOTES)
sum(is.na(unique_mismatched_agecomp$NOTES))

for (irow in 1:nrow(x = unique_mismatched_agecomp)) {
  mismatched_agecomp$NOTES[
    mismatched_agecomp$YEAR == unique_mismatched_agecomp$YEAR[irow] &
      mismatched_agecomp$SPECIES_CODE == unique_mismatched_agecomp$SPECIES_CODE[irow]
                     ] <- unique_mismatched_agecomp$NOTES[irow]
}

subset(mismatched_agecomp, is.na(NOTES))

subset(test_agecomp,
       SPECIES_CODE == 30576    & YEAR == 2006        )

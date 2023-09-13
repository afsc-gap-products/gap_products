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
##   Import production tables, trim 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## gapindex data object
production_data <- readRDS(file = "temp/production/production_data_EBS.RDS")
## CPUE
production_cpue <- read.csv(file = "temp/production/production_cpue_EBS.csv")
## stratum information
production_strata <- read.csv(file = "temp/production/production_strata_EBS.csv")
## subarea information
production_subarea <- read.csv(file = "temp/production/production_subarea_EBS.csv")

## stratum-level biomass, abundance, mean/var CPUE
production_biomass <- read.csv(file = "temp/production/production_biomass_EBS.csv")
production_biomass <- subset(x = production_biomass,
                             subset = AREA_ID %in% production_strata$STRATUM)
names(production_biomass)[names(production_biomass) == "AREA_ID"] <- "STRATUM"
## size composition (Change "AREA_ID" field name to "STRATUM")
production_sizecomp <- read.csv(file = "temp/production_sizecomp_EBS.csv")
production_sizecomp <- subset(x = production_sizecomp,
                              subset = AREA_ID %in% production_strata$STRATUM)
names(production_sizecomp)[names(production_sizecomp) == "AREA_ID"] <- "STRATUM"
## age-length key
production_alk <- read.csv(file = "temp/production/production_alk_EBS.csv")
## age composition
production_agecomp <- read.csv(file = "temp/production/production_agecomp_EBS.csv")
production_agecomp <- subset(x = production_agecomp,
                             subset = AREA_ID %in% production_strata$STRATUM)
names(production_agecomp)[names(production_agecomp) == "AREA_ID"] <- "STRATUM"

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## CPUE
historical_cpue <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT HAULJOIN, SPECIES_CODE, STRATUM, YEAR, ",
                                 "CPUE_KGHA, CPUE_NOHA FROM HAEHNR.CPUE_EBS_PLUSNW"))
historical_cpue <- cbind(historical_cpue[, c("HAULJOIN", "SPECIES_CODE",
                                             "STRATUM", "YEAR")],
                         CPUE_KGKM2 = historical_cpue$CPUE_KGHA * 100,
                         CPUE_NOKM2 = historical_cpue$CPUE_NOHA * 100)

## Stratum-level biomass
historical_biomass <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM, SPECIES_CODE, ",
                    "BIOMASS AS BIOMASS_MT, VARBIO AS BIOMASS_VAR, ", 
                    "POPULATION AS POPULATION_COUNT, ",
                    "VARPOP AS POPULATION_VAR, ",
                    "HAULCOUNT AS N_HAUL, CATCOUNT AS N_WEIGHT, ",
                    "NUMCOUNT AS N_COUNT, ",
                    "MEANWGTCPUE AS CPUE_KGKM2_MEAN, ", 
                    "VARMNWGTCPUE AS CPUE_KGKM2_VAR, ",
                    "MEANNUMCPUE AS CPUE_NOKM2_MEAN, ", 
                    "VARMNNUMCPUE AS CPUE_NOKM2_VAR FROM ",
                    "HAEHNR.BIOMASS_EBS_STANDARD WHERE STRATUM in ", 
                    gapindex::stitch_entries(production_strata$STRATUM))),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM, SPECIES_CODE, ",
                    "BIOMASS AS BIOMASS_MT, VARBIO AS BIOMASS_VAR, ", 
                    "POPULATION AS POPULATION_COUNT, ",
                    "VARPOP AS POPULATION_VAR, ",
                    "HAULCOUNT AS N_HAUL, CATCOUNT AS N_WEIGHT, ",
                    "NUMCOUNT AS N_COUNT, ",
                    "MEANWGTCPUE AS CPUE_KGKM2_MEAN, ", 
                    "VARMNWGTCPUE AS CPUE_KGKM2_VAR, ",
                    "MEANNUMCPUE AS CPUE_NOKM2_MEAN, ", 
                    "VARMNNUMCPUE AS CPUE_NOKM2_VAR FROM ",
                    "HAEHNR.BIOMASS_EBS_PLUSNW WHERE STRATUM IN (82, 90)")) 
)
historical_biomass$CPUE_KGKM2_MEAN <- historical_biomass$CPUE_KGKM2_MEAN * 100
historical_biomass$CPUE_KGKM2_VAR <- historical_biomass$CPUE_KGKM2_VAR * 10000
historical_biomass$CPUE_NOKM2_MEAN <- historical_biomass$CPUE_NOKM2_MEAN * 100
historical_biomass$CPUE_NOKM2_VAR <- historical_biomass$CPUE_NOKM2_VAR * 10000

## Stratum-level sizecomp
historical_sizecomp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM, SPECIES_CODE, ",
                    "LENGTH AS LENGTH_MM, ",
                    "TOTAL AS POPULATION_COUNT FROM ", 
                    "HAEHNR.SIZECOMP_EBS_STANDARD_STRATUM ",
                    "WHERE STRATUM != 999999")),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM, SPECIES_CODE, ",
                    "LENGTH AS LENGTH_MM, ",
                    "TOTAL AS POPULATION_COUNT FROM ", 
                    "HAEHNR.SIZECOMP_EBS_PLUSNW_STRATUM ",
                    "WHERE STRATUM in (82, 90)"))
)

## Stratum-level agecomp
historical_agecomp <- RODBC::sqlQuery(channel = sql_channel,
                                      query = paste0(
                                        "SELECT YEAR, STRATUM, SPECIES_CODE, ",
                                        "SEX, AGE, AGEPOP as POPULATION_COUNT FROM ", 
                                        "HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM ",
                                        "WHERE STRATUM != 999999"))

historical_agecomp$SEX[historical_agecomp$SEX == 9 & 
                         historical_agecomp$AGE == -99] <- 3



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import CPUE tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Truncate `production_cpue` values to match those in `historical_cpue`
production_cpue$CPUE_KGKM2 <- round(x = production_cpue$CPUE_KGKM2, 2)
production_cpue$CPUE_NOKM2 <- round(x = production_cpue$CPUE_NOKM2, 2)
historical_cpue$CPUE_KGKM2 <- round(x = historical_cpue$CPUE_KGKM2, 2)
historical_cpue$CPUE_NOKM2 <- round(x = historical_cpue$CPUE_NOKM2, 2)

nrow(historical_cpue)
nrow(production_cpue)

length(unique(historical_cpue$SPECIES_CODE))
length(unique(production_cpue$SPECIES_CODE))

## Merge CPUE tables using HAULJOIN and SPECIES_CODE as a composite key. 
test_cpue <-
  merge(x = subset(x = production_cpue,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE),
                   select = c(HAULJOIN, SPECIES_CODE, YEAR, STRATUM,
                              WEIGHT_KG, COUNT, CPUE_KGKM2, CPUE_NOKM2)), 
        y = subset(x = historical_cpue,
                   subset = SPECIES_CODE %in% 
                     unique(x = production_cpue$SPECIES_CODE)),
        by = c("HAULJOIN", "SPECIES_CODE", "STRATUM", "YEAR"),
        all.x = TRUE, all.y = TRUE, suffixes = c("_prod", "_hist"))

## Calculate difference between reported weight and count. If these are 
## different then the CPUE values will also be different. 
test_cpue$CPUE_KGKM2 <- with(test_cpue, CPUE_KGKM2_hist - CPUE_KGKM2_prod)
test_cpue$CPUE_NOKM2 <- with(test_cpue, CPUE_NOKM2_hist - CPUE_NOKM2_prod)

## Subset mismatched records
mismatch_cpue <- subset(x = test_cpue, 
                        subset = CPUE_NOKM2 != 0 | CPUE_KGKM2 != 0 |
                          is.na(CPUE_NOKM2) | is.na(CPUE_KGKM2))
mismatch_cpue <- subset(x = mismatch_cpue, 
                        subset = !(is.na(x = CPUE_NOKM2_hist) & 
                                     is.na(x = CPUE_NOKM2_prod) & 
                                     CPUE_KGKM2 == 0))

## Remove zero-filled records for instances when taxa are split during the 
## time series. Rock soles (10260) were used from 1982-1995 and were then
## split into northern and southern rock soles (10261, 10262). So there are 
## at least for now zero-filled records for NRS/SRS from 1982-1995 when they
## should removed (not a true zero, per se) From 1996-on 10260 is not used
## so those zero-filled records are also removed.  
with(subset(x = mismatch_cpue, 
            subset = (!is.na(x = CPUE_KGKM2_prod) & 
                        is.na(x = CPUE_KGKM2_hist)) ),
     table(YEAR, SPECIES_CODE))

mismatch_cpue <- subset(x = mismatch_cpue, 
                        subset = !(!is.na(x = CPUE_KGKM2_prod) & 
                                     is.na(x = CPUE_KGKM2_hist)) )

## Merge current WEIGHT and NUMBER_FISH from RACEBASE.CATCH to mismatch_cpue
mismatch_cpue <- merge(x = mismatch_cpue, all.x = TRUE,
                       y = production_data$catch,
                       by = c("HAULJOIN", "SPECIES_CODE"))

## Take note of those records where there was an observed catch record in the 
## historical tables but does not exist in RACEBASE.CATCH anymore
mismatch_cpue$NOTES[is.na(x = mismatch_cpue$NUMBER_FISH) & 
                      !is.na(x = mismatch_cpue$CPUE_NOKM2_hist)] <- 
  "record removed"

mismatch_cpue$NOTES[mismatch_cpue$CPUE_NOKM2_hist != mismatch_cpue$NUMBER_FISH] <-
  "record modified"

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Strata information and biomass tables. For the biomass comparison
##   only stratum-level estimates are being tested. However, in some regions,
##   there are some subareas that are just single strata with the same ID 
##   (e.g., 793 is an AI stratum and a subarea). Thus, when importing the 
##   production table, only unique record are imported.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Trim decimal places of production biomass
production_biomass$BIOMASS_MT <- 
  round(x = production_biomass$BIOMASS_MT, digits = 2)
production_biomass$BIOMASS_VAR <- 
  round(x = production_biomass$BIOMASS_VAR, digits = 4)
production_biomass$POPULATION_COUNT <- 
  round(x = production_biomass$POPULATION_COUNT, digits = 0)
production_biomass$CPUE_NOKM2_MEAN <- 
  round(x = production_biomass$CPUE_NOKM2_MEAN, digits = 2)
production_biomass$CPUE_NOKM2_VAR <- 
  round(x = production_biomass$CPUE_NOKM2_VAR, digits = 6)
production_biomass$CPUE_KGKM2_MEAN <- 
  round(x = production_biomass$CPUE_KGKM2_MEAN, digits = 2)
production_biomass$CPUE_KGKM2_VAR <- 
  round(x = production_biomass$CPUE_KGKM2_VAR, digits = 6)

nrow(historical_biomass)
nrow(production_biomass)

length(unique(historical_biomass$SPECIES_CODE))
length(unique(production_biomass$SPECIES_CODE))

hist_non_obs_taxa <- subset(x = stats::aggregate(CPUE_NOKM2_MEAN ~ SPECIES_CODE, 
                                                 FUN = sum, 
                                                 data = historical_biomass), 
                            subset = CPUE_NOKM2_MEAN  == 0)$SPECIES_CODE
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

test_biomass$CPUE_NOKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_VAR_PROD - CPUE_NOKM2_VAR_HIST) / ifelse(CPUE_NOKM2_VAR_HIST == 0, 1, CPUE_NOKM2_VAR_HIST) ))
test_biomass$CPUE_NOKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_MEAN_PROD - CPUE_NOKM2_MEAN_HIST) / ifelse(CPUE_NOKM2_MEAN_HIST == 0, 1, CPUE_NOKM2_MEAN_HIST) ))

test_biomass$CPUE_KGKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_VAR_PROD - CPUE_KGKM2_VAR_HIST) / ifelse(CPUE_KGKM2_VAR_HIST == 0, 1, CPUE_KGKM2_VAR_HIST) ))
test_biomass$CPUE_KGKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_MEAN_PROD - CPUE_KGKM2_MEAN_HIST) / ifelse(CPUE_KGKM2_MEAN_HIST == 0, 1, CPUE_KGKM2_MEAN_HIST) ))

test_biomass$BIOMASS_MT <- 
  with(test_biomass, round(100 * (BIOMASS_MT_PROD - BIOMASS_MT_HIST) / ifelse(BIOMASS_MT_HIST == 0, 1, BIOMASS_MT_HIST)))
test_biomass$BIOMASS_VAR <- 
  with(test_biomass, round(100 * (BIOMASS_VAR_PROD - BIOMASS_VAR_HIST) / ifelse(BIOMASS_VAR_HIST == 0, 1, BIOMASS_VAR_HIST)))

test_biomass$POPULATION_COUNT <- 
  with(test_biomass, round(100 * (POPULATION_COUNT_PROD - POPULATION_COUNT_HIST) / ifelse(POPULATION_COUNT_HIST == 0, 1, POPULATION_COUNT_HIST)))
test_biomass$POPULATION_VAR <- 
  with(test_biomass, round(100 * (POPULATION_VAR_PROD - POPULATION_VAR_HIST) / ifelse(POPULATION_VAR_HIST == 0, 1, POPULATION_VAR_HIST)))

test_biomass$N_HAUL <- with(test_biomass, N_HAUL_PROD - N_HAUL_HIST)

## Subset mismatched records
mismatched_biomass <- subset(test_biomass, 
                             CPUE_NOKM2_MEAN != 0 | is.na(CPUE_NOKM2_MEAN) |
                               CPUE_NOKM2_VAR != 0 | is.na(CPUE_NOKM2_VAR) |
                               CPUE_KGKM2_MEAN != 0 | is.na(CPUE_KGKM2_MEAN) |
                               CPUE_KGKM2_VAR != 0 | is.na(CPUE_KGKM2_VAR) )

mismatched_biomass$NOTES <- NA

## Note those records of new species_code values. e.g., rock soles were lumped
## together with one species code prior to 1996 and then split into two
## distinct species codes. So prior to 1996 there will not be records for the 
## two rock soles and after 1996, there will not be records for rock soles unid 

mismatched_biomass$NOTES[!is.na(mismatched_biomass$N_HAUL_PROD) & 
                           is.na(mismatched_biomass$N_HAUL_HIST)] <-
  "split_taxon"

mismatched_biomass$NOTES[mismatched_biomass$N_WEIGHT_HIST != 
                           mismatched_biomass$N_COUNT_HIST] <- "missing_counts"

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

subset(mismatched_biomass, is.na(NOTES))
table(mismatched_biomass$NOTES)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import sizecomp tables. For the sizecomp comparison, we will only compare
##   the total sex-aggregated size compositions at the stratum-level. 
##   In some regions, there are some subareas that are just single strata with 
##   the same ID (e.g., 793 is an AI stratum and a subarea). Thus, when 
##   importing the production table, only unique record are imported. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Lump size composition by sex
production_sizecomp <-
  stats::aggregate(POPULATION_COUNT ~ YEAR + STRATUM + SPECIES_CODE + LENGTH_MM,
                   FUN = sum,
                   data = production_sizecomp)

nrow(historical_sizecomp)
nrow(production_sizecomp)

length(unique(historical_sizecomp$SPECIES_CODE))
length(unique(production_sizecomp$SPECIES_CODE))

## Merge SIZECOMP tables using YEAR, STRATUM, SPECIES_CODE, and LENGTH_MM
## as a composite key. 
test_sizecomp <- 
  merge(x = subset(production_sizecomp,
                   SPECIES_CODE %in% unique(historical_sizecomp$SPECIES_CODE)),
        y = historical_sizecomp,
        by = c("YEAR", "STRATUM", "SPECIES_CODE", "LENGTH_MM"),
        all.x = TRUE, all.y = TRUE, suffixes = c("_PROD", "_HIST"))

## Calculate difference between size comps
test_sizecomp$DIFF <- with(test_sizecomp, round(100 * abs(POPULATION_COUNT_PROD  - POPULATION_COUNT_HIST) / ifelse(POPULATION_COUNT_HIST == 0, 1, POPULATION_COUNT_HIST)))

## Subset mismatched records and then calculate the percent difference. 
## Size comps can be really big and so values may be slightly different just
## due to truncation errors. Thus we subset values with >0.5% difference. 
mismatched_sizecomp <- subset(test_sizecomp, DIFF != 0 | is.na(DIFF))
mismatched_sizecomp$PERC_DIFF <- round(x = 100 * mismatched_sizecomp$DIFF / 
                                         mismatched_sizecomp$POPULATION_COUNT_prod)
mismatched_sizecomp <- subset(x = mismatched_sizecomp, 
                              PERC_DIFF != 0 | is.na(PERC_DIFF))

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

# unique_mismatched_sizecomp <-
#   unique(subset(x = mismatched_sizecomp,
#                 is.na(NOTES),
#                 select = c(YEAR, STRATUM, SPECIES_CODE)))
# 
# test <- merge(x = unique_mismatched_sizecomp,
#               y = test_biomass[, c("YEAR", "STRATUM", "SPECIES_CODE",
#                                    "POPULATION_COUNT_prod",
#                                    "POPULATION_COUNT_hist")],
#               by = c("YEAR", "STRATUM", "SPECIES_CODE"),
#               all.x = TRUE)
# 
# test$DIFF <- abs(floor(100 * abs(test$POPULATION_COUNT_prod - test$POPULATION_COUNT_hist) /
#                          test$POPULATION_COUNT_hist))
# nrow(subset(test, DIFF != 0))
# test <- subset(test, DIFF == 0)
# 
# for (irow in 1:nrow(test)) {
#   temp_sizecomp <-
#     colSums(subset(test_sizecomp,
#                    YEAR == test$YEAR[irow] & 
#                      SPECIES_CODE == test$SPECIES_CODE[irow] & 
#                      STRATUM == test$STRATUM[irow]), 
#             na.rm = TRUE)
#   
#   temp_bio <-
#     subset(test_biomass,
#            YEAR == test$YEAR[irow] & SPECIES_CODE == test$SPECIES_CODE[irow] & STRATUM == test$STRATUM[irow])
#   
#   temp_bio$POPULATION_COUNT <- floor(100 * abs(temp_bio$POPULATION_COUNT_hist -
#                                                  temp_bio$POPULATION_COUNT_prod) / 
#                                        temp_bio$POPULATION_COUNT_prod)
#   
#   match_with_count <- floor(100 * abs(temp_sizecomp[ c("POPULATION_COUNT", "TOTAL")] - temp_bio[, c("POPULATION_COUNT_prod", "POPULATION_COUNT_hist")]) / temp_bio[, c("POPULATION_COUNT_prod", "POPULATION_COUNT_hist")])
#   
#   test[irow, c("summed_lengths_prod", "summed_lengths_hist")] <- match_with_count
#   
#   if (match_with_count$POPULATION_COUNT_prod == 0 &
#       match_with_count$POPULATION_COUNT_hist != 0) {
#     mismatched_sizecomp$NOTES[
#       which(
#         mismatched_sizecomp$YEAR == test$YEAR[irow] &
#           mismatched_sizecomp$SPECIES_CODE == test$SPECIES_CODE[irow] &
#           mismatched_sizecomp$STRATUM == test$STRATUM[irow]
#       )
#     ] <- "sizecomp_doesnt_addup"
#   }
#   
#   if (temp_bio$POPULATION_COUNT != 0) {
#     mismatched_sizecomp$NOTES[
#       which(
#         mismatched_sizecomp$YEAR == test$YEAR[irow] &
#           mismatched_sizecomp$SPECIES_CODE == test$SPECIES_CODE[irow] &
#           mismatched_sizecomp$STRATUM == test$STRATUM[irow]
#       )
#     ] <- "mismatched_abundance"
#   }
#   
# }
# 
# with(subset(mismatched_sizecomp, is.na(NOTES)),
#      table(YEAR, SPECIES_CODE, STRATUM))
# 
# subset(historical_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)
# sum(subset(historical_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)$TOTAL)
# 
# subset(production_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)
# sum(subset(production_sizecomp0, YEAR == 1999 & STRATUM == 122 & SPECIES_CODE == 30152)$POP)


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Age comps
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_hauls_w_neg <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT * FROM RACEBASE.HAUL WHERE HAUL_TYPE = 3 ",
                    "AND STATIONID IS NOT NULL ",
                    "AND STRATUM IN (10,20,31,32,41,42,43,50,61,62,82,90)"))
production_specimen_w_neg <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM RACEBASE.SPECIMEN ",
                                 "WHERE REGION = 'BS' AND AGE >= 0"))
production_specimen_w_neg2 <- 
  subset(x = production_specimen_w_neg,
         subset = HAULJOIN %in% production_hauls_w_neg$HAULJOIN)

all_specimen <- production_specimen_w_neg2
all_specimen$YEAR <- as.integer(x = substr(x = all_specimen$CRUISE,
                                           start = 1,
                                           stop = 4))
all_specimen <- 
  subset(x = all_specimen,
         subset = YEAR >= 1987 &
           SPECIES_CODE %in% unique(x = historical_agecomp$SPECIES_CODE))
all_specimen$STRATUM <- 
  production_data$haul$STRATUM[match(x = all_specimen$HAULJOIN, 
                                     table = production_data$haul$HAULJOIN)]

all_specimen_good_hauls <-
  production_data$specimen
all_specimen_good_hauls$STRATUM <-
  production_data$haul$STRATUM[match(all_specimen_good_hauls$HAULJOIN,
                                     production_data$haul$HAULJOIN)]

all_specimen_good_hauls$YEAR <-
  as.integer(x = substr(x = all_specimen_good_hauls$CRUISE,
                        start = 1,
                        stop = 4))

length(x = sort(unique(x = historical_agecomp$SPECIES_CODE)))
length(x = sort(unique(x = production_alk$SPECIES_CODE)))

sample_size_all <-
  stats::aggregate(HAULJOIN ~ YEAR + SPECIES_CODE ,
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

nrow(historical_agecomp)
nrow(production_agecomp)

length(unique(historical_agecomp$SPECIES_CODE))
length(unique(production_agecomp$SPECIES_CODE))

test_agecomp <- 
  merge(x = subset(x = production_agecomp, 
                   subset = YEAR >= 1987 & YEAR < 2020), 
        y = subset(x = historical_agecomp, 
                   subset = POPULATION_COUNT > 0 & 
                     SPECIES_CODE %in% unique(x = production_agecomp$SPECIES_CODE) & SEX != 9 & YEAR < 2020),
        by = c("YEAR", "STRATUM", "SPECIES_CODE", "SEX", "AGE"),
        all.x = TRUE, all.y = TRUE, 
        suffixes = c("_prod", "_hist"))

## Filter out rows where we expect there to be a difference in the age 
## composition because of the inclusion of specimen data from hauls with 
## negative performance.

for (irow in 1:nrow(x = sample_size_all)) {
  test_agecomp <- 
    subset(x = test_agecomp,
           subset = !(YEAR == sample_size_all$YEAR[irow] &
                        SPECIES_CODE == sample_size_all$SPECIES_CODE[irow]))
}

test_agecomp$POPULATION_COUNT <-
  with(test_agecomp,
       round(100 * abs(POPULATION_COUNT_prod -
                         POPULATION_COUNT_hist) /
               ifelse(test = POPULATION_COUNT_hist != 0,
                      yes = POPULATION_COUNT_hist,
                      no = 1)))

mismatched_agecomp <- subset(x = test_agecomp, POPULATION_COUNT != 0 | is.na(POPULATION_COUNT & AGE >= 0))

nrow(mismatched_agecomp)
mismatched_agecomp$NOTES <- NA

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

unique_mismatched_biomass <-  
  unique(x = subset(x = mismatched_biomass,
                    subset = STRATUM != 999 & SPECIES_CODE %in% 
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

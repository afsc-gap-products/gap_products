##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare historical data product tables with those produced
##                with the most recent run production tables currently in the 
##                temp/ folder
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
                                 SELECT DISTINCT REGION, HAULJOIN, 
                                 FLOOR(CRUISE/100) YEAR 
                                 FROM RACEBASE.HAUL
                                 WHERE REGION IN ('AI', 'GOA')) 
                                 haul ON cpue.HAULJOIN = haul.HAULJOIN; "))
production_cpue$SURVEY_DEFINITION_ID <-
  ifelse(test = production_cpue$REGION == "AI", yes = 52, no = 47)
production_cpue <- subset(x = production_cpue,
                          select = -c(HAULJOIN.1, REGION))

## Biomass
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT * FROM GAP_PRODUCTS.BIOMASS
                           BIOMASS
                                 
                           INNER JOIN (
                           SELECT AREA_ID FROM GAP_PRODUCTS.AREA 
                            WHERE
                            (SURVEY_DEFINITION_ID = 47 
                            AND DESIGN_YEAR = 1984 
                            AND TYPE = 'STRATUM')
                            OR
                            (SURVEY_DEFINITION_ID = 52
                            AND DESIGN_YEAR = 1980 
                            AND TYPE = 'STRATUM')
                            ) STRATUM
                                 
                            ON BIOMASS.AREA_ID = STRATUM.AREA_ID
                            WHERE BIOMASS.SURVEY_DEFINITION_ID IN (47, 52)")

## Size composition
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT * FROM GAP_PRODUCTS.SIZECOMP SIZECOMP
                          INNER JOIN (
                           SELECT AREA_ID FROM GAP_PRODUCTS.AREA 
                             WHERE
                             (SURVEY_DEFINITION_ID = 47 
                             AND DESIGN_YEAR = 1984 
                             AND TYPE = 'STRATUM')
                             OR
                             (SURVEY_DEFINITION_ID = 52
                             AND DESIGN_YEAR = 1980 
                             AND TYPE = 'STRATUM')
                             ) STRATUM
                                 
                             ON SIZECOMP.AREA_ID = STRATUM.AREA_ID
                             WHERE SIZECOMP.SURVEY_DEFINITION_ID IN (47, 52)")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables from GOA Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
historical_cpue <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, HAULJOIN, SPECIES_CODE,
                    WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT,
                    WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2
                    FROM GOA.CPUE WHERE YEAR >= 1993")),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, HAULJOIN, SPECIES_CODE,
                    WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT,
                    WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2
                    FROM AI.CPUE WHERE YEAR >= 1991"))
)

historical_biomass <- 
  rbind(
    ## Biomass by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 47 SURVEY_DEFINITION_ID, 
                      YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                      HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                      MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, 
                      VAR_WGT_CPUE AS CPUE_KGKM2_VAR,
                      MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN,
                      VAR_NUM_CPUE AS CPUE_NOKM2_VAR,
                      STRATUM_BIOMASS AS BIOMASS_MT, 
                      BIOMASS_VAR,
                      STRATUM_POP AS POPULATION_COUNT,
                      POP_VAR AS POPULATION_VAR
                      FROM GOA.BIOMASS_STRATUM WHERE YEAR >= 1993")),
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 52 SURVEY_DEFINITION_ID,
                      YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                      HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                      MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN,
                      VAR_WGT_CPUE AS CPUE_KGKM2_VAR,
                      MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN,
                      VAR_NUM_CPUE AS CPUE_NOKM2_VAR,
                      STRATUM_BIOMASS AS BIOMASS_MT,
                      BIOMASS_VAR,
                      STRATUM_POP AS POPULATION_COUNT,
                      POP_VAR AS POPULATION_VAR
                      FROM AI.BIOMASS_STRATUM WHERE YEAR >= 1991"))
  )

historical_biomass <- 
  subset(x = historical_biomass,
         subset = SPECIES_CODE %in% 
           unique(x = production_biomass$SPECIES_CODE))
historical_biomass <- 
  subset(x = historical_biomass,
         subset = !SPECIES_CODE %in% c(150, 400, 21200, 21300, 23000, 23800, 
                                       66000, 78010, 79000))

historical_sizecomp <-
  rbind(
    ## Sizecomp by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 47 SURVEY_DEFINITION_ID, YEAR, 
                      STRATUM AS AREA_ID, SPECIES_CODE, LENGTH as LENGTH_MM, 
                      MALES, FEMALES, UNSEXED 
                      FROM GOA.SIZECOMP_STRATUM WHERE YEAR >= 1993")),
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 52 SURVEY_DEFINITION_ID, YEAR, 
                      STRATUM AS AREA_ID, SPECIES_CODE,
                      LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED
                      FROM AI.SIZECOMP_STRATUM WHERE YEAR >= 1991"))
  )


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
##   CPUE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
nrow(historical_cpue)
nrow(production_cpue)

length(unique(historical_cpue$SPECIES_CODE))
length(unique(production_cpue$SPECIES_CODE))

## Query any taxa not observed in the historical dataset. These would not
## be in the production dataset. 
historical_cpue <- subset(x = historical_cpue,
                          subset = SPECIES_CODE %in% 
                            unique(x = production_cpue$SPECIES_CODE))
historical_cpue <- subset(x = historical_cpue,
                          subset = !SPECIES_CODE %in% c(150, 400,21200, 21300, 
                                                        23000, 23800, 66000, 
                                                        78010, 79000))

## Merge CPUE tables using HAULJOIN and SPECIES_CODE as a composite key. 
test_cpue <- merge(x = historical_cpue,
                   y = production_cpue, 
                   by = c("YEAR", "HAULJOIN", "SPECIES_CODE"),
                   all.x = TRUE, suffixes = c("_hist", "_prod"))

## Calculate difference between reported weight and count. If these are 
## different then the CPUE values will also be different. 
test_cpue$WEIGHT_KG <- with(test_cpue, WEIGHT_KG_prod - WEIGHT_KG_hist )
test_cpue$COUNT <- with(test_cpue, COUNT_prod - COUNT_hist )

test_cpue$CPUE_KGKM2 <- 
  with(test_cpue, round(CPUE_KGKM2_prod - CPUE_KGKM2_hist, 5 ))
test_cpue$CPUE_NOKM2 <- 
  with(test_cpue, round(CPUE_NOKM2_prod - CPUE_NOKM2_hist, 5 ))

## Subset mismatched records
mismatch_cpue <- subset(x = test_cpue, 
                        subset = is.na(COUNT) | COUNT != 0 | 
                          WEIGHT_KG != 0 | is.na(WEIGHT_KG) |
                          CPUE_KGKM2 != 0 | is.na(CPUE_KGKM2) |
                          CPUE_NOKM2 != 0 | is.na(CPUE_NOKM2))
mismatch_cpue$NOTE <- ""
mismatch_cpue$NOTE[mismatch_cpue$COUNT_hist == 0 & 
                     is.na(x = mismatch_cpue$COUNT_prod)] <- 
  "pos wgt w/ no count"

pos_wgt_no_count <- 
  unique(x = subset(x = mismatch_cpue,
                    subset = NOTE != "",
                    select = c("SPECIES_CODE", "YEAR", "AREA_ID")))


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Biomass Tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Merge BIOMASS tables using YEAR, STRATUM, AND SPECIES_CODE as composite key. 
test_biomass <- merge(x = historical_biomass,
                      y = production_biomass,
                      by = c("SURVEY_DEFINITION_ID", "YEAR", 
                             "AREA_ID", "SPECIES_CODE"),
                      all.x = TRUE, suffixes = c("_HIST", "_PROD"))

test_biomass_digits <-
  apply(X = subset(x = test_biomass,
                   select = as.vector(sapply(X = c("CPUE_NOKM2_MEAN",
                                                   "CPUE_KGKM2_MEAN"),
                                             FUN = function(x)
                                               paste0(x, c("_PROD",
                                                           "_HIST"))))),
        MARGIN = 1:2,
        FUN = decimalplaces)



test_biomass$CPUE_NOKM2_MEAN_PROD <-
  round(x = test_biomass$CPUE_NOKM2_MEAN_PROD,
        digits = apply(X = test_biomass_digits[, c("CPUE_NOKM2_MEAN_HIST",
                                                   "CPUE_NOKM2_MEAN_PROD")],
                       MARGIN = 1, FUN = min))
test_biomass$CPUE_NOKM2_MEAN_HIST <-
  round(x = test_biomass$CPUE_NOKM2_MEAN_HIST,
        digits = apply(X = test_biomass_digits[, c("CPUE_NOKM2_MEAN_HIST",
                                                   "CPUE_NOKM2_MEAN_PROD")],
                       MARGIN = 1, FUN = min))

test_biomass$CPUE_KGKM2_MEAN_PROD <-
  round(x = test_biomass$CPUE_KGKM2_MEAN_PROD,
        digits = apply(X = test_biomass_digits[, c("CPUE_KGKM2_MEAN_HIST",
                                                   "CPUE_KGKM2_MEAN_PROD")],
                       MARGIN = 1, FUN = min))
test_biomass$CPUE_KGKM2_MEAN_HIST <-
  round(x = test_biomass$CPUE_KGKM2_MEAN_HIST,
        digits = apply(X = test_biomass_digits[, c("CPUE_KGKM2_MEAN_HIST",
                                                   "CPUE_KGKM2_MEAN_PROD")],
                       MARGIN = 1, FUN = min))

test_biomass$BIOMASS_MT_HIST <-
  round(x = test_biomass$BIOMASS_MT_HIST, digits = 0)
test_biomass$BIOMASS_MT_PROD <-
  round(x = test_biomass$BIOMASS_MT_PROD, digits = 0)
test_biomass$POPULATION_COUNT_PROD <-
  round(x = test_biomass$POPULATION_COUNT_PROD, digits = 0)
test_biomass$CPUE_KGKM2_VAR_HIST <- 
  round(x = test_biomass$CPUE_KGKM2_VAR_HIST, digits = 6)
test_biomass$BIOMASS_VAR_HIST <- 
  round(x = test_biomass$BIOMASS_VAR_HIST, digits = 6)

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

test_biomass$BIOMASS_MT <- 
  round(x = with(test_biomass, calc_diff(v1 = BIOMASS_MT_PROD, 
                                         v2 = BIOMASS_MT_HIST)),
        digits = 2)
test_biomass$BIOMASS_MT_abs <- 
  with(test_biomass, calc_diff(v1 = BIOMASS_MT_PROD, 
                               v2 = BIOMASS_MT_HIST,
                               percent = FALSE))

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
mismatched_biomass$NOTE = ""

## Remove stratum biomass records that would contain a mismatched haul
for (irow in 1:nrow(x = pos_wgt_no_count)){
  mismatched_biomass$NOTE[
    with(mismatched_biomass,
         SPECIES_CODE == pos_wgt_no_count$SPECIES_CODE[irow] & 
           YEAR == pos_wgt_no_count$YEAR[irow] & 
           AREA_ID == pos_wgt_no_count$AREA_ID[irow])
  ] <- "mismatched cpue"
}

mismatched_biomass$NOTE[
  with(mismatched_biomass, N_WEIGHT_HIST != N_WEIGHT_PROD)
] <- "diff n_weight"

mismatched_biomass$NOTE[
  with(mismatched_biomass, N_HAUL != 0)
] <- "diff n_haul"

mismatched_biomass$NOTE[
  with(mismatched_biomass, 
       N_HAUL_HIST == 1 & CPUE_NOKM2_MEAN == 0 & 
         CPUE_NOKM2_MEAN_HIST == 0 & 
         is.na(x = CPUE_KGKM2_VAR) & 
         is.na(x = CPUE_NOKM2_VAR))
] <- "truncation error"

mismatched_biomass$NOTE[
  with(mismatched_biomass, abs(BIOMASS_MT_abs) <= 1)
] <- "truncation error"

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
                       by = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID", 
                              "SPECIES_CODE", "LENGTH_MM", "SEX"),
                       suffixes = c("_hist", "_prod"))

## Calculate difference between size comps
test_sizecomp$POPULATION_COUNT <- 
  with(test_sizecomp, round(x = calc_diff(POPULATION_COUNT_prod,
                                          POPULATION_COUNT_hist),
                            digits = 0))

## Subset mismatched records and then calculate the percent difference. 
## Size comps can be really big and so values may be slightly different just
## due to truncation errors. Thus we subset values with >0.5% difference. 
mismatched_sizecomp <- subset(test_sizecomp, POPULATION_COUNT != 0)
mismatched_sizecomp$NOTE <- ""

for (irow in 1:nrow(x = mismatched_biomass)){
  mismatched_sizecomp$NOTE[
    with(mismatched_sizecomp,
         SPECIES_CODE == mismatched_biomass$SPECIES_CODE[irow] & 
           YEAR == mismatched_biomass$YEAR[irow] & 
           AREA_ID == mismatched_biomass$AREA_ID[irow])
  ] <- "mismatched abundance"
}
table(mismatched_sizecomp$NOTE)
unique_size <- 
  unique(subset(mismatched_sizecomp, NOTE == "",
                select = c(SURVEY_DEFINITION_ID, YEAR, AREA_ID, SPECIES_CODE)))

unique_size$NOTE <- ""

for (irow in 1:nrow(x = unique_size)) {
  summed_hist <- 
    sum(subset(x = historical_sizecomp, 
               subset = SURVEY_DEFINITION_ID == unique_size$SURVEY_DEFINITION_ID[irow] &
                 YEAR == unique_size$YEAR[irow] & 
                 AREA_ID == unique_size$AREA_ID[irow] & 
                 SPECIES_CODE == unique_size$SPECIES_CODE[irow])$POPULATION)
  hist_abund <- 
    subset(x = historical_biomass, 
         subset = SURVEY_DEFINITION_ID == unique_size$SURVEY_DEFINITION_ID[irow] &
           YEAR == unique_size$YEAR[irow] & 
           AREA_ID == unique_size$AREA_ID[irow] & 
           SPECIES_CODE == unique_size$SPECIES_CODE[irow])$POPULATION_COUNT
         
  if(abs(100 * (hist_abund - summed_hist) / hist_abund) > 0.01) 
    unique_size$NOTE[irow] <- "mismatched_abundance"
}


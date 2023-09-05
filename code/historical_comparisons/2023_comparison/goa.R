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

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import production tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## gapindex data object
production_data <- readRDS(file = "temp/production/production_data_GOA.RDS")

## CPUE
production_cpue <- subset(x = read.csv(file = "temp/production/production_cpue_GOA.csv"),
                          YEAR == 2023)

## strata information
production_strata <- read.csv(file = paste0("temp/production/production_strata_GOA.csv"))

## subarea information
production_subarea <- read.csv(file = paste0("temp/production/production_subarea_GOA.csv"))

## stratum biomass
production_biomass <- 
  unique(x = subset(x = read.csv(file = "temp/production/production_biomass_GOA.csv"),
                    subset = YEAR == 2023))
## Change AREA_ID field name to STRATUM
# names(production_biomass)[names(production_biomass) == "AREA_ID"] <- "STRATUM" 

## stratum size composition
production_sizecomp <- 
  unique(x = subset(x = read.csv(file = "temp/production/production_sizecomp_GOA.csv"),
                    subset = YEAR == 2023))
production_sizecomp21 <- 
  unique(x = subset(x = read.csv(file = "temp/production/production_sizecomp_GOA.csv"),
                    subset = YEAR == 2021))
## Change AREA_ID field name to STRATUM
# names(x = production_sizecomp0)[names(x = production_sizecomp0) == "AREA_ID"] <- 
# "STRATUM" 
## Age-length key
production_alk <- read.csv(file = paste0("temp/production/production_alk_GOA.csv"))
# age composition
production_agecomp <- 
  subset(x = read.csv(file = "temp/production/production_agecomp_GOA.csv"),
         subset = YEAR == 2021 & AREA_ID == 99903,
         select = -c(AREA_ID, SURVEY, SURVEY_DEFINITION_ID))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
historical_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT HAULJOIN, SPECIES_CODE, ",
                    "WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT, ",
                    "WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2 ",
                    "FROM GOA.CPUE WHERE YEAR = 2023"))

historical_biomass <- 
  rbind(
    ## Biomass by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                      "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                      "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                      "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                      "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                      "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                      "STRATUM_BIOMASS AS BIOMASS_MT, ",
                      "BIOMASS_VAR, ",
                      "STRATUM_POP AS POPULATION_COUNT, ",
                      "POP_VAR AS POPULATION_VAR ",
                      " FROM GOA.BIOMASS_STRATUM WHERE YEAR = 2023")),
    
    ## Biomass by INPFC area
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, SUMMARY_AREA AS AREA_ID, SPECIES_CODE, ",
                      "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                      "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                      "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                      "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                      "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                      "AREA_BIOMASS AS BIOMASS_MT, ",
                      "BIOMASS_VAR, ",
                      "AREA_POP AS POPULATION_COUNT, ",
                      "POP_VAR AS POPULATION_VAR ",
                      " FROM GOA.BIOMASS_INPFC WHERE YEAR = 2023")),
    
    ## Biomass by Depth Bins
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, SUMMARY_DEPTH AS AREA_ID, SPECIES_CODE, ",
                      "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                      "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                      "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                      "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                      "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                      "AREA_BIOMASS AS BIOMASS_MT, ",
                      "BIOMASS_VAR, ",
                      "AREA_POP AS POPULATION_COUNT, ",
                      "POP_VAR AS POPULATION_VAR ",
                      " FROM GOA.BIOMASS_DEPTH WHERE YEAR = 2023")),
    
    ## Biomass by INPFC-Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, SUMMARY_AREA_DEPTH AS AREA_ID, SPECIES_CODE, ",
                      "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                      "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                      "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                      "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                      "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                      "AREA_BIOMASS AS BIOMASS_MT, ",
                      "BIOMASS_VAR, ",
                      "AREA_POP AS POPULATION_COUNT, ",
                      "POP_VAR AS POPULATION_VAR ",
                      " FROM GOA.BIOMASS_INPFC_DEPTH WHERE YEAR = 2023")),
    
    ## Biomass by Regulatory Area
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, ",
                      "CASE
                      WHEN REGULATORY_AREA_NAME = 'CENTRAL GOA' THEN 803
                      WHEN REGULATORY_AREA_NAME = 'WESTERN GOA' THEN 805
                      WHEN REGULATORY_AREA_NAME = 'EASTERN GOA' THEN 804
                      ELSE NULL
                   END AS AREA_ID, ",
                      "SPECIES_CODE, HAUL_COUNT as N_HAUL, ",
                      "CATCH_COUNT AS N_WEIGHT, ",
                      "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                      "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                      "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                      "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                      "AREA_BIOMASS AS BIOMASS_MT, ",
                      "BIOMASS_VAR, ",
                      "AREA_POP AS POPULATION_COUNT, ",
                      "POP_VAR AS POPULATION_VAR ",
                      " FROM GOA.BIOMASS_AREA WHERE YEAR = 2023")),
    
    ## Total Biomass
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, 99903 AREA_ID, SPECIES_CODE, ",
                      "HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT, ",
                      "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                      "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                      "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                      "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                      "TOTAL_BIOMASS AS BIOMASS_MT, ",
                      "BIOMASS_VAR, ",
                      "TOTAL_POP AS POPULATION_COUNT, ",
                      "POP_VAR AS POPULATION_VAR ",
                      " FROM GOA.BIOMASS_TOTAL WHERE YEAR = 2023"))
  )

historical_biomass <- 
  subset(x = historical_biomass,
         subset = !(AREA_ID %in% c(915, 925, 935, 945, 955, 995)))
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
                      "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                      "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                      " FROM GOA.SIZECOMP_STRATUM WHERE YEAR = 2023")) ,
    
    ## Sizecomp by INPFC area
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, SUMMARY_AREA AS AREA_ID, SPECIES_CODE, ",
                      "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                      " FROM GOA.SIZECOMP_INPFC WHERE YEAR = 2023")) ,
    
    ## Sizecomp by Depth Bins
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, SUMMARY_DEPTH AS AREA_ID, SPECIES_CODE, ",
                      "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                      " FROM GOA.SIZECOMP_DEPTH WHERE YEAR = 2023")) ,
    
    ## Sizecomp by INPFC-Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, SUMMARY_AREA_DEPTH AS AREA_ID, SPECIES_CODE, ",
                      "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                      " FROM GOA.SIZECOMP_INPFC_DEPTH WHERE YEAR = 2023")),
    
    ## Sizecomp by Regulatory Area
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, ",
                      "CASE
                      WHEN REGULATORY_AREA_NAME = 'CENTRAL GOA' THEN 803
                      WHEN REGULATORY_AREA_NAME = 'WESTERN GOA' THEN 805
                      WHEN REGULATORY_AREA_NAME = 'EASTERN GOA' THEN 804
                      ELSE NULL
                   END AS AREA_ID, SPECIES_CODE, ",
                      "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                      " FROM GOA.SIZECOMP_AREA WHERE YEAR = 2023")),
    
    ## Total Biomass
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT YEAR, 99903 AREA_ID, SPECIES_CODE, ",
                      "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                      " FROM GOA.SIZECOMP_TOTAL WHERE YEAR = 2023"))
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

historical_agecomp <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT SURVEY_YEAR as YEAR, SPECIES_CODE, ",
                                 "SEX, AGE, AGEPOP as POPULATION_COUNT, ",
                                 "MEAN_LENGTH AS LENGTH_MM_MEAN , ",
                                 "STANDARD_DEVIATION AS LENGTH_MM_SD FROM ",
                                 "GOA.AGECOMP_TOTAL WHERE SURVEY_YEAR = 2021"))
historical_agecomp$LENGTH_MM_MEAN <- round(historical_agecomp$LENGTH_MM_MEAN, 2)
historical_agecomp$LENGTH_MM_SD <- round(historical_agecomp$LENGTH_MM_SD, 2)
historical_agecomp$POPULATION_COUNT <- round(historical_agecomp$POPULATION_COUNT, 0)

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
test_cpue <-
  merge(x = subset(x = production_cpue,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE)), 
        y = historical_cpue,
        by = c("HAULJOIN", "SPECIES_CODE"),
        all = TRUE, suffixes = c("_prod", "_hist"))

## Calculate difference between reported weight and count. If these are 
## different then the CPUE values will also be different. 
test_cpue$WEIGHT_KG <- 
  with(test_cpue, WEIGHT_KG_prod - WEIGHT_KG_hist )
test_cpue$COUNT <- with(test_cpue, COUNT_prod - COUNT_hist )

test_cpue$CPUE_KGKM2 <- 
  with(test_cpue, round(CPUE_KGKM2_prod - CPUE_KGKM2_hist, 9 ))
test_cpue$CPUE_NOKM2 <- 
  with(test_cpue, round(CPUE_NOKM2_prod - CPUE_NOKM2_hist, 9 ))

## Subset mismatched records
mismatch_cpue <- subset(x = test_cpue, 
                        subset = is.na(COUNT) | COUNT != 0 | 
                          WEIGHT_KG != 0 | is.na(WEIGHT_KG) |
                          CPUE_KGKM2 != 0 | is.na(CPUE_KGKM2) |
                          CPUE_NOKM2 != 0 | is.na(CPUE_NOKM2))

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

test_biomass$BIOMASS_MT_PROD <-
  round(x = test_biomass$BIOMASS_MT_PROD, digits = 1)
test_biomass$POPULATION_COUNT_PROD <-
  round(x = test_biomass$POPULATION_COUNT_PROD, digits = 0)


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
           POPULATION_VAR != 0 | is.na(x = POPULATION_VAR))

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


# mismatched_biomass$CPUE_KGKM2_MEAN_PROD <- 
#   round(mismatched_biomass$CPUE_KGKM2_MEAN_PROD, 1)
# mismatched_biomass$CPUE_KGKM2_MEAN <-
#   with(mismatched_biomass, round(x = (CPUE_KGKM2_MEAN_PROD - CPUE_KGKM2_MEAN_HIST) / ifelse(CPUE_KGKM2_MEAN_HIST == 0, 1, CPUE_KGKM2_MEAN_HIST), 2) )

# mismatched_biomass$CPUE_NOKM2_MEAN_PROD <- 
#   round(mismatched_biomass$CPUE_NOKM2_MEAN_PROD, 1)
# mismatched_biomass$CPUE_NOKM2_MEAN <-
#   with(mismatched_biomass, round(x = (CPUE_NOKM2_MEAN_PROD - CPUE_NOKM2_MEAN_HIST) / ifelse(CPUE_NOKM2_MEAN_HIST == 0, 1, CPUE_NOKM2_MEAN_HIST), 2) )


mismatched_biomass <- 
  subset(x = mismatched_biomass, 
         subset = CPUE_NOKM2_MEAN != 0 | is.na(x = CPUE_NOKM2_MEAN) |
           CPUE_NOKM2_VAR != 0 | is.na(x = CPUE_NOKM2_VAR) |
           CPUE_KGKM2_MEAN != 0 | is.na(x = CPUE_KGKM2_MEAN) |
           CPUE_KGKM2_VAR != 0 | is.na(x = CPUE_KGKM2_VAR) | 
           BIOMASS_MT != 0 | is.na(x = BIOMASS_MT) |
           POPULATION_COUNT != 0 | is.na(x = POPULATION_COUNT) | 
           BIOMASS_VAR != 0 | is.na(x = BIOMASS_VAR) |
           POPULATION_VAR != 0 | is.na(x = POPULATION_VAR))
tail(mismatched_biomass)

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
                       y = subset(x = production_sizecomp,
                                  select = -c(SURVEY_DEFINITION_ID )),
                       by = c("YEAR", "AREA_ID", "SPECIES_CODE", "LENGTH_MM", "SEX"),
                       suffixes = c("_hist", "_prod"))

## Calculate difference between size comps
test_sizecomp$DIFF <- 
  with(test_sizecomp, POPULATION_COUNT_hist - POPULATION_COUNT_prod)

## Subset mismatched records and then calculate the percent difference. 
## Size comps can be really big and so values may be slightly different just
## due to truncation errors. Thus we subset values with >0.5% difference. 
mismatched_sizecomp <- subset(test_sizecomp, abs(DIFF) > 9)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Age comps
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
length(x = unique(x = production_agecomp$SPECIES_CODE))
length(x = unique(x = historical_agecomp$SPECIES_CODE))

test_agecomp <- merge(x = historical_agecomp,
                      y = subset(x = production_agecomp),
                      by = c("YEAR", "SPECIES_CODE", "AGE", "SEX"),
                      all.y = TRUE,
                      suffixes = c("_hist", "_prod"))

test_agecomp$POPULATION_COUNT <- 
  with(test_agecomp, POPULATION_COUNT_prod - POPULATION_COUNT_hist)
test_agecomp$LENGTH_MM_MEAN <- 
  with(test_agecomp, round(x = (LENGTH_MM_MEAN_prod - LENGTH_MM_MEAN_hist) / LENGTH_MM_MEAN_prod, 2))
test_agecomp$LENGTH_MM_SD <- 
  with(test_agecomp, round(x = (LENGTH_MM_SD_prod - LENGTH_MM_SD_hist) / ifelse(test = LENGTH_MM_SD_prod == 0, 1, LENGTH_MM_SD_prod), 2))

mismatched_age <- 
  subset(x = test_agecomp, 
         subset =  abs(POPULATION_COUNT) > 5000 | is.na(x = POPULATION_COUNT)) #|
           # LENGTH_MM_MEAN != 0 | is.na(x = LENGTH_MM_MEAN) |
           # LENGTH_MM_SD != 0 | is.na(x = LENGTH_MM_SD))

tail(mismatched_age)
test <- merge(x = subset(production_alk, 
                         YEAR == 2021 & SPECIES_CODE == 30060 & AGE == 32 & SEX == 3),
              y = subset(production_sizecomp21, 
                         subset = AREA_ID == 99903 & YEAR == 2021 &
                           SPECIES_CODE == 30060 & SEX == 3),
              by = c("YEAR", "SPECIES_CODE", "SEX", "LENGTH_MM"))

subset(test_agecomp, SPECIES_CODE == 30060 & AGE == 32 & SEX == 3)
weighted.mean(as.numeric(test$LENGTH_MM), test$POPULATION_COUNT)

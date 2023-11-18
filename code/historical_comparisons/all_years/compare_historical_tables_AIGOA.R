##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare historical data product tables with those produced
##                with the most recent run production tables currently in the 
##                temp/ folder
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())
options(scipen = 999)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import packages, connect to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(readxl)
library(gapindex)
library(reshape2)

sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import helper functions 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source(file = "functions/calc_diff.R")
source(file = "functions/compare_tables.R")

spp_year <- RODBC::sqlQuery(channel = sql_channel,
                            query = "SELECT * FROM GAP_PRODUCTS.SPECIES_YEAR")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import CPUE tables from GAP_PRODUCTS as historical AI/GOA schemata
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, HAULJOIN,
                           SPECIES_CODE, WEIGHT_KG, COUNT, AREA_SWEPT_KM2,
                           CPUE_KGKM2, CPUE_NOKM2 
                           FROM GAP_PRODUCTS.CPUE
                           
                           INNER JOIN (
                           SELECT DISTINCT 
                           CASE 
                            WHEN REGION = 'AI' THEN 52
                            WHEN REGION = 'GOA' THEN 47
                            ELSE NULL
                           END AS SURVEY_DEFINITION_ID, 
                           HAULJOIN, 
                           FLOOR(CRUISE/100) YEAR 
                           FROM RACEBASE.HAUL
                           WHERE REGION IN ('AI', 'GOA')) 
                           
                           USING (HAULJOIN)")

historical_cpue <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, HAULJOIN, SPECIES_CODE,
                    WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT,
                    WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2
                    FROM GOA.CPUE WHERE YEAR >= 1990")),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, HAULJOIN, SPECIES_CODE,
                    WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT,
                    WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2
                    FROM AI.CPUE WHERE YEAR >= 1991"))
)

## Merge CPUE tables using YEAR, HAULJOIN, and SPECIES_CODE as a composite key. 
test_cpue <- merge(x = historical_cpue,
                   y = production_cpue, 
                   by = c("YEAR", "HAULJOIN", "SPECIES_CODE"),
                   all = TRUE, suffixes = c("_HIST", "_PROD"))

eval_cpue <-     
  compare_tables(
    x = test_cpue,
    cols_to_check = data.frame(
      colname = c("CPUE_KGKM2", "CPUE_NOKM2"),
      percent = c(F, F),
      decplaces = c(2, 2)),
    base_table_suffix = "_HIST",
    update_table_suffix = "_PROD",
    key_columns = c("SURVEY_DEFINITION_ID", "YEAR", "HAULJOIN", "SPECIES_CODE"))

eval_cpue$new_records$NOTE <- ""

goa_hist_analysis_species_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SPECIES_CODE 
                           FROM GOA.ANALYSIS_SPECIES 
                           WHERE BIOMASS_FLAG IN ('GOA', 'BOTH')")$SPECIES_CODE
ai_hist_analysis_species_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SPECIES_CODE 
                           FROM GOA.ANALYSIS_SPECIES 
                           WHERE BIOMASS_FLAG IN ('AI', 'BOTH')")$SPECIES_CODE

eval_cpue$new_records$NOTE[
  !(eval_cpue$new_records$SPECIES_CODE %in% goa_hist_analysis_species_biomass
    & eval_cpue$new_records$SURVEY_DEFINITION_ID == 47) |
    !(eval_cpue$new_records$SPECIES_CODE %in% ai_hist_analysis_species_biomass
      & eval_cpue$new_records$SURVEY_DEFINITION_ID == 52) 
] <- "taxon now included"

table(eval_cpue$new_records$NOTE)

head(eval_cpue$removed_records)

eval_cpue$removed_records$NOTE = ""

for (irow in 1:nrow(x = spp_year)) 
  eval_cpue$removed_records$NOTE[
    eval_cpue$removed_records$SPECIES_CODE == spp_year$SPECIES_CODE[irow] 
    & eval_cpue$removed_records$YEAR < spp_year$YEAR_STARTED[irow]
  ] <- "before start year"

table(eval_cpue$removed_records$NOTE)

subset(eval_cpue$removed_records, NOTE == "")

ai_spp_nonobs <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT * FROM (SELECT SPECIES_CODE, 
                                          SUM(WEIGHT) WEIGHT_KG 
                                          FROM AI.CPUE 
                                          WHERE YEAR >= 1991
                                          GROUP BY SPECIES_CODE) 
                           WHERE WEIGHT_KG = 0")
goa_spp_nonobs <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT * FROM (SELECT SPECIES_CODE, 
                                          SUM(WEIGHT) WEIGHT_KG 
                                          FROM GOA.CPUE
                                          WHERE YEAR >= 1990
                                          GROUP BY SPECIES_CODE) 
                           WHERE WEIGHT_KG = 0")

eval_cpue$removed_records$NOTE[
  eval_cpue$removed_records$SPECIES_CODE %in% 
    c(ai_spp_nonobs$SPECIES_CODE, goa_spp_nonobs$SPECIES_CODE)
] <- "not observed"

subset(eval_cpue$removed_records, NOTE == "")

eval_cpue$removed_records$NOTE[
  eval_cpue$removed_records$CPUE_KGKM2_DIFF == 0 
  & eval_cpue$removed_records$CPUE_NOKM2_HIST == 0 
  & is.na(x = eval_cpue$removed_records$CPUE_NOKM2_PROD)
] <- "no count treated as zero" 

eval_cpue$modified_records$NOTE = ""

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Biomass tables from GAP_PRODUCTS as historical AI/GOA schemata
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
                           SPECIES_CODE, N_HAUL, N_WEIGHT, N_COUNT, N_LENGTH,
                           ROUND(CPUE_KGKM2_MEAN, 1) AS CPUE_KGKM2_MEAN, 
                           ROUND(CPUE_KGKM2_VAR, 2) AS CPUE_KGKM2_VAR, 
                           ROUND(CPUE_NOKM2_MEAN, 1) AS CPUE_NOKM2_MEAN, 
                           ROUND(CPUE_NOKM2_VAR, 2) AS CPUE_NOKM2_VAR, 
                           ROUND(BIOMASS_MT, 1) AS BIOMASS_MT, 
                           ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR, 
                           ROUND(POPULATION_COUNT) AS POPULATION_COUNT, 
                           ROUND(POPULATION_VAR) AS POPULATION_VAR
                           FROM GAP_PRODUCTS.BIOMASS BIOMASS
                           
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
                            ) 
                            USING (AREA_ID)
                            
                            WHERE BIOMASS.SURVEY_DEFINITION_ID IN (47, 52)")

historical_biomass <- 
  rbind(
    ## Biomass by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 47 SURVEY_DEFINITION_ID, 
                      YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                      HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                      MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, 
                      ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                      MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN,
                      ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                      STRATUM_BIOMASS AS BIOMASS_MT, 
                      ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                      STRATUM_POP AS POPULATION_COUNT,
                      POP_VAR AS POPULATION_VAR
                      FROM GOA.BIOMASS_STRATUM WHERE YEAR >= 1990")),
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 52 SURVEY_DEFINITION_ID,
                      YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                      HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                      MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN,
                      ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                      MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN,
                      ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                      STRATUM_BIOMASS AS BIOMASS_MT,
                      ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                      STRATUM_POP AS POPULATION_COUNT,
                      ROUND(POP_VAR) AS POPULATION_VAR
                      FROM AI.BIOMASS_STRATUM WHERE YEAR >= 1991"))
  )


# historical_biomass <- 
#   subset(x = historical_biomass,
#          subset = !SPECIES_CODE %in% c(150, 400, 21200, 21300, 23000, 23800, 
#                                        66000, 78010, 79000))

## Size composition
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE,
                           AREA_ID, LENGTH_MM, SEX, POPULATION_COUNT 
                           FROM GAP_PRODUCTS.SIZECOMP SIZECOMP
                          
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
                             ) 
                             
                             USING (AREA_ID)
                             
                             WHERE SIZECOMP.SURVEY_DEFINITION_ID IN (47, 52)")

historical_sizecomp <-
  rbind(
    ## Sizecomp by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 47 SURVEY_DEFINITION_ID, YEAR, 
                      STRATUM AS AREA_ID, SPECIES_CODE, LENGTH as LENGTH_MM, 
                      MALES, FEMALES, UNSEXED 
                      FROM GOA.SIZECOMP_STRATUM WHERE YEAR >= 1990")),
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

production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE,
                           AREA_ID, AGE, SEX, POPULATION_COUNT 
                           FROM GAP_PRODUCTS.AGECOMP AGECOMP
                          
                          INNER JOIN (
                           SELECT AREA_ID FROM GAP_PRODUCTS.AREA 
                             WHERE
                             (SURVEY_DEFINITION_ID = 47 
                             AND DESIGN_YEAR = 1984 
                             AND TYPE = 'REGION')
                             OR
                             (SURVEY_DEFINITION_ID = 52
                             AND DESIGN_YEAR = 1980 
                             AND TYPE = 'REGION')
                             ) 
                             
                             USING (AREA_ID)
                             
                             WHERE AGECOMP.SURVEY_DEFINITION_ID IN (47, 52)")

historical_agecomp <-
  rbind(
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 47 SURVEY_DEFINITION_ID, SURVEY_YEAR AS YEAR, 
                       SPECIES_CODE, 99903 AS AREA_ID, SEX, AGE, 
                       ROUND(AGEPOP) AS POPULATION_COUNT,
                       ROUND(MEAN_LENGTH, 2) AS LENGTH_MM_MEAN,
                       ROUND(STANDARD_DEVIATION, 2) AS LENGTH_MM_SD
                       FROM GOA.AGECOMP_TOTAL WHERE SURVEY_YEAR >= 1990")),
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0(
                      "SELECT 52 SURVEY_DEFINITION_ID, SURVEY_YEAR AS YEAR, 
                       SPECIES_CODE, 99904 AS AREA_ID, SEX, AGE,                        
                       ROUND(AGEPOP) AS POPULATION_COUNT,
                       ROUND(MEAN_LENGTH, 2) AS LENGTH_MM_MEAN,
                       ROUND(STANDARD_DEVIATION, 2) AS LENGTH_MM_SD
                       FROM GOA.AGECOMP_TOTAL WHERE SURVEY_YEAR >= 1991"))
  )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables from GOA Oracle schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# for (irow in 1:nrow(x = spp_year)) {
#   
#   historical_cpue <- 
#     subset(x = historical_cpue,
#            subset = !(SPECIES_CODE == spp_year$SPECIES_CODE[irow] & 
#                         YEAR < spp_year$YEAR_STARTED[irow]))  
#   historical_biomass <- 
#     subset(x = historical_biomass,
#            subset = !(SPECIES_CODE == spp_year$SPECIES_CODE[irow] & 
#                         YEAR < spp_year$YEAR_STARTED[irow]))
#   historical_sizecomp <- 
#     subset(x = historical_sizecomp,
#            subset = !(SPECIES_CODE == spp_year$SPECIES_CODE[irow] & 
#                         YEAR < spp_year$YEAR_STARTED[irow]))
#   historical_agecomp <- 
#     subset(x = historical_agecomp,
#            subset = !(SPECIES_CODE == spp_year$SPECIES_CODE[irow] & 
#                         YEAR < spp_year$YEAR_STARTED[irow]))
# }
# rm(irow)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   CPUE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~




## Calculate difference between reported weight and count. If these are 
## different then the CPUE values will also be different. 
test_cpue$WEIGHT_KG <- with(test_cpue, WEIGHT_KG_PROD - WEIGHT_KG_HIST )
test_cpue$COUNT <- with(test_cpue, COUNT_PROD - COUNT_HIST )

test_cpue$CPUE_KGKM2 <- 
  with(test_cpue, round(CPUE_KGKM2_PROD - CPUE_KGKM2_HIST, 5 ))
test_cpue$CPUE_NOKM2 <- 
  with(test_cpue, round(CPUE_NOKM2_PROD - CPUE_NOKM2_HIST, 5 ))

## Subset mismatched records
mismatch_cpue <- subset(x = test_cpue,
                        subset = is.na(COUNT) | COUNT != 0 |
                          WEIGHT_KG != 0 | is.na(WEIGHT_KG) |
                          CPUE_KGKM2 != 0 | is.na(CPUE_KGKM2) |
                          CPUE_NOKM2 != 0 | is.na(CPUE_NOKM2))


mismatch_cpue$NOTE <- ""
mismatch_cpue$NOTE[mismatch_cpue$COUNT_HIST == 0 & 
                     is.na(x = mismatch_cpue$COUNT_PROD)] <- 
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
  with(mismatched_biomass, N_WEIGHT_PROD > N_COUNT)
] <- "n_weight gt n_count"

mismatched_biomass$NOTE[
  with(mismatched_biomass, 
       N_HAUL_HIST == 1 & CPUE_NOKM2_MEAN == 0 & 
         CPUE_NOKM2_MEAN_HIST == 0 & 
         is.na(x = CPUE_KGKM2_VAR) & 
         is.na(x = CPUE_NOKM2_VAR))
] <- "truncation error"

mismatched_biomass$NOTE[
  with(mismatched_biomass, N_HAUL_HIST == 1 & N_WEIGHT_HIST == 1)
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
                       all.x = TRUE,
                       suffixes = c("_HIST", "_PROD"))

## Remove zero-filled results
test_sizecomp <- subset(x = test_sizecomp,
                        subset = !(POPULATION_COUNT_HIST == 0 & 
                                     is.na(x = POPULATION_COUNT_PROD)) )

## Calculate difference between size comps
test_sizecomp$POPULATION_COUNT <- 
  round(x = with(test_sizecomp, calc_diff(v1 = POPULATION_COUNT_PROD,
                                          v2 = POPULATION_COUNT_HIST)))

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
unique_size <- unique(x = subset(x = mismatched_sizecomp, 
                                 subset = NOTE == "",
                                 select = c(SURVEY_DEFINITION_ID, YEAR, 
                                            AREA_ID, SPECIES_CODE)))
unique_size$NOTE <- ""

for (irow in 1:nrow(x = unique_size)) {
  summed_HIST <- 
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
  
  if(abs(100 * (hist_abund - summed_HIST) / hist_abund) > 0.01) 
    unique_size$NOTE[irow] <- "mismatched_abundance"
}

for (irow in which(unique_size$NOTE != "") ){
  mismatched_sizecomp$NOTE[
    with(mismatched_sizecomp,
         SPECIES_CODE == unique_size$SPECIES_CODE[irow] & 
           YEAR == unique_size$YEAR[irow] & 
           AREA_ID == unique_size$AREA_ID[irow])
  ] <- "mismatched abundance"
}

subset(mismatched_sizecomp, NOTE == "")


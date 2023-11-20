##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare EBS+PLUSNW and NBS historical data product tables 
##                in the HAEHNR schema with those tables produced in the 
##                GAP_PRODUCTS schema.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import packages, connect to Oracle ---------------------------------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
library(reshape2)

if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
  sql_channel <- channel_products
} else {
  sql_channel <- gapindex::get_connected()
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import helper functions -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source(file = "functions/calc_diff.R")
source(file = "functions/compare_tables.R")

spp_year <- RODBC::sqlQuery(channel = sql_channel,
                            query = "SELECT * FROM GAP_PRODUCTS.SPECIES_YEAR")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare CPUE Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Filter EBS and NBS records from GAP_PRODUCTS.CPUE
production_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 
                           cc.YEAR, cc.SURVEY_DEFINITION_ID, HAULJOIN, 
                           SPECIES_CODE, WEIGHT_KG, COUNT,
                           ROUND(cp.CPUE_KGKM2, 2) CPUE_KGKM2, 
                           ROUND(cp.CPUE_NOKM2, 2) CPUE_NOKM2
                           FROM GAP_PRODUCTS.CPUE cp

                           -- Use HAUL data to connect to cruisejoin
                           LEFT JOIN RACEBASE.HAUL hh
                           USING (HAULJOIN)

                           -- Use CRUISES data to obtain YEAR and 
                           -- SURVEY_DEFINITION_ID
                           LEFT JOIN GAP_PRODUCTS.AKFIN_CRUISE cc
                           ON hh.CRUISEJOIN = cc.CRUISEJOIN

                           WHERE cc.SURVEY_DEFINITION_ID in (98, 143) 
                           AND hh.ABUNDANCE_HAUL = 'Y'")

## Bind the EBS and NBS CPUE tables in the HAEHNR schema. 
historical_cpue <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 98 AS SURVEY_DEFINITION_ID, YEAR,
                           HAULJOIN, SPECIES_CODE, 
                           ROUND(CPUE_KGHA * 100, 2) AS CPUE_KGKM2,
                           ROUND(CPUE_NOHA * 100, 2) AS CPUE_NOKM2 
                           FROM HAEHNR.CPUE_EBS_PLUSNW"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 143 AS SURVEY_DEFINITION_ID, YEAR, 
                           HAULJOIN, SPECIES_CODE, 
                           ROUND(CPUE_KGHA * 100, 2) AS CPUE_KGKM2,
                           ROUND(CPUE_NOHA * 100, 2) AS CPUE_NOKM2 
                           FROM HAEHNR.CPUE_NBS")
)

## Full join CPUE tables using "SURVEY_DEFINITION_ID, YEAR, HAULJOIN and 
## SPECIES_CODE as a composite key. 
test_cpue <- merge(x = production_cpue, 
                   y = historical_cpue,
                   all = TRUE,
                   by = c("SURVEY_DEFINITION_ID", "YEAR","HAULJOIN", 
                          "SPECIES_CODE"),
                   suffixes = c("_GP", "_HAEHNR"))

## Evaluate the new, removed, and modified records between the HAEHNR
## and GAP_PRODUCTS versions of the biomass tables. 
eval_cpue <- compare_tables(x = test_cpue,
                            cols_to_check = data.frame(
                              colname = c("CPUE_KGKM2", "CPUE_NOKM2"),
                              percent = c(F, F),
                              decplaces = c(0, 0)),
                            base_table_suffix = "_HAEHNR",
                            update_table_suffix = "_GP",
                            key_columns = c("SURVEY_DEFINITION_ID", "YEAR", 
                                            "HAULJOIN", "SPECIES_CODE"))

## Annotate new cpue records: records that are not in the HAEHNR versions of 
## the CPUE tables and unique to the GAP_PRODUCTS versions of the CPUE table.

## Reason Code 1: The historical Bering Sea tables only include a subset of 
## taxa. The GAP_PRODUCTS tables include all values of SPECIES_CODES present 
## in RACEBASE.CATCH for a given survey region. Assign these records a code
## 1 in the NOTES field. 

## Query distinct species codes in the EBS and NBS HAEHNR CPUE tables. 
ebs_cpue_taxa <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT SPECIES_CODE
                           FROM HAEHNR.CPUE_EBS_PLUSNW")$SPECIES_CODE
nbs_cpue_taxa <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT SPECIES_CODE
                           FROM HAEHNR.CPUE_NBS")$SPECIES_CODE

eval_cpue$new_records$NOTE[
  !(eval_cpue$new_records$SPECIES_CODE %in% ebs_cpue_taxa & 
      eval_cpue$new_records$SURVEY_DEFINITION_ID == 98) |
    !(eval_cpue$new_records$SPECIES_CODE %in% nbs_cpue_taxa & 
        eval_cpue$new_records$SURVEY_DEFINITION_ID == 143)
] <- 1

table(eval_cpue$new_records$NOTE)

## Annotate removed cpue records: records that are in the HAEHNR versions of 
## the CPUE tables but removed in the GAP_PRODUCTS versions of the CPUE table.

## Reason code 2: For a subset of taxa, GAP was confident about the 
## identification of these species after some given year, e.g., northern rock 
## sole was confidently identified starting from 1996. Records before this 
## start year were removed and are not present in the GAP_PRODUCTS tables. See
## GAP_PRODUCTS.SPECIES_YEAR for the full list of species and starting years. 
## Assign these records a code 2 in the NOTES field. 

for (irow in 1:nrow(x = spp_year)) { ## Loop over species -- start
  eval_cpue$removed_records$NOTE[
    eval_cpue$removed_records$SPECIES_CODE == spp_year$SPECIES_CODE[irow] &
      eval_cpue$removed_records$YEAR < spp_year$YEAR_STARTED[irow] 
  ] <- 2
} ## Loop over species -- end

table(eval_cpue$removed_records$NOTE)

## Annotate modified cpue records: records that changed between the HAEHNR and
## GAP_PRODUCTS versions of the CPUE tables.

## Reason code 3: The number of individuals caught was different between when 
## the HAEHNR version of the table was created and when the GAP_PRODUCTS 
## version of the table was created. Assign these records a code 3 in the 
## NOTES field. 
eval_cpue$modified_records$NOTE[
  (eval_cpue$modified_records$SPECIES_CODE == 21725 &
     eval_cpue$modified_records$YEAR == 2010) |
    (eval_cpue$modified_records$SPECIES_CODE == 21371 &
       eval_cpue$modified_records$YEAR == 2017)
] <- 3

table(eval_cpue$modified_records$NOTE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Biomass Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Filter EBS and NBS records from GAP_PRODUCTS.BIOMASS. Only the EBS + NW 
## survey region is included for comparison, so the YEAR is further filtered
## to those years after 1986. 99901, 101, 201, 301 are area_id values 
## corresponding to the EBS Standard survey region. 
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, AREA_ID, SPECIES_CODE, 
                           YEAR, N_HAUL, N_WEIGHT, N_COUNT, 
                           ROUND(CPUE_KGKM2_MEAN, 2) AS CPUE_KGKM2_MEAN,
                           CPUE_KGKM2_VAR,
                           ROUND(CPUE_NOKM2_MEAN, 2) AS CPUE_NOKM2_MEAN,
                           CPUE_NOKM2_VAR,
                           ROUND(BIOMASS_MT, 2) AS BIOMASS_MT,
                           ROUND(BIOMASS_VAR, 4) AS BIOMASS_VAR,
                           ROUND(POPULATION_COUNT) AS POPULATION_COUNT,
                           POPULATION_VAR FROM GAP_prodUCTS.BIOMASS 
                           WHERE SURVEY_DEFINITION_ID in (98, 143)
                           AND YEAR >= 1987
                           AND AREA_ID NOT IN (101, 201, 301, 99901)")

## Filter EBS and NBS records from GAP_PRODUCTS.BIOMASS. Only the EBS + NW 
## survey region is included for comparison, so the YEAR is further filtered
## to those years after 1986
historical_biomass <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 98 AS SURVEY_DEFINITION_ID, YEAR, 
                           SPECIES_CODE, 
                           CASE 
                              WHEN STRATUM = 999 THEN 99900
                              ELSE STRATUM
                              END AS AREA_ID,
                           HAULCOUNT as N_HAUL, 
                           CATCOUNT AS N_WEIGHT, 
                           NUMCOUNT AS N_COUNT,
                           100 * MEANWGTCPUE AS CPUE_KGKM2_MEAN,
                           10000 * VARMNWGTCPUE AS CPUE_KGKM2_VAR,
                           100 * MEANNUMCPUE AS CPUE_NOKM2_MEAN,
                           10000 * VARMNNUMCPUE AS CPUE_NOKM2_VAR,
                           BIOMASS AS BIOMASS_MT, 
                           VARBIO AS BIOMASS_VAR, 
                           POPULATION AS POPULATION_COUNT, 
                           VARPOP AS POPULATION_VAR
                    
                           FROM HAEHNR.BIOMASS_EBS_PLUSNW
                           WHERE YEAR >= 1987"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 143 AS SURVEY_DEFINITION_ID, YEAR, 
                           SPECIES_CODE, 
                           CASE 
                             WHEN STRATUM = 999 THEN 99902
                             ELSE STRATUM
                           END AS AREA_ID,
                           HAUL_COUNT as N_HAUL, 
                           CATCH_COUNT AS N_WEIGHT, 
                           NUMBER_COUNT AS N_COUNT,
                           MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN,
                           VAR_WGT_CPUE AS CPUE_KGKM2_VAR, 
                           MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN,
                           VAR_NUM_CPUE AS CPUE_NOKM2_VAR, 
                           STRATUM_BIOMASS AS BIOMASS_MT, 
                           BIOMASS_VAR AS BIOMASS_VAR,
                           STRATUM_POP AS POPULATION_COUNT,
                           POP_VAR AS POPULATION_VAR 
                    
                           FROM HAEHNR.BIOMASS_NBS_AKFIN 
                           WHERE YEAR > 1987")
)

## Full join the two tables using SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
## and SPECIES_CODE as a composite key.
test_biomass <- merge(x = production_biomass,
                      y = historical_biomass,
                      by = c("SURVEY_DEFINITION_ID", "YEAR", 
                             "AREA_ID", "SPECIES_CODE"),
                      all = TRUE, 
                      suffixes = c("_GP", "_HAEHNR"))

## Evaluate the new, removed, and modified records between the HAEHNR
## and GAP_PRODUCTS versions of the biomass tables. 
eval_biomass <- 
  compare_tables(x = test_biomass,
                 cols_to_check = data.frame(
                   colname = c("N_HAUL", "N_WEIGHT", "N_COUNT",
                               "CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                               "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR", 
                               "BIOMASS_MT", "BIOMASS_VAR", 
                               "POPULATION_COUNT", "POPULATION_VAR"),
                   percent = c(F, F, F, T, T, T, T, T, T, T, T),
                   decplaces = c(0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0)),
                 base_table_suffix = "_HAEHNR",
                 update_table_suffix = "_GP",
                 key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', 
                                 "SPECIES_CODE", "YEAR"))

## Annotate new biomass records: records that are not in the HAEHNR versions of 
## the biomass tables and unique to the GAP_PRODUCTS version of the biomass
## table.

## Reason Code 1: The historical Bering Sea tables only include a subset of 
## taxa. The GAP_PRODUCTS tables include all values of SPECIES_CODES present 
## in RACEBASE.CATCH for a given survey region. Assign these records a code
## 1 in the NOTES field. 

## Query distinct species codes in the EBS and NBS HAEHNR biomass tables. 
ebs_bio_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                query = "SELECT DISTINCT SPECIES_CODE
                                         FROM HAEHNR.BIOMASS_EBS_PLUSNW
                                         WHERE YEAR >= 1987")$SPECIES_CODE
nbs_bio_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                query = "SELECT DISTINCT SPECIES_CODE
                                         FROM HAEHNR.BIOMASS_NBS_AKFIN 
                                         WHERE YEAR >= 1987")$SPECIES_CODE
eval_biomass$new_records$NOTE[
  !(eval_biomass$new_records$SPECIES_CODE %in% ebs_bio_taxa & 
      eval_biomass$new_records$SURVEY_DEFINITION_ID == 98) |
    !(eval_biomass$new_records$SPECIES_CODE %in% nbs_bio_taxa & 
        eval_biomass$new_records$SURVEY_DEFINITION_ID == 143)
] <- 1

table(eval_biomass$new_records$NOTE)

## Annotate removed biomass records: records that are in the HAEHNR versions of 
## the biomass tables but removed in the GAP_PRODUCTS version of the biomass 
## table.

## Reason code 2: For a subset of taxa, GAP was confident about the 
## identification of these species after some given year, e.g., northern rock 
## sole was confidently identified starting from 1996. Records before this 
## start year were removed and are not present in the GAP_PRODUCTS tables. See
## GAP_PRODUCTS.SPECIES_YEAR for the full list of species and starting years. 
## Assign these records a code 2 in the NOTES field. 
for (irow in 1:nrow(x = spp_year)) {
  eval_biomass$removed_records$NOTE[
    eval_biomass$removed_records$SPECIES_CODE == spp_year$SPECIES_CODE[irow] &
      eval_biomass$removed_records$YEAR < spp_year$YEAR_STARTED[irow] 
  ] <- 2
}

## Reason code 4: there are some taxa in the HAEHNR tables that were not 
## observed in the Bering Sea and are completely zero-filled. In 
## GAP_PRODUCTS.BIOMASS, biomass records are only present for observed taxa.
## Assign these records a code 4 in the NOTES field. 
temp_totals <- 
  stats::aggregate(BIOMASS_MT ~ SPECIES_CODE + SURVEY_DEFINITION_ID,
                   data = historical_biomass,
                   subset = SPECIES_CODE %in% 
                     unique(x = subset(x = eval_biomass$removed_records, 
                                       subset = NOTE == "")$SPECIES_CODE),
                   FUN = sum)

for (irow in which(temp_totals$BIOMASS_MT == 0)) {
  eval_biomass$removed_records$NOTE[
    eval_biomass$removed_records$SPECIES_CODE == 
      temp_totals$SPECIES_CODE[irow]  
    &
      eval_biomass$removed_records$SURVEY_DEFINITION_ID == 
      temp_totals$SURVEY_DEFINITION_ID[irow]
  ] <- 4
}

## Reason code 5: NBS and EBS commercial crab taxa are removed from 
## GAP_PRODUCTS.BIOMASS. Assign these records a code 5 in the NOTES field. 
eval_biomass$removed_records$NOTE[
  eval_biomass$removed_records$SPECIES_CODE %in% c(69323, 69322, 68580, 68560)
] <- 5

## Reason code 15: In the HAEHNR version of the biomass tables, for strata 
## where the hauls only collect weight data, the POPULATION_COUNT is 
## incorrectly assumed to be zero with zero variance or NA with zero variance.
## Assign these records a code 15 in the NOTES field. 
eval_biomass$removed_records$NOTE[
  eval_biomass$removed_records$NOTE == "" 
  & eval_biomass$removed_records$N_COUNT_GP == 0 
  & is.na(x = eval_biomass$removed_records$POPULATION_VAR_GP)
] <- 15

table(eval_biomass$removed_records$NOTE)

## Annotate modified biomass records: records that changed between the HAEHNR 
## and GAP_PRODUCTS version of the biomass tables.

## Reason code 6: For instances where the number of hauls with weight data does
## not equal the number of hauls with count data, the way NA values are handled
## is slightly different when using gapindex to calculate variances. Assign 
## these records a code 6 in the NOTES field. 
eval_biomass$modified_records$NOTE[
  eval_biomass$modified_records$N_WEIGHT_HAEHNR != 
    eval_biomass$modified_records$N_COUNT_HAEHNR
] <- 6

## Reason code 3: The number of individuals caught was different between when 
## the HAEHNR version of the table was created and when the GAP_PRODUCTS 
## version of the table was created. These changes in the CPUE records 
## propagate onto the biomass tables. Assign these records a code 6 in the 
## NOTES field. 
eval_biomass$modified_records$NOTE[
  (eval_biomass$modified_records$SPECIES_CODE == 21725 &
     eval_biomass$modified_records$YEAR == 2010) |
    (eval_biomass$modified_records$SPECIES_CODE == 21371 &
       eval_biomass$modified_records$YEAR == 2017)
] <- 3

table(eval_biomass$modified_records$NOTE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Size Composition Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Filter EBS and NBS records from GAP_PRODUCTS.SIZECOMP. Only the EBS + NW 
## survey region is included for comparison, so the YEAR is further filtered
## to those years after 1986. 99901, 101, 201, 301 are area_id values 
## corresponding to the EBS Standard survey region. 
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, 
                           AREA_ID, SEX, LENGTH_MM, POPULATION_COUNT 
                           FROM GAP_PRODUCTS.SIZECOMP 
                           WHERE SURVEY_DEFINITION_ID in (98, 143) 
                           AND YEAR >= 1987 
                           AND AREA_ID NOT IN (99901, 101, 201, 301)")

## Bind the EBS and NBS sizecomp tables in the HAEHNR schema. 
historical_sizecomp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 98 AS SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, 
                           CASE 
                             WHEN STRATUM = 999999 THEN 99900
                             ELSE STRATUM
                           END AS AREA_ID,
                           LENGTH as LENGTH_MM, 
                           MALES, FEMALES, UNSEXED, TOTAL
                           FROM HAEHNR.SIZECOMP_EBS_PLUSNW_STRATUM"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 143 AS SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, 
                           CASE 
                             WHEN STRATUM = 999999 THEN 99902
                             ELSE STRATUM
                           END AS AREA_ID,
                           LENGTH as LENGTH_MM, 
                           MALES, FEMALES, UNSEXED, TOTAL
                           FROM HAEHNR.SIZECOMP_NBS_STRATUM")
)

## Melt the MALES, FEMALES, UNSEXED fields into one SEX field. Recode M/F/3
## to 1/2/3.
historical_sizecomp$UNSEXED[historical_sizecomp$LENGTH_MM == -9] <- 
  historical_sizecomp$TOTAL[historical_sizecomp$LENGTH_MM == -9]

historical_sizecomp <- 
  reshape2::melt(data = subset(x = historical_sizecomp,
                               select = -TOTAL),
                 measure.vars = c("MALES", "FEMALES", "UNSEXED"),
                 variable.name = "SEX",
                 value.name = "POPULATION_COUNT")
historical_sizecomp$SEX <- 
  ifelse(test = historical_sizecomp$SEX == "MALES",
         yes = 1,
         no = ifelse(test = historical_sizecomp$SEX == "FEMALES",
                     yes = 2, no = 3))

## Full join the sizecomp tables using YEAR, AREA_ID, SPECIES_CODE, LENGTH_MM,
## and SEX as a composite key.
test_sizecomp <- 
  merge(x = historical_sizecomp,
        y = production_sizecomp,
        by = c("SURVEY_DEFINITION_ID","YEAR", "AREA_ID", 
               "SPECIES_CODE", "LENGTH_MM", "SEX"),
        all = TRUE, 
        suffixes = c("_HAEHNR", "_GP"))

## Evaluate the new, removed, and modified records between the HAEHNR
## and GAP_PRODUCTS versions of the sizecomp tables. 
eval_sizecomp <-   
  compare_tables(
    x = test_sizecomp,
    cols_to_check = data.frame(colname = "POPULATION_COUNT", 
                               percent = T, 
                               decplaces = 2),
    base_table_suffix = "_HAEHNR",
    update_table_suffix = "_GP",
    key_columns = c("SURVEY_DEFINITION_ID","AREA_ID", "YEAR", 
                    "SPECIES_CODE", "SEX", "LENGTH_MM"))

## Annotate new sizecomp records: records that are not in the HAEHNR versions of 
## the sizecomp tables and unique to the GAP_PRODUCTS version of the sizecomp
## table.

## Reason Code 1: The historical Bering Sea tables only include a subset of 
## taxa. The GAP_PRODUCTS tables include all values of SPECIES_CODES present 
## in RACEBASE.CATCH for a given survey region. Assign these records a code
## 1 in the NOTES field. 

## Query distinct species codes in the EBS and NBS HAEHNR sizecomp tables. 
ebs_bio_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                query = "SELECT DISTINCT SPECIES_CODE
                                         FROM HAEHNR.SIZECOMP_EBS_PLUSNW_STRATUM
                                         WHERE YEAR > 1987")$SPECIES_CODE
nbs_bio_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                query = "SELECT DISTINCT SPECIES_CODE
                                         FROM HAEHNR.SIZECOMP_NBS_STRATUM 
                                         WHERE YEAR > 1987")$SPECIES_CODE

eval_sizecomp$new_records$NOTE[
  !(eval_sizecomp$new_records$SPECIES_CODE %in% ebs_bio_taxa & 
      eval_sizecomp$new_records$SURVEY_DEFINITION_ID == 98) |
    !(eval_sizecomp$new_records$SPECIES_CODE %in% nbs_bio_taxa & 
        eval_sizecomp$new_records$SURVEY_DEFINITION_ID == 143)
] <- 1

table(eval_sizecomp$new_records$NOTE)

## Annotate removed sizecomp records: records that are in the HAEHNR versions of 
## the sizecomp tables but removed in the GAP_PRODUCTS version of the sizecomp 
## table.

## Reason code 7: The GAP_PRDOUCTS versions of the age and size composition 
## tables are not zero-filled whereas the HAEHNR version of the composition 
## tables are zero-filled. included in the GAP_PRODUCTS version of the 
## sizecomp table. Assign these records a code 7 in the NOTES field. 
eval_sizecomp$removed_records$NOTE[
  eval_sizecomp$removed_records$POPULATION_COUNT_HAEHNR == 0 
] <- 7

## Reason code 2: For a subset of taxa, GAP was confident about the 
## identification of these species after some given year, e.g., northern rock 
## sole was confidently identified starting from 1996. Records before this 
## start year were removed and are not present in the GAP_PRODUCTS tables. See
## GAP_PRODUCTS.SPECIES_YEAR for the full list of species and starting years. 
## Assign these records a code 2 in the NOTES field. 
for (irow in 1:nrow(x = spp_year)) {
  eval_sizecomp$removed_records$NOTE[
    eval_sizecomp$removed_records$SPECIES_CODE == spp_year$SPECIES_CODE[irow] &
      eval_sizecomp$removed_records$YEAR < spp_year$YEAR_STARTED[irow] 
  ] <- 2
}

## The remaining removed records were anomalously long individuals that were
## corrected. 
eval_sizecomp$removed_records$NOTE[
  eval_sizecomp$removed_records$NOTE == ""
] <- 8
table(eval_sizecomp$removed_records$NOTE)

## Annotate modified sizecomp records: records that changed between the HAEHNR 
## and GAP_PRODUCTS version of the sizecomp tables.

## Reason code 8: These anomalously large size classes are errors and have 
## since been removed from RACEBASE.LENGTH. Assign these records a code 8 in 
## the NOTES field. 
eval_sizecomp$modified_records$NOTE[
  (eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == 143 & 
     eval_sizecomp$modified_records$YEAR == 2017 & 
     eval_sizecomp$modified_records$SPECIES_CODE == 21371) |
    (eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == 143 & 
       eval_sizecomp$modified_records$YEAR == 2010 & 
       eval_sizecomp$modified_records$SPECIES_CODE == 21725)
] <- 8

## Reason code 9: There was a discrepancy with how juvenile and adult 
## northern rock sole were handled and have been resolved in the current 
## version of GAP_PRODUCTS. Assign these records a code 9 in the NOTES field. 
eval_sizecomp$modified_records$NOTE[
  eval_sizecomp$modified_records$SPECIES_CODE == 10261
] <- 9

## Reason code 10: Unresolved issue: These length bins were somehow excluded 
## from the HAEHNR version of the sizecomp tables. Assign these records a code 
## 10 in the NOTES field. 
excluded_length_bin <- 
  unique(x = subset(x = eval_sizecomp$modified_records, 
                    NOTE == "" & POPULATION_COUNT_HAEHNR == 0,
                    select = c(SURVEY_DEFINITION_ID, SPECIES_CODE, YEAR)))

for (irow in 1:nrow(x = excluded_length_bin)) {
  eval_sizecomp$modified_records$NOTE[
    eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == excluded_length_bin$SURVEY_DEFINITION_ID[irow]
    & eval_sizecomp$modified_records$SPECIES_CODE == excluded_length_bin$SPECIES_CODE[irow]
    & eval_sizecomp$modified_records$YEAR == excluded_length_bin$YEAR[irow]
  ] <-10
}

## Reason code 11: This mismatch is due to an unresolved issue with juvenile 
## walleye pollock 1991 data. Assign these records a code 11 in the NOTES field. 

eval_sizecomp$modified_records$NOTE[
  eval_sizecomp$modified_records$SPECIES_CODE == 21740
  & eval_sizecomp$modified_records$NOTE == ""
  & eval_sizecomp$modified_records$YEAR == 1991
] <- 11

table(eval_sizecomp$modified_records$NOTE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Age Composition Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, 
                           AREA_ID, SEX, AGE, 
                           POPULATION_COUNT, LENGTH_MM_MEAN, LENGTH_MM_SD 
                           FROM GAP_PRODUCTS.AGECOMP 
                           WHERE SURVEY_DEFINITION_ID in (98, 143)
                           AND AREA_ID != 99901")

historical_agecomp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 98 AS SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, 
                           CASE 
                              WHEN STRATUM = 999999 THEN 99900
                              ELSE STRATUM
                           END AS AREA_ID, AGE, SEX,
                           ROUND(AGEPOP) as POPULATION_COUNT,
                           ROUND(MEANLEN, 2) AS LENGTH_MM_MEAN,
                           ROUND(SDEV, 2) AS LENGTH_MM_SD 
                           FROM HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM"),
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT 143 AS SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE, 
                           CASE 
                              WHEN STRATUM = 999999 THEN 99902
                              ELSE STRATUM
                           END AS AREA_ID, AGE, SEX,
                           ROUND(AGEPOP) as POPULATION_COUNT,
                           ROUND(MEANLEN, 2) AS LENGTH_MM_MEAN,
                           ROUND(SDEV, 2) AS LENGTH_MM_SD 
                           FROM HAEHNR.AGECOMP_NBS_STRATUM")
)
historical_agecomp$SEX[
  historical_agecomp$SEX == 9 & historical_agecomp$AGE == -99
] <- 3

historical_agecomp <- subset(x = historical_agecomp,
                             subset = SEX < 9)

## Full join the agecomp tables using SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
## SPECIES_CODE, AGE, and SEX as a composite key.
test_agecomp <- merge(x = historical_agecomp, 
                      y = production_agecomp,
                      all = TRUE, 
                      by = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID", 
                             "SPECIES_CODE", "AGE", "SEX"),
                      suffixes = c("_HAEHNR", "_GP"))

## Evaluate the new, removed, and modified records between the HAEHNR
## and GAP_PRODUCTS versions of the agecomp tables. 
eval_agecomp <- 
  compare_tables(
    x = test_agecomp,
    cols_to_check = data.frame(
      colname = c("POPULATION_COUNT", "LENGTH_MM_MEAN", "LENGTH_MM_SD"),
      percent = c(T, F, F),
      decplaces = c(0, 1, 1)),
    base_table_suffix = "_HAEHNR",
    update_table_suffix = "_GP",
    key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', "YEAR",
                    "SPECIES_CODE", "SEX", "AGE"))

## Annotate new agecomp records: records that are not in the HAEHNR versions of 
## the agecomp tables and unique to the GAP_PRODUCTS version of the agecomp
## table.

## Reason code 12: historically, otoliths from hauls with negative performance
## codes were included in the calculation of the age composition, even though
## these hauls were excluded from the biomass and size composition calculations.
## The GAP_PRODUCTS version of the age composition table only includes data from
## hauls with positive performance codes. Assign these records a code 12 in the
## NOTES field.

## But first, query specimen data that come from hauls with negative 
## performance codes. 
spp_year_neg_hauls <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT 
                           FLOOR(CRUISE/100) AS YEAR, SPECIES_CODE
                           FROM RACEBASE.SPECIMEN 
                           
                           LEFT JOIN 
                           (SELECT HAULJOIN, PERFORMANCE, STRATUM 
                            FROM RACEBASE.HAUL)
                           USING (HAULJOIN)

                           WHERE REGION = 'BS' 
                           AND AGE > 0
                           AND PERFORMANCE < 0
                           AND CRUISE >= 198700
                           AND STRATUM IS NOT NULL
                           ORDER BY SPECIES_CODE, YEAR")

for (irow in 1:nrow(x = spp_year_neg_hauls)) { # Loop over spp/year -- start
  eval_agecomp$new_records$NOTE[
    eval_agecomp$new_records$SPECIES_CODE == 
      spp_year_neg_hauls$SPECIES_CODE[irow] 
    & eval_agecomp$new_records$YEAR == 
      spp_year_neg_hauls$YEAR[irow]  
  ] <- 12
} # Loop over spp/year -- end

## Reason code 13: By default, if otoliths were not collected for a given 
## species/year gapindex reports the total age-aggregated abundance by sex 
## with age -9 or -99 (age and sex aggregated). These records are not in the
## HAEHNR versions of the table. Assign these records a code 13 in the NOTES 
## field.

## Query distinct species codes in the EBS and NBS HAEHNR agecomp tables. 
ebs_agecomp_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                    query = "SELECT DISTINCT SPECIES_CODE
                                         FROM HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM
                                         WHERE YEAR >= 1987")$SPECIES_CODE
nbs_agecomp_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                    query = "SELECT DISTINCT SPECIES_CODE
                                         FROM HAEHNR.AGECOMP_NBS_STRATUM 
                                         WHERE YEAR >= 1987")$SPECIES_CODE

for (ispp in ebs_agecomp_taxa) { ## Loop over EBS spp -- start
  temp_years <- 
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT DISTINCT YEAR 
                                  FROM HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM 
                                  WHERE SPECIES_CODE = ", ispp, 
                                   " AND YEAR >= 1987 AND AGE > 0"))$YEAR
  eval_agecomp$new_records$NOTE[
    (eval_agecomp$new_records$SURVEY_DEFINITION_ID == 98 
     & eval_agecomp$new_records$SPECIES_CODE == ispp 
     & !eval_agecomp$new_records$YEAR %in% temp_years)
  ] <- 13
} ## Loop over EBS spp -- end

for (ispp in nbs_agecomp_taxa) { ## Loop over NBS spp -- start
  temp_years <- 
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT DISTINCT YEAR 
                                  FROM HAEHNR.AGECOMP_NBS_STRATUM 
                                  WHERE SPECIES_CODE = ", ispp, 
                                   " AND YEAR >= 1987 AND AGE > 0"))$YEAR
  eval_agecomp$new_records$NOTE[
    (eval_agecomp$new_records$SURVEY_DEFINITION_ID == 143 
     & eval_agecomp$new_records$SPECIES_CODE == ispp 
     & !eval_agecomp$new_records$YEAR %in% temp_years)
  ] <- 13
} ## Loop over NBS spp -- end

## Reason code 14: There was an addition of 2022 NRS otolith data since the 
## HAEHNR versions of the tables were produced. Assign these records a code 
## 14 in the NOTES field.
eval_agecomp$new_records$NOTE[
  eval_agecomp$new_records$NOTE == "" 
  & eval_agecomp$new_records$SPECIES_CODE == 10261
] <- 14

table(eval_agecomp$new_records$NOTE)

## Annotate removed agecomp records: records that are in the HAEHNR versions of 
## the agecomp tables but removed in the GAP_PRODUCTS version of the agecomp 
## table.

## Reason code 7: The GAP_PRDOUCTS versions of the age and size composition 
## tables are not zero-filled whereas the HAEHNR version of the composition 
## tables are zero-filled. included in the GAP_PRODUCTS version of the 
## sizecomp table. Assign these records a code 7 in the NOTES field. 
eval_agecomp$removed_records$NOTE[
  eval_agecomp$removed_records$POPULATION_COUNT_HAEHNR == 0 
] <- 7

## Reason code 12: historically, otoliths from hauls with negative performance
## codes were included in the calculation of the age composition, even though
## these hauls were excluded from the biomass and size composition calculations.
## The GAP_PRODUCTS version of the age composition table only includes data from
## hauls with positive performance codes. Assign these records a code 12 in the
## NOTES field.
for (irow in 1:nrow(x = spp_year_neg_hauls)) {
  eval_agecomp$removed_records$NOTE[
    eval_agecomp$removed_records$SPECIES_CODE == spp_year_neg_hauls$SPECIES_CODE[irow] 
    & eval_agecomp$removed_records$YEAR == 
      spp_year_neg_hauls$YEAR[irow]  
  ] <-12
}

eval_agecomp$removed_records$NOTE[
  eval_agecomp$removed_records$NOTE == "" 
  & eval_agecomp$removed_records$SPECIES_CODE == 10261
] <- 14

for (irow in which(eval_agecomp$removed_records$NOTE == "")) {
  temp_df <- 
    subset(x = production_agecomp,
           subset = SURVEY_DEFINITION_ID == eval_agecomp$removed_records$SURVEY_DEFINITION_ID[irow] 
           & AREA_ID == eval_agecomp$removed_records$AREA_ID[irow] 
           & YEAR  == eval_agecomp$removed_records$YEAR[irow]
           & SPECIES_CODE  == eval_agecomp$removed_records$SPECIES_CODE[irow] )
  
  if (nrow(x = temp_df) == 0)
    eval_agecomp$removed_records$NOTE[irow] <-12
}

table(eval_agecomp$removed_records$NOTE)

## Annotate modified agecomp records: records that changed between the HAEHNR 
## and GAP_PRODUCTS version of the agecomp tables.
eval_agecomp$modified_records$NOTE[
  eval_agecomp$modified_records$SPECIES_CODE == 21740
  & eval_agecomp$modified_records$NOTE == ""
  & eval_agecomp$modified_records$YEAR == 1991
] <- 11

for (irow in 1:nrow(x = spp_year_neg_hauls)) {
  eval_agecomp$modified_records$NOTE[
    eval_agecomp$modified_records$SPECIES_CODE == spp_year_neg_hauls$SPECIES_CODE[irow] 
    & eval_agecomp$modified_records$YEAR == spp_year_neg_hauls$YEAR[irow]  
  ] <-12
}

eval_agecomp$modified_records$NOTE[
  eval_agecomp$modified_records$NOTE == "" 
  & eval_agecomp$modified_records$SPECIES_CODE == 10261
  & eval_agecomp$modified_records$YEAR == 2022
] <- 14

table(eval_agecomp$modified_records$NOTE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Taxonomic Tables -----------------
##   reference GAP_PRODUCTS.TAXONOMIC_CHANGES
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_taxon <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SPECIES_CODE, COMMON_NAME, SPECIES_NAME 
                           FROM GAP_PRODUCTS.AKFIN_TAXONOMIC_CLASSIFICATION")

historical_taxon <- 
  unique(x = rbind(
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT DISTINCT SPECIES_CODE, 
                                      COMMON_NAME, SPECIES_NAME
                                      FROM HAEHNR.CPUE_EBS_PLUSNW"),
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT DISTINCT SPECIES_CODE, 
                                      COMMON_NAME, SPECIES_NAME 
                                      FROM HAEHNR.CPUE_NBS")
  ))

## Full join the taxonomic tables using SPECIES_CODE as the key. 
test_taxon <-
  merge(x = subset(x = production_taxon,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE)), 
        y = unique(historical_taxon),
        all = TRUE,
        by = "SPECIES_CODE", 
        suffixes = c("_GP", "_HAEHNR"))

## The compare_tables function currently only compares tables with numeric
## columns, so for these character comparisons, evaluate diffs explicitly.  
test_taxon$SPECIES_NAME_DIFF <- 
  test_taxon$SPECIES_NAME_GP != test_taxon$SPECIES_NAME_HAEHNR
test_taxon$SPECIES_NAME_DIFF <- 
  ifelse(test = is.na(x = test_taxon$SPECIES_NAME_DIFF), 
         yes = FALSE, 
         no = test_taxon$SPECIES_NAME_DIFF)
test_taxon$COMMON_NAME_DIFF <- 
  test_taxon$COMMON_NAME_GP != test_taxon$COMMON_NAME_HAEHNR
test_taxon$COMMON_NAME_DIFF <- 
  ifelse(test = is.na(x = test_taxon$COMMON_NAME_DIFF), 
         yes = FALSE, 
         no = test_taxon$COMMON_NAME_DIFF)

eval_taxon <- 
  subset(x = test_taxon,
         subset = (SPECIES_NAME_DIFF | COMMON_NAME_DIFF) )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Save Comparison Tables -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bs_table_comparisons <- 
  list(cpue = eval_cpue,
       biomass = eval_biomass,
       sizecomp = eval_sizecomp,
       agecomp = eval_agecomp,
       taxon = eval_taxon)

for (idata in c("cpue", "biomass", "sizecomp", "agecomp")) {
  print(lapply(X = bs_table_comparisons[[idata]], 
               FUN = function(x) table(x$NOTE)))
}

saveRDS(object = bs_table_comparisons, 
        file = paste0("code/historical_comparisons/",
                      "bering_sea_shelf_comparisons/",
                      "bs_table_comparisons.RDS"))

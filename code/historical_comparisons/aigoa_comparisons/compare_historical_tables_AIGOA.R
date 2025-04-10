##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare AI and GOA historical data product tables  with those
##                tables produced in the GAP_PRODUCTS schema.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())
options(scipen = 999999)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import packages, connect to Oracle 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex); library(reshape2)
sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import helper functions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source(file = "functions/calc_diff.R")
source(file = "functions/compare_tables.R")

spp_year <- RODBC::sqlQuery(channel = sql_channel,
                            query = "SELECT * FROM GAP_PRODUCTS.SPECIES_YEAR")

decimalplaces <- Vectorize(function(x) {
  if ((x %% 1) != 0 & !is.na(x = x)) {
    nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed=TRUE)[[1]][[2]])
  } else {
    return(0)
  }
}
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import CPUE tables from GAP_PRODUCTS as historical AI/GOA schemata
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Filter AI and GOA records from GAP_PRODUCTS.CPUE
production_cpue <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, HAULJOIN,
                           AREA_ID, SPECIES_CODE, WEIGHT_KG, COUNT, 
                           AREA_SWEPT_KM2, CPUE_KGKM2, CPUE_NOKM2 
                           FROM GAP_PRODUCTS.CPUE
                           
                           INNER JOIN (
                           SELECT DISTINCT 
                           CASE 
                            WHEN REGION = 'AI' THEN 52
                            WHEN REGION = 'GOA' THEN 47
                            ELSE NULL
                           END AS SURVEY_DEFINITION_ID, 
                           HAULJOIN, STRATUM AS AREA_ID,
                           FLOOR(CRUISE/100) YEAR 
                           FROM RACEBASE.HAUL
                           WHERE REGION IN ('AI', 'GOA')) 
                           
                           USING (HAULJOIN)")

## Bind the CPUE tables from that AI and GOA schemata. 
historical_cpue <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT 47 SURVEY_DEFINITION_ID,
                    YEAR, STRATUM AS AREA_ID, HAULJOIN, SPECIES_CODE,
                    WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT,
                    WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2
                    FROM GOA.CPUE WHERE YEAR >= 1990")),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT 52 SURVEY_DEFINITION_ID,
                    YEAR, STRATUM AS AREA_ID, HAULJOIN, SPECIES_CODE,
                    WEIGHT AS WEIGHT_KG, NUMBER_FISH AS COUNT,
                    WGTCPUE AS CPUE_KGKM2, NUMCPUE AS CPUE_NOKM2
                    FROM AI.CPUE WHERE YEAR >= 1991"))
)

## Merge CPUE tables using YEAR, HAULJOIN, AREA_ID, and SPECIES_CODE 
## as a composite key. 
test_cpue <- merge(x = historical_cpue,
                   y = production_cpue, 
                   by = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID",
                          "HAULJOIN", "SPECIES_CODE"),
                   all = TRUE, suffixes = c("_HIST", "_PROD"))

eval_cpue <-     
  compare_tables(
    x = test_cpue,
    cols_to_check = data.frame(
      colname = c("CPUE_KGKM2", "CPUE_NOKM2", "WEIGHT_KG", "COUNT"),
      percent = c(F, F, F, F),
      decplaces = c(2, 2, 3, 0)),
    base_table_suffix = "_HIST",
    update_table_suffix = "_PROD",
    key_columns = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID",
                    "HAULJOIN", "SPECIES_CODE"))

## Annotate new cpue records: records that are not in the historical versions of 
## the CPUE tables and unique to the GAP_PRODUCTS versions of the CPUE table.

## Reason Code 1: The historical AIGOA tables only include a subset of taxa 
## highlighted in GOA.ANALYSIS_SPECIES. The GAP_PRODUCTS tables include all 
## values of SPECIES_CODES present in RACEBASE.CATCH for a given survey region.
## Assign these records a 1 in the NOTES field. 

## Query distinct species codes in the EBS and NBS HAEHNR CPUE tables. 
goa_cpue_taxa <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT SPECIES_CODE
                           FROM GOA.CPUE")$SPECIES_CODE
ai_cpue_taxa <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT SPECIES_CODE
                           FROM AI.CPUE")$SPECIES_CODE

eval_cpue$new_records$NOTE[
  !(eval_cpue$new_records$SPECIES_CODE %in% goa_cpue_taxa & 
      eval_cpue$new_records$SURVEY_DEFINITION_ID == 47)
] <- 1
eval_cpue$new_records$NOTE[
  !(eval_cpue$new_records$SPECIES_CODE %in% goa_cpue_taxa & 
      eval_cpue$new_records$SURVEY_DEFINITION_ID == 52)
] <- 1

table(eval_cpue$new_records$NOTE)

## Annotate removed cpue records: records that are in the historical versions of 
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

## Reason code 3. There are some taxa in the historical tables that were not 
## observed in the AI/GOA and are completely zero-filled. In 
## GAP_PRODUCTS.BIOMASS, biomass records are only present for observed taxa.
## Assign these records a code 3 in the NOTES field. 
goa_obs_cpue_spp <- unique(x = subset(x = production_cpue,
                                      subset = SURVEY_DEFINITION_ID == 47,
                                      select = SPECIES_CODE))$SPECIES_CODE
ai_obs_cpue_spp <- unique(x = subset(x = production_cpue,
                                     subset = SURVEY_DEFINITION_ID == 52,
                                     select = SPECIES_CODE)$SPECIES_CODE)
eval_cpue$removed_records$NOTE[
  eval_cpue$removed_records$NOTE == "" &
    ((eval_cpue$removed_records$SURVEY_DEFINITION_ID == 52 &
        !eval_cpue$removed_records$SPECIES_CODE %in% ai_obs_cpue_spp) |
       (eval_cpue$removed_records$SURVEY_DEFINITION_ID == 47 &
          !eval_cpue$removed_records$SPECIES_CODE %in% goa_obs_cpue_spp))
  
] <- 3

## Reason code 4. There was a change in the reported weight in RACEBASE.CATCH
## that was not updated in the historical CPUE tables. Assign these records a 
## code 4 in the NOTES field. 
eval_cpue$removed_records$NOTE[
  eval_cpue$removed_records$WEIGHT_KG_DIFF != 0 
] <- 4

## Reason code 5. In the historical CPUE tables, sometimes a zero count is 
## associated with a positive weight when it should be NA. ssign these records 
## a code 5 in the NOTES field. 
for (irow in which(eval_cpue$removed_records$NOTE == "")){
  temp_record <- eval_cpue$removed_records[irow, ]
  if (temp_record$CPUE_KGKM2_DIFF == 0 &
      is.na(x = temp_record$CPUE_NOKM2_DIFF)) {
    eval_cpue$removed_records$NOTE[irow] <- 5
  } 
}

table(eval_cpue$removed_records$NOTE)

## Annotate modified cpue records: records that changed between the historical
## and GAP_PRODUCTS versions of the CPUE tables.
eval_cpue$modified_records$NOTE[
  eval_cpue$modified_records$WEIGHT_KG_DIFF != 0 
] <- 4

table(eval_cpue$modified_records$NOTE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Biomass Tables 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Filter EBS and NBS records from GAP_PRODUCTS.BIOMASS. 
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
                           SPECIES_CODE, N_HAUL, N_WEIGHT, N_COUNT, N_LENGTH,
                           ROUND(CPUE_KGKM2_MEAN, 2) AS CPUE_KGKM2_MEAN, 
                           ROUND(CPUE_KGKM2_VAR, 2) AS CPUE_KGKM2_VAR, 
                           ROUND(CPUE_NOKM2_MEAN, 2) AS CPUE_NOKM2_MEAN, 
                           ROUND(CPUE_NOKM2_VAR, 2) AS CPUE_NOKM2_VAR, 
                           ROUND(BIOMASS_MT, 1) AS BIOMASS_MT, 
                           ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR, 
                           ROUND(POPULATION_COUNT) AS POPULATION_COUNT, 
                           ROUND(POPULATION_VAR) AS POPULATION_VAR
                           FROM GAP_PRODUCTS.BIOMASS 
                            
                           WHERE SURVEY_DEFINITION_ID IN (47, 52)")

production_biomass[production_biomass$N_HAUL == 1, 
                   c("CPUE_KGKM2_MEAN", "CPUE_NOKM2_MEAN", 
                     "BIOMASS_MT", "POPULATION_COUNT")] <- 
  round(x = production_biomass[production_biomass$N_HAUL == 1, 
                               c("CPUE_KGKM2_MEAN", "CPUE_NOKM2_MEAN", 
                                 "BIOMASS_MT", "POPULATION_COUNT")],
        digits = 0)

## Import Biomass tables from historical AI/GOA schemata
historical_biomass <- 
  rbind(
    ## GOA Biomass by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             STRATUM_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             STRATUM_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM GOA.BIOMASS_STRATUM
                             WHERE YEAR >= 1990"),
    ## AI Biomass by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             STRATUM_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             STRATUM_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM AI.BIOMASS_STRATUM
                             WHERE YEAR >= 1991"),
    
    ## GOA Biomass by INPFC area
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             AREA_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             AREA_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM GOA.BIOMASS_INPFC 
                             WHERE YEAR >= 1990"),
    ## AI Biomass by INPFC area
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             AREA_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             AREA_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM AI.BIOMASS_INPFC
                             WHERE YEAR >= 1991"),
    
    ## GOA Biomass by Depth Bins
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_DEPTH AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             AREA_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             AREA_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM GOA.BIOMASS_DEPTH 
                             WHERE YEAR >= 1990"),
    ## AI Biomass by Depth Bins
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_DEPTH AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             AREA_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             AREA_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM AI.BIOMASS_DEPTH
                             WHERE YEAR >= 1991"),
    
    ## GOA Biomass by INPFC-Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA_DEPTH AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             AREA_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             AREA_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM GOA.BIOMASS_INPFC_DEPTH 
                             WHERE YEAR >= 1990"),
    ## AI Biomass by INPFC-Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA_DEPTH AS AREA_ID, SPECIES_CODE,
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             AREA_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             AREA_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM AI.BIOMASS_INPFC_DEPTH
                             WHERE YEAR >= 1991"),
    
    ## GOA Biomass by Regulatory Area
    RODBC::sqlQuery(channel = sql_channel,
                    query = 
                      "SELECT 47 SURVEY_DEFINITION_ID, YEAR,
                       CASE
                        WHEN REGULATORY_AREA_NAME = 'CENTRAL GOA' THEN 803
                        WHEN REGULATORY_AREA_NAME = 'WESTERN GOA' THEN 805
                        WHEN REGULATORY_AREA_NAME = 'EASTERN GOA' THEN 804
                        ELSE NULL
                       END AS AREA_ID,
                       SPECIES_CODE, HAUL_COUNT as N_HAUL,
                       CATCH_COUNT AS N_WEIGHT,
                       ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                       ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                       ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                       ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                       AREA_BIOMASS AS BIOMASS_MT,
                       ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                       AREA_POP AS POPULATION_COUNT,
                       POP_VAR AS POPULATION_VAR
                       FROM GOA.BIOMASS_AREA 
                       WHERE YEAR >= 1990"),
    ## AI Biomass by Regulatory Area
    RODBC::sqlQuery(channel = sql_channel,
                    query = 
                      "SELECT 52 SURVEY_DEFINITION_ID, YEAR,
                       CASE
                        WHEN REGULATORY_AREA_NAME = 'ALEUTIANS' THEN 810
                        WHEN REGULATORY_AREA_NAME = 'S BERING SEA' THEN 820
                        ELSE NULL
                       END AS AREA_ID,
                       SPECIES_CODE, HAUL_COUNT as N_HAUL,
                       CATCH_COUNT AS N_WEIGHT,
                       ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                       ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                       ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                       ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                       AREA_BIOMASS AS BIOMASS_MT,
                       ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                       AREA_POP AS POPULATION_COUNT,
                       POP_VAR AS POPULATION_VAR
                       FROM AI.BIOMASS_AREA
                       WHERE YEAR >= 1991"),
    
    ## AI Biomass by Regulatory Area x Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID, YEAR,
                             SUMMARY_DEPTH AS AREA_ID,
                             SPECIES_CODE, HAUL_COUNT as N_HAUL,
                             CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             AREA_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             AREA_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM AI.BIOMASS_AREA_DEPTH
                             WHERE YEAR >= 1991"),
    
    ## GOA Total Biomass
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID, YEAR, 
                             99903 AREA_ID, SPECIES_CODE, 
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             TOTAL_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             TOTAL_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM GOA.BIOMASS_TOTAL
                             WHERE YEAR >= 1990"),
    ## AI Total Biomass
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID, YEAR, 
                             99904 AREA_ID, SPECIES_CODE, 
                             HAUL_COUNT as N_HAUL, CATCH_COUNT AS N_WEIGHT,
                             ROUND(MEAN_WGT_CPUE, 2) AS CPUE_KGKM2_MEAN,
                             ROUND(VAR_WGT_CPUE, 2) AS CPUE_KGKM2_VAR,
                             ROUND(MEAN_NUM_CPUE, 2) AS CPUE_NOKM2_MEAN,
                             ROUND(VAR_NUM_CPUE, 2) AS CPUE_NOKM2_VAR,
                             TOTAL_BIOMASS AS BIOMASS_MT,
                             ROUND(BIOMASS_VAR, 2) AS BIOMASS_VAR,
                             TOTAL_POP AS POPULATION_COUNT,
                             POP_VAR AS POPULATION_VAR
                             FROM AI.BIOMASS_TOTAL
                             WHERE YEAR >= 1991")
  )

## Full join the two tables using SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
## and SPECIES_CODE as a composite key.
test_biomass <- merge(x = production_biomass,
                      y = historical_biomass,
                      by = c("SURVEY_DEFINITION_ID", "YEAR", 
                             "AREA_ID", "SPECIES_CODE"),
                      all = TRUE, 
                      suffixes = c("_PROD", "_HIST"))
test_biomass$CPUE_KGKM2_MEAN_PROD <- 
  round(x = test_biomass$CPUE_KGKM2_MEAN_PROD,
        digits = decimalplaces(test_biomass$CPUE_KGKM2_MEAN_HIST))
test_biomass$CPUE_NOKM2_MEAN_PROD <- 
  round(x = test_biomass$CPUE_NOKM2_MEAN_PROD,
        digits = decimalplaces(test_biomass$CPUE_NOKM2_MEAN_HIST))

test_biomass$CPUE_NOKM2_VAR_PROD <- 
  round(x = test_biomass$CPUE_NOKM2_VAR_PROD,
        digits = decimalplaces(test_biomass$CPUE_NOKM2_VAR_HIST))
test_biomass$CPUE_NOKM2_VAR_PROD <- 
  round(x = test_biomass$CPUE_NOKM2_VAR_PROD,
        digits = decimalplaces(test_biomass$CPUE_NOKM2_VAR_HIST))

## Evaluate the new, removed, and modified records between the HAEHNR
## and GAP_PRODUCTS versions of the biomass tables. 
eval_biomass <- 
  compare_tables(x = unique(x = test_biomass),
                 cols_to_check = data.frame(
                   colname = c("N_HAUL", "N_WEIGHT",
                               "CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                               "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR", 
                               "BIOMASS_MT", "BIOMASS_VAR", 
                               "POPULATION_COUNT", "POPULATION_VAR"),
                   percent = c(F, F, T, T, T, T, F, T, T, T),
                   decplaces = c(0, 0, 0, 0, 2, 2, 0, 0, 1, 1)),
                 base_table_suffix = "_HIST",
                 update_table_suffix = "_PROD",
                 key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', 
                                 "SPECIES_CODE", "YEAR"))

## Annotate new biomass records: records that are not in the historical 
## versions of the biomass tables and unique to the GAP_PRODUCTS version of 
## the biomass table.

## Reason Code 1: The historical AIGOA tables only include a subset of taxa 
## highlighted in GOA.ANALYSIS_SPECIES. The GAP_PRODUCTS tables include all 
## values of SPECIES_CODES present in RACEBASE.CATCH for a given survey region. 
## Assign these records a code 1 in the NOTES field. 

## Query distinct species codes in the EBS and NBS HAEHNR biomass tables. 
goa_bio_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                query = "SELECT DISTINCT SPECIES_CODE
                                         FROM GOA.BIOMASS_STRATUM
                                         WHERE YEAR >= 1990")$SPECIES_CODE
ai_bio_taxa <- RODBC::sqlQuery(channel = sql_channel,
                               query = "SELECT DISTINCT SPECIES_CODE
                                         FROM AI.BIOMASS_STRATUM 
                                         WHERE YEAR >= 1991")$SPECIES_CODE
eval_biomass$new_records$NOTE[
  !(eval_biomass$new_records$SPECIES_CODE %in% goa_bio_taxa & 
      eval_biomass$new_records$SURVEY_DEFINITION_ID == 47) |
    !(eval_biomass$new_records$SPECIES_CODE %in% ai_bio_taxa & 
        eval_biomass$new_records$SURVEY_DEFINITION_ID == 52)
] <- 1

table(eval_biomass$new_records$NOTE)

## Annotate removed biomass records: records that are in the historical 
## versions of the biomass tables but removed in the GAP_PRODUCTS version of 
## the biomass table.

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

## Reason code 3. There are some taxa in the historical tables that were not 
## observed in the AI/GOA and are completely zero-filled. In 
## GAP_PRODUCTS.BIOMASS, biomass records are only present for observed taxa.
## Assign these records a code 3 in the NOTES field. 
eval_biomass$removed_records$NOTE[
  eval_biomass$removed_records$NOTE == "" &
    ((eval_biomass$removed_records$SURVEY_DEFINITION_ID == 52 &
        !eval_biomass$removed_records$SPECIES_CODE %in% ai_obs_cpue_spp) |
       (eval_biomass$removed_records$SURVEY_DEFINITION_ID == 47 &
          !eval_biomass$removed_records$SPECIES_CODE %in% goa_obs_cpue_spp))
  
] <- 3

## Reason code 5. In the historical CPUE tables, sometimes a zero count is 
## associated with a positive weight when it should be NA. Assign these 
## records a code 5 in the NOTES field. 
for (irow in which(eval_cpue$removed_records$NOTE == 5)){
  temp_record <- eval_cpue$removed_records[irow, ]
  
  eval_biomass$removed_records$NOTE[
    eval_biomass$removed_records$NOTE == "" & 
      (eval_biomass$removed_records$SURVEY_DEFINITION_ID == 
         temp_record$SURVEY_DEFINITION_ID & 
         eval_biomass$removed_records$YEAR == 
         temp_record$YEAR & 
         eval_biomass$removed_records$SPECIES_CODE == 
         temp_record$SPECIES_CODE & 
         eval_biomass$removed_records$AREA_ID == 
         temp_record$AREA_ID)
  ] <- 5
}

table(eval_biomass$removed_records$NOTE)
table(subset(eval_biomass$removed_records, NOTE== "")$AREA_ID)

subset(eval_biomass$removed_records, NOTE== "" & AREA_ID == 35)
subset(eval_cpue$removed_records, AREA_ID == 35 & YEAR == 1990 & SPECIES_CODE == 66120)

## Annotate modified records

## Sometimes there is a mismatch due to truncation in the mean CPUE estimates
## but no mismatch  when extrapolated to total abundance/biomass. This is a 
## false mismatche only due to truncation. Assign these records a code 6.
## To avoid any false mismatches due to truncation, only include modified 
## records where either the mean numerical CPUE and abundance estimates are 
## mismatched OR the mean weight CPUE and biomass estimates are mismatched. 
eval_biomass$modified_records$NOTE[
  eval_biomass$modified_records$POPULATION_COUNT_DIFF == 0 &
    eval_biomass$modified_records$CPUE_NOKM2_MEAN_DIFF != 0
] <- 6
eval_biomass$modified_records$NOTE[
  eval_biomass$modified_records$BIOMASS_MT_DIFF == 0 &
    eval_biomass$modified_records$CPUE_KGKM2_MEAN_DIFF != 0
] <- 6
eval_biomass$modified_records$NOTE[
  eval_biomass$modified_records$BIOMASS_MT_DIFF != 0 &
    eval_biomass$modified_records$CPUE_KGKM2_MEAN_DIFF == 0
] <- 6
eval_biomass$modified_records$NOTE[
  eval_biomass$modified_records$N_HAUL_HIST == 1 &
    eval_biomass$modified_records$N_WEIGHT_HIST == 1
] <- 6

## Reason code 7. Different number of N_HAUL between historical and 
## GAP_PRODUCTS versions of the biomass tables. Assign these records a code 7.
eval_biomass$modified_records$NOTE[
  eval_biomass$modified_records$N_HAUL_DIFF != 0
] <- 7

## Reason code 8. Different number of N_WEIGHT between historical and 
## GAP_PRODUCTS versions of the biomass tables. Assign these records a code 8.
eval_biomass$modified_records$NOTE[
  eval_biomass$modified_records$N_WEIGHT_DIFF != 0
] <- 8

strata_id <- RODBC::sqlQuery(channel = sql_channel,
                             query = "SELECT AREA_ID 
                                      FROM GAP_PRODUCTS.AREA 
                                      WHERE SURVEY_DEFINITION_ID IN (47, 52) 
                                      AND AREA_TYPE = 'STRATUM'")$AREA_ID

for (irow in which(eval_biomass$modified_records$NOTE == "" & 
                   eval_biomass$modified_records$AREA_ID %in% strata_id)) {
  
  temp_record <- eval_biomass$modified_records[irow, ]
  test_query <- 
    subset(x = rbind(eval_cpue$removed_records, eval_cpue$modified_records),
           SURVEY_DEFINITION_ID == temp_record$SURVEY_DEFINITION_ID &
             AREA_ID == temp_record$AREA_ID &
             SPECIES_CODE == temp_record$SPECIES_CODE & 
             YEAR == temp_record$YEAR)
  
  if (nrow(x = test_query) > 0) {
    eval_biomass$modified_records$NOTE[irow] <- unique(test_query$NOTE)
    
    affected_subareas <- 
      RODBC::sqlQuery(channel = sql_channel,
                      query = paste0("SELECT AREA_ID FROM 
                                      GAP_PRODUCTS.STRATUM_GROUPS
                                      WHERE STRATUM = ", temp_record$AREA_ID,
                                     "AND SURVEY_DEFINITION_ID = ",
                                     temp_record$SURVEY_DEFINITION_ID))$AREA_ID
    
    affected_subarea_records <- 
      subset(x = eval_biomass$modified_records,
             subset = SURVEY_DEFINITION_ID == 
               temp_record$SURVEY_DEFINITION_ID &
               AREA_ID %in% affected_subareas &
               SPECIES_CODE == temp_record$SPECIES_CODE & 
               YEAR == temp_record$YEAR)
    
    if (nrow(x = affected_subarea_records) > 0) 
      eval_biomass$modified_records$NOTE[
        eval_biomass$modified_records$SURVEY_DEFINITION_ID == 
          temp_record$SURVEY_DEFINITION_ID &
          eval_biomass$modified_records$AREA_ID %in% affected_subareas &
          eval_biomass$modified_records$SPECIES_CODE == 
          temp_record$SPECIES_CODE & 
          eval_biomass$modified_records$YEAR == 
          temp_record$YEAR
      ] <-  test_query$NOTE
  }
}

table(eval_biomass$modified_records$NOTE)
head(subset(eval_biomass$modified_records, NOTE == ""))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Sizecomp Tables 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Filter AI and GOA records from GAP_PRODUCTS.SIZECOMP 
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
                           SPECIES_CODE, SEX, LENGTH_MM, POPULATION_COUNT
                           FROM GAP_PRODUCTS.SIZECOMP 
                            
                           WHERE SURVEY_DEFINITION_ID IN (47, 52)")

## Import Biomass tables from historical AI/GOA schemata
historical_sizecomp <- 
  rbind(
    ## GOA Size Composition by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, STRATUM AS AREA_ID, SPECIES_CODE, 
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM GOA.SIZECOMP_STRATUM
                             WHERE YEAR >= 1990"),
    ## AI Size Composition by Stratum
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, STRATUM AS AREA_ID, SPECIES_CODE,
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM AI.SIZECOMP_STRATUM
                             WHERE YEAR >= 1991"),
    
    ## GOA Size Composition by INPFC area
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA AS AREA_ID, SPECIES_CODE,
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM GOA.SIZECOMP_INPFC 
                             WHERE YEAR >= 1990"),
    ## AI Size Composition by INPFC area
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA AS AREA_ID, SPECIES_CODE,
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM AI.SIZECOMP_INPFC
                             WHERE YEAR >= 1991"),
    
    ## GOA Size Composition by Depth Bins
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_DEPTH AS AREA_ID, SPECIES_CODE,
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM GOA.SIZECOMP_DEPTH 
                             WHERE YEAR >= 1990"),
    ## AI Size Composition by Depth Bins
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_DEPTH AS AREA_ID, SPECIES_CODE,
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM AI.SIZECOMP_DEPTH
                             WHERE YEAR >= 1991"),
    
    ## GOA Size Composition by INPFC-Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA_DEPTH AS AREA_ID, SPECIES_CODE,
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM GOA.SIZECOMP_INPFC_DEPTH 
                             WHERE YEAR >= 1990"),
    ## AI Size Composition by INPFC-Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID,
                             YEAR, SUMMARY_AREA_DEPTH AS AREA_ID, SPECIES_CODE,
                             LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM AI.SIZECOMP_INPFC_DEPTH
                             WHERE YEAR >= 1991"),
    
    ## GOA Size Composition by Regulatory Area
    RODBC::sqlQuery(channel = sql_channel,
                    query = 
                      "SELECT 47 SURVEY_DEFINITION_ID, YEAR,
                       CASE
                        WHEN REGULATORY_AREA_NAME = 'CENTRAL GOA' THEN 803
                        WHEN REGULATORY_AREA_NAME = 'WESTERN GOA' THEN 805
                        WHEN REGULATORY_AREA_NAME = 'EASTERN GOA' THEN 804
                        ELSE NULL
                       END AS AREA_ID,
                       SPECIES_CODE, LENGTH AS LENGTH_MM, 
                       MALES, FEMALES, UNSEXED
                       FROM GOA.SIZECOMP_AREA 
                       WHERE YEAR >= 1990"),
    ## AI Size Composition by Regulatory Area
    RODBC::sqlQuery(channel = sql_channel,
                    query = 
                      "SELECT 52 SURVEY_DEFINITION_ID, YEAR,
                       CASE
                        WHEN REGULATORY_AREA_NAME = 'ALEUTIANS' THEN 810
                        WHEN REGULATORY_AREA_NAME = 'S BERING SEA' THEN 820
                        ELSE NULL
                       END AS AREA_ID,
                       SPECIES_CODE, LENGTH AS LENGTH_MM,
                       MALES, FEMALES, UNSEXED
                       FROM AI.SIZECOMP_AREA
                       WHERE YEAR >= 1991"),
    
    ## AI Size Composition by Regulatory Area x Depth
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID, YEAR,
                             SUMMARY_DEPTH AS AREA_ID,
                             SPECIES_CODE, LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM AI.SIZECOMP_AREA_DEPTH
                             WHERE YEAR >= 1991"),
    
    ## GOA Size Composition Biomass
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 47 SURVEY_DEFINITION_ID, YEAR, 
                             99903 AREA_ID, SPECIES_CODE, LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM GOA.SIZECOMP_TOTAL
                             WHERE YEAR >= 1990"),
    ## AI Size Composition Biomass
    RODBC::sqlQuery(channel = sql_channel,
                    query = "SELECT 52 SURVEY_DEFINITION_ID, YEAR, 
                             99904 AREA_ID, SPECIES_CODE, LENGTH AS LENGTH_MM,
                             MALES, FEMALES, UNSEXED
                             FROM AI.SIZECOMP_TOTAL
                             WHERE YEAR >= 1991")
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
historical_sizecomp <- subset(x = historical_sizecomp, 
                              subset = POPULATION_COUNT != 0)

## Full join the two tables using SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
## and SPECIES_CODE as a composite key.
test_sizecomp <- merge(x = production_sizecomp,
                       y = historical_sizecomp,
                       by = c("SURVEY_DEFINITION_ID", "YEAR", 
                              "AREA_ID", "SPECIES_CODE", "SEX", "LENGTH_MM"),
                       all = TRUE, 
                       suffixes = c("_PROD", "_HIST"))

eval_sizecomp <-   
  compare_tables(
    x = test_sizecomp,
    cols_to_check = data.frame(colname = "POPULATION_COUNT", 
                               percent = T, 
                               decplaces = 0),
    base_table_suffix = "_HIST",
    update_table_suffix = "_PROD",
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
goa_sizecomp_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                     query = "SELECT DISTINCT SPECIES_CODE
                                         FROM GOA.SIZECOMP_TOTAL
                                         WHERE YEAR >= 1990")$SPECIES_CODE
ai_sizecomp_taxa <- RODBC::sqlQuery(channel = sql_channel,
                                    query = "SELECT DISTINCT SPECIES_CODE
                                         FROM AI.SIZECOMP_TOTAL
                                         WHERE YEAR >= 1991")$SPECIES_CODE

eval_sizecomp$new_records$NOTE[
  !(eval_sizecomp$new_records$SPECIES_CODE %in% goa_sizecomp_taxa & 
      eval_sizecomp$new_records$SURVEY_DEFINITION_ID == 47) 
] <- 1

eval_sizecomp$new_records$NOTE[
  !(eval_sizecomp$new_records$SPECIES_CODE %in% ai_sizecomp_taxa & 
      eval_sizecomp$new_records$SURVEY_DEFINITION_ID == 52)
] <- 1

table(eval_sizecomp$new_records$NOTE)

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

table(eval_sizecomp$removed_records$NOTE)
subset(eval_sizecomp$removed_records, NOTE == "")

## Reason code 9. Differences in estimated abundance is propagated to the size 
## comps. Assign these records a error code 9. 

for (irow in which(eval_biomass$modified_records$POPULATION_COUNT_DIFF != 0 &
                   eval_biomass$modified_records$SPECIES_CODE %in%
                   unique(eval_sizecomp$modified_records$SPECIES_CODE))[]) {
  
  temp_record <- eval_biomass$modified_records[irow, ]
  eval_sizecomp$modified_records$NOTE[
    eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == temp_record$SURVEY_DEFINITION_ID & 
      eval_sizecomp$modified_records$AREA_ID == temp_record$AREA_ID &
      eval_sizecomp$modified_records$SPECIES_CODE == temp_record$SPECIES_CODE  &
      eval_sizecomp$modified_records$YEAR == temp_record$YEAR 
  ] <- 9
  
  affected_subareas <- 
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT AREA_ID FROM 
                                      GAP_PRODUCTS.STRATUM_GROUPS
                                      WHERE STRATUM = ", temp_record$AREA_ID,
                                   "AND SURVEY_DEFINITION_ID = ",
                                   temp_record$SURVEY_DEFINITION_ID))$AREA_ID
  
  affected_subarea_records <- 
    subset(x = eval_sizecomp$modified_records,
           subset = SURVEY_DEFINITION_ID == 
             temp_record$SURVEY_DEFINITION_ID &
             AREA_ID %in% affected_subareas &
             SPECIES_CODE == temp_record$SPECIES_CODE & 
             YEAR == temp_record$YEAR)
  
  if (nrow(x = affected_subarea_records) > 0) 
    eval_sizecomp$modified_records$NOTE[
      eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == 
        temp_record$SURVEY_DEFINITION_ID &
        eval_sizecomp$modified_records$AREA_ID %in% affected_subareas &
        eval_sizecomp$modified_records$SPECIES_CODE == 
        temp_record$SPECIES_CODE & 
        eval_sizecomp$modified_records$YEAR == 
        temp_record$YEAR
    ] <-  9
}
table(eval_sizecomp$modified_records$NOTE)

## But first, query length data that come from hauls with negative 
## performance codes. 
spp_year_neg_hauls <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT 
                           CASE
                            WHEN REGION = 'AI' THEN 52
                            WHEN REGION = 'GOA' THEN 47
                           END AS SURVEY_DEFINITION_ID,
                           FLOOR(CRUISE/100) AS YEAR, STRATUM, SPECIES_CODE
                           FROM RACEBASE.LENGTH
                           
                           LEFT JOIN 
                           (SELECT HAULJOIN, PERFORMANCE, STRATUM 
                            FROM RACEBASE.HAUL)
                           USING (HAULJOIN)

                           WHERE REGION IN ('AI', 'GOA') 
                           AND CRUISE >= 199001
                           AND PERFORMANCE < 0
                           AND STRATUM IS NOT NULL
                           ORDER BY SPECIES_CODE, YEAR")

for (irow in 1:nrow(x = spp_year_neg_hauls)) {
  eval_sizecomp$modified_records$NOTE[
    eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == spp_year_neg_hauls$SURVEY_DEFINITION_ID[irow] &
      eval_sizecomp$modified_records$AREA_ID == spp_year_neg_hauls$STRATUM[irow] &
      eval_sizecomp$modified_records$SPECIES_CODE == spp_year_neg_hauls$SPECIES_CODE[irow] &
      eval_sizecomp$modified_records$YEAR == spp_year_neg_hauls$YEAR[irow]
  ] <- "USED NEG HAUL"
  
  affected_subareas <- 
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT AREA_ID FROM 
                                      GAP_PRODUCTS.STRATUM_GROUPS
                                      WHERE STRATUM = ", spp_year_neg_hauls$STRATUM[irow],
                                   "AND SURVEY_DEFINITION_ID = ",
                                   spp_year_neg_hauls$SURVEY_DEFINITION_ID))$AREA_ID
  
  affected_subarea_records <- 
    subset(x = eval_sizecomp$modified_records,
           subset = SURVEY_DEFINITION_ID == spp_year_neg_hauls$SURVEY_DEFINITION_ID[irow] &
             AREA_ID %in% affected_subareas &
             SPECIES_CODE == spp_year_neg_hauls$SPECIES_CODE[irow] & 
             YEAR == spp_year_neg_hauls$YEAR[irow])
  
  if (nrow(x = affected_subarea_records) > 0) 
    eval_sizecomp$modified_records$NOTE[
      eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == spp_year_neg_hauls$SURVEY_DEFINITION_ID[irow] &
        eval_sizecomp$modified_records$AREA_ID %in% affected_subareas &
        eval_sizecomp$modified_records$SPECIES_CODE == spp_year_neg_hauls$SPECIES_CODE[irow] & 
        eval_sizecomp$modified_records$YEAR == spp_year_neg_hauls$YEAR[irow]
    ] <-  "USED NEG HAUL"
}

table(eval_sizecomp$modified_records$NOTE)

unique_size_mismatches <- 
  unique(x = subset(x = eval_sizecomp$modified_records, 
                    subset = NOTE == "",
                    select = c(SURVEY_DEFINITION_ID, AREA_ID, 
                               YEAR, SPECIES_CODE)))

for (irow in 1:nrow(x = unique_size_mismatches)) {
  temp_bio_query <- 
    subset(x = test_biomass,
           subset = SURVEY_DEFINITION_ID == 
             unique_size_mismatches$SURVEY_DEFINITION_ID[irow] &
             AREA_ID == unique_size_mismatches$AREA_ID[irow] & 
             YEAR == unique_size_mismatches$YEAR[irow] & 
             SPECIES_CODE == unique_size_mismatches$SPECIES_CODE[irow])
  temp_size_query <- 
    subset(x = test_sizecomp,
           subset = SURVEY_DEFINITION_ID == 
             unique_size_mismatches$SURVEY_DEFINITION_ID[irow] &
             AREA_ID == unique_size_mismatches$AREA_ID[irow] & 
             YEAR == unique_size_mismatches$YEAR[irow] & 
             SPECIES_CODE == unique_size_mismatches$SPECIES_CODE[irow])
  
  if( nrow(temp_bio_query) == 1)
    if (round(x = 100 * abs(temp_bio_query$POPULATION_COUNT_HIST - 
                            sum(temp_size_query$POPULATION_COUNT_HIST, 
                                na.rm = TRUE)) / 
              temp_bio_query$POPULATION_COUNT_HIST, 
              digits = 2) != 0)
      eval_sizecomp$modified_records$NOTE[
        eval_sizecomp$modified_records$SURVEY_DEFINITION_ID == 
          unique_size_mismatches$SURVEY_DEFINITION_ID[irow] &
          eval_sizecomp$modified_records$AREA_ID == unique_size_mismatches$AREA_ID[irow] & 
          eval_sizecomp$modified_records$YEAR == unique_size_mismatches$YEAR[irow] & 
          eval_sizecomp$modified_records$SPECIES_CODE == unique_size_mismatches$SPECIES_CODE[irow]
      ] <- "TOTAL of SIZECOMP != POP Abundance"
  
}

table(eval_sizecomp$modified_records$NOTE)
subset(eval_sizecomp$modified_records, NOTE == "")

subset(spp_year_neg_hauls, SPECIES_CODE == 21720 & STRATUM == 222)
# subset(test_sizecomp, SPECIES_CODE == 30152 & AREA_ID == 122 & YEAR == 1999)

subset(test_sizecomp, SPECIES_CODE == 21921 & YEAR == 2002 & AREA_ID == 293)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Agecomp Tables 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT SURVEY_DEFINITION_ID, YEAR, SPECIES_CODE,
                           AREA_ID, AGE, SEX, POPULATION_COUNT, 
                           LENGTH_MM_MEAN, LENGTH_MM_SD
                           FROM GAP_PRODUCTS.AGECOMP AGECOMP
                          
                          INNER JOIN (
                           SELECT AREA_ID FROM GAP_PRODUCTS.AREA 
                             WHERE
                             (SURVEY_DEFINITION_ID = 47 
                             AND DESIGN_YEAR = 1984 
                             AND AREA_TYPE = 'REGION')
                             OR
                             (SURVEY_DEFINITION_ID = 52
                             AND DESIGN_YEAR = 1980 
                             AND AREA_TYPE = 'REGION')
                             ) 
                             
                             USING (AREA_ID)
                             
                             WHERE AGECOMP.SURVEY_DEFINITION_ID IN (47, 52)")

# production_agecomp$AGE[production_agecomp$SEX == 3] <- -9

historical_agecomp <-
  rbind(RODBC::sqlQuery(channel = sql_channel,
                        query = "SELECT 47 SURVEY_DEFINITION_ID,
                           99903 AREA_ID,
                           SURVEY_YEAR as YEAR, SPECIES_CODE, SEX, AGE, 
                           ROUND(AGEPOP, 0) as POPULATION_COUNT,
                           ROUND(MEAN_LENGTH, 2) AS LENGTH_MM_MEAN,
                           ROUND(STANDARD_DEVIATION, 2) AS LENGTH_MM_SD 
                           FROM GOA.AGECOMP_TOTAL WHERE SURVEY_YEAR >= 1990"),
        RODBC::sqlQuery(channel = sql_channel,
                        query = "SELECT 52 SURVEY_DEFINITION_ID,
                           99904 AREA_ID,
                           SURVEY_YEAR as YEAR, SPECIES_CODE, SEX, AGE, 
                           ROUND(AGEPOP, 0) as POPULATION_COUNT,
                           ROUND(MEAN_LENGTH, 2) AS LENGTH_MM_MEAN,
                           ROUND(STANDARD_DEVIATION, 2) AS LENGTH_MM_SD 
                           FROM AI.AGECOMP_TOTAL WHERE SURVEY_YEAR >= 1991"))

## Full join the agecomp tables using SURVEY_DEFINITION_ID, YEAR, AREA_ID, 
## SPECIES_CODE, AGE, and SEX as a composite key.
test_agecomp <- merge(x = historical_agecomp, 
                      y = production_agecomp,
                      all = TRUE, 
                      by = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID",
                             "SPECIES_CODE", "AGE", "SEX"),
                      suffixes = c("_HIST", "_PROD"))

## Evaluate the new, removed, and modified records between the HAEHNR
## and GAP_PRODUCTS versions of the agecomp tables. 
eval_agecomp <- 
  compare_tables(
    x = test_agecomp,
    cols_to_check = data.frame(
      colname = c("POPULATION_COUNT"),
      percent = c(T),
      decplaces = c(0)),
    base_table_suffix = "_HIST",
    update_table_suffix = "_PROD",
    key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', "YEAR",
                    "SPECIES_CODE", "SEX", "AGE"))

spp_year_neg_hauls <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT 
                           FLOOR(CRUISE/100) AS YEAR, SPECIES_CODE
                           FROM RACEBASE.SPECIMEN 
                           
                           LEFT JOIN 
                           (SELECT HAULJOIN, PERFORMANCE, STRATUM, ABUNDANCE_HAUL
                            FROM RACEBASE.HAUL)
                           USING (HAULJOIN)

                           WHERE REGION IN ('AI', 'GOA')
                           AND AGE > 0
                           AND (PERFORMANCE < 0 OR ABUNDANCE_HAUL = 'N')
                           AND CRUISE >= 199001
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
## AI or GOA versions of the table. Assign these records a code 13 in the NOTES 
## field.

## Query distinct species codes in the EBS and NBS HAEHNR agecomp tables. 
goa_agecomp_taxa <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT SPECIES_CODE
                           FROM GOA.AGECOMP_TOTAL
                           WHERE SURVEY_YEAR >= 1990")$SPECIES_CODE
ai_agecomp_taxa <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT DISTINCT SPECIES_CODE
                           FROM AI.AGECOMP_TOTAL
                           WHERE SURVEY_YEAR >= 1991")$SPECIES_CODE

for (ispp in goa_agecomp_taxa) { ## Loop over EBS spp -- start
  temp_years <- 
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT DISTINCT SURVEY_YEAR 
                                  FROM GOA.AGECOMP_TOTAL
                                  WHERE SPECIES_CODE = ", ispp, 
                                   " AND SURVEY_YEAR >= 1990 AND AGE > 0"))$SURVEY_YEAR
  eval_agecomp$new_records$NOTE[
    (eval_agecomp$new_records$SURVEY_DEFINITION_ID == 47 
     & eval_agecomp$new_records$SPECIES_CODE == ispp 
     & !eval_agecomp$new_records$YEAR %in% temp_years)
  ] <- 13
} ## Loop over EBS spp -- end

for (ispp in ai_agecomp_taxa) { ## Loop over NBS spp -- start
  temp_years <- 
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT DISTINCT SURVEY_YEAR 
                                  FROM AI.AGECOMP_TOTAL
                                  WHERE SPECIES_CODE = ", ispp, 
                                   " AND SURVEY_YEAR >= 1991 AND AGE > 0"))$SURVEY_YEAR
  eval_agecomp$new_records$NOTE[
    (eval_agecomp$new_records$SURVEY_DEFINITION_ID == 143 
     & eval_agecomp$new_records$SPECIES_CODE == ispp 
     & !eval_agecomp$new_records$YEAR %in% temp_years)
  ] <- 13
} ## Loop over NBS spp -- end

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

for (irow in 1:nrow(x = spp_year)) {
  eval_agecomp$removed_records$NOTE[
    eval_agecomp$removed_records$SPECIES_CODE == spp_year$SPECIES_CODE[irow] &
      eval_agecomp$removed_records$YEAR < spp_year$YEAR_STARTED[irow] 
  ] <- 2
}

table(eval_agecomp$removed_records$NOTE)
subset(eval_agecomp$removed_records, NOTE == "")

for (irow in 1:nrow(x = spp_year_neg_hauls)) {
  eval_agecomp$modified_records$NOTE[
    eval_agecomp$modified_records$SPECIES_CODE == spp_year_neg_hauls$SPECIES_CODE[irow] 
    & eval_agecomp$modified_records$YEAR == spp_year_neg_hauls$YEAR[irow]  
  ] <-12
}

unique_agecomp_mismatches <- 
  unique(x = subset(x = eval_agecomp$modified_records,
                    subset = NOTE == "",
                    select = c(SURVEY_DEFINITION_ID, AREA_ID, 
                               YEAR, SPECIES_CODE)))

for (irow in 1:nrow(x = unique_agecomp_mismatches)) {
  temp_hist_age_query <- 
    unique(subset(x = historical_agecomp,
                  subset = SURVEY_DEFINITION_ID == unique_agecomp_mismatches$SURVEY_DEFINITION_ID[irow] &
                    AREA_ID == unique_agecomp_mismatches$AREA_ID[irow] &
                    YEAR == unique_agecomp_mismatches$YEAR[irow] &
                    SPECIES_CODE == unique_agecomp_mismatches$SPECIES_CODE[irow] )$SEX)
  temp_prod_age_query <- 
    unique(subset(x = production_agecomp,
                  subset = SURVEY_DEFINITION_ID == unique_agecomp_mismatches$SURVEY_DEFINITION_ID[irow] &
                    AREA_ID == unique_agecomp_mismatches$AREA_ID[irow] &
                    YEAR == unique_agecomp_mismatches$YEAR[irow] &
                    SPECIES_CODE == unique_agecomp_mismatches$SPECIES_CODE[irow] )$SEX)
  
  if (length(x = temp_hist_age_query) != length(x = temp_prod_age_query)) {
    eval_agecomp$modified_records[
      eval_agecomp$modified_records$SURVEY_DEFINITION_ID == unique_agecomp_mismatches$SURVEY_DEFINITION_ID[irow] &
        eval_agecomp$modified_records$AREA_ID == unique_agecomp_mismatches$AREA_ID[irow] &
        eval_agecomp$modified_records$YEAR == unique_agecomp_mismatches$YEAR[irow] &
        eval_agecomp$modified_records$SPECIES_CODE == unique_agecomp_mismatches$SPECIES_CODE[irow]
      , ]<- "UNSEXED EXCLUDED"
    eval_agecomp$removed_records[
      eval_agecomp$removed_records$SURVEY_DEFINITION_ID == unique_agecomp_mismatches$SURVEY_DEFINITION_ID[irow] &
        eval_agecomp$removed_records$AREA_ID == unique_agecomp_mismatches$AREA_ID[irow] &
        eval_agecomp$removed_records$YEAR == unique_agecomp_mismatches$YEAR[irow] &
        eval_agecomp$removed_records$SPECIES_CODE == unique_agecomp_mismatches$SPECIES_CODE[irow]
      , ] <- "UNSEXED EXCLUDED"
  }
  
}

unique_agecomp_mismatches <- 
  unique(x = subset(x = eval_agecomp$modified_records, 
                    subset = NOTE == "",
                    select = c(SURVEY_DEFINITION_ID, AREA_ID, 
                               YEAR, SPECIES_CODE)))

for (irow in 1:nrow(x = unique_agecomp_mismatches)) {
  temp_bio_query <- 
    subset(x = test_biomass,
           subset = SURVEY_DEFINITION_ID == 
             unique_agecomp_mismatches$SURVEY_DEFINITION_ID[irow] &
             AREA_ID == unique_agecomp_mismatches$AREA_ID[irow] & 
             YEAR == unique_agecomp_mismatches$YEAR[irow] & 
             SPECIES_CODE == unique_agecomp_mismatches$SPECIES_CODE[irow])
  temp_age_query <- 
    subset(x = test_agecomp,
           subset = SURVEY_DEFINITION_ID == 
             unique_agecomp_mismatches$SURVEY_DEFINITION_ID[irow] &
             AREA_ID == unique_agecomp_mismatches$AREA_ID[irow] & 
             YEAR == unique_agecomp_mismatches$YEAR[irow] & 
             SPECIES_CODE == unique_agecomp_mismatches$SPECIES_CODE[irow])
  
  if( nrow(temp_bio_query) == 1)
    if (round(x = 100 * abs(temp_bio_query$POPULATION_COUNT_HIST - 
                            sum(temp_age_query$POPULATION_COUNT_HIST, 
                                na.rm = TRUE)) / 
              temp_bio_query$POPULATION_COUNT_HIST, 
              digits = 2) != 0)
      eval_agecomp$modified_records$NOTE[
        eval_agecomp$modified_records$SURVEY_DEFINITION_ID == 
          unique_agecomp_mismatches$SURVEY_DEFINITION_ID[irow] &
          eval_agecomp$modified_records$AREA_ID == unique_agecomp_mismatches$AREA_ID[irow] & 
          eval_agecomp$modified_records$YEAR == unique_agecomp_mismatches$YEAR[irow] & 
          eval_agecomp$modified_records$SPECIES_CODE == unique_agecomp_mismatches$SPECIES_CODE[irow]
      ] <- "TOTAL of AGECOMP != POP Abundance"
  
}

table(eval_agecomp$modified_records$NOTE)
subset(eval_agecomp$modified_records, NOTE == "")

subset(test_agecomp, SURVEY_DEFINITION_ID == 47 & YEAR == 2009 & SPECIES_CODE == 21720)

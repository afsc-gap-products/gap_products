##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Data table comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare EBS+PLUSNW and NBS historical data product tables 
##                in the HAEHNR schema with those tables produced in the 
##                GAP_PRODUCTS schema.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
# rm(list = ls())

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
##   Import production tables from GAP_prodUCTS Oracle schema -----------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### CPUE -----------------------------------------------------------------------
# hauljoins_2023 <-
#   c(RODBC::sqlQuery(channel = sql_channel,
#                     query = paste0("SELECT DISTINCT HAULJOIN
#                     FROM HAEHNR.CPUE_EBS_PLUSNW"#,  "WHERE YEAR = 2023"
#                     ))$HAULJOIN,
#     RODBC::sqlQuery(channel = sql_channel,
#                     query = paste0("SELECT DISTINCT HAULJOIN
#                                    FROM HAEHNR.CPUE_NBS"#,  "WHERE YEAR = 2023"
#                     ))$HAULJOIN)

hauljoins <-
  c(RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT DISTINCT HAULJOIN
                    FROM HAEHNR.CPUE_EBS_PLUSNW"#,  "WHERE YEAR = 2023"
                    ))$HAULJOIN,
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT DISTINCT HAULJOIN
                                   FROM HAEHNR.CPUE_NBS"#,  "WHERE YEAR = 2023"
                    ))$HAULJOIN)

start0 <- end0 <- 1
production_cpue <- data.frame()
aa <- (ceiling(length(hauljoins)/999))

for (i in 1:aa) {
  end0 <- ifelse(i == max(aa), length(hauljoins), (start0 + 999))
  production_cpue0 <-
    RODBC::sqlQuery(channel = sql_channel,
                    query = paste0("SELECT *
                                   FROM GAP_prodUCTS.CPUE
                                   WHERE WEIGHT_KG > 0 ",
                                   "AND HAULJOIN IN (",
                                   paste0(hauljoins[start0:end0], collapse = ", "), ")"
                                   ))
  production_cpue <- rbind.data.frame(production_cpue, production_cpue0)
  print(paste0("i = ",i,", start: ", start0, ", end: ", end0, ", diff: ", end0-start0))
  start0 <- end0 + 1
}
production_cpue$CPUE_KGKM2 <- round(production_cpue$CPUE_KGKM2, 2)
production_cpue$CPUE_NOKM2 <- round(production_cpue$CPUE_NOKM2, 2)

### Species --------------------------------------------------------------------
production_spp <- RODBC::sqlQuery(channel = sql_channel,
                                  query = paste0(
                                    "SELECT SPECIES_CODE, COMMON_NAME, SPECIES_NAME ",
                                    "FROM GAP_prodUCTS.AKFIN_TAXONOMIC_CLASSIFICATION"))

### Biomass --------------------------------------------------------------------
production_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT SURVEY_DEFINITION_ID, AREA_ID,
                                 SPECIES_CODE, YEAR, N_HAUL, N_WEIGHT,
                                 N_COUNT, N_LENGTH,
                                 ROUND(CPUE_KGKM2_MEAN, 2) AS CPUE_KGKM2_MEAN,
                                 CPUE_KGKM2_VAR,
                                 CPUE_NOKM2_MEAN,
                                 CPUE_NOKM2_VAR,
                                 ROUND(BIOMASS_MT, 2) AS BIOMASS_MT,
                                 BIOMASS_VAR,
                                 POPULATION_COUNT,
                                 POPULATION_VAR FROM GAP_prodUCTS.BIOMASS ",
                                 "WHERE SURVEY_DEFINITION_ID in (98, 143) ",
                                 # "AND YEAR = 2023 ",
                                 "AND AREA_ID NOT IN (101, 201, 301, 99901)"))

# test_biomass$CPUE_KGKM2_MEAN_hist <- round(test_biomass$CPUE_KGKM2_MEAN_hist, 2)
# test_biomass$CPUE_NOKM2_MEAN_hist <- round(test_biomass$CPUE_NOKM2_MEAN_hist, 2)
# test_biomass$CPUE_KGKM2_VAR_prod <- round(test_biomass$CPUE_KGKM2_VAR_prod, 6)
# test_biomass$BIOMASS_MT_prod <- round(test_biomass$BIOMASS_MT_prod, 2)
# test_biomass$BIOMASS_MT_hist <- round(test_biomass$BIOMASS_MT_hist, 2)
# test_biomass$BIOMASS_VAR_prod <- round(test_biomass$BIOMASS_VAR_prod, 4)

### Size composition -----------------------------------------------------------
production_sizecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT * FROM GAP_prodUCTS.SIZECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID in (98, 143) ",
                                 "AND YEAR = 2023 AND ",
                                 "AREA_ID NOT IN (99901, 101, 201, 301)"))

### Age composition ------------------------------------------------------------
production_agecomp <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, AREA_ID, SEX, ",
                                 "AGE, POPULATION_COUNT, LENGTH_MM_MEAN, ",
                                 "LENGTH_MM_SD FROM GAP_prodUCTS.AGECOMP ",
                                 "WHERE SURVEY_DEFINITION_ID in (98, 143) ",
                                 "AND YEAR = 2022 AND AREA_ID != 99901"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import historical tables from HAEHNR Oracle schema -----------------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### CPUE -----------------------------------------------------------------------
historical_cpue <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT HAULJOIN, SPECIES_CODE, ",
                    "ROUND(CPUE_KGHA * 100, 2) AS CPUE_KGKM2,
                     ROUND(CPUE_NOHA * 100, 2) AS CPUE_NOKM2 ",
                    "FROM HAEHNR.CPUE_EBS_PLUSNW"#,  "WHERE YEAR = 2023"
                  )),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT HAULJOIN, SPECIES_CODE, 
                     ROUND(CPUE_KGHA * 100, 2) AS CPUE_KGKM2,
                     ROUND(CPUE_NOHA * 100, 2) AS CPUE_NOKM2 
                     FROM HAEHNR.CPUE_NBS"#,  "WHERE YEAR = 2023"
                  ))
)

### Species --------------------------------------------------------------------
historical_spp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT SPECIES_CODE, COMMON_NAME, SPECIES_NAME ",
                    "FROM HAEHNR.CPUE_EBS_PLUSNW"#,  "WHERE YEAR = 2023"
                  )),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT SPECIES_CODE, COMMON_NAME, SPECIES_NAME 
                     FROM HAEHNR.CPUE_NBS"#,  "WHERE YEAR = 2023"
                  ))
) 
historical_spp <- unique(historical_spp)

### Biomass --------------------------------------------------------------------
historical_biomass <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT 98 AS SURVEY_DEFINITION_ID, YEAR,
                    CASE 
                      WHEN STRATUM = 999 THEN 99900
                      ELSE STRATUM
                    END AS AREA_ID,
                    SPECIES_CODE, ",
                    "HAULCOUNT as N_HAUL, CATCOUNT AS N_WEIGHT, ",
                    "100 * MEANWGTCPUE AS CPUE_KGKM2_MEAN, ",
                    "10000 * VARMNWGTCPUE AS CPUE_KGKM2_VAR, ",
                    "100 * MEANNUMCPUE AS CPUE_NOKM2_MEAN, ",
                    "10000 * VARMNNUMCPUE AS CPUE_NOKM2_VAR, ",
                    "BIOMASS AS BIOMASS_MT, ",
                    "VARBIO AS BIOMASS_VAR, ",
                    "POPULATION AS POPULATION_COUNT, ",
                    "VARPOP AS POPULATION_VAR ",
                    "FROM HAEHNR.BIOMASS_EBS_PLUSNW"#,  "WHERE YEAR = 2023"
                  )),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT 143 AS SURVEY_DEFINITION_ID, YEAR, 
                     CASE 
                      WHEN STRATUM = 999 THEN 99902
                      ELSE STRATUM
                     END AS AREA_ID,
                    SPECIES_CODE, ",
                    "HAUL_COUNT as N_HAUL,", 
                    "CATCH_COUNT AS N_WEIGHT, ",
                    "MEAN_WGT_CPUE AS CPUE_KGKM2_MEAN, ",
                    "VAR_WGT_CPUE AS CPUE_KGKM2_VAR, ",
                    "MEAN_NUM_CPUE AS CPUE_NOKM2_MEAN, ",
                    "VAR_NUM_CPUE AS CPUE_NOKM2_VAR, ",
                    "STRATUM_BIOMASS AS BIOMASS_MT, ",
                    "BIOMASS_VAR AS BIOMASS_VAR, ",
                    "STRATUM_POP AS POPULATION_COUNT, ",
                    "POP_VAR AS POPULATION_VAR ",
                    "FROM HAEHNR.BIOMASS_NBS_AKFIN"#,  "WHERE YEAR = 2023"
                    ))
)


### Size composition -----------------------------------------------------------
historical_sizecomp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR,
                    CASE 
                      WHEN STRATUM = 999999 THEN 99900
                      ELSE STRATUM
                    END AS AREA_ID,
                    SPECIES_CODE, ",
                    "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                    "FROM HAEHNR.SIZECOMP_EBS_PLUSNW_STRATUM"#,  "WHERE YEAR = 2023"
                  )),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, 
                    CASE 
                      WHEN STRATUM = 999999 THEN 99902
                      ELSE STRATUM
                    END AS AREA_ID, SPECIES_CODE, ",
                    "LENGTH as LENGTH_MM, MALES, FEMALES, UNSEXED ",
                    "FROM HAEHNR.SIZECOMP_NBS_STRATUM"#,  "WHERE YEAR = 2023"
                  ))
  
)

# historical_sizecomp$AREA_ID[historical_sizecomp$AREA_ID == 999999] <- 99900
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

### Age composition ------------------------------------------------------------
historical_agecomp <- rbind(
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, ",
                                 "CASE 
                                    WHEN STRATUM = 999999 THEN 99900
                                    ELSE STRATUM
                                  END AS AREA_ID, SEX, AGE, ",
                                 "AGEPOP as POPULATION_COUNT, ",
                                 "MEANLEN AS LENGTH_MM_MEAN , ",
                                 "SDEV AS LENGTH_MM_SD FROM ",
                                 "HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM "#,"WHERE YEAR = 2022"
                                 )),
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT YEAR, SPECIES_CODE, ",
                                 "CASE 
                                    WHEN STRATUM = 999999 THEN 99902
                                    ELSE STRATUM
                                  END AS AREA_ID, SEX, AGE, ",
                                 "AGEPOP as POPULATION_COUNT, ",
                                 "MEANLEN AS LENGTH_MM_MEAN , ",
                                 "SDEV AS LENGTH_MM_SD FROM ",
                                 "HAEHNR.AGECOMP_NBS_STRATUM "#, "WHERE YEAR = 2022"
                                 )) 
)

historical_agecomp$LENGTH_MM_MEAN <- 
  round(x = historical_agecomp$LENGTH_MM_MEAN, digits = 2)
historical_agecomp$LENGTH_MM_SD <- 
  round(x = historical_agecomp$LENGTH_MM_SD, digits = 2)
historical_agecomp$POPULATION_COUNT <-
  round(x = historical_agecomp$POPULATION_COUNT, digits = 0)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Tables -----------------------------------------------------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### CPUE --------------------------------------------------------------------

## Merge CPUE tables using HAULJOIN and SPECIES_CODE as a composite key. 
test_cpue <-
  merge(x = subset(x = production_cpue,
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE)), 
        y = historical_cpue,
        by = c("HAULJOIN", "SPECIES_CODE"),
        suffixes = c("_prod", "_hist"))

test_cpue$CPUE_KGKM2 <- 
  round(x = test_cpue$CPUE_KGKM2_prod - test_cpue$CPUE_KGKM2_hist, digits = 6)
test_cpue$CPUE_NOKM2 <- 
  round(x = test_cpue$CPUE_NOKM2_prod - test_cpue$CPUE_NOKM2_hist, digits = 6)

mismatch_cpue <- subset(x = test_cpue, 
                        subset = CPUE_KGKM2 != 0 | is.na(x = CPUE_KGKM2) |
                          CPUE_NOKM2 != 0 | is.na(x = CPUE_NOKM2))

mismatch_cpue <- 
  subset(x = mismatch_cpue,
         subset = !(is.na(x = COUNT) & 
                      is.na(x = CPUE_NOKM2_prod) &
                      is.na(x = CPUE_NOKM2_hist)) )

### Species --------------------------------------------------------------------

# production_spp$SPECIES_CODE <- trimws(production_spp$SPECIES_CODE)
# production_spp$COMMON_NAME <- trimws(production_spp$COMMON_NAME)
# production_spp$SPECIES_NAME <- trimws(production_spp$SPECIES_NAME)
# 
# historical_spp$SPECIES_CODE <- trimws(historical_spp$SPECIES_CODE)
# historical_spp$COMMON_NAME <- trimws(historical_spp$COMMON_NAME)
# historical_spp$SPECIES_NAME <- trimws(mismatch_spp$SPECIES_NAME)

mismatch_spp <-
  merge(x = subset(x = unique(production_spp),
                   subset = SPECIES_CODE %in% 
                     unique(x = historical_cpue$SPECIES_CODE)), 
        y = unique(historical_spp),
        by = c("SPECIES_CODE"),
        suffixes = c("_prod", "_hist"))


mismatch_spp$SPECIES_NAME_diff <- (mismatch_spp$SPECIES_NAME_prod != mismatch_spp$SPECIES_NAME_hist)
mismatch_spp$SPECIES_NAME_diff <- ifelse(is.na(mismatch_spp$SPECIES_NAME_diff), FALSE, mismatch_spp$SPECIES_NAME_diff)
mismatch_spp$COMMON_NAME_diff <- (mismatch_spp$COMMON_NAME_prod != mismatch_spp$COMMON_NAME_hist)
mismatch_spp$COMMON_NAME_diff <- ifelse(is.na(mismatch_spp$COMMON_NAME_diff), FALSE, mismatch_spp$COMMON_NAME_diff)

mismatch_spp <- 
  subset(x = mismatch_spp,
         subset = (SPECIES_NAME_diff | COMMON_NAME_diff) )

production_spp_change <- RODBC::sqlQuery(channel = sql_channel,
                                  query = paste0(
                                    "SELECT *",
                                    "FROM GAP_prodUCTS.TAXONOMIC_CHANGES
                                    WHERE YEAR_CHANGED = 2023")) 
mismatch_spp_change <- production_spp_change[(production_spp_change$OLD_SPECIES_CODE %in% 
                                                 historical_spp$SPECIES_CODE |
                                                 production_spp_change$NEW_SPECIES_CODE %in% 
                                                 production_spp$SPECIES_CODE), ]

### Biomass --------------------------------------------------------------------

# historical_biomass <- 
#   subset(x = historical_biomass,
#          subset = SPECIES_CODE %in% 
#            unique(x = production_biomass$SPECIES_CODE))

## Merge BIOMASS tables using YEAR, STRATUM, AND SPECIES_CODE as composite key. 
test_biomass <- merge(y = historical_biomass,
                      x = production_biomass,
                      # x = subset(x = production_biomass,
                      #            subset = SPECIES_CODE %in%
                      #              unique(historical_biomass$SPECIES_CODE)),
                      by = c("SURVEY_DEFINITION_ID", "YEAR", "AREA_ID", "SPECIES_CODE"),
                      all = TRUE, 
                      # all.x = TRUE, 
                      suffixes = c("_prod", "_hist"))

test_biomass$CPUE_KGKM2_MEAN_hist <- round(test_biomass$CPUE_KGKM2_MEAN_hist, 2)
test_biomass$CPUE_NOKM2_MEAN_hist <- round(test_biomass$CPUE_NOKM2_MEAN_hist, 2)
test_biomass$CPUE_KGKM2_VAR_prod <- round(test_biomass$CPUE_KGKM2_VAR_prod, 6)
test_biomass$BIOMASS_MT_prod <- round(test_biomass$BIOMASS_MT_prod, 2)
test_biomass$BIOMASS_MT_hist <- round(test_biomass$BIOMASS_MT_hist, 2)
test_biomass$BIOMASS_VAR_hist <- round(test_biomass$BIOMASS_VAR_hist, 4)

test_biomass$CPUE_NOKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_VAR_prod - CPUE_NOKM2_VAR_hist) / ifelse(CPUE_NOKM2_VAR_hist == 0, 1, CPUE_NOKM2_VAR_hist) ))
test_biomass$CPUE_NOKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_NOKM2_MEAN_prod - CPUE_NOKM2_MEAN_hist) / ifelse(CPUE_NOKM2_MEAN_hist == 0, 1, CPUE_NOKM2_MEAN_hist) ))

test_biomass$CPUE_KGKM2_VAR <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_VAR_prod - CPUE_KGKM2_VAR_hist) / ifelse(CPUE_KGKM2_VAR_hist == 0, 1, CPUE_KGKM2_VAR_hist) ))
test_biomass$CPUE_KGKM2_MEAN <- 
  with(test_biomass, round(100 * (CPUE_KGKM2_MEAN_prod - CPUE_KGKM2_MEAN_hist) / ifelse(CPUE_KGKM2_MEAN_hist == 0, 1, CPUE_KGKM2_MEAN_hist) ))

test_biomass$N_HAUL <- 
  with(test_biomass, N_HAUL_prod - N_HAUL_hist)
test_biomass$N_WEIGHT <- 
  with(test_biomass, N_WEIGHT_prod - N_WEIGHT_hist)

test_biomass$BIOMASS_MT <- 
  with(test_biomass, round((BIOMASS_MT_prod - BIOMASS_MT_hist)/ifelse(BIOMASS_MT_hist == 0, 1, BIOMASS_MT_hist), 2) ) 

test_biomass$POPULATION_COUNT <- 
  with(test_biomass, round((POPULATION_COUNT_prod - POPULATION_COUNT_hist)/ifelse(POPULATION_COUNT_hist == 0, 1, POPULATION_COUNT_hist), 2) ) 

test_biomass$BIOMASS_VAR <- 
  with(test_biomass, round((BIOMASS_VAR_prod - BIOMASS_VAR_hist)/ifelse(BIOMASS_VAR_hist == 0, 1, BIOMASS_VAR_hist), 2) ) 
test_biomass$POPULATION_VAR <- 
  with(test_biomass, round((POPULATION_VAR_prod - POPULATION_VAR_hist)/ifelse(POPULATION_VAR_hist == 0, 1, POPULATION_VAR_hist), 2) ) 


## Subset mismatched records
mismatch_biomass <- 
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

subset(mismatch_biomass, 
       select = c(YEAR, AREA_ID, SPECIES_CODE, N_WEIGHT_hist, N_COUNT, 
                  CPUE_NOKM2_VAR_hist, CPUE_NOKM2_VAR_prod, CPUE_NOKM2_VAR,
                  POPULATION_VAR_hist, POPULATION_VAR_prod, POPULATION_VAR))

### Sizecomp -------------------------------------------------------------------

length(x = unique(x = production_sizecomp$SPECIES_CODE))
length(x = unique(x = historical_sizecomp$SPECIES_CODE))

## Merge SIZECOMP tables using YEAR, STRATUM, SPECIES_CODE, and LENGTH_MM
## as a composite key. 
test_sizecomp <- merge(x = historical_sizecomp,
                       y = production_sizecomp,
                       by = c("YEAR", "AREA_ID", "SPECIES_CODE", 
                              "LENGTH_MM", "SEX"),
                       all = TRUE, 
                       suffixes = c("_hist", "_prod"))

## Calculate difference between size comps
test_sizecomp$DIFF <- 
  with(test_sizecomp, POPULATION_COUNT_hist - POPULATION_COUNT_prod)

## Subset mismatched records
mismatch_sizecomp <- subset(test_sizecomp, abs(DIFF) > 3 | is.na(x = DIFF))

### Age comps ------------------------------------------------------------------
test_agecomp <- merge(x = historical_agecomp, 
                      y = production_agecomp,
                      all = TRUE, 
                      by = c("YEAR", "AREA_ID", "SPECIES_CODE", "AGE", "SEX"),
                      suffixes = c("_hist", "_prod"))

test_agecomp$POPULATION_COUNT <- 
  with(test_agecomp, POPULATION_COUNT_prod - POPULATION_COUNT_hist)
test_agecomp$LENGTH_MM_MEAN <- 
  with(test_agecomp, 
       round(x = 100 * (LENGTH_MM_MEAN_prod - LENGTH_MM_MEAN_hist) / 
               LENGTH_MM_MEAN_prod, 
             digits = 2))

test_agecomp$LENGTH_MM_SD <- 
  with(test_agecomp, 
       round(x = 100 * (LENGTH_MM_SD_prod - LENGTH_MM_SD_hist) / 
               ifelse(test = LENGTH_MM_SD_prod == 0, 1, LENGTH_MM_SD_prod), 
             digits = 2))

mismatch_age <- 
  subset(x = test_agecomp, 
         subset =  abs(POPULATION_COUNT) > 8 | is.na(x = POPULATION_COUNT) |
           LENGTH_MM_MEAN != 0 | is.na(x = LENGTH_MM_MEAN) |
           LENGTH_MM_SD != 0 | is.na(x = LENGTH_MM_SD))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Combine all mismatches ---------------------------------------------------
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_mismatches <- 
  list(cpue = mismatch_cpue,
       species = mismatch_spp,
       species_changes = mismatch_spp_change, 
       biomass = mismatch_biomass,
       sizecomp = mismatch_sizecomp,
       agecomp = mismatch_age)

# save(all_mismatches, file = here::here("temp", "all_mismatches_2023"))

rmarkdown::render(here::here("code/historical_comparisons/2023_comparison/mismatch_report.Rmd"),
                  output_dir = here::here("temp"),
                  output_file = "mismatch_report_2023_bs.docx")


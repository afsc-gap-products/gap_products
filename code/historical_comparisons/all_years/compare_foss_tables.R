##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Compare FOSS tables
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare FOSS CPUE View in GAP_PRODUCTS with GAP_PRODUCTS.CPUE
##                and the taxonomic tables. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import libraries, connect to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import tables from Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## all hauls with abundance_haul == "Y"
all_hauls <- RODBC::sqlQuery(channel = sql_channel,
                             query = paste0("SELECT HAULJOIN, REGION, CRUISE,",
                                            "STRATUM FROM RACEBASE.HAUL ",
                                            "WHERE ABUNDANCE_HAUL = 'Y'"))

## FOSS CPUE table
foss_cpue <- RODBC::sqlQuery(channel = sql_channel,
                             query = paste0("SELECT * ",
                                            "FROM GAP_PRODUCTS.FOSS_CATCH"))

## GAP_PRODUCTS CPUE table
gp_cpue <- RODBC::sqlQuery(channel = sql_channel,
                           query = paste0("SELECT * FROM GAP_PRODUCTS.CPUE"))

## GAP_PRODUCTS WORMS DB
gp_worms <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT SPECIES_CODE, ACCEPTED_NAME as SCIENTIFIC_NAME, ",
                                 "COMMON_NAME, DATABASE_ID AS WORMS ",
                                 "FROM GAP_PRODUCTS.TAXONOMICS_WORMS"))
gp_itis <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0("SELECT SPECIES_CODE, SURVEY_NAME AS SCIENTIFIC_NAME, ",
                                 "COMMON_NAME, DATABASE_ID AS ITIS ",
                                 "FROM GAP_PRODUCTS.TAXONOMICS_ITIS"))

nrow(foss_cpue); nrow(gp_cpue)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Merge CPUE values. Filter out Mock GOA data by only subsetting CPUE
##   with HAULJOIN values contained within `all_hauls`
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cpue <- merge(x = subset(x = foss_cpue, 
                         subset = HAULJOIN %in% all_hauls$HAULJOIN),
              y = subset(x = gp_cpue, 
                         subset = HAULJOIN %in% all_hauls$HAULJOIN),
              all.x = TRUE, all.y = TRUE,
              by = c("HAULJOIN", "SPECIES_CODE"),
              suffixes = c("_FOSS", "_GP"))

## Comare weights, counts, CPUE values
cpue$WEIGHT <- cpue$WEIGHT_KG_FOSS - cpue$WEIGHT_KG_GP
cpue$COUNT <- cpue$COUNT_FOSS - cpue$COUNT_GP
cpue$CPUE_KGKM2 <- cpue$CPUE_KGKM2_FOSS - cpue$CPUE_KGKM2_GP
cpue$CPUE_NOKM2 <- cpue$CPUE_NOKM2_FOSS - cpue$CPUE_NOKM2_GP

## Subset CPUE values where WEIGHT, COUNT, CPUEs are either != 0 or NA
mismatch_cpue <- subset(x = cpue,
                        subset = WEIGHT != 0 | is.na(x = WEIGHT) |
                          COUNT != 0 | is.na(x = COUNT) |
                          CPUE_KGKM2 != 0 | is.na(x = CPUE_KGKM2) |
                          CPUE_NOKM2 != 0 | is.na(x = CPUE_NOKM2))
## Filter out instances where the weight comparison is zero but no counts
## were collected
mismatch_cpue <- subset(x = mismatch_cpue,
                        subset = !(WEIGHT == 0 & 
                                     is.na(x = COUNT_FOSS) & 
                                     is.na(x = COUNT_GP) ))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Save results
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
write.csv(x = subset(x = all_hauls, 
                     subset = HAULJOIN %in% unique(x = mismatch_cpue$HAULJOIN)),
          file = "temp/foss_cpue_mismatch.csv")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare Taxonomic Information
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foss_cpue_spp <- unique(subset(foss_cpue, select = c(HAULJOIN, SPECIES_CODE)))
foss_cpue_worms <- merge(x = foss_cpue, y = gp_worms, by = "SPECIES_CODE", suffixes = c("_FOSS", "_GP"))
foss_cpue_itis <- merge(x = foss_cpue, y = gp_itis, by = "SPECIES_CODE", suffixes = c("_FOSS", "_GP"))

foss_cpue_worms[is.na(foss_cpue_worms)] <- ""

foss_cpue_worms$SCIENTIFIC_NAME <- 
  with(foss_cpue_worms, SCIENTIFIC_NAME_FOSS == SCIENTIFIC_NAME_GP)
foss_cpue_worms$COMMON_NAME <- 
  with(foss_cpue_worms, COMMON_NAME_FOSS == COMMON_NAME_GP)
foss_cpue_worms$WORMS  <- 
  with(foss_cpue_worms, WORMS_FOSS == WORMS_GP)

head(foss_cpue_worms)
all(foss_cpue_worms$SCIENTIFIC_NAME)
all(foss_cpue_worms$COMMON_NAME)
all(foss_cpue_worms$WORMS)

subset(foss_cpue_worms, SCIENTIFIC_NAME == F)

foss_cpue_itis[is.na(foss_cpue_itis)] <- ""

foss_cpue_itis$SCIENTIFIC_NAME <- 
  with(foss_cpue_itis, SCIENTIFIC_NAME_FOSS == SCIENTIFIC_NAME_GP)
foss_cpue_itis$COMMON_NAME <- 
  with(foss_cpue_itis, COMMON_NAME_FOSS == COMMON_NAME_GP)
foss_cpue_itis$itis  <- 
  with(foss_cpue_itis, ITIS_FOSS == ITIS_GP)

head(foss_cpue_itis)
all(foss_cpue_itis$SCIENTIFIC_NAME)
all(foss_cpue_itis$COMMON_NAME)
all(foss_cpue_itis$itis)

unique(x = subset(x = foss_cpue_worms, 
                  subset = SCIENTIFIC_NAME == F, 
                  select = c(SPECIES_CODE, 
                             SCIENTIFIC_NAME_GP, 
                             SCIENTIFIC_NAME_FOSS)))

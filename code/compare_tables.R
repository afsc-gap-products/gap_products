##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Table Comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare production tables with existing production tables
##                in the GAP_PRODUCTS schema (CPUE, BIOMASS, SIZECOMP, AGECOMP)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Main result object
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mismatches <- list()
regions <- c("AI", "GOA", "EBS", "BSS", "NBS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over regions, Merge GAP_PRODUCTS and production CPUE/BIOMASS/SIZE/
##   AGE tables 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (iregion in 1:length(x = regions)) {
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##   Pull CPUE tables from the GAP_PRODUCTS schema and the most recent 
  ##   production run. 
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gp_cpue <- read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_CPUE", 
                                    "_", regions[iregion], ".csv"))
  production_cpue <- read.csv(file = paste0("temp/production/production_cpue", 
                                            "_", regions[iregion], ".csv"))
  
  ## Merge the two tables together using HAULJOIN AND SPECIES_CODE as a 
  ## composite key
  test_cpue <- merge(x = production_cpue,
                     y = gp_cpue,
                     all = TRUE,
                     suffixes = c("_prod", "_gp"),
                     by = c("HAULJOIN", "SPECIES_CODE"))
  
  ## Compare the CPUEs, weights, and counts
  test_cpue$CPUE_NOKM2 <- with(test_cpue, round(CPUE_NOKM2_gp - CPUE_NOKM2_prod, 2))
  test_cpue$CPUE_KGKM2 <- with(test_cpue, round(CPUE_KGKM2_gp - CPUE_KGKM2_prod, 2))
  test_cpue$COUNT <- with(test_cpue, COUNT_gp - COUNT_prod)
  test_cpue$WEIGHT_KG <- with(test_cpue, round(WEIGHT_KG_gp, 2) - 
                                round(WEIGHT_KG_prod, 2))
  
  ## Subset records where there's a non-zero or NA match between the two tables
  cpue_mismatches <-
    unique(subset(x = test_cpue,
                  subset = abs(COUNT) != 0 | is.na(COUNT) |
                    WEIGHT_KG != 0 | is.na(WEIGHT_KG) ))
  
  cpue_mismatches <-
    unique(subset(x =cpue_mismatches,
                  subset = !is.na(COUNT_prod) & !is.na(COUNT_gp),
                  select = c(HAULJOIN, SPECIES_CODE, SURVEY, STRATUM, YEAR,
                             COUNT_prod, COUNT_gp, WEIGHT_KG_prod, WEIGHT_KG_gp,
                             CPUE_KGKM2_prod, CPUE_KGKM2_gp,
                             CPUE_NOKM2_prod, CPUE_NOKM2_gp,
                             CPUE_NOKM2, CPUE_KGKM2)))
  
  ## Attach to main results object
  mismatches$cpue <- rbind(mismatches$cpue, cpue_mismatches)
  
  cat(paste0("Finished with CPUE for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##   Pull BIOMASS tables from the GAP_PRODUCTS schema and the most recent 
  ##   production run. 
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gp_biomass <- 
    subset(x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_BIOMASS",
                                      "_", regions[iregion], ".csv")))
  production_biomass <- 
    read.csv(file = paste0("temp/production/production_biomass", 
                           "_", regions[iregion], ".csv"))
  
  production_strata <- 
    read.csv(paste0("temp/production/production_strata_",
                    regions[iregion], ".csv"))
  
  ## Merge the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
  ## SPECIES_CODE, and YEAR as a composite key
  test_biomass <- 
    merge(x = subset(x = production_biomass,
                     subset = AREA_ID %in% production_strata$STRATUM,
                     select = -SURVEY),
          y = subset(x = gp_biomass, 
                     subset = YEAR < 2025 & 
                       AREA_ID %in% production_strata$STRATUM),
          all.x = TRUE, all.y = TRUE,
          suffixes = c("_prod", "_gp"),
          by = c("SURVEY_DEFINITION_ID", 'AREA_ID',
                 "SPECIES_CODE", "YEAR"))
  
  ## Compare the total population count
  test_biomass$POPULATION_COUNT <- 
    with(test_biomass,
         round(x = POPULATION_COUNT_gp - POPULATION_COUNT_prod,
               digits = 0))
  
  ## Compare the total biomass  
  test_biomass$BIOMASS_MT <- 
    with(test_biomass,
         round(x = BIOMASS_MT_gp - BIOMASS_MT_prod,
               digits = 0))
  
  ## Compare the number of hauls with positive weights
  test_biomass$N_WEIGHT <- with(test_biomass, N_WEIGHT_gp - N_WEIGHT_prod)
  test_biomass$N_COUNT <- with(test_biomass, N_COUNT_gp - N_COUNT_prod)
  
  ## Subset records where there's a non-zero or NA match between the two tables
  # biomass_mismatch <-
  #   subset(x = test_biomass,
  #          subset = POPULATION_COUNT != 0 | is.na(POPULATION_COUNT) |
  #            BIOMASS_MT != 0 | is.na(BIOMASS_MT)  )
  
  biomass_mismatch <-
    subset(x = test_biomass,
           subset = N_WEIGHT != 0 | is.na(N_WEIGHT) |
             N_COUNT != 0 | is.na(N_COUNT) |
             POPULATION_COUNT != 0 | is.na(POPULATION_COUNT) |
             BIOMASS_MT != 0 | is.na(BIOMASS_MT))
  
  ## Attach to main results object
  mismatches$biomass <- rbind(mismatches$biomass, biomass_mismatch)
  
  cat(paste0("Finished with BIOMASS for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent 
  ##   production run. 
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gp_sizecomp <- read.csv(file = paste0("temp/GAP_PRODUCTS_SIZECOMP",
                                        "_", regions[iregion],
                                        ".csv"))
  production_sizecomp <- read.csv(file = paste0("temp/production_sizecomp", 
                                                "_", regions[iregion], ".csv"))
  
  ## Merge the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
  ## YEAR, and SPECIES_CODE, SEX, AND LENGTH_MM as a composite key
  test_sizecomp <- merge(x = gp_sizecomp,
                         y = production_sizecomp,
                         all.x = TRUE, all.y = TRUE,
                         suffixes = c("_gp", "_prod"),
                         by = c("SURVEY_DEFINITION_ID", "AREA_ID", "YEAR",
                                "SPECIES_CODE", "SEX", "LENGTH_MM"))
  
  ## Compare the total population count
  test_sizecomp$POPULATION_COUNT <-
    with(test_sizecomp, round(POPULATION_COUNT_gp - POPULATION_COUNT_prod))
  
  ## Subset records where there's a non-zero or NA match between the two tables
  sizecomp_mismatch <- subset(x = test_sizecomp,
                              subset = POPULATION_COUNT != 0 | 
                                is.na(POPULATION_COUNT))
  
  ## Attach to main results object
  mismatches$sizecomp <- rbind(mismatches$sizecomp, sizecomp_mismatch)
  
  cat(paste0("Finished with SIZECOMP for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Pull age composition tables   
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gp_agecomp <- subset(x = read.csv(file = paste0("temp/GAP_PRODUCTS_AGECOMP",
                                                  "_", regions[iregion],
                                                  ".csv")))
  production_agecomp <- read.csv(file = paste0("temp/production_agecomp", 
                                               "_", regions[iregion], ".csv"))
  
  ## Merge the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
  ## YEAR, and SPECIES_CODE, SEX, AND AGE as a composite key
  test_agecomp <- merge(x = gp_agecomp,
                        y = subset(x = production_agecomp, select = -SURVEY),
                        all.x = TRUE, all.y = TRUE,
                        suffixes = c("_gp", "_prod"),
                        by = c("SURVEY_DEFINITION_ID", "AREA_ID", "YEAR",
                               "SPECIES_CODE", "SEX", "AGE"))
  
  ## Compare the total population count
  test_agecomp$POPULATION_COUNT <-
    with(test_agecomp, POPULATION_COUNT_gp - POPULATION_COUNT_prod) 
  
  ## Compare the mean length
  test_agecomp$LENGTH_MM_MEAN <-
    test_agecomp$LENGTH_MM_MEAN_gp - test_agecomp$LENGTH_MM_MEAN_prod
  
  ## Compare the sd of the mean length
  test_agecomp$LENGTH_MM_SD <-
    test_agecomp$LENGTH_MM_SD_gp - test_agecomp$LENGTH_MM_SD_prod
  
  ## Remove the GOA mock data (for now) and species not in the ALK
  agecomp_mismatch <-
    subset(x = test_agecomp,
           subset = POPULATION_COUNT != 0 | is.na(POPULATION_COUNT) |
             LENGTH_MM_MEAN != 0 | is.na(LENGTH_MM_MEAN) |
             LENGTH_MM_SD != 0 | is.na(LENGTH_MM_SD))
  
  ## Attach to main results object
  mismatches$agecomp <- rbind(mismatches$agecomp, agecomp_mismatch)
  
  cat(paste0("Finished with AGECOMP for the ", regions[iregion], " Region\n"))
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Save mismatch object
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
saveRDS(object = mismatches, file = "temp/mismatches.RDS")

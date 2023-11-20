##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Table Comparison
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Compare production tables contained in the temp/ foler 
##                created using the produciton.R script with existing 
##                production tables in the GAP_PRODUCTS schema:
##                1) CPUE, 2) BIOMASS, 3) SIZECOMP, 4) AGECOMP
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())
options(scipen = 999999)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Shortcut Functions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source(file = "functions/calc_diff.R")
source(file = "functions/compare_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Main result object
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mismatches <- list()
regions <- c("AI", "GOA", "EBS", "BSS", "NBS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over regions, Pull in the current version of each data table, the 
##   updated version of the data table, Full join the two tables, evaluate
##   the 1) new records, 2) removed records, and 3) modified records. Then,
##   append to the mismatches list. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (iregion in 1:length(x = regions)) { ## Loop over regions -- start
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  CPUE TABLE
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  ## Pull CPUE tables from the GAP_PRODUCTS schema and the most recent run. 
  gp_cpue <- read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_CPUE", 
                                    "_", regions[iregion], ".csv"))
  production_cpue <- read.csv(file = paste0("temp/production/production_cpue", 
                                            "_", regions[iregion], ".csv"))
  
  ## Full join the two tables together using HAULJOIN AND SPECIES_CODE as a 
  ## composite key
  test_cpue <- merge(x = production_cpue,
                     y = gp_cpue,
                     all = TRUE,
                     suffixes = c("_UPDATE", "_CURRENT"),
                     by = c("HAULJOIN", "SPECIES_CODE"))
  
  ## Evaluate the new, removed, and modified records between the two tables
  eval_cpue <- 
    compare_tables(
      x = test_cpue,
      cols_to_check = data.frame(
        colname = c("WEIGHT_KG", "COUNT", "CPUE_KGKM2", "CPUE_NOKM2"),
        percent = c(F, F, F, F),
        decplaces = c(2, 0, 2, 2)),
      base_table_suffix = "_CURRENT",
      update_table_suffix = "_UPDATE",
      key_columns = c("HAULJOIN", "SPECIES_CODE"))
  
  ## Ignore very, very small cpue discrepancies when the weight or count of the
  ## record has not changed.
  eval_cpue$modified_records <- 
    subset(x = eval_cpue$modified_records, 
           subset = WEIGHT_KG_DIFF != 0 | COUNT_DIFF != 0)
  
  cat(paste0("Finished with CPUE for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  BIOMASS TABLE
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  ## Pull BIOMASS tables from the GAP_PRODUCTS schema and the most recent ruN
  gp_biomass <- 
    subset(x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_BIOMASS",
                                      "_", regions[iregion], ".csv")))
  production_biomass <- 
    read.csv(file = paste0("temp/production/production_biomass", 
                           "_", regions[iregion], ".csv"))
  for (icol in c("CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", "CPUE_NOKM2_MEAN",
                 "CPUE_NOKM2_VAR", "BIOMASS_MT", "BIOMASS_VAR"))
    production_biomass[, icol] <- 
    round(x = production_biomass[, icol], digits = 6)
  
  ## Full join the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
  ## SPECIES_CODE, and YEAR as a composite key
  test_biomass <- 
    merge(x = subset(x = production_biomass,
                     ## Don't compare mock GOA 2025 data
                     subset = YEAR != 2025,
                     select = -SURVEY),
          y = subset(x = gp_biomass,
                     ## Don't compare mock GOA 2025 data
                     subset = YEAR != 2025),
          all = TRUE,
          suffixes = c("_UPDATE", "_CURRENT"),
          by = c("SURVEY_DEFINITION_ID", 'AREA_ID', "SPECIES_CODE", "YEAR"))
  
  ## Evaluate the new, removed, and modified records between the two tables
  eval_biomass <- 
    compare_tables(
      x = test_biomass,
      cols_to_check = data.frame(
        colname = c("N_WEIGHT", "N_COUNT", 
                    "CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                    "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR", 
                    "BIOMASS_MT", "BIOMASS_VAR", 
                    "POPULATION_COUNT", "POPULATION_VAR"),
        percent = c(F, F, T, T, T, T, T, T, T, T),
        decplaces = c(0, 0, 2, 2, 2, 2, 2, 2, 2, 2)),
      base_table_suffix = "_CURRENT",
      update_table_suffix = "_UPDATE",
      key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', 
                      "SPECIES_CODE", "YEAR"))
  
  cat(paste0("Finished with BIOMASS for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  SIZECOMP TABLE
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent run
  gp_sizecomp <- 
    read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_SIZECOMP",
                           "_", regions[iregion], ".csv"))
  production_sizecomp <- 
    read.csv(file = paste0("temp/production/production_sizecomp", 
                           "_", regions[iregion], ".csv"))
  
  ## Full join the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
  ## YEAR, and SPECIES_CODE, SEX, AND LENGTH_MM as a composite key
  test_sizecomp <- merge(x = subset(x = gp_sizecomp,
                                    ## Don't compare mock GOA 2025 data
                                    subset = YEAR != 2025),
                         y = subset(x = production_sizecomp,
                                    ## Don't compare mock GOA 2025 data
                                    subset = YEAR != 2025),
                         all = TRUE,
                         suffixes = c("_CURRENT", "_UPDATE"),
                         by = c("SURVEY_DEFINITION_ID", "AREA_ID", "YEAR",
                                "SPECIES_CODE", "SEX", "LENGTH_MM"))
  
  ## Evaluate the new, removed, and modified records between the two tables
  eval_sizecomp <- 
    compare_tables(
      x = test_sizecomp,
      cols_to_check = data.frame(
        colname = "POPULATION_COUNT",
        percent = F,
        decplaces = 0),
      base_table_suffix = "_CURRENT",
      update_table_suffix = "_UPDATE",
      key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', "YEAR",
                      "SPECIES_CODE", "SEX", "LENGTH_MM"))
  
  cat(paste0("Finished with SIZECOMP for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  Age Composition Table
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent run
  gp_agecomp <- 
    subset(x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_AGECOMP",
                                      "_", regions[iregion], ".csv")))
  production_agecomp <- 
    read.csv(file = paste0("temp/production/production_agecomp", 
                           "_", regions[iregion], ".csv"))
  
  ## Full join the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
  ## YEAR, and SPECIES_CODE, SEX, AND AGE as a composite key
  test_agecomp <- merge(x = subset(x = gp_agecomp,
                                   ## Don't compare mock GOA 2025 data
                                   subset = YEAR != 2025),
                        y = subset(x = production_agecomp,
                                   ## Don't compare mock GOA 2025 data
                                   subset = YEAR != 2025),
                        all = TRUE,
                        suffixes = c("_CURRENT", "_UPDATE"),
                        by = c("SURVEY_DEFINITION_ID", "AREA_ID", "YEAR",
                               "SPECIES_CODE", "SEX", "AGE"))
  
  ## Evaluate the new, removed, and modified records between the two tables
  eval_agecomp <- 
    compare_tables(
      x = test_agecomp,
      cols_to_check = data.frame(
        colname = c("POPULATION_COUNT", "LENGTH_MM_MEAN", "LENGTH_MM_SD"),
        percent = c(F, T, T),
        decplaces = c(0, 2, 2)),
      base_table_suffix = "_CURRENT",
      update_table_suffix = "_UPDATE",
      key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', "YEAR",
                      "SPECIES_CODE", "SEX", "AGE"))
  
  cat(paste0("Finished with AGECOMP for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  Attach to mismatch objects
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  mismatches[[regions[iregion]]] <- 
    list(cpue = eval_cpue,
         biomass = eval_biomass,
         sizecomp = eval_sizecomp,
         agecomp = eval_agecomp)
  
} ## Loop over regions -- end

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Save mismatch object
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
saveRDS(object = mismatches, file = "temp/mismatches.RDS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Look at the mismatch object and write a quick paragraph about the changes
##   in the data tables. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gapindex_version <- 
  subset(x = read.csv(file = "temp/installed_packages.csv"),
         subset = Package == "gapindex")$Version

detailed_notes <- 
  "A new version of gapindex ([v2.1.2](https://github.com/afsc-gap-products/gapindex/releases/tag/v2.1.2)) was used to produced these data. There was a slight change to how subarea biomass totals are calculated that was not fully addressed in v2.1.1. The modified biomass records reflect this change."

timestamp <- readLines(con = "temp/timestamp.txt")
rmarkdown::render(input = "code/report_changes.RMD",
                  output_format = "html_document",
                  output_file = "../temp/report_changes.html",
                  params = list("detailed_notes" = detailed_notes,
                                "gapindex_version" = gapindex_version,
                                "timestamp" = timestamp))

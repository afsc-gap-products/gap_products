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

library(gapindex)
library(data.table)

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
  gp_cpue <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_CPUE", 
                               "_", regions[iregion], ".csv")))
  production_cpue <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_cpue", 
                               "_", regions[iregion], ".csv")))
  
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
          colname = c("WEIGHT_KG", "COUNT", "AREA_SWEPT_KM2",
                      "CPUE_KGKM2", "CPUE_NOKM2"),
          percent = c(F, F, F, F, F),
          decplaces = c(2, 0, 2, 2, 2)),
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
  gp_biomass <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_BIOMASS",
                               "_", regions[iregion], ".csv")))
  
  production_biomass <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_biomass", 
                               "_", regions[iregion], ".csv")))
  
  for (icol in c("CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                 "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR", 
                 "BIOMASS_MT", "BIOMASS_VAR"))
    production_biomass[
      , 
      paste(icol) := round(x = production_biomass[, paste(icol), with = F],
                           digits = 6)]
  production_biomass[
    , POPULATION_COUNT := round(x = production_biomass[, POPULATION_COUNT],
                                digits = 0)]
  
  ## Full join the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
  ## SPECIES_CODE, and YEAR as a composite key
  test_biomass <- 
    merge(x = production_biomass[YEAR != 2025, -"SURVEY"],
          y = gp_biomass[YEAR != 2025],
          all = TRUE,
          suffixes = c("_UPDATE", "_CURRENT"),
          by = c("SURVEY_DEFINITION_ID", 'AREA_ID', "SPECIES_CODE", "YEAR"))
  
  ## Evaluate the new, removed, and modified records between the two tables
  eval_biomass <- 
    compare_tables(
      x = test_biomass,
      cols_to_check = data.frame(
        colname = c("N_HAUL", "N_WEIGHT", "N_COUNT", "N_LENGTH",
                    "CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR",
                    "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR",
                    "BIOMASS_MT", "BIOMASS_VAR",
                    "POPULATION_COUNT", "POPULATION_VAR"),
        percent = c(F, F, F, F, T, T, T, T, T, T, T, T),
        decplaces = c(0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 2)),
      base_table_suffix = "_CURRENT",
      update_table_suffix = "_UPDATE",
      key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID',
                      "SPECIES_CODE", "YEAR"))
  
  cat(paste0("Finished with BIOMASS for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  SIZECOMP TABLE
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent run
  gp_sizecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_SIZECOMP",
                               "_", regions[iregion], ".csv")))
  production_sizecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_sizecomp", 
                               "_", regions[iregion], ".csv")))
  
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
        percent = T,
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
  gp_agecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_AGECOMP",
                               "_", regions[iregion], ".csv")))
  
  production_agecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_agecomp",
                               "_", regions[iregion], ".csv")))
  
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
                               "AREA_ID_FOOTPRINT",
                               "SPECIES_CODE", "SEX", "AGE"))
  
  ## Evaluate the new, removed, and modified records between the two tables
  eval_agecomp <-
    compare_tables(
      x = test_agecomp,
      cols_to_check = data.frame(
        colname = c("POPULATION_COUNT", "LENGTH_MM_MEAN", "LENGTH_MM_SD"),
        percent = c(T, T, T),
        decplaces = c(0, 2, 2)),
      base_table_suffix = "_CURRENT",
      update_table_suffix = "_UPDATE",
      key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', "YEAR",
                      "AREA_ID_FOOTPRINT",
                      "SPECIES_CODE", "SEX", "AGE"))
  
  cat(paste0("Finished with AGECOMP for the ", regions[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  Attach to mismatch objects
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  mismatches[[regions[iregion]]] <- 
    list(cpue = eval_cpue,
         biomass = eval_biomass,
         sizecomp = eval_sizecomp,
         agecomp = eval_agecomp
    )
  
} ## Loop over regions -- end

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Save mismatch object as RDS and excel file
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
saveRDS(object = mismatches, file = "temp/mismatches.RDS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Look at the mismatch object and write a quick paragraph about the changes
##   in the data tables. Include your name and gapindex version used to produce
##   these data. In the next step, a summary of how many records were 
##   new/removed/modified are already provided so you don't need to tabulate 
##   these, just the reasons why these changes occurred (new data, new 
##   vouchered data, ad hoc decisions about taxon aggregations, updated stratum
##   areas, updated gapindex package, etc.) 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
detailed_notes <- 
  "Run completed by: Ned Laman, Zack Oyafuso

A development branch version of gapindex called [using_datatable](https://github.com/afsc-gap-products/gap_products/tree/using_datatable) uses the data.table package for many dataframe manipulations, which greatly decreased the computation time of many of the functions. There were no major changes in the calculations in this version of the gapindex package and thus the major changes listed below are not related to the gapindex package.

There was a minor issue with how the 9/4/2024 run uploaded records to Oracle from R that has been remedied. This run was a redo of the previous run and all changes in this run are summarized in the 9/4/2024 version of the changelog.

"

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create report changelog
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gapindex_version <- 
  subset(x = read.csv(file = "temp/installed_packages.csv"),
         subset = Package == "gapindex")$Version
timestamp <- readLines(con = "temp/timestamp.txt")
rmarkdown::render(input = "code/report_changes.RMD",
                  output_format = "html_document",
                  output_file = paste0("../temp/report_changes.html"),
                  params = list("detailed_notes" = detailed_notes,
                                "gapindex_version" = gapindex_version,
                                "timestamp" = timestamp))

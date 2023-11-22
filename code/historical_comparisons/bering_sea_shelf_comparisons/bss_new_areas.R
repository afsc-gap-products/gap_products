##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Comparison of new Bering slope stratum areas on data products
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Use gapindex to calculate the CPUE, Biomass, Size/Age 
##                Compositions using 2023 updates to the Bering Slope Strata.
##                Compare results with the tables in GAP_PRODUCTS which use
##                2002 versions of the stratum areas. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

## Restart R Session before running
rm(list = ls())
options(scipen = 999)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Shortcut Functions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source(file = "functions/calc_diff.R")
source(file = "functions/compare_tables.R")

# devtools::install_github("afsc-gap-products/gapindex")
library(gapindex)

## Connect to Oracle
sql_channel <- gapindex::get_connected()

spp_start_year <-
  RODBC::sqlQuery(channel = sql_channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.SPECIES_YEAR")

## Pull data.
gapindex_data <- gapindex::get_data(
  year_set = c(2002:2016),
  survey_set = "BSS",
  haul_type = 3,
  spp_codes = NULL,
  abundance_haul = "Y",
  pull_lengths = T,
  sql_channel = sql_channel)

gapindex_data$survey$DESIGN_YEAR <- 
  gapindex_data$cruise$DESIGN_YEAR <-
  gapindex_data$survey_design$DESIGN_YEAR <- 
  gapindex_data$stratum_groups$DESIGN_YEAR <-2023
gapindex_data$strata <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT * FROM GAP_PRODUCTS.AREA
                           WHERE SURVEY_DEFINITION_ID = 78
                           AND DESIGN_YEAR = 2023 
                           AND AREA_TYPE = 'STRATUM'")
names(x = gapindex_data$strata)[names(x = gapindex_data$strata) %in% "AREA_ID"] <- "STRATUM"
gapindex_data$strata$SURVEY <- "BSS"

gapindex_data$subarea <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = "SELECT * FROM GAP_PRODUCTS.AREA
                           WHERE SURVEY_DEFINITION_ID = 78
                           AND DESIGN_YEAR = 2023 
                           AND AREA_TYPE != 'STRATUM'")


## Fill in zeros and calculate CPUE
cpue <- gapindex::calc_cpue(racebase_tables = gapindex_data)

## Calculate stratum-level biomass, population abundance, mean CPUE and 
## associated variances
biomass_stratum <- gapindex::calc_biomass_stratum(
  racebase_tables = gapindex_data,
  cpue = cpue)

## Calculate aggregated biomass and population abundance across subareas,
## management areas, and regions
biomass_subareas <- gapindex::calc_biomass_subarea(
  racebase_tables = gapindex_data,
  biomass_strata = biomass_stratum)

## Calculate size composition by stratum. See ?gapindex::calc_sizecomp_stratum
## for details on arguments
size_comp_stratum <- gapindex::calc_sizecomp_stratum(
  racebase_tables = gapindex_data,
  racebase_cpue = cpue,
  racebase_stratum_popn = biomass_stratum,
  spatial_level = "stratum",
  fill_NA_method = "BS")

## Calculate aggregated size compositon across subareas, management areas, and
## regions
size_comp_subareas <- gapindex::calc_sizecomp_subarea(
  racebase_tables = gapindex_data,
  size_comps = size_comp_stratum)

## Calculate age-length key. See ?gapindex::calc_ALK for details on arguments
alk <- gapindex::calc_alk(racebase_tables = gapindex_data, 
                          unsex = "all", 
                          global = F)

## Calculate age composition by stratum
age_comp_stratum <- gapindex::calc_agecomp_stratum(
  racebase_tables = gapindex_data, 
  alk = alk,
  size_comp = size_comp_stratum)

## Calculate aggregated age compositon across regions
age_comp_region <- gapindex::calc_agecomp_region(
  racebase_tables = gapindex_data, 
  age_comps_stratum = age_comp_stratum)

# Change "STRATUM" field name to "AREA_ID"
names(x = biomass_stratum)[
  names(x = biomass_stratum) == "STRATUM"] <- "AREA_ID"

names(x = size_comp_stratum)[
  names(x = size_comp_stratum) == "STRATUM"] <- "AREA_ID"

names(x = age_comp_stratum$age_comp)[
  names(x = age_comp_stratum$age_comp) == "STRATUM"] <- "AREA_ID"

## Combine stratum, subarea, and region estimates for the biomass and 
## size composition tables
biomass <- 
  rbind(biomass_stratum[, names(biomass_subareas)],
        biomass_subareas)

sizecomp <- 
  rbind(size_comp_subareas,
        size_comp_stratum[, names(size_comp_subareas)])

agecomp <- 
  rbind(age_comp_region,
        age_comp_stratum$age_comp[, names(age_comp_region)])

## Remove commercial crab data from biomass table
biomass <- 
  subset(x = biomass,
         subset = !(SPECIES_CODE %in% c(69323, 69322, 68580, 68560) &
                      SURVEY_DEFINITION_ID %in% c(98, 143)))

## For certain SPECIES_CODEs, constrain all of the data tables to only the
## years when we feel confident about their taxonomic accuracy, e.g., remove
## northern rock sole values prior to 1996.
for (irow in 1:nrow(x = spp_start_year)) { ## Loop over species -- start
  for (idata in c("cpue", "biomass", 
                  "sizecomp", "agecomp")) { ## Loop over data table -- start
    assign(x = idata,
           value = subset(
             x = get(idata),
             subset = !(SPECIES_CODE == spp_start_year$SPECIES_CODE[irow] & 
                          YEAR < spp_start_year$YEAR_STARTED[irow])
           )
    )
  } ## Loop over data table -- end
} ## Loop over species -- end

## Save to the temp/ folder 
for (idata in c("biomass", "sizecomp", "agecomp")) 
  write.csv(x = get(idata),
            file = paste0("temp/production/production_", idata, "_BSS.csv"),
            row.names = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  BIOMASS TABLE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Pull BIOMASS tables from the GAP_PRODUCTS schema and the most recent ruN
gp_biomass <- read.csv(file = "temp/cloned_gp/GAP_PRODUCTS_BIOMASS_BSS.csv")
production_biomass <- read.csv(file = "temp/production/production_biomass_BSS.csv")
for (icol in c("CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", "CPUE_NOKM2_MEAN",
               "CPUE_NOKM2_VAR", "BIOMASS_MT", "BIOMASS_VAR"))
  production_biomass[, icol] <- 
  round(x = production_biomass[, icol], digits = 6)

## Full join the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
## SPECIES_CODE, and YEAR as a composite key
test_biomass <- 
  merge(x = subset(x = production_biomass,
                   select = -SURVEY),
        y = gp_biomass,
        all = TRUE,
        suffixes = c("_UPDATE", "_CURRENT"),
        by = c("SURVEY_DEFINITION_ID", 'AREA_ID', "SPECIES_CODE", "YEAR"))

## Evaluate the new, removed, and modified records between the two tables
eval_biomass <- 
  compare_tables(
    x = test_biomass,
    cols_to_check = data.frame(
      colname = c("CPUE_KGKM2_MEAN", "CPUE_KGKM2_VAR", 
                  "CPUE_NOKM2_MEAN", "CPUE_NOKM2_VAR", 
                  "BIOMASS_MT", "BIOMASS_VAR", 
                  "POPULATION_COUNT", "POPULATION_VAR"),
      percent = T,
      decplaces = 10),
    base_table_suffix = "_CURRENT",
    update_table_suffix = "_UPDATE",
    key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', 
                    "SPECIES_CODE", "YEAR"))


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  SIZECOMP TABLE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent run
gp_sizecomp <- read.csv(file = "temp/cloned_gp/GAP_PRODUCTS_SIZECOMP_BSS.csv")
production_sizecomp <- read.csv(file = "temp/production/production_sizecomp_BSS.csv")

## Full join the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
## YEAR, and SPECIES_CODE, SEX, AND LENGTH_MM as a composite key
test_sizecomp <- merge(x = gp_sizecomp,
                       y = production_sizecomp,
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
      decplaces = 2),
    base_table_suffix = "_CURRENT",
    update_table_suffix = "_UPDATE",
    key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', "YEAR",
                    "SPECIES_CODE", "SEX", "LENGTH_MM"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Age Composition Table
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent run
gp_agecomp <- read.csv(file = "temp/cloned_gp/GAP_PRODUCTS_AGECOMP_BSS.csv")
production_agecomp <- 
  read.csv(file = "temp/production/production_agecomp_BSS.csv")

## Full join the two tables together using SURVEY_DEFINITION_ID, AREA_ID, 
## YEAR, and SPECIES_CODE, SEX, AND AGE as a composite key
test_agecomp <- merge(x = gp_agecomp,
                      y = production_agecomp,
                      all = TRUE,
                      suffixes = c("_CURRENT", "_UPDATE"),
                      by = c("SURVEY_DEFINITION_ID", "AREA_ID", "YEAR",
                             "SPECIES_CODE", "SEX", "AGE"))

## Evaluate the new, removed, and modified records between the two tables
eval_agecomp <- 
  compare_tables(
    x = test_agecomp,
    cols_to_check = data.frame(
      colname = "POPULATION_COUNT",
      percent = T,
      decplaces = 0),
    base_table_suffix = "_CURRENT",
    update_table_suffix = "_UPDATE",
    key_columns = c("SURVEY_DEFINITION_ID", 'AREA_ID', "YEAR",
                    "SPECIES_CODE", "SEX", "AGE"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Attach to mismatch objects
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mismatches <- 
  list(biomass = eval_biomass,
       sizecomp = eval_sizecomp,
       agecomp = eval_agecomp)


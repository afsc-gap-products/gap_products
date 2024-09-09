##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Standard Index Products
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Calculate CPUE, Biomass/Abundance, size composition and
##                age compositions for all species of interest.
##                Save to the temp/ folder.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())
options(scipen = 999999)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Libraries
##   Connect to Oracle (Make sure to connect to network or VPN)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex); library(data.table)
source(file = "functions/calc_diff.R")
source(file = "functions/compare_tables.R")
channel <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Specify the range of years to calculate indices
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
current_year <- as.integer(format(x = Sys.Date(), format = "%Y"))
start_year <- 
  c("AI" = 1991, "GOA" = 1990, "EBS" = 1982, "BSS" = 2002, "NBS" = 2010)
regions <- c("AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143)

spp_start_year <-
  RODBC::sqlQuery(channel = channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.SPECIES_YEAR")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Create temporary folder to put downloaded metadata files. Double-check 
## that the temp/ folder is in the gitignore file. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (!dir.exists(paths = "temp/production/")) 
  dir.create(path = "temp/production/")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Loop over regions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (iregion in 1:length(x = regions) ) { ## Loop over regions -- start
  
  ## Pull data for all years and species from Oracle
  start_time <- Sys.time()
  production_data <- gapindex::get_data(
    year_set = start_year[iregion]:current_year,
    survey_set = names(regions)[iregion],
    spp_codes = NULL,
    pull_lengths = TRUE,
    haul_type = 3,
    abundance_haul = "Y",
    channel = channel)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  
  ## Save production data object
  saveRDS(object = production_data,
          file = paste0("temp/production/production_data_",
                        names(regions)[iregion], ".RDS"))
  
  ## Extract stratum and subarea information to be saved later
  production_strata <- production_data$strata
  production_subarea <- production_data$subarea
  
  ## Calculate and zero-fill CPUE
  cat("\nCalculating and zero-filling CPUE...")
  start_time <- Sys.time()
  production_cpue <-
    gapindex::calc_cpue(gapdata = production_data)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  ## Calculate biomass/abundance (w/variance), mean/variance CPUE across strata
  cat("\nCalculating biomass/abundance across strata...")
  start_time <- Sys.time()
  production_biomass_stratum <-
    gapindex::calc_biomass_stratum(
      gapdata = production_data,
      cpue = production_cpue)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  ## Aggregate `production_biomass_stratum` to subareas and regions
  cat("\nAggregate biomass/abundance to subareas and regions...")
  start_time <- Sys.time()
  production_biomass_subarea <-
    gapindex::calc_biomass_subarea(
      gapdata = production_data,
      biomass_stratum = production_biomass_stratum)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  ## Calculate size composition by stratum. Since the Bering and AIGOA regions
  ## slightly calculate size compositions differently, the fill_NA_method
  ## argument is used to specify region
  cat("\nCalculate size composition across strata...")
  
  start_time <- Sys.time()
  production_sizecomp_stratum <- 
    gapindex::calc_sizecomp_stratum(
      gapdata = production_data,
      cpue = production_cpue,
      abundance_stratum = production_biomass_stratum,
      spatial_level = "stratum",
      fill_NA_method = ifelse(test = names(x = regions)[iregion] %in% 
                                c("GOA", "AI"),
                              yes = "AIGOA",
                              no = "BS"))
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  ## Aggregate `production_sizecomp_stratum` to subareas and regions
  cat("\nAggregate size composition to subareas and regions...")
  start_time <- Sys.time()
  production_sizecomp_subarea <- gapindex::calc_sizecomp_subarea(
    gapdata = production_data, 
    sizecomp_stratum = production_sizecomp_stratum)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  ## Calculate age-length key
  cat("\nCalculate regional ALK...")
  start_time <- Sys.time()
  production_alk <-
    subset(x = gapindex::calc_alk(
      gapdata = production_data,
      unsex = c("all", "unsex")[1],
      global = FALSE),
      subset = AGE_FRAC > 0)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  ## Calculate age composition by stratum
  cat("\nCalculate age composition by stratum...")
  start_time <- Sys.time()
  production_agecomp_stratum <-
    gapindex::calc_agecomp_stratum(
      gapdata = production_data,
      alk = production_alk,
      sizecomp_stratum = production_sizecomp_stratum)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  ## Aggregate `production_agecomp_stratum` to subareas and regions
  cat("\nAggregate age composition to regions...")
  start_time <- Sys.time()
  production_agecomp_region <-
    gapindex::calc_agecomp_region(
      gapdata = production_data, 
      agecomp_stratum = production_agecomp_stratum)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  
  # Change "STRATUM" field name to "AREA_ID"
  names(x = production_biomass_stratum)[
    names(x = production_biomass_stratum) == "STRATUM"] <- "AREA_ID"
  
  names(x = production_sizecomp_stratum)[
    names(x = production_sizecomp_stratum) == "STRATUM"] <- "AREA_ID"
  
  names(x = production_agecomp_stratum$age_comp)[
    names(x = production_agecomp_stratum$age_comp) == "STRATUM"] <- "AREA_ID"
  
  ## Combine stratum, subarea, and region estimates for the biomass and
  ## size composition tables
  production_biomass <-
    rbind(production_biomass_stratum[,
                                     names(x = production_biomass_subarea), 
                                     with = F],
          production_biomass_subarea)
  
  production_sizecomp <-
    rbind(production_sizecomp_subarea,
          production_sizecomp_stratum[, 
                                      names(x = production_sizecomp_subarea),  
                                      with = F])
  
  production_agecomp <-
    rbind(
      production_agecomp_region,
      production_agecomp_stratum$age_comp[,
                                          names(x = production_agecomp_region),
                                          with = F])
  
  ## AREA_ID_FOOTPRINT denotes survey footprint and distinguishes the EBS
  ## STANDARD area vs EBS STANDARD PLUS NW 
  production_agecomp$AREA_ID_FOOTPRINT <-
    c("52" = "AI", "47" = "GOA", "78" = "BSS",
      "98" = "EBS STANDARD PLUS NW", "143" = "NBS" )[paste(regions[iregion])]
  
  ## if EBS, recalculate agecomps using only the EBS Standard Region (sans
  ## strata 82 and 90) and then append to production_agecomp.
  if (regions[iregion] == 98) {
    
    cat("\nFor the EBS region: reformatting data to exclude data from strata
82 and 90 to recalculate production indices and compositions for the 
EBS Standard Area.\n\n")
    
    ## Create a copy of the production data to start from
    production_data_ebsstand <- production_data
    
    ## Remove hauls and data associated with hauls in strata 82 and 90
    ebs_standard_hauls <- 
      production_data_ebsstand$haul[!(STRATUM %in% c(82, 90))]$HAULJOIN
    
    ## Filter haul, catch, size, and specimen to only hauls within the 
    ## EBS Standard Area survey footprint
    production_data_ebsstand$haul <-
      production_data_ebsstand$haul[HAULJOIN %in% ebs_standard_hauls]
    
    production_data_ebsstand$catch <-
      production_data_ebsstand$catch[HAULJOIN %in% ebs_standard_hauls]
    
    production_data_ebsstand$size <-
      production_data_ebsstand$size[HAULJOIN %in% ebs_standard_hauls]
    
    production_data_ebsstand$specimen <-
      production_data_ebsstand$specimen[HAULJOIN %in% ebs_standard_hauls]
    
    ## Remove strata 82 and 90 from the strata slot
    production_data_ebsstand$strata <-
      production_data_ebsstand$strata[!(STRATUM %in% c(82, 90))]
    
    ## Remove subareas associated w/ the EBS + NW region from the subarea slot
    production_data_ebsstand$subarea <- 
      subset(x = production_data_ebsstand$subarea,
             subset = !(AREA_ID %in% c(7, 8, 9, 100, 200, 300, 99900)))
    
    ## Calculate and zero-fill CPUE
    cat("\nRecalculating CPUE for the EBS Standard Area...")
    start_time <- Sys.time()
    production_cpue_ebsstand <-
      gapindex::calc_cpue(gapdata = production_data_ebsstand)
    end_time <- Sys.time()
    print(round(end_time - start_time, 2))
    
    ## Calculate stratum biomass/abundance (w/var), mean, and var of wt/no.-CPUE
    cat("\nRecalculating stratum-level Biomass for the EBS Standard Area...")
    start_time <- Sys.time()
    production_biomass_stratum_ebsstand <-
      gapindex::calc_biomass_stratum(
        gapdata = production_data_ebsstand,
        cpue = production_cpue_ebsstand)
    end_time <- Sys.time()
    print(round(end_time - start_time, 2))
    
    ## Calculate size composition by stratum. Since the two regions have
    ## different functions, sizecomp_fn toggles which function to use
    ## and then it is called in the do.call function.
    cat("\nRecalculating size composition for the EBS Standard Area...")
    start_time <- Sys.time()
    production_sizecomp_stratum_ebsstand <-
      gapindex::calc_sizecomp_stratum(
        gapdata = production_data_ebsstand,
        cpue = production_cpue_ebsstand,
        abundance_stratum = production_biomass_stratum_ebsstand,
        spatial_level = "stratum",
        fill_NA_method = "BS")
    end_time <- Sys.time()
    print(round(end_time - start_time, 2))
    
    # Calculate regional ALK only including hauls in the EBS Standard Region
    cat("\nRecalculating age-length key for the EBS Standard Area...")
    start_time <- Sys.time()
    production_alk_ebsstand <-
      subset(x = gapindex::calc_alk(
        gapdata = production_data_ebsstand,
        unsex = c("all", "unsex")[1],
        global = FALSE),
        subset = AGE_FRAC > 0)
    end_time <- Sys.time()
    print(round(end_time - start_time, 2))
    
    ## Calculate age composition by stratum
    cat("\nRecalculating stratum-level age composition for the EBS Standard Area...")
    start_time <- Sys.time()
    production_agecomp_stratum_ebsstand <-
      gapindex::calc_agecomp_stratum(
        gapdata = production_data_ebsstand,
        alk = production_alk_ebsstand,
        sizecomp_stratum = production_sizecomp_stratum_ebsstand)
    end_time <- Sys.time()
    print(round(end_time - start_time, 2))
    
    ## Aggregate `production_agecomp_stratum` to subareas and regions
    cat("\nReaggregating agecomps to region for the EBS Standard Area...")
    start_time <- Sys.time()
    production_agecomp_region_ebsstand <-
      gapindex::calc_agecomp_region(
        gapdata = production_data_ebsstand,
        agecomp_stratum = production_agecomp_stratum_ebsstand)
    end_time <- Sys.time()
    print(round(end_time - start_time, 2))
    
    # Change "STRATUM" field name to "AREA_ID"
    names(x = production_agecomp_stratum_ebsstand$age_comp)[
      names(x = production_agecomp_stratum_ebsstand$age_comp) == "STRATUM"] <-
      "AREA_ID"
    production_agecomp_stratum_ebsstand$age_comp$AREA_ID_FOOTPRINT <- 
      "EBS STANDARD"
    production_agecomp_region_ebsstand$AREA_ID_FOOTPRINT <-
      "EBS STANDARD"
    
    production_agecomp <-
      rbind(
        production_agecomp,
        production_agecomp_region_ebsstand,
        production_agecomp_stratum_ebsstand$age_comp[, 
                                                     names(x = production_agecomp_region_ebsstand),
                                                     with = F])
    
  }
  
  ## For certain SPECIES_CODEs, constrain all of the data tables to only the
  ## years when we feel confident about their taxonomic accuracy, e.g., remove
  ## northern rock sole values prior to 1996.
  for (irow in 1:nrow(x = spp_start_year)) { ## Loop over species -- start
    for (idata in paste0("production_", ## Loop over data table -- start
                         c("cpue", "biomass", "sizecomp", "agecomp"))) { 
      assign(x = idata,
             value = subset(
               x = get(idata),
               subset = !(SPECIES_CODE == spp_start_year$SPECIES_CODE[irow] & 
                            YEAR < spp_start_year$YEAR_STARTED[irow])
             )
      )
    } ## Loop over data table -- end
  } ## Loop over species -- end
  
  ## Remove commercial crab data from biomass table
  production_biomass <- 
    production_biomass[!(SPECIES_CODE %in% c(69323,69322,68580,68560,68590))]
  
  ## The EBS agecomp only applies to the Standard + NW area and thus should only
  ## go back to 1987.
  if (names(x = regions[iregion]) == "EBS") {
    
    production_agecomp <- 
      subset(x = production_agecomp,
             subset = (YEAR >= 1987 & 
                         AREA_ID_FOOTPRINT == "EBS STANDARD PLUS NW") |
               (YEAR >= 1982 & 
                  AREA_ID_FOOTPRINT == "EBS STANDARD"))
    production_agecomp <- 
      subset(x = production_agecomp,
             subset = !(AREA_ID == 99901 & 
                          AREA_ID_FOOTPRINT == "EBS STANDARD PLUS NW"))
  }
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##   
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  historical_taxonomic_groups <- 
    read.csv(file = "data/historical_group_ids.csv")
  historical_taxonomic_species <- 
    read.csv(file = "data/historical_group_id_composition.csv")
  
  all_groups_cpue <- all_groups_biomass <- data.frame()
  
  for (igroup in 1:nrow(x = historical_taxonomic_groups)) {
    years_to_pull <- 
      with(historical_taxonomic_groups, YEAR_START[igroup]:YEAR_END[igroup])
    
    if (all(start_year[iregion] > years_to_pull)) next
    
    species_in_group_code <- 
      data.frame(GROUP_CODE = historical_taxonomic_groups$GROUP_CODE[igroup],
                 subset(historical_taxonomic_species,
                        subset = GROUP_CODE_ID == igroup,
                        select = SPECIES_CODE))
    
    ## Pull data for all years and species from Oracle
    group_data <- gapindex::get_data(
      year_set = years_to_pull,
      survey_set = names(regions)[iregion],
      spp_codes = species_in_group_code,
      pull_lengths = T,
      haul_type = 3,
      abundance_haul = "Y",
      channel = channel)
    
    ## Calculate and zero-fill CPUE
    group_cpue <- gapindex::calc_cpue(gapdata = group_data)
    
    ## Calculate biomass/abundance (w/variance), mean/variance CPUE across strata
    group_biomass_stratum <- 
      gapindex::calc_biomass_stratum(
        gapdata = group_data,
        cpue = group_cpue)
    
    ## Aggregate `group_biomass_stratum` to subareas and regions
    group_biomass_subarea <-
      gapindex::calc_biomass_subarea(
        gapdata = group_data,
        biomass_stratum = group_biomass_stratum)
    
    all_groups_cpue <- rbind(all_groups_cpue,
                             group_cpue)
    
    names(x = group_biomass_stratum)[
      names(x = group_biomass_stratum) == "STRATUM"
    ] <- "AREA_ID"
    all_groups_biomass <- rbind(all_groups_biomass,
                                group_biomass_stratum,
                                group_biomass_subarea)
    
    ## Removed these new grouped_taxa data from the production cpue and
    ## biomass tables so that when they are all appended outside the loop
    ## in the next step, there are no duplications.
    
    production_cpue <- production_cpue[
      !(production_cpue$HAULJOIN %in% group_cpue$HAULJOIN &
          production_cpue$SPECIES_CODE == 
          historical_taxonomic_groups$GROUP_CODE[igroup])
    ]
    
    production_biomass <- production_biomass[
      !(production_biomass$SPECIES_CODE == 
          historical_taxonomic_groups$GROUP_CODE[igroup] &
          production_biomass$YEAR %in% years_to_pull), 
    ]
    
  }
  
  ## Append to cpue and biomass
  production_cpue <- rbind(production_cpue, all_groups_cpue)
  production_biomass <- rbind(production_biomass, all_groups_biomass)
  
  ## Save to the temp/ folder 
  cat("\nSaving output to temp/production/...")
  start_time <- Sys.time()
  for (idata in c("cpue", "biomass", "sizecomp", "agecomp", "alk", 
                  "strata", "subarea")) 
    write.csv(x = get(paste0("production_", idata)),
              file = paste0("temp/production/production_", idata, "_", 
                            names(regions)[iregion], ".csv"),
              row.names = F)
  end_time <- Sys.time()
  print(round(end_time - start_time, 2))
  cat("\n")
}


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare the production tables just created and outputted to 
##   temp/production/ with current version of tables in temp/cloned_gp/
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mismatches <- list() 

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
                               "_", names(x = regions)[iregion], ".csv")))
  production_cpue <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_cpue", 
                               "_", names(x = regions)[iregion], ".csv")))
  
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
  
  cat(paste0("Finished with CPUE for the ", 
             names(x = regions)[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  BIOMASS TABLE
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  ## Pull BIOMASS tables from the GAP_PRODUCTS schema and the most recent ruN
  gp_biomass <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_BIOMASS",
                               "_", names(x = regions)[iregion], ".csv")))
  
  production_biomass <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_biomass", 
                               "_", names(x = regions)[iregion], ".csv")))
  
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
  
  cat(paste0("Finished with BIOMASS for the ", 
             names(x = regions)[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  SIZECOMP TABLE
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent run
  gp_sizecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_SIZECOMP",
                               "_", names(x = regions)[iregion], ".csv")))
  production_sizecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_sizecomp", 
                               "_", names(x = regions)[iregion], ".csv")))
  
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
  
  cat(paste0("Finished with SIZECOMP for the ", 
             names(x = regions)[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  Age Composition Table
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Pull SIZECOMP tables from the GAP_PRODUCTS schema and the most recent run
  gp_agecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/cloned_gp/GAP_PRODUCTS_AGECOMP",
                               "_", names(x = regions)[iregion], ".csv")))
  
  production_agecomp <- data.table::as.data.table(
    x = read.csv(file = paste0("temp/production/production_agecomp",
                               "_", names(x = regions)[iregion], ".csv")))
  
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
  
  cat(paste0("Finished with AGECOMP for the ", 
             names(x = regions)[iregion], " Region\n"))
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##  Attach to mismatch objects
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  mismatches[[names(x = regions)[iregion]]] <- 
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

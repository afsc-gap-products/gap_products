##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Standard Index Products
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Calculate CPUE, Biomass/Abundance, size composition and
##                age compositions for all species of interest.
##                Save to the temp/ folder.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Libraries
##   Connect to Oracle (Make sure to connect to network or VPN)
##   Be sure to use the username and password for the GAP_PRODUCTS schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(gapindex)
sql_channel <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Specify the range of years to calculate indices
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
current_year <- as.integer(format(x = Sys.Date(), format = "%Y"))
start_year <- 
  c("AI" = 1991, "GOA" = 1990, "EBS" = 1982, "BSS" = 2002, "NBS" = 2010)
regions <- c("AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143)

spp_start_year <-
  RODBC::sqlQuery(channel = sql_channel, 
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
for (iregion in (length(x = regions):1) ) { ## Loop over regions -- start
  ## Pull data for all years and species from Oracle
  start_time <- Sys.time()
  production_data <- gapindex::get_data(
    year_set = start_year[iregion]:current_year,
    survey_set = names(regions)[iregion],
    spp_codes = NULL,
    pull_lengths = TRUE, 
    haul_type = 3, 
    abundance_haul = "Y",
    channel = sql_channel)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  saveRDS(object = production_data,
          file = paste0("temp/production/production_data_", 
                        names(regions)[iregion], ".RDS"))
  
  ## Extract stratum and subarea information
  production_strata <- production_data$strata
  production_subarea <- production_data$subarea
  
  ## Calculate and zero-fill CPUE
  cat("\nCalculating and zero-filling CPUE\n")
  start_time <- Sys.time()
  production_cpue <-
    gapindex::calc_cpue(racebase_tables = production_data)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  ## Calculate biomass/abundance (w/variance), mean/variance CPUE across strata
  cat("\nCalculating biomass/abundance across strata\n")
  start_time <- Sys.time()
  production_biomass_stratum <-
    gapindex::calc_biomass_stratum(
      gapdata = production_data,
      cpue = production_cpue)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  ## Aggregate `production_biomass_stratum` to subareas and regions
  cat("\nAggregate biomass/abundance to subareas and regions\n")
  start_time <- Sys.time()
  production_biomass_subarea <-
    gapindex::calc_biomass_subarea(
      gapdata = production_data,
      biomass_stratum = production_biomass_stratum)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  ## Calculate size composition by stratum. Since the two regions have
  ## different functions, sizecomp_fn toggles which function to use
  ## and then it is called in the do.call function.
  cat("\nCalculate size composition across strata\n")
  
  start_time <- Sys.time()
  production_sizecomp_stratum <- 
    gapindex::calc_sizecomp_stratum(
      racebase_tables = production_data,
      racebase_cpue = production_cpue,
      racebase_stratum_popn = production_biomass_stratum,
      spatial_level = "stratum",
      fill_NA_method = ifelse(test = names(x = regions)[iregion] %in% 
                                c("GOA", "AI"),
                              yes = "AIGOA",
                              no = "BS"))
  end_time <- Sys.time()
  print(end_time - start_time)
  
  ## Aggregate `production_sizecomp_stratum` to subareas and regions
  cat("\nAggregate size composition to subareas and regions\n")
  start_time <- Sys.time()
  production_sizecomp_subarea <- gapindex::calc_sizecomp_subarea(
    racebase_tables = production_data,
    size_comps = production_sizecomp_stratum)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  ## Aggregate `production_sizecomp_stratum` to subareas and regions
  cat("\nCalculate regional ALK\n")
  start_time <- Sys.time()
  production_alk <-
    subset(x = gapindex::calc_alk(
      racebase_tables = production_data,
      unsex = c("all", "unsex")[1],
      global = FALSE),
      subset = AGE_FRAC > 0)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  cat("\nCalculate age composition by stratum\n")
  start_time <- Sys.time()
  production_agecomp_stratum <-
    gapindex::calc_agecomp_stratum(
      gapdata = production_data,
      alk = production_alk,
      sizecomp_stratum = production_sizecomp_stratum)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  ## Aggregate `production_agecomp_stratum` to subareas and regions
  cat("\nAggregate age composition to regions\n\n")
  start_time <- Sys.time()
  production_agecomp_region <-
    gapindex::calc_agecomp_region(
      racebase_tables = production_data,
      age_comps_stratum = production_agecomp_stratum)
  end_time <- Sys.time()
  print(end_time - start_time)
  
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
    rbind(production_biomass_stratum[, names(production_biomass_subarea), with = F],
          production_biomass_subarea)
  
  production_sizecomp <-
    rbind(production_sizecomp_subarea,
          production_sizecomp_stratum[, names(production_sizecomp_subarea),  with = F])
  
  production_agecomp <-
    rbind(production_agecomp_region,
          production_agecomp_stratum$age_comp[, names(production_agecomp_region), with = F])
  
  production_agecomp$AREA_ID_FOOTPRINT <-
    c("52" = "AI", "47" = "GOA", "78" = "BSS",
      "98" = "EBS STANDARD PLUS NW", "143" = "NBS" )[paste(regions[iregion])]
  
  ## if EBS, recalculate agecomps using only the EBS Standard Region (sans
  ## strata 82 and 90) and then append to production_agecomp.
  if (regions[iregion] == 98) {
    ## Remove hauls and data associated with hauls in strata 82 and 90
    production_data_ebsstand <- production_data
    ebs_standard_hauls <- 
      production_data_ebsstand$haul[!(STRATUM %in% c(82, 90))]$HAULJOIN
    # with(production_data_ebsstand$haul, HAULJOIN[!(STRATUM %in% c(82, 90))])
    
    production_data_ebsstand$haul <-
      production_data_ebsstand$haul[HAULJOIN %in% ebs_standard_hauls]
    
    production_data_ebsstand$catch <-
      production_data_ebsstand$catch[HAULJOIN %in% ebs_standard_hauls]
    
    production_data_ebsstand$size <-
      production_data_ebsstand$size[HAULJOIN %in% ebs_standard_hauls]
    
    production_data_ebsstand$specimen <-
      production_data_ebsstand$specimen[HAULJOIN %in% ebs_standard_hauls]
    
    production_data_ebsstand$strata <-
      production_data_ebsstand$strata[!(STRATUM %in% c(82, 90))]
    
    ## Remove subareas associated with the EBS + NW region
    production_data_ebsstand$subarea <- 
      subset(x = production_data_ebsstand$subarea,
             subset = !(AREA_ID %in% c(7, 8, 9, 100, 200, 300, 99900)))
    
    ## Calculate and zero-fill CPUE
    production_cpue_ebsstand <-
      gapindex::calc_cpue(racebase_tables = production_data_ebsstand)
    
    ## Calculate biomass/abundance (w/variance), mean/variance CPUE across strata
    production_biomass_stratum_ebsstand <-
      gapindex::calc_biomass_stratum(
        racebase_tables = production_data_ebsstand,
        cpue = production_cpue_ebsstand)
    
    ## Calculate size composition by stratum. Since the two regions have
    ## different functions, sizecomp_fn toggles which function to use
    ## and then it is called in the do.call function.
    production_sizecomp_stratum_ebsstand <-
      gapindex::calc_sizecomp_stratum(
        racebase_tables = production_data_ebsstand,
        racebase_cpue = production_cpue_ebsstand,
        racebase_stratum_popn = production_biomass_stratum_ebsstand,
        spatial_level = "stratum",
        fill_NA_method = "BS")
    
    # Calculate regional ALK only including hauls in the EBS Standard Region
    production_alk_ebsstand <-
      subset(x = gapindex::calc_alk(
        racebase_tables = production_data_ebsstand,
        unsex = c("all", "unsex")[1],
        global = FALSE),
        subset = AGE_FRAC > 0)
    
    ## Calculate age composition by stratum
    production_agecomp_stratum_ebsstand <-
      gapindex::calc_agecomp_stratum(
        racebase_tables = production_data_ebsstand,
        alk = production_alk_ebsstand,
        size_comp = production_sizecomp_stratum_ebsstand)
    
    ## Aggregate `production_agecomp_stratum` to subareas and regions
    production_agecomp_region_ebsstand <-
      gapindex::calc_agecomp_region(
        racebase_tables = production_data_ebsstand,
        age_comps_stratum = production_agecomp_stratum_ebsstand)
    
    # Change "STRATUM" field name to "AREA_ID"
    names(x = production_agecomp_stratum_ebsstand$age_comp)[
      names(x = production_agecomp_stratum_ebsstand$age_comp) == "STRATUM"] <-
      "AREA_ID"
    production_agecomp_stratum_ebsstand$age_comp$AREA_ID_FOOTPRINT <- "EBS STANDARD"
    production_agecomp_region_ebsstand$AREA_ID_FOOTPRINT <- "EBS STANDARD"
    
    production_agecomp <-
      rbind(production_agecomp,
            production_agecomp_region_ebsstand,
            production_agecomp_stratum_ebsstand$age_comp[, names(x = production_agecomp_region_ebsstand), with = F])
    
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
  
  ## Save to the temp/ folder 
  for (idata in c("cpue", "biomass", "sizecomp", "agecomp", "alk", 
                  "strata", "subarea")) 
    write.csv(x = get(paste0("production_", idata)),
              file = paste0("temp/production/production_", idata, "_", 
                            names(regions)[iregion], ".csv"),
              row.names = F)
}

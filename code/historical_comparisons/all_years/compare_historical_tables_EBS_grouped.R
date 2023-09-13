##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

library(gapindex)

sql_channel <- gapindex::get_connected()

skate_unid <- RODBC::sqlQuery(
  channel = sql_channel, 
  query = "SELECT SPECIES_CODE
  FROM GAP_PRODUCTS.TEST_SPECIES_CLASSIFICATION 
  WHERE SURVEY_SPECIES = 1 
  AND SPECIES_CODE BETWEEN 400 AND 495 
  AND SPECIES_CODE NOT IN (402, 403, 411, 421, 436, 441, 446, 456,
  461, 473, 474, 476, 478, 481, 484, 486)")

production_data <- get_data(
  year_set = 1982:2023,
  survey_set = "EBS",
  spp_codes = rbind(
    ## Skate unident.
    data.frame(GROUP = 400, SPECIES_CODE = skate_unid),
    ## ATF + Kams
    data.frame(GROUP = 10111, SPECIES_CODE = 10110:10112),
    ## FHS + Bering flounder
    data.frame(GROUP = 10129, SPECIES_CODE = 10130:10140),
    ## rock sole unid.
    data.frame(GROUP = 10260, SPECIES_CODE = 10260:10262),
    ## Octopididae
    data.frame(GROUP = 78010, SPECIES_CODE = 78010:78455),
    ## Squid unid
    data.frame(GROUP = 79000, SPECIES_CODE = 79000:79513),
    ## Some test single species
    data.frame(GROUP = c(21720, 30060), SPECIES_CODE = c(21720, 30060))
  ),
  pull_lengths = TRUE, 
  haul_type = 3, 
  abundance_haul = "Y",
  sql_channel = sql_channel)

production_cpue <- calc_cpue(racebase_tables = production_data)

production_biomass_stratum <- 
  gapindex::calc_biomass_stratum(racebase_tables = production_data,
                                 cpue = production_cpue)
names(x = production_biomass_stratum)[
  names(x = production_biomass_stratum) == "STRATUM"
] <- "AREA_ID"

production_biomass_subarea <- 
  calc_biomass_subarea(racebase_tables = production_data, 
                       biomass_strata = production_biomass_stratum)

production_biomass <- rbind(production_biomass_stratum, 
                            production_biomass_subarea)

production_sizecomp_stratum <- 
  gapindex::calc_sizecomp_stratum(
    racebase_tables = production_data,
    racebase_cpue = production_cpue,
    racebase_stratum_popn = production_biomass_stratum,
    spatial_level = "stratum",
    fill_NA_method = "BS")

production_sizecomp_subarea <- gapindex::calc_sizecomp_subareas(
  racebase_tables = production_data,
  size_comps = production_sizecomp_stratum)

historical_biomass <- 
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste0(
                    "SELECT YEAR, STRATUM AS AREA_ID, SPECIES_CODE, ",
                    "HAULCOUNT as N_HAUL, CATCOUNT AS N_WEIGHT, ",
                    "100 * MEANWGTCPUE AS CPUE_KGKM2_MEAN, ",
                    "10000 * VARMNWGTCPUE AS CPUE_KGKM2_VAR, ",
                    "100 * MEANNUMCPUE AS CPUE_NOKM2_MEAN, ",
                    "10000 * VARMNNUMCPUE AS CPUE_NOKM2_VAR, ",
                    "BIOMASS AS BIOMASS_MT, ",
                    "VARBIO AS BIOMASS_VAR, ",
                    "POPULATION AS POPULATION_COUNT, ",
                    "VARPOP AS POPULATION_VAR ",
                    "FROM HAEHNR.BIOMASS_EBS_PLUSNW_GROUPED WHERE YEAR = 2023"))
historical_biomass$AREA_ID[historical_biomass$AREA_ID == 999] <- 99900

test_biomass <- 
  merge(x = historical_biomass, all.x = TRUE, 
        y = production_biomass, 
        by = c("AREA_ID", "SPECIES_CODE", "YEAR"), 
        suffixes = c("_HIST", "_PROD"))

test_biomass$BIOMASS_MT <- 
  100 * round(x = (test_biomass$BIOMASS_MT_HIST - test_biomass$BIOMASS_MT_PROD) / 
          ifelse(test = test_biomass$BIOMASS_MT_PROD == 0, 
                 yes = 1, 
                 no = test_biomass$BIOMASS_MT_PROD),
        digits = 4)

subset(test_biomass, BIOMASS_MT != 0 )

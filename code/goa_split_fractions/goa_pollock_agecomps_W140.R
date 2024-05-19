##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       GOA pollock age composition west of -140 longitude
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## 
## Description:   Truncate the GOA survey to just those areas west of -140
##                longitude and calculate regional-wide age composition. 
##                However, the -140 longitude boundary cuts through many strata 
##                in the Yakutat INPFC area. The procedure here is similar to 
##                how the GOA.SPLIT_FRACTIONS table is created and so the 
##                decisions made in the script about how to reclassify hauls 
##                is directly patterned from that procedure. Below is the series
##                of decisions that were made to reclassify hauls for the 
##                GOA.SPLIT_FRACTIONS table: 
##                
##                - Hauls east of -140 lon in stratum 40  are now in stratum 50
##                - Hauls west of -140 lon in stratum 142 are now in stratum 141
##                - Hauls east of -140 lon in stratum 142 are now in stratum 152
##                - Hauls in Stratum 143                  are now in stratum 152
##                - Hauls east of -140 lon in stratum 240 are now in stratum 250
##                - Hauls east of -140 lon in stratum 241 are now in stratum 250
##                - Hauls east of -140 lon in stratum 340 are now in stratum 350
##                - Hauls east of -140 lon in stratum 341 are now in stratum 351
##                - Hauls east of -140 lon in stratum 440 are now in stratum 450
##                - Hauls east of -140 lon in stratum 540 are now in stratum 550
##                
##                The stratum areas (km2) were updated below in this script
##                to reflect these changes.
##                
##                Strata with a "4" in the tens digit of the number belong to 
##                the Yakutat INPFC area and strata with a "5" in the tens 
##                digit of the number belong to the SE AK INPFC area. For this 
##                analysis, hauls east of -140 long are first removed, entirely
##                removing the SE INPFC strata. The only hauls that are 
##                reclassified are those hauls formerly in stratum 142 west of
##                -140 long, reclassified as belonging to stratum 141. 
##                
##                The data querying and design-based calculations are done in 
##                the gapindex R package. In the script there is some hard-
##                coding to program the package to calculate age composition 
##                on this new truncated GOA region. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Setup: load libraries and connect to Oracle
##   Note: as of 3/22/2024 this development branch of gapindex is being used.
##   It produces the same values but is much faster than the main branch 
##   version. To be merged in the future.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Import Libraries
# devtools::install_github(repo = "asfc-gap-products/gapindex@using_datatable")
library(gapindex)
library(data.table)

## Connect to Oracle
channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull GOA pollock data from the gapindex R Package
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gp_data <- gapindex::get_data(year_set = 1990:2021,
                              survey_set = "GOA",
                              spp_codes = 21740,
                              channel = channel,
                              pull_lengths = T)
# saveRDS(gp_data, "C:/Users/zack.oyafuso/Desktop/goa_wp_data.RDS")
# gp_data <- readRDS("C:/Users/zack.oyafuso/Desktop/goa_wp_data.RDS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Constrain the GOA region and data to the areas west of -140 longitude. 
##   This involves adjusting the haul, strata, subarea, stratum_groups, catch,
##   size, and specimen slots in the `gp_data` object, in that order. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Calculate midpoint of the observed start and end longitudes for each haul
gp_data$haul$MID_LONGITUDE <- 
  (gp_data$haul$START_LONGITUDE + gp_data$haul$END_LONGITUDE) / 2  

## Remove any hauls east of -140 Longitude
gp_data$haul <- gp_data$haul[MID_LONGITUDE < -140]

## Reclassify hauls formerly in stratum 142 west of -140 long to now belonging 
## to stratum 141. 
gp_data$haul[STRATUM == 142, "STRATUM"] <- 141

## Update the stratum areas for the affected INPFC Yakutat strata based on 
## the decisions descirbed in the opening comments in this script. These
## areas (km2) were directly pulled from the original SQL query that produced
## the GOA.SPLIT_FRACTIONS table. 
updated_stratum_area <- 
  data.table::data.table(
    SURVEY_DEFINITION_ID = 47, SURVEY = "GOA", DESIGN_YEAR = 1984,
    STRATUM = c(40, 41, 140, 141, 240, 
                241, 340, 341, 440, 540
    ),
    AREA_NAME = NA, DESCRIPTION = NA,
    AREA_KM2 = c(4980.0055, 6714.745, 7346.035, 9993.9158, 2286.1398, 
                 1503.6357, 751.2782, 1296.7165, 1252.9542, 1609.551
    ))

## Update the stratum information in the gp_data list
gp_data$strata <- 
  rbind(gp_data$strata[!(STRATUM %in% c(updated_stratum_area$STRATUM,
                                        142, 143, 
                                        50, 150, 151, 250, 251, 
                                        350, 351, 450, 550))],
        updated_stratum_area)[order(STRATUM)]

## The only subarea we are aggregating to is to region, the GOA region being
## area_id 99903.
gp_data$subarea <- gp_data$subarea[AREA_ID == 99903]

## The strata that are contained in 99903 is simply all of the strata in the 
## updated strata in gp_data$strata, i.e., all strata except those in the 
## SE AK INPFC area.
gp_data$stratum_groups <- 
  gp_data$stratum_groups[AREA_ID == 99903 & 
                           STRATUM %in% gp_data$strata$STRATUM]

## Constrain the catch, size, and otolith data to only those hauls that are 
## west of -140 longitude, i.e., only the hauls present in the updated gp_haul
## table. 
gp_data$catch <- gp_data$catch[HAULJOIN %in% gp_data$haul$HAULJOIN]
gp_data$size <- gp_data$size[HAULJOIN %in% gp_data$haul$HAULJOIN]
gp_data$specimen <- gp_data$specimen[HAULJOIN %in% gp_data$haul$HAULJOIN]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Calculate CPUE, Biomass, Size Composition, Age-Length Keys, Age Composition
##   on the truncated GOA region west of -140 longitude. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## CPUE
gp_cpue <- gapindex::calc_cpue(racebase_tables = gp_data)

## Stratum Biomass 
gp_stratum_biomass <- gapindex::calc_biomass_stratum(
  racebase_tables = gp_data, 
  cpue = gp_cpue)

## Region Biomass
gp_region_biomass <- gapindex::calc_biomass_subarea(
  racebase_tables = gp_data, 
  biomass_strata = gp_stratum_biomass)

## Stratum Size Composition
gp_sizecomp_stratum <- gapindex::calc_sizecomp_stratum(
  racebase_tables = gp_data,
  racebase_cpue = gp_cpue,
  racebase_stratum_popn = gp_stratum_biomass,
  spatial_level = "stratum",
  fill_NA_method = "AIGOA")

## Regional Age-Length Key
gp_alk <- gapindex::calc_alk(
  racebase_tables = gp_data, 
  unsex = "all", 
  global = F)

## Stratum Age Composition
gp_agecomp_stratum <- gapindex::calc_agecomp_stratum(
  racebase_tables = gp_data, 
  alk = gp_alk,
  size_comp = gp_sizecomp_stratum)

## Region Age Composition
gp_agecomp_region <- gapindex::calc_agecomp_region(
  racebase_tables = gp_data, 
  age_comps_stratum = gp_agecomp_stratum)

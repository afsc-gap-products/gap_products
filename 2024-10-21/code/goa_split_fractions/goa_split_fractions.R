##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Reproduce the GOA.SPLIT_FRACTIONS tables using the gapindex
##                R package
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Setup 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Import Libraries
library(gapindex)

## Connect to Oracle
sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull Data from the gapindex R Package
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Pull GOA Management Groups from the GOA schema
goa_mgmt_spp <-  RODBC::sqlQuery(channel = sql_channel,
                                query = "SELECT MANAGEMENT_GROUP, SPECIES_CODE 
                                         FROM GOA.GOA_MANAGEMENT_GROUPS")
names(x = goa_mgmt_spp)[1] <- "GROUP"

## Pull data from gapindex based on the species groupings from 
## GOA.GOA_MANAGEMENT_GROUPS for only the past few survey years.
gp_data <- gapindex::get_data(year_set = c(2019, 2021, 2023), 
                              survey_set = "GOA",
                              spp_codes = goa_mgmt_spp, 
                              sql_channel = sql_channel, 
                              pull_lengths = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Post-stratify hauls based on the NMFS Areas
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Calculate midpoint of the observed start and end longitudes for each haul
gp_data$haul$MID_LONGITUDE <- 
  (gp_data$haul$START_LONGITUDE + gp_data$haul$END_LONGITUDE) / 2  

## Following ... reclassify hauls
gp_data$haul$STRATUM[gp_data$haul$STRATUM == 40 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 50
gp_data$haul$STRATUM[gp_data$haul$STRATUM == 142 & 
                       gp_data$haul$MID_LONGITUDE < -140] <- 141
gp_data$haul$STRATUM[gp_data$haul$STRATUM == 142 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 152

gp_data$haul$STRATUM[gp_data$haul$STRATUM == 143] <- 152 ## Note: new stratum

gp_data$haul$STRATUM[gp_data$haul$STRATUM == 240 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 250
gp_data$haul$STRATUM[gp_data$haul$STRATUM == 241 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 250

gp_data$haul$STRATUM[gp_data$haul$STRATUM == 340 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 350
gp_data$haul$STRATUM[gp_data$haul$STRATUM == 341 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 351

gp_data$haul$STRATUM[gp_data$haul$STRATUM == 440 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 450
gp_data$haul$STRATUM[gp_data$haul$STRATUM == 540 & 
                       gp_data$haul$MID_LONGITUDE >= -140] <- 550

## This is a hard-copied version of GOA.SPLIT_something
updated_stratum_area <- 
  data.frame(
    SURVEY_DEFINITION_ID = 47, SURVEY = "GOA", DESIGN_YEAR = 1984,
    STRATUM = c(40,	41,	50,	140,	141,	152,	150,	151, 240,	241, 250,	251,	
                340,	341,	350,	351, 440,	450,	540,	550),
    AREA_NAME = NA, DESCRIPTION = NA,
    AREA_KM2 = c(4980.005501,	6714.745,	11514.5325,	7346.035, 9993.915778,	
                 12043.32322,	4196.599,	6888.172, 2286.139849,	1503.635678,	
                 1882.079151, 4551.089322,	751.2781795,	1296.716466, 
                 2700.424821,	996.6395344,	1252.954196, 1249.897804, 
                 1609.551032,	1484.372968) )

## Update the stratum information in the gp_data list
gp_data$strata <- 
  rbind(subset(x = gp_data$strata,
               subset = !(STRATUM %in% updated_stratum_area$STRATUM)),
        updated_stratum_area)

## Update the stratum groupings in the gp_data list to include the new stratum
## 152. Note I'm only modifying the stratum grouping for AREA_ID 959 because
## it is the only AREA_ID that is affected. 
gp_data$stratum_groups <- rbind(
  gp_data$stratum_groups, 
  data.frame(SURVEY_DEFINITION_ID = 47,
             SURVEY = "GOA",
             AREA_ID = c(959),
             DESIGN_YEAR = 1984,
             STRATUM = 152))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Calculate CPUE, stratum biomass, then aggregate biomass across subareas
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gp_cpue <- 
  gapindex::calc_cpue(racebase_tables = gp_data)
gp_stratum_biomass <- 
  gapindex::calc_biomass_stratum(racebase_tables = gp_data, 
                                 cpue = gp_cpue)
gp_subarea_biomass <- 
  gapindex::calc_biomass_subarea(racebase_tables = gp_data, 
                                 biomass_strata = gp_stratum_biomass)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Reformat gp_subarea_biomass to something that looks like
##   GOA.GOA_SPLIT_FRACTION
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
goa_split_fractions <- 
  gp_subarea_biomass[gp_subarea_biomass$AREA_ID %in% c(949, 959), 
                 c("YEAR", "SPECIES_CODE", "AREA_ID", "BIOMASS_MT")]
goa_split_fractions <- 
  reshape(data = goa_split_fractions, 
          idvar = c("SPECIES_CODE", "YEAR"),
          timevar = "AREA_ID",
          direction = "wide")
names(x = goa_split_fractions) <- c("YEAR", "MANAGEMENT_GROUP",
                                    "WEST_BIOMASS", "EAST_BIOMASS")
goa_split_fractions$WEST_BIOMASS <- 
  round(x = goa_split_fractions$WEST_BIOMASS, digits = 1)
goa_split_fractions$EAST_BIOMASS <- 
  round(x = goa_split_fractions$EAST_BIOMASS, digits = 1)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare output from gapindex to what is currently in the GOA schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
## Pull current split fractions table
# historical_split <-
#   RODBC::sqlQuery(channel = sql_channel,
#                   query = "SELECT YEAR, MANAGEMENT_GROUP, 
#                            WEST_BIOMASS, EAST_BIOMASS 
#                            FROM GOA.SPLIT_FRACTIONS 
#                            WHERE YEAR >= 2019")
# 
# ## Merge the current split fraction table with the gapindex-produced table
# test_split <- 
#   merge(x = historical_split,
#         y = goa_split_fractions,
#         by = c("YEAR", "MANAGEMENT_GROUP"),
#         all.x = TRUE, 
#         suffixes = c("_HIST", "_GP"))
# 
# ## Calculate absolute differences between the west and east biomass estimates
# test_split$WEST_BIOMASS_DIFF <- 
#   test_split$WEST_BIOMASS_GP - test_split$WEST_BIOMASS_HIST
# test_split$EAST_BIOMASS_DIFF <- 
#   test_split$EAST_BIOMASS_GP - test_split$EAST_BIOMASS_HIST
# 
# write.csv(x = test_split[order(test_split$MANAGEMENT_GROUP), 
#                          c("YEAR", "MANAGEMENT_GROUP", 
#                              "WEST_BIOMASS_HIST", "WEST_BIOMASS_GP", 
#                              "WEST_BIOMASS_DIFF", "EAST_BIOMASS_HIST", 
#                              "EAST_BIOMASS_GP", "EAST_BIOMASS_DIFF")], 
#           file = "code/goa_split_fractions/goa_split_fractions.csv",
#           row.names = F)


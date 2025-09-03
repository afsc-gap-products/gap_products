##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Northern Bering Sea comparisons
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
##
## Description:   Comparison of 2025 NBS biomass indices for all species 
##                under two survey footprint scenarios: A) DESIGN_YEAR = 2022 
##                stratum areas and as we would normally calculate them and 
##                B) DESIGN_YEAR = 2022 area records but with stratum XX 
##                reduced to account for the survey not surveying that section.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Connect to Oracle (Make sure to connect to network or VPN)
library(gapindex)
channel <- gapindex::get_connected(check_access = F)

## Pull NBS data, make a copy for the "b" scenario.
gapindex_data_2025a <- gapindex_data_2025b <- gapindex::get_data(
  year_set = 2023,
  survey_set = "NBS",
  spp_codes = NULL,
  channel = channel)

## Modify the stratum area for the "b" version
# gapindex_data_2025b$strata$AREA_KM2[
#   gapindex_data_2025b$strata$STRATUM == 70
# ] <- 79259.89

## Fill in zeros and calculate CPUE under both stratum scenarios
cpue_a <- gapindex::calc_cpue(gapdata = gapindex_data_2025a)
cpue_b <- gapindex::calc_cpue(gapdata = gapindex_data_2025b)

## Calculate stratum-level biomass, population abundance, mean CPUE and 
## associated variances under both stratum scenarios
biomass_stratum_a <- gapindex::calc_biomass_stratum(
  gapdata = gapindex_data_2025a,
  cpue = cpue_a)

biomass_stratum_b <- gapindex::calc_biomass_stratum(
  gapdata = gapindex_data_2025b,
  cpue = cpue_b)

## Calculate aggregated biomass and population abundance across subareas,
## management areas, and regions under both stratum scenarios
biomass_subarea_a <- gapindex::calc_biomass_subarea(
  gapdata = gapindex_data_2025a,
  biomass_stratum = biomass_stratum_a)

biomass_subarea_b <- gapindex::calc_biomass_subarea(
  gapdata = gapindex_data_2025b,
  biomass_stratum = biomass_stratum_b)

## Rename fields and combine stratum and region estimates into one dataframe
names(x = biomass_stratum_a)[
  names(x = biomass_stratum_a) == "STRATUM"
] <- "AREA_ID"
names(x = biomass_stratum_b)[
  names(x = biomass_stratum_b) == "STRATUM"
] <- "AREA_ID"

biomass_a <-
  rbind(biomass_stratum_a[,
                          names(x = biomass_subarea_a), 
                          with = F],
        biomass_subarea_a)

## calculate CV of total biomass estimate
biomass_a$CV <- sqrt(x = biomass_a$BIOMASS_VAR) / 
  ifelse(test = biomass_a$BIOMASS_MT == 0, 
         yes = 1,
         no = biomass_a$BIOMASS_MT)

biomass_b <- 
  rbind(biomass_stratum_b[,
                          names(x = biomass_subarea_b), 
                          with = F],
        biomass_subarea_b)

## Calculate CV of total biomass estimate
biomass_b$CV <- sqrt(x = biomass_b$BIOMASS_VAR) / 
  ifelse(test = biomass_b$BIOMASS_MT == 0, 
         yes = 1,
         no = biomass_b$BIOMASS_MT)

## Merge the two scenarios into one dataframe
merged_biomass <- 
  merge(x = subset(x = biomass_a, select = c("SPECIES_CODE", "AREA_ID", 
                                             "BIOMASS_MT", "CV")),
        y = subset(x = biomass_b, select = c("SPECIES_CODE", "AREA_ID", 
                                             "BIOMASS_MT", "CV")),
        by = c("SPECIES_CODE", "AREA_ID"), 
        suffixes = c("_a", "_b"))

## Calculate percent difference for total biomass and absolute difference for CV
merged_biomass$BIOMASS_PERC_DIFF <- 
  round(x = with(merged_biomass, 
                 (BIOMASS_MT_b - BIOMASS_MT_a) / 
                   ifelse(test = BIOMASS_MT_a == 0, 
                          yes = 1, 
                          no = BIOMASS_MT_a) * 100), 
        digits = 2) 
merged_biomass$CV_DIFF <- 
  round(x = with(merged_biomass, (CV_b - CV_a), 
                 digits = 6) )

## Reorder columns
merged_biomass <- 
  merged_biomass[BIOMASS_MT_a > 0, 
                 c("SPECIES_CODE", "AREA_ID", 
                   "BIOMASS_MT_a", "BIOMASS_MT_b", "BIOMASS_PERC_DIFF",
                   "CV_a", "CV_b", "CV_DIFF"), 
                 with = F] 

table(merged_biomass$SPECIES_CODE)

## Save
write.csv(merged_biomass,
          "code/analysis/nbs_2025/nbs_2025_biomass_comparison.csv",
          row.names = F)

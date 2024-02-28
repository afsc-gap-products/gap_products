##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Prepare VAST Index Data Input via `gapindex` R Package
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Pull NBS/EBS index data and then compare with the 2023 
##                Hindcast data for yellowfin sole (10210), Kamchatka flounder 
##                (10112), northern rock sole (10261), and Pacific cod (21720)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())
options(scipen = 99999)

## Import gapindex and connect to Oracle.
library(gapindex)
chl <- gapindex::get_connected()

## Import comparison functions
source("functions/calc_diff.R"); source("functions/compare_tables.R")

ispp = c("yellowfin_sole", "Pacific_cod")[2]

wcpue_gp <- subset(x = readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                             ispp, "_gp/data_geostat_biomass_index.RDS")),
                   select = -c(Pass, AreaSwept_km2, Vessel))
wcpue_sf <- subset(x = readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                             ispp, "_sumfish/data_geostat_biomass_index.RDS")),
                   select = -c(Pass, AreaSwept_km2, Vessel))
wcpue_sf$Catch_KG <- wcpue_sf$Catch_KG * 100 

wcpue_merge <- merge(x = wcpue_gp, y = wcpue_sf,
                     by = c("Hauljoin"), 
                     all = T, suffixes = c("_gp", "_sf"))


compare_tables(x = wcpue_merge, 
               key_columns = c("Hauljoin"), 
               cols_to_check = data.frame(colname = "Catch_KG", 
                                          percent = F, 
                                          decplaces = 4),
               base_table_suffix = "_sf", 
               update_table_suffix = "_gp")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ncpue_gp <- subset(x = readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                             ispp, "_gp/data_geostat_numerical_index.RDS")),
                   select = -c(Pass, AreaSwept_km2, Vessel))

ncpue_sf <- subset(x = readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                             ispp, "_sumfish/data_geostat_numerical_index.RDS")),
                   select = -c(Pass, AreaSwept_km2, Vessel))
ncpue_sf$Catch_KG <- ncpue_sf$Catch_KG * 100

ncpue_merge <- merge(x = ncpue_gp, y = ncpue_sf,
                     by = c("Hauljoin"), 
                     all = T, suffixes = c("_gp", "_sf"))
head(ncpue_merge)

ncpue_test <- compare_tables(x = ncpue_merge, 
                             key_columns = c("Hauljoin"), 
                             cols_to_check = data.frame(colname = "Catch_KG", 
                                                        percent = F, 
                                                        decplaces = 4),
                             base_table_suffix = "_sf", 
                             update_table_suffix = "_gp")
ncpue_test
na_recs <- RODBC::sqlQuery(channel = chl, 
                query = paste("SELECT * 
                              FROM RACEBASE.CATCH 
                              WHERE SPECIES_CODE = ",
                              c("Pacific_cod" = 21720, 
                                "yellowfin_sole" = 10210)[ispp], 
                              "AND HAULJOIN IN ", 
                              gapindex::stitch_entries(ncpue_test$removed_records$Hauljoin)))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
agecpue_gp <- 
  subset(x = readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                   ispp, "_gp/data_geostat_agecomps.RDS")),
         select = -c(Pass, AreaSwept_km2, Vessel))
agecpue_sf <- subset(x = readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                               ispp, "_sumfish/data_geostat_agecomps.RDS")),
                     select = -c(Pass, AreaSwept_km2, Vessel))
agecpue_sf$Catch_KG <- agecpue_sf$Catch_KG * 100 

if (ispp == "Pacific_cod")
  agecpue_sf <- subset(x = agecpue_sf, Year >= 1994)

agecpue_merge <- merge(x = agecpue_gp, y = agecpue_sf,
                       by = c("Hauljoin", "Year", "Age"), 
                       all = T, suffixes = c("_gp", "_sf"))
head(agecpue_merge)

age_test <- compare_tables(x = agecpue_merge, 
               key_columns = c("Hauljoin", "Year", "Age"), 
               cols_to_check = data.frame(colname = "Catch_KG", 
                                          percent = F, 
                                          decplaces = 4),
               base_table_suffix = "_sf", 
               update_table_suffix = "_gp")

RODBC::sqlQuery(channel = chl, 
                query = paste("SELECT * 
                              FROM RACEBASE.CATCH
                              JOIN (SELECT * FROM RACEBASE.HAUL) USING (HAULJOIN)
                              WHERE SPECIES_CODE = ",
                              c("Pacific_cod" = 21720, 
                                "yellowfin_sole" = 10210)[ispp], 
                              "AND HAULJOIN IN ", 
                              gapindex::stitch_entries(sort(unique(age_test$removed_records$Hauljoin)))))

RODBC::sqlQuery(channel = chl, 
                query = paste("SELECT * 
                              FROM RACEBASE.LENGTH 
                              WHERE SPECIES_CODE = ",
                              c("Pacific_cod" = 21720, 
                                "yellowfin_sole" = 10210)[ispp], 
                              "AND HAULJOIN IN ", 
                              gapindex::stitch_entries(sort(unique(age_test$removed_records$Hauljoin)))))

merge(x = aggregate(Catch_KG ~ Hauljoin,
                    data = agecpue_sf,
                    FUN = sum,
                    subset = Hauljoin %in% age_test$modified_records$Hauljoin),
      y = ncpue_sf,
      by = "Hauljoin")
merge(x = aggregate(Catch_KG ~ Hauljoin,
                    data = agecpue_gp,
                    FUN = sum,
                    subset = Hauljoin %in% age_test$modified_records$Hauljoin),
      y = ncpue_gp,
      by = "Hauljoin")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Compare ALKs
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alk_gp <- subset(readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                       ispp, "_gp/alk.RDS")))
alk_sf <- readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                ispp, "_sumfish/unstratified_alk.RDS"))
names(x = alk_sf) <- c("LENGTH_MM", "AGE", "AGE_FRAC", "SPECIES_CODE",
                       "SEX", "YEAR", "SURVEY")

alk_merge <- merge(x = alk_gp, y = alk_sf,
                   by = c("SURVEY", "YEAR", "SPECIES_CODE", 
                          "SEX", "LENGTH_MM", "AGE"), 
                   all = T, suffixes = c("_gp", "_sf"))
head(alk_merge)

alk_test <- compare_tables(x = alk_merge, 
               key_columns = c("SURVEY", "YEAR", "SPECIES_CODE", 
                               "SEX", "LENGTH_MM", "AGE"), 
               cols_to_check = data.frame(colname = "AGE_FRAC", 
                                          percent = F, 
                                          decplaces = 4),
               base_table_suffix = "_sf", 
               update_table_suffix = "_gp")

subset(alk_test$new, SURVEY == "EBS")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
data_gp <- readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                       ispp, "_gp/ebs_data.RDS"))
data_sf <- readRDS(file = paste0("code/modsquad_bridge/bering_sea/",
                                ispp, "_sumfish/raw_data.RDS"))

unique_hauls_cpue_sf <- data_sf$NBS$haul$HAULJOIN
unique_hauls_otos_sf <- sort(unique(data_sf$NBS$specimen$HAULJOIN[!is.na(x = data_sf$NBS$specimen$AGE)]))


RODBC::sqlQuery(channel = chl,
                query = paste("SELECT HAULJOIN, FLOOR(CRUISE/100) AS YEAR, 
                              STRATUM, HAUL_TYPE, PERFORMANCE, ABUNDANCE_HAUL
                              FROM RACEBASE.HAUL
                              WHERE HAULJOIN IN",
                              gapindex::stitch_entries(unique_hauls_otos_sf[!(unique_hauls_otos_sf %in% unique_hauls_cpue_sf)])))

unique_hauls_cpue_gp <- data_gp$haul$HAULJOIN
unique_hauls_otos_gp <- sort(unique(data_gp$specimen$HAULJOIN))
unique_hauls_otos_gp[!(unique_hauls_otos_gp %in% unique_hauls_cpue_gp)]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
summed_agecpue_gp <- aggregate(Catch_KG ~ Hauljoin + Year, data = agecpue_gp, FUN = sum)

compare_tables(x = merge(x = summed_agecpue_gp,
                         y = ncpue_gp,
                         by = c("Hauljoin", "Year"),
                         suffixes = c("_age", "_ncpue")), 
               key_columns = c("Hauljoin", "Year"), 
               cols_to_check = data.frame(colname = "Catch_KG", 
                                          percent = F, 
                                          decplaces = 4),
               base_table_suffix = "_age", 
               update_table_suffix = "_ncpue")



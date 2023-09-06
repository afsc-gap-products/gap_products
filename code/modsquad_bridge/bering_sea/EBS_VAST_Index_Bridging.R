##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Prepare VAST Index Data Input via `gapindex` R Package
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   Pull NBS/EBS index data and then compare with the 2023 
##                Hindcast data for yellowfin sole (10210), Kamchatka flounder 
##                (10112), northern rock sole (10261), and Pacific cod (21720)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import gapindex package, connect to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
library(googledrive)
sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Constants
##   There are some species codes missing from the suite of species in the 
##   Bering Sea ModSquad requests (pollock, tanner crab) but I am not sure
##   if there are different data requirements for those... These four species
##   all have the same data pulls (except NRS where we only pull yeras 1995-on)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
species_code <- c(10210, 10112, 10261, 21720)
start_year <- 1982
current_year <- 2022

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull catch and effort data
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Standard EBS stations
yfs_ebs_standard <- gapindex::get_data(year_set = start_year:current_year,
                                       survey_set = "EBS",
                                       spp_codes = species_code,
                                       pull_lengths = FALSE, 
                                       haul_type = 3, 
                                       abundance_haul = c("Y"),
                                       sql_channel = sql_channel,
                                       na_rm_strata = TRUE)

## Well-performing hauls that are not included in the design-based indices
## (abundance_haul == "N") but are included in VAST.  
yfs_ebs_other <- gapindex::get_data(year_set = c(1994, 2001, 2005, 2006),
                                    survey_set = "EBS",
                                    spp_codes = species_code,
                                    pull_lengths = FALSE, 
                                    haul_type = 3, 
                                    abundance_haul = c("N"),
                                    sql_channel = sql_channel, 
                                    na_rm_strata = TRUE)

yfs_ebs <- list(
  ## Some cruises are shared between the standard and other EBS cruises, so the
  ## unique() wrapper is there to remove duplicate cruise records. 
  cruise = unique(rbind(yfs_ebs_standard$cruise,
                        yfs_ebs_other$cruise)),
  haul = rbind(yfs_ebs_standard$haul,
               yfs_ebs_other$haul),
  catch = rbind(yfs_ebs_standard$catch,
                yfs_ebs_other$catch),
  size = rbind(yfs_ebs_standard$size,
               yfs_ebs_other$size),
  species = yfs_ebs_standard$species,
  specimen = rbind(yfs_ebs_standard$specimen,
                   yfs_ebs_other$specimen))

yfs_ebs_cpue <- gapindex::calc_cpue(racebase_tables = yfs_ebs)

## Standard NBS stations
yfs_nbs_standard <- get_data(year_set = start_year:current_year,
                             survey_set = "NBS",
                             spp_codes = species_code,
                             pull_lengths = FALSE, 
                             haul_type = 3, 
                             abundance_haul = c("Y"),
                             sql_channel = sql_channel)
nrow(yfs_nbs_standard$haul)

## Misc. stations in 1985, 1988, and 1991 that were in the NBS but not a part 
## of the standard stations. These cruises have a different survey definition 
## ID, so they will not come up in gapindex::get_data()
yfs_nbs_other_hauls <-
  RODBC::sqlQuery(channel = sql_channel,
                  query = paste("SELECT * from RACEBASE.HAUL WHERE",
                                "CRUISE IN (198502, 198808, 199102) AND",
                                "HAUL_TYPE = 3 AND PERFORMANCE >= 0 AND",
                                "ABUNDANCE_HAUL = 'Y'"))

yfs_nbs_other_catch <- RODBC::sqlQuery(
  channel = sql_channel,
  query = paste("SELECT HAULJOIN, SPECIES_CODE, WEIGHT, NUMBER_FISH",
                "FROM RACEBASE.CATCH WHERE",
                "SPECIES_CODE IN ", gapindex::stitch_entries(species_code),
                "AND HAULJOIN IN",
                gapindex::stitch_entries(yfs_nbs_other_hauls$HAULJOIN)))

yfs_nbs_other_cruise <-
  data.frame(YEAR = c(1988, 1985, 1991),
             SURVEY_DEFINITION_ID = 112,
             RODBC::sqlQuery(
               channel = sql_channel,
               query = paste("SELECT CRUISEJOIN, REGION, CRUISE",
                             "FROM RACEBASE.CRUISE WHERE",
                             "CRUISE IN (198502, 198808, 199102) AND",
                             "REGION = 'BS'")),
             CRUISE_ID = NA,
             SURVEY = "NBS",
             DESIGN_YEAR = 2022)

yfs_nbs_other <- list(cruise = yfs_nbs_other_cruise,
                      species = yfs_nbs_standard$species,
                      haul = yfs_nbs_other_hauls,
                      catch = yfs_nbs_other_catch)

## 2018 NBS survey that is defined as an EBS survey
yfs_nbs18 <- get_data(year_set = 2018,
                      survey_set = "EBS",
                      spp_codes = species_code,
                      pull_lengths = TRUE, 
                      haul_type = 13, 
                      abundance_haul = "N",
                      sql_channel = sql_channel)
yfs_nbs18$cruise$SURVEY <- "NBS"
yfs_nbs18$cruise$SURVEY_DEFINITION_ID <- 143

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Append all NBS data into one list, calculate CPUE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
yfs_nbs <- list(cruise = rbind(yfs_nbs_standard$cruise,
                               yfs_nbs_other$cruise,
                               yfs_nbs18$cruise),
                catch = rbind(yfs_nbs_standard$catch,
                              yfs_nbs_other$catch,
                              yfs_nbs18$catch),
                haul = rbind(yfs_nbs_standard$haul,
                             yfs_nbs_other$haul,
                             yfs_nbs18$haul),
                species = yfs_nbs_standard$species)
yfs_nbs_cpue <- gapindex::calc_cpue(racebase_tables = yfs_nbs)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Append EBS and NBS CPUE records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
yfs_ebs_nbs_cpue <- 
  subset(x = rbind(yfs_ebs_cpue,
                   yfs_nbs_cpue),
         subset = !(SPECIES_CODE == 10261 & YEAR < 1995),
         select = c("SURVEY", "YEAR", "STRATUM", "HAULJOIN",
                    "LATITUDE_DD_START", "LATITUDE_DD_END",
                    "LONGITUDE_DD_START", "LONGITUDE_DD_END",
                    "SPECIES_CODE", "WEIGHT_KG", "COUNT",
                    "AREA_SWEPT_KM2", "CPUE_KGKM2", "CPUE_NOKM2"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Authorize R to communicate with google drive
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
googledrive::drive_auth()
1

data_sources <- 
  data.frame(
    species_code = species_code,
    link = c("https://drive.google.com/file/d/1xnhrLLgslsS00okHPNA2UqacdgUr-Zyl/view?usp=drive_link",
             "https://drive.google.com/file/d/1Ceux8QNtl6fV-DHTOTAL3SGV69hfWrTR/view?usp=drive_link",
             "https://drive.google.com/file/d/15ohn8ZAauygf3ixA3FCe0211pYZINKnN/view?usp=drive_link",
             "https://drive.google.com/file/d/19pRwy-Z-I9YzaojYGfVd3Iooy6q99X0P/view?usp=drive_link")
  )

for (irow in 1:nrow(data_sources)) {
  googledrive::with_drive_quiet(
    googledrive::drive_download( 
      file = googledrive::as_id(x = data_sources$link[irow]),
      overwrite = TRUE,
      path = paste0("temp/VAST_Index_", data_sources$species_code[irow], ".RDS")
      )
    )
  
  temp_file <- readRDS(file = paste0("temp/VAST_Index_",
                                     data_sources$species_code[irow],
                                     ".RDS"))
  
  temp_gapindex <- subset(yfs_ebs_nbs_cpue, 
                          SPECIES_CODE == data_sources$species_code[irow])
  temp_gapindex$CPUE_KGKM2 <- temp_gapindex$CPUE_KGKM2 / 100
  
  test <- merge(x = temp_file[, c("HAULJOIN", "wCPUE")],
                y = temp_gapindex[, c("HAULJOIN", "CPUE_KGKM2")],
                by = "HAULJOIN")
  test$diff <- test$wCPUE  - test$CPUE_KGKM2
  cat("Number of mismatched records for", 
      data_sources$species_code[irow], "-", sum(round(test$diff, 1) != 0), "\n")
}

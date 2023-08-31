##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       GAP_PRODUCTS standard table production workflow
##                NOAA AFSC GAP Survey Team
## PoC:           Zack Oyafuso (zack.oyafuso@noaa.gov)
##                Emily Markowitz (emily.markowitz@noaa.gov)
##                
## Description:   This script houses the sequence of programs that calculate
##                the standard data products resulting from the NOAA AFSC 
##                Groundfish Assessment Program bottom trawl surveys.
##                
##                The GAP_PRODUCTS Oracle schema houses the standard data
##                product tables and views and will be updated twice a year,
##                once after the survey season following finalization of that
##                summer's bottom trawl survey data to incorporate the new 
##                catch, size, and effort data and once prior to an upcoming
##                survey to incorporate new age data that were processed after
##                the prior summer's survey season ended. This second 
##                pre-survey production run will also incorporate changes in 
##                the data due to the specimen voucher process as well as other
##                post-hoc changes in the survey data. 
##                
##                Step 1 of the workflow is importing versions of the tables
##                in GAP_PRODUCTS locally within the gap_products repository
##                in a temporary (temp/) folder. The temp/ folder is ignored in
##                the GitHub workflow and is important when comparing the 
##                updated production tables to what is currently in the 
##                GAP_PRODUCTS schema. Any updates to a production table will 
##                be compared and checked to make sure changes to the contents 
##                of the table are intentional and documented.
##                
##                Step 2 involves updating the metadata tables in GAP_PRODUCTS
##                used to create the metadata for the tables and views in 
##                GAP_PRODUCTS. The contents of these tables are maintained
##                in a shared googlesheets document. These tables are compared 
##                and checked to their respective locally saved copies and any 
##                changes to the tables are vetted and documented. These
##                tables are then uploaded to GAP_PRODUCTS.
##                
##                Step 3 involves updating the tables containing taxonomic
##                information. Taxonomic information change over time (e.g., 
##                classifications, new taxa, deprecated taxa, lumped/
##                split taxa) so this step updates the taxonomic information 
##                used in GAP_PRODUCTS. These tables are compared and checked 
##                to their respective locally saved copies and any changes to 
##                the tables are vetted and documented. These tables are then 
##                uploaded to GAP_PRODUCTS.
##                
##                Step 4 is the calculation of the four major standard data
##                products: CPUE, BIOMASS, SIZECOMP, AGECOMP. These tables are 
##                compared and checked to their respective locally saved copies 
##                and any changes to the tables are vetted and documented.  
##                These tables are then uploaded to GAP_PRODUCTS.
##                
##                Step 5 is the calculation of the various materialized views
##                for AKFIN purposes. Since these are derivative of the tables
##                in GAP_PRODUCTS as well as other base tables in RACEBASE and
##                RACE_DATA, it is not necessary to check these views. 
## 
##                Step 6 is the calculation of the CPUE and haul materialized 
##                views for FOSS purposes. Since these are derivative of the 
##                tables and views in GAP_PRODUCTS as well as other base tables
##                in RACEBASE and RACE_DATA, it is not necessary to check these
##                views. 
##                
##                Disclaimer: Each script is self-contained. Do not source 
##                this script. The script for each step needs to be run 
##                line-by-line with caution.  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step 1 Setup ----
##   Make sure temp file is created, save R version data
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (!dir.exists(paths = "temp/"))
  dir.create(path = "temp/")

writeLines(text = capture.output(sessionInfo()), 
           con = "temp/sessionInfo.txt")
write.csv(x = as.data.frame(installed.packages()[, c("Package", "Version")], 
                            row.names = F), 
          file = "temp/installed_packages.csv", 
          row.names = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step 2 Pull Exisiting GAP_PRODUCTS Tables and Views ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/pull_existing_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step 3 Update Metadata Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/metadata.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step X Create Production Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/production.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step X Compare Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/compare_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step Upload Production Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/push_oracle.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step Upload Production Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/akfin.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step X Create Citations ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/CITATION.R")




# # Support scripts --------------------------------------------------------------
# 
# source('./code/functions.R')
# 
# # Set output directory ---------------------------------------------------------
# 
# dir_out <- paste0(getwd(), "/output/", Sys.Date(),"/")
# dir.create(dir_out)
# dir_data <- paste0(getwd(), "/data/")
# 
# # Save scripts from each run to output -----------------------------------------
# # Just for safe keeping
# 
# dir.create(paste0(dir_out, "/code/"))
# listfiles<-list.files(path = paste0("./code/"))
# listfiles0<-c(listfiles[grepl(pattern = "\\.r",
#                               x = listfiles, ignore.case = T)],
#               listfiles[grepl(pattern = "\\.rmd",
#                               x = listfiles, ignore.case = T)])
# listfiles0<-listfiles0[!(grepl(pattern = "~",ignore.case = T, x = listfiles0))]
# 
# for (i in 1:length(listfiles0)){
#   file.copy(from = paste0("./code/", listfiles0[i]),
#             to = paste0(dir_out, "/code/", listfiles0[i]),
#             overwrite = T)
# }
# 
# ## sign into google drive ------------------------------------------------------
# 
# # library(googledrive)
# # googledrive::drive_deauth()
# googledrive::drive_auth()
# 2
# 
# ## Connect to Oracle -----------------------------------------------------------
# 
# if (file.exists("Z:/Projects/ConnectToOracle.R")) {
#   source("Z:/Projects/ConnectToOracle.R") # EHM shortcut
#   channel <- channel_products
# } else {
#   gapindex::get_connected()
# }
# 
# ## Resources -------------------------------------------------------------------
# 
# # Create Citation File and find citation links ---------------------------------
# 
# source(here::here("code", "citation.R"))
# 
# # Create tables ----------------------------------------------------------------
# 
# ## Metadata --------------------------------------------------------------------
# 
# source(here::here("code","metadata.R")) 
# # source(here::here("code","metadata_current.R")) 
# 
# ## Taxonomic Tables -----------------------------------------------------------
# 
# # Check with Sarah - maybe we should post this, or maybe she wants to be responsible for this?
# source(here::here("code", "taxonomics.R"))
# 
# ## Calculate Production Tables -------------------------------------------------
# 
# # @Zack, reformat: 
# # How do we want to deal with stratum/stratum_groupings/area tables/survey_design?
# # should we remove crab data? Question for Alix? 
# if (FALSE) {
#   source("https://github.com/afsc-gap-products/gapindex/blob/master/code_testing/production.R")
#   source(here::here("code", "production.R")) # some suggested fixes in here
# }
# 
# ## FOSS Tables -----------------------------------------------------------------
# 
# source(here::here("code", "foss.R"))
# 
# ## AKFIN Tables -----------------------------------------------------------------
# 
# source(here::here("code", "akfin.R"))
# 
# # Upload tables to GAP_PRODUCTS -----------------------------------------------
# 
# source(here::here("code","load_oracle.R")) 
# 
# # Save README and other documentation ------------------------------------------
# 
# dir_out <- paste0(getwd(), "/output/2023-06-26/") # Don't forget to change as needed!
# source(here::here("code", "website.R"))
# ## Type `quarto render` in the terminal 

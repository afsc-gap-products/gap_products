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
##                Step 3 is the calculation of the four major standard data
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
##   Step 0 Setup ----
##   Make sure temp file is created, save R version data
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (!dir.exists(paths = "temp/"))
  dir.create(path = "temp/")

writeLines(text = as.character(Sys.Date()), 
           con = "temp/timestamp.txt")
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
##   Step 4 Create Production Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/production.R")
file.edit("code/check_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step Upload Production Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/push_oracle.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step Upload Production Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/akfin.R")
file.edit("code/taxonomics.R")
file.edit("code/foss.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Archive GAP_PRODUCTS  ----
##   Only archive the bits that would allow one to reproduce the 
##   Standard Data tables. The session info and package versions are also 
##   csv files in the temp/folder. The NEWS html is currently the way that 
##   changes are reported. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Create a new directory with the timestamp as the title
dir.create(path = readLines(con = "temp/timestamp.txt"))

## Copy the necessary items into the directory
file.copy(from = "gap_products.Rproj", 
          to = )
fs::dir_copy(path = "code/", 
         new_path = readLines(con = "temp/timestamp.txt"))
fs::dir_copy(path = "functions/", 
             new_path = readLines(con = "temp/timestamp.txt"))
fs::dir_copy(path = "temp/", 
             new_path = readLines(con = "temp/timestamp.txt"))

## zip folder and move to G: drive
utils::zip(files = readLines(con = "temp/timestamp.txt"),
           zipfile = paste0(getwd(), "/", 
                            readLines(con = "temp/timestamp.txt"), ".zip") )

fs::file_move(path = paste0(readLines(con = "temp/timestamp.txt"), ".zip"),
              new_path = "Y:/RACE_GF/GAP_PRODUCTS_Archives/")
fs::file_delete(path = readLines(con = "temp/timestamp.txt"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step Create Citations ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# file.edit("code/CITATION.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Step Create README ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rmarkdown::render("code/README.Rmd",
#                   output_file = "README.md")

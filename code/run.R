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
##                the data due to the specimen voucher process, as well as 
##                other post hoc changes to the survey data. 
##                
##                **DISCLAIMER**: Each script is self-contained. Do not source 
##                this script. The script for each step needs to be run 
##                line-by-line with caution. The file.edit() function simply
##                opens the script in a new tab within RStudio. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   etup ----
##   Make sure temp file is created, save R version data, and install packages
##   if not available on your machine or if outdated.
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

# devtools::install_github("afsc-gap-products/gapindex@using_datatable", force = TRUE)
# devtools::install_github("afsc-gap-products/gapindex")
# install.packages("data.table")
# install.packages("rmarkdown")
library(gapindex)
library(data.table)
library(rmarkdown)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull Exisiting GAP_PRODUCTS Tables and Views ----
##   Import the current version of the tables in GAP_PRODUCTS locally within 
##   the gap_products repository in the temporary (temp/) folder that was just
##   created. The local versions of these tables are used to compare the 
##   updated production tables that we create in a later step to what is 
##   currently in the GAP_PRODUCTS schema.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/pull_existing_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create Production Tables ----
##   Calculate the four major standard data products: CPUE, BIOMASS, SIZECOMP, 
##   AGECOMP for all taxa, survey years, survey regions. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/production.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   These tables are compared and checked to their respective locally saved 
##   copies in the temp/ folder, and any changes to the tables are tabulated 
##   and documented in a text file outputted to the temp/ folder.  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/check_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Upload Production Tables ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/push_oracle.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Upload Production Tables ----
##   Set up queries for the various materialized views created for AKFIN
##   and FOSS.
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
## Copy report changes to news section
fs::file_copy(path = "temp/report_changes.txt",
              new_path = paste0("content/intro-news/", 
                                readLines(con = "temp/timestamp.txt"), 
                                ".txt") )

## Create a new directory with the timestamp as the title
dir.create(path = readLines(con = "temp/timestamp.txt"))

## Copy the necessary items into the directory
file.copy(from = "gap_products.Rproj", 
          to = readLines(con = "temp/timestamp.txt"))
fs::dir_copy(path = "code/", 
         new_path = readLines(con = "temp/timestamp.txt"))
fs::dir_copy(path = "functions/", 
             new_path = readLines(con = "temp/timestamp.txt"))
fs::dir_copy(path = "temp/", 
             new_path = readLines(con = "temp/timestamp.txt"))

## Zip folder and move to G: drive
utils::zip(files = readLines(con = "temp/timestamp.txt"),
           zipfile = paste0(getwd(), "/", 
                            readLines(con = "temp/timestamp.txt"), ".zip") )

fs::file_move(path = paste0(readLines(con = "temp/timestamp.txt"), ".zip"),
              new_path = "Y:/RACE_GF/GAP_PRODUCTS_Archives/")
fs::file_delete(path = readLines(con = "temp/timestamp.txt"))

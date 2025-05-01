##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       GAP_PRODUCTS standard table production workflow
##                NOAA AFSC GAP Survey Team
## PoC:           Zack Oyafuso (zack.oyafuso@noaa.gov)
##                Emily Markowitz (emily.markowitz@noaa.gov)
##                
## Description:   This script houses a sequence of programs that calculates
##                the standard data products resulting from the NOAA AFSC 
##                Groundfish Assessment Program bottom trawl surveys and 
##                Standard GAP survey data products in this repository include
##                CPUE, Biomass, Size Composition, and Age Composition. Tables
##                that are served to the Alaska Fisheries Information Network
##                (AKFIN) and Fisheries One Stop Shop (FOSS) data portals are
##                also housed here as materialized views that are often 
##                mirrors of these standard data tables or queries of tables in 
##                RACEBASE/RACE_DATA. 
##                
##                The GAP_PRODUCTS Oracle schema houses the four standard data
##                product tables and views and will be updated at least twice a
##                year: once prior to the survey season to incorporate new age
##                data and vouchered specimens that were processed after the 
##                prior year's survey and at least once after the survey season
##                following the conclusion of each region's survey. 
##                
##                **DISCLAIMER**: Each script is self-contained. Do not source 
##                this script. Each of the following scripts needs to be run 
##                line-by-line with caution. The file.edit() function simply
##                opens the script in a new tab within RStudio.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Setup ----
##   Make sure a local temp/ directory is created, save R version data, 
##   and install packages if not available on your machine or if outdated.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex) # devtools::install_github("afsc-gap-products/gapindex")
source("functions/output_r_session.R")
output_r_session(path = "temp/") ## sets up temp/ folder

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull Existing GAP_PRODUCTS Tables and Views ----
##   Import current versions of the data tables in GAP_PRODUCTS locally within 
##   the gap_products repository in temp/ folder. These local versions of the 
##   tables are used to compare against the updated production tables that we 
##   create in a later step to what is currently in the GAP_PRODUCTS schema.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/pull_existing_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create Production Tables and Compare Data Table----
##   Calculate the four major standard data products: CPUE, BIOMASS, SIZECOMP, 
##   AGECOMP for all taxa, survey years, survey regions and compare to what
##   is on GAP_PRODUCTS currently 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/production.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update Production Tables and Update AKFIN and FOSS Tables----
##   Removed, new, and modified records are updated in GAP_PRODUCTS.
##   Once GAP_PRODUCTS tables are updated, run queries for the materialized 
##   views created for AKFIN and FOSS.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/update_production_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Archive GAP_PRODUCTS  ----
##   Archive the bits that would allow one to reproduce the standard data 
##   tables. The session info and package versions are also .csv files in the 
##   temp/folder.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
source("functions/archive_gap_products.R") 
archive_gap_products(path = "temp/", 
                     archive_path = "G:/GAP_PRODUCTS_Archives/")

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
##                (AKFIN) are also housed here as materialized views that are 
##                often mirrors of these standard data tables or queries of 
##                tables in RACEBASE/RACE_DATA. 
##                
##                The GAP_PRODUCTS Oracle schema is updated a handful of times 
##                throughout the year: 
##                1) After finalization of each region's survey data in time 
##                for the September Plan Team Groundfish meeting.
##                2) After the Bering Sea pollock ages from the current year's 
##                summer survey are read
##                3) As needed as age data are updated throughout the year.
##                Usually this happens in the Spring before we leave for survey
##                
##                **DISCLAIMER**: Each script is self-contained. Do not source 
##                this script. Each of the following scripts needs to be run 
##                line-by-line with caution. The file.edit() function simply
##                opens the script in a new tab within RStudio.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   R Setup ----
##   Make sure a local temp/ directory is created, save R version data, 
##   and install packages if not available on your machine or if outdated.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex) # devtools::install_github("afsc-gap-products/gapindex")
source("functions/output_r_session.R")
output_r_session(path = "temp/") ## sets up temp/ folder

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   GCS Bucekt Setup ----
##   A Google Cloud Storage (GCS) bucket caled afs_race_gap_products has been 
##   created to archive each production run and the end of this process. 
##   Here is general info on GCB buckets from the NOAA AFSC Intranet:
##   https://sites.google.com/noaa.gov/myafsc/technology/google-cloud-storage-gcs-buckets
##
##   The data owners are currently: Zack Oyafuso, Ned Laman, Duane Stevenson, 
##   and Susanne McDermott. If you do not have read and write access to the GCS 
##   bucket, contact one of the data owners to have your account added.
##  
##   Here are instructions for data owners on how to update privileges to users: 
##   https://docs.google.com/document/d/1Dlsnh62ORyZ86GrFadE89Dy7i_lAFSwL_2r8Scbi5Pc/edit?tab=t.0#heading=h.grqang12lyra
##  
##   Once you confirm read and write access to the GCS bucket, read these 
##   instruction from OFIS on how to mount the GCS bucket onto your machine: 
##   https://docs.google.com/document/d/15kAJnN_vlsZMx6KA3wrLUyvdjHKICdoNbMFJdzSgP_Y/edit?tab=t.0#heading=h.ntn2bqhuehb9
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Pull Existing GAP_PRODUCTS Tables ----
##   Import current versions of the data tables in GAP_PRODUCTS locally within 
##   the gap_products repository in temp/ folder. These local versions of the 
##   tables are used to compare against the updated production tables that we 
##   create in a later step to what is currently in the GAP_PRODUCTS schema.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/pull_existing_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create Production Tables----
##   Calculate the four major standard data products: CPUE, BIOMASS, SIZECOMP, 
##   AGECOMP for all taxa, survey years, survey regions and compare to what
##   is on GAP_PRODUCTS currently 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/production.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update Production Tables----
##   Removed, new, and modified records are updated in GAP_PRODUCTS.
##   Once GAP_PRODUCTS tables are updated, run queries for the materialized 
##   views created for AKFIN and FOSS.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/update_production_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Transfer to AKFIN ----
##   Directly Upload AKFIN_* production tables to AKFIN server
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/direct_upload_akfin.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Transfer changelog text file ----
##   Copy the changelog (timestamp.txt) to the content/intro-news/ folder
##   so that it can be added to the NEWS section of the gap_products webpage
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fs::file_copy(
  path = "temp/report_changes.txt",
  new_path = paste0("content/intro-news/", 
                    readLines(con = "temp/timestamp.txt"), ".txt")
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Archive gap_products Run ----
##   Zip your local copy of the gap_products repo and rename it as the timestamp
##   in temp/timestamp.txt, i.e., 2026-09-10.zip. Move that zipped folder to 
##   the afsc_race_gap_products GCS bucket 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Git Merge your changes ----
##   Create a pull request to merge your branch/fork to the main repo.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

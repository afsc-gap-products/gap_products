##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       GAP_PRODUCTS standard table production workflow
##                NOAA AFSC GAP Survey Team
##                Utility tasks 
## PoC:           Zack Oyafuso (zack.oyafuso@noaa.gov)
##                Emily Markowitz (emily.markowitz@noaa.gov)
##                
## Description:   This script houses R scripts used to update certain tables 
##                within the GAP_PRODUCTS schema as needed. 
##                
##                **DISCLAIMER**: Each script is self-contained. Do not source 
##                this script. The script for each step needs to be run 
##                line-by-line with caution. The file.edit() function simply
##                opens the script in a new tab within RStudio. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update Metadata Tables ----
##   Currently Done As Needed
##   metadata.R script updates the metadata tables in GAP_PRODUCTS used to 
##   create the metadata for the tables and views in GAP_PRODUCTS. 
##   pull_support_tables.R updates the AREA, SURVEY_DESIGN, STRATUM_GROUPS, 
##   and SPECIES_YEAR tables in GAP_PRODUCTS used to create the
##   metadata for the tables and views in GAP_PRODUCTS. The contents of these 
##   tables are maintained in a shared googlesheets document. These tables are 
##   then uploaded to the GAP_PRODUCTS Oracle schema. A future goal of this 
##   step is to move away from making changes to the googlesheet and instead 
##   setting up triggers in Oracle to provide an audit record any time a change
##   is made to these metadata tables. In this way, changes are arguably 
##   better documented and the upkeep of the tables are fully contained within
##   Oracle instead of the current workflow which is Google Sheets --> R (via 
##   the googledrive R package) --> Oracle. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/utility_scripts/metadata.R")
file.edit("code/utility_scripts/pull_support_tables.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update GAP_PRODUCTS.Taxonomic_Confidence Table ----
##   Once a year prior to survey to populate taxonomic confidence values for
##   the current survey year
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/utility_scripts/taxonomic_confidence.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update GAP_PRODUCTS.TAXON_GROUPS Table ----
##   Once a year prior to survey or as needed to update any taxonomic changes
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/utility_scripts/taxonomic_groupings.R")

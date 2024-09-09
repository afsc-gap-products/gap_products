##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       GAP_PRODUCTS Utility Scripts
##                NOAA AFSC GAP Survey Team
## PoC:           Zack Oyafuso (zack.oyafuso@noaa.gov)
##                Emily Markowitz (emily.markowitz@noaa.gov)
##                
## Description:   This script houses a hodgepodge of R scripts used to perform
##                miscellaneous functions to maintain the GAP_PRODUCTS 
##                Oracle schema outside of the standard production run of 
##                CPUE, Biomass, Size Composition, and Age Composition. In
##                each section header, I put the frequency at which one would
##                need to run each script. 
##                
##                **DISCLAIMER**: Each script is self-contained. Do not source 
##                this script. The script for each step needs to be run 
##                line-by-line with caution. The file.edit() function simply
##                opens the script in a new tab within RStudio. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update GAP_PRODUCTS.Taxonomic_Confidence Table ----
##   Frequncy: Once a year prior to survey 
##   Populates opulate taxonomic confidence values for the current survey year
##   for FOSS purposes. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/utility_scripts/taxonomic_confidence.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Update GAP_PRODUCTS.TAXONONOIC_GROUPS Table ----
##   Frequency: Once a year prior to survey or as needed
##   Updates any taxonomic changes to the taxonomic grouping table
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/utility_scripts/taxonomic_groupings.R")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   In case you need recreate audit tables. 
##   Frequency: As Needed (mostly in case of emergency)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file.edit("code/utility_scripts/create_audit_tables.R")

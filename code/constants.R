##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Source metadata constants
## Description:   Script that houses commonly used constants used to produce
##                the metadata for the various production tables and views.  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

## Links to various references
link_foss <- "https://www.fisheries.noaa.gov/foss"  
link_repo <- "https://github.com/afsc-gap-products/gap_products" # paste0(shell("git config --get remote.origin.url")) 
link_repo_web <- "https://afsc-gap-products.github.io/gap_products/"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"

## Today's date
pretty_date <- format(Sys.Date(), "%B %d, %Y")


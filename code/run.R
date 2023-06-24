#' -----------------------------------------------------------------------------
#' title: Create GAP_PRODUCT data 
#' author: EH Markowitz (emily.markowitz AT noaa.gov)
#' start date: 2023-06-21
#' last modified: 2023-06-21
#' Notes: 
#' -----------------------------------------------------------------------------

# Support scripts --------------------------------------------------------------

source('./code/functions.R')

## sign into google drive ------------------------------------------------------

# library(googledrive)
# googledrive::drive_deauth()
googledrive::drive_auth()
2

## Connect to Oracle -----------------------------------------------------------

if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R") # EHM shortcut
  channel <- channel_products
} else {
  gapindex::get_connected()
}

## Resources -------------------------------------------------------------------

# Create Citation File and find citation links ---------------------------------

source(here::here("code", "citation.R"))
link_repo <- "https://github.com/afsc-gap-products/gap_products" # paste0(shell("git config --get remote.origin.url")) 
link_repo_web <- "https://afsc-gap-products.github.io/gap_products/"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"
pretty_date <- format(Sys.Date(), "%B %d, %Y")

# Create tables ----------------------------------------------------------------

## Metadata --------------------------------------------------------------------

source(here::here("code","metadata.R")) 
# source(here::here("code","metadata_current.R")) 

## FOSS Tables -----------------------------------------------------------------

source(here::here("code", "foss.R"))

## Taxonomic Tables -----------------------------------------------------------

# Check with Sarah - maybe we should post this, or maybe she wants to be responsible for this?
source(here::here("code", "taxonomics.R"))

## Calculate Production Tables -------------------------------------------------

# @Zack, reformat: 
# How do we want to deal with stratum/stratum_groupings/area tables/survey_design?
if (FALSE) {
 source("https://github.com/afsc-gap-products/gapindex/blob/master/code_testing/production.R")
 source(here::here("code", "production.R")) # some suggested fixes in here
}

# Upload tables to GAP_PRODUCTS -----------------------------------------------

source(here::here("code","load_oracle.R")) 

# Save README and other documentation ------------------------------------------

dir_out <- paste0(getwd(), "/output/2023-06-23/") # Don't forget to change as needed!
source(here::here("code", "website.R"))


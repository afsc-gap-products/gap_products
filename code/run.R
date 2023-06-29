#' -----------------------------------------------------------------------------
#' title: Create GAP_PRODUCT data 
#' author: EH Markowitz (emily.markowitz AT noaa.gov)
#' start date: 2023-06-21
#' last modified: 2023-06-21
#' Notes: 
#' -----------------------------------------------------------------------------

# Support scripts --------------------------------------------------------------

source('./code/functions.R')

# Set output directory ---------------------------------------------------------

dir_out <- paste0(getwd(), "/output/", Sys.Date(),"/")
dir.create(dir_out)
dir_data <- paste0(getwd(), "/data/")

# Save scripts from each run to output -----------------------------------------
# Just for safe keeping

dir.create(paste0(dir_out, "/code/"))
listfiles<-list.files(path = paste0("./code/"))
listfiles0<-c(listfiles[grepl(pattern = "\\.r",
                              x = listfiles, ignore.case = T)],
              listfiles[grepl(pattern = "\\.rmd",
                              x = listfiles, ignore.case = T)])
listfiles0<-listfiles0[!(grepl(pattern = "~",ignore.case = T, x = listfiles0))]

for (i in 1:length(listfiles0)){
  file.copy(from = paste0("./code/", listfiles0[i]),
            to = paste0(dir_out, "/code/", listfiles0[i]),
            overwrite = T)
}

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

# Create tables ----------------------------------------------------------------

## Metadata --------------------------------------------------------------------

source(here::here("code","metadata.R")) 
# source(here::here("code","metadata_current.R")) 

## Taxonomic Tables -----------------------------------------------------------

# Check with Sarah - maybe we should post this, or maybe she wants to be responsible for this?
source(here::here("code", "taxonomics.R"))

## Calculate Production Tables -------------------------------------------------

# @Zack, reformat: 
# How do we want to deal with stratum/stratum_groupings/area tables/survey_design?
# should we remove crab data? Question for Alix? 
if (FALSE) {
  source("https://github.com/afsc-gap-products/gapindex/blob/master/code_testing/production.R")
  source(here::here("code", "production.R")) # some suggested fixes in here
}

## FOSS Tables -----------------------------------------------------------------

source(here::here("code", "foss.R"))

## AKFIN Tables -----------------------------------------------------------------

source(here::here("code", "akfin.R"))

# Upload tables to GAP_PRODUCTS -----------------------------------------------

source(here::here("code","load_oracle.R")) 

# Save README and other documentation ------------------------------------------

dir_out <- paste0(getwd(), "/output/2023-06-26/") # Don't forget to change as needed!
source(here::here("code", "website.R"))
## Type `quarto render` in the terminal 

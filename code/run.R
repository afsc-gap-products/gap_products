#' -----------------------------------------------------------------------------
#' title: Create GAP_PRODUCT data 
#' author: EH Markowitz (emily.markowitz AT noaa.gov)
#' start date: 2022-011-21
#' last modified: 2022-011-21
#' Notes: 
#' -----------------------------------------------------------------------------

# Support scripts --------------------------------------------------------------

source('./code/functions.R')

# sign into google drive -------------------------------------------------------

# library(googledrive)
# googledrive::drive_deauth()
googledrive::drive_auth()
2

# Connect to Oracle ------------------------------------------------------------

if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R") # EHM shortcut
  channel <- channel_products
} else {
  gapindex::get_connected()
}

## Resources -------------------------------------------------------------------

link_repo <- "https://github.com/afsc-gap-products/gap_products/"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"
pretty_date <- format(Sys.Date(), "%B %d, %Y")

# # The surveys we will cover in this data are: 
# surveys <-
#   data.frame(survey_definition_id = c(143, 98, 47, 52, 78),
#              SRVY = c("NBS", "EBS", "GOA", "AI", "BSS"),
#              SRVY_long = c("northern Bering Sea",
#                            "eastern Bering Sea",
#                            "Gulf of Alaska",
#                            "Aleutian Islands",
#                            "Bering Sea Slope") )

# Create tables ----------------------------------------------------------------

## Metadata --------------------------------------------------------------------

source(here::here("code","metadata.R")) 
# source(here::here("code","metadata_current.R")) 

for (i in 1:nrow(NEW_metadata_table)){
  assign(x = paste0("metadata_sentence_", NEW_metadata_table$metadata_sentence_name[i]), 
         value = NEW_metadata_table$metadata_sentence[i])
}

metadata_sentence_github <- gsub(
  x = metadata_sentence_github, 
  pattern = "INSERT_REPO", 
  replacement = link_repo)

metadata_sentence_last_updated <- gsub(
  x = metadata_sentence_last_updated, 
  pattern = "INSERT_DATE", 
  replacement = pretty_date)

## Taxonomic Tables -----------------------------------------------------------

# Check with Sarah - maybe we should post this, or maybe she wants to be responsible for this?
source(here::here("code", "taxonomics.R"))

## Calculate Production Tables -------------------------------------------------

# @Zack, reformat: 
if (FALSE) {
 source("https://github.com/afsc-gap-products/gapindex/blob/master/code_testing/production.R")
  
  # For table metadata
  
  temp <- paste0(metadata_sentence_survey_institution, " ",
                 metadata_sentence_legal_restrict, " ",
                 metadata_sentence_github, " ",
                 metadata_sentence_codebook, " ",
                 metadata_sentence_last_updated)
  
  NEW_CPUE_comment <- paste0("Zero-filled haul-level catch per unit effort (units in kg/km2).", 
                                    temp)
    BIOMASS_comment <- paste0("Stratum/subarea/management area/region-level mean/variance CPUE (weight and numbers), total biomass (with variance), total abundance (with variance). The 'AREA_ID' field replaces the 'STRATUM' field name to generalize the description to include different types of areas (strata, subareas, regulatory areas, regions, etc.). Use the GAP_PRODUCTS.AREA table to look up the values of AREA_ID for your particular region. Note confidence intervals are currently not supported in the GAP_PRODUCTS version of the biomass/abundance tables. The associated variance of estimates will suffice as the metric of variability to use.", 
                                     temp)
    AGECOMP_comment <- paste0("Stratum/subarea/management area/region-level abundance by sex/length bin. Sex-specific columns (i.e., MALES, FEMALES, UNSEXED), previously formatted in historical versions of this table, are melted into a single column (called 'SEX') similar to the AGECOMP tables with values 1/2/3 for M/F/U. The 'AREA_ID' field replaces the 'STRATUM' field name to generalize the description to include different types of areas (strata, subareas, regulatory areas, regions, etc.). Use the GAP_PRODUCTS.AREA table to look up the values of AREA_ID for your particular region. ", 
                                     temp)
    SIZECOMP_comment <- paste0("Region-level abundance by sex/age. ", 
                                      temp)
  
}

# Upload tables to GAP_PRODUCTS -----------------------------------------------

source(here::here("code","load_oracle.R")) 

# CITATION file ----------------------------------------------------------------

# Create Citation File ----------------------------------------------

source(here::here("code", "CITATION.R"))

# Save README and other documentation ------------------------------------------

source('./code/functions.R')
dir_out <- paste0(getwd(), "/output/2023-06-22/") # Don't forget to change as need!

# locations <- c(
#   "GAP_PRODUCTS.CPUE",
#   "GAP_PRODUCTS.BIOMASS",
#   "GAP_PRODUCTS.AGECOMP",
#   "GAP_PRODUCTS.SIZECOMP",
#   "GAP_PRODUCTS.STRATUM_GROUPS",
#   "GAP_PRODUCTS.AREA",
#   "GAP_PRODUCTS.SURVEY_DESIGN",
#   "GAP_PRODUCTS.TAXONOMICS_WORMS", 
#   "GAP_PRODUCTS.TAXONOMICS_ITIS", 
#   "GAP_PRODUCTS.TAXON_CONFIDENCE", 
#   "GAP_PRODUCTS.METADATA_COLUMN" 
# )
# 
# for (i in 1:length(locations)) {
#   print(locations[i])
#   a <- RODBC::sqlQuery(channel, paste0("SELECT * FROM ", locations[i]))
#   write.csv(x = a, file = here::here("data", paste0(locations[i], ".csv")))
# }

comb <- list.files(path = "docs/", pattern = ".Rmd", ignore.case = TRUE)
comb <- comb[comb != "footer.Rmd"]
comb <- gsub(pattern = ".Rmd", replacement = "", x = comb, ignore.case = TRUE)

for (i in 1:length(comb)) {
  tocTF <- FALSE
  file_in <- here::here("docs", paste0(comb[i],".Rmd"))
  file_out <- here::here("docs", 
                         ifelse(comb[i] == "README", "index.html", paste0(comb[i], ".html")))
  file_out_main <- here::here(ifelse(comb[i] == "README", "index.html", paste0(comb[i], ".html")))
  
  rmarkdown::render(input = file_in,
                    output_dir = "./", 
                    output_format = 'html_document', 
                    output_file = file_out)
  file.copy(from = file_out_main, 
            to = file_out, 
            overwrite = TRUE)
  file.remove(file_out_main)
}

tocTF <- TRUE
rmarkdown::render(input = here::here("docs", "README.Rmd"),
                  output_dir = "./", 
                  output_format = 'md_document', 
                  output_file = "./README.md")

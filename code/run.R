#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz (emily.markowitz AT noaa.gov)
#' start date: 2022-011-21
#' last modified: 2022-011-21
#' Notes: 
#' -----------------------------------------------------------------------------

# source("./code/run.R")
# 1

# *** Resource Links -----------------------------------------------------------

link_foss <- "https://www.fisheries.noaa.gov/foss/f?p=215:200:13045102793007:Mail:NO:::"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"
link_repo <- "https://github.com/afsc-gap-products/gap_products"

# Support scripts --------------------------------------------------------------

source('./code/functions.R')
# source('./code/data_dl.R') # run annually -- files from RACEBASE and RACE_DATA you will need to prepare the following files
source("./code/data.R") # Wrangle data

dir_data <- "./data/"
dir_out <- "./output/"

# Run new compiled data sets ---------------------------------------------------

# Find the species ID codes for AFSC species codes in ITIS and WoRMS
taxize0 <- FALSE# incorporate species codes from databases
if (taxize0) { # only if you need to rerun {taxize} stuff - very time intensive!
  # NOTES: EHM 2022-11-21: borrowed from https://github.com/afsc-gap-products/gap_public_data/blob/main/code/find_taxize_species_codes.R
  source('./code/find_taxize_species_codes.R') 
} 
taxize0 <- TRUE

# Calculate the station level num and wgt CPUE and summarized weight and count catches for each species
# zero-filled (presence and absense) CPUE
# NOTES: EHM 2022-11-21: borrowed from https://github.com/afsc-gap-products/gap_public_data/blob/main/code/analysis.R
source('./code/data_cpue_station.R') 

# Calculate the stratum- and total-level Biomass and Abundance estimates
# NOTES: EHM 2022-11-21: does not have any code for these calculations, so it is currently a blank file
source('./code/data_biomass_abundance_stratum_total.R')

# Calculate the stratum- and total-level Length and Age Comp estimates
# NOTES: EHM 2022-11-21: does not have any code for these calculations, so it is currently a blank file
source('./code/data_length_age_comps_stratum_total.R')

# source("./code/load_oracle.R") # Share table to oracle

# Compile old datasets (for future comparison0 ---------------------------------

source("./code/data_dl_compile_old_data.R")
source('./code/compile_old_data.R')

# Check work -------------------------------------------------------------------

# source('./code/data_dl_check.R')

dir.create(path = paste0(dir_out, "/check/"))
rmarkdown::render(paste0("./code/check.Rmd"),
                  output_dir = dir_out,
                  output_file = paste0("./check/check.docx"))

# Save README ------------------------------------------------------------------

rmarkdown::render(paste0("./README.Rmd"),
                  output_dir = "./",
                  output_file = paste0("README.md"))


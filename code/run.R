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


# The surveys we will cover in this data are: 
surveys <- 
  data.frame(survey_definition_id = c(143, 98, 47, 52, 78), 
             SRVY = c("NBS", "EBS", "GOA", "AI", "BSS"), 
             SRVY_long = c("northern Bering Sea", 
                           "eastern Bering Sea", 
                           "Gulf of Alaska", 
                           "Aleutian Islands", 
                           "Bering Sea Slope") )

dir_data <- "./data/"
dir_out <- "./output/"


# Support scripts --------------------------------------------------------------

source('./code/functions.R')
source("https://raw.githubusercontent.com/afsc-gap-products/metadata/main/code/functions_oracle.R")

# Notes: There are oracle files that are sourced from RACE_DATA - we should only be sourcing from RACEBASE
# source('./code/data_dl.R') # run annually -- files from RACEBASE and RACE_DATA you will need to prepare the following files

source("./code/data.R") # Wrangle data

# Run new compiled data sets ---------------------------------------------------

# Calculate the station level num and wgt CPUE and summarized weight and count catches for each species
# zero-filled (presence and absense) CPUE
# NOTES: EHM 2022-11-21: borrowed from https://github.com/afsc-gap-products/gap_public_data/blob/main/code/analysis.R
source('./code/data_cpue_station.R') 

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


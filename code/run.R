#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz (emily.markowitz AT noaa.gov)
#' start date: 2022-01-01
#' last modified: 2022-04-01
#' Notes: 
#' -----------------------------------------------------------------------------

# source("./code/run.R")
# 1

# Source help files ------------------------------------------------------------

# Download data
dir_data <- "./data/"
dir_out <- "./output/"
dir_fig <- paste0(dir_out, Sys.Date(), "/")
dir.create(dir_fig)

# source("./code/data_dl.R") # run annually

# Wrangle data
source("./code/data.R")

# *** REPORT KNOWNS ------------------------------------------------------------

link_foss <- "https://www.fisheries.noaa.gov/foss/f?p=215:200:13045102793007:Mail:NO:::"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"
link_repo <- "https://github.com/afsc-gap-products/gap_public_data"

# The surveys we will consider covering in this data are: 
surveys <- 
  data.frame(survey_definition_id = c(143, 98, 47, 52, 78), 
             SRVY = c("NBS", "EBS", "GOA", "AI", "BSS"), 
             SRVY_long = c("northern Bering Sea", 
                           "eastern Bering Sea", 
                           "Gulf of Alaska", 
                           "Aleutian Islands", 
                           "Bering Sea Slope") )

taxize0 <- FALSE# incorporate species codes from databases

# Support scripts --------------------------------------------------------------

# source('./code/data_dl.R')
source('./code/functions.R')
if (taxize0) { # only if you need to rerun {taxize} stuff - very time intensive!
  source('./code/find_taxize_species_codes.R')
}
taxize0 <- TRUE
source('./code/data.R')

# Run analysis -----------------------------------------------------------------

source('./code/analysis.R')

# Check work -------------------------------------------------------------------

# source('./code/data_dl_check.R')

dir.create(path = paste0(dir_out, "/check/"))
rmarkdown::render(paste0("./code/check.Rmd"),
                  output_dir = dir_out,
                  output_file = paste0("./check/check.docx"))

# Share table to oracle --------------------------------------------------------

dir_out <- "./output/2022-10-18/"


# cpue_station <- readr::read_csv(file = paste0("./output/2022-06-10/cpue_station.csv"))
source("./code/load_oracle.R")

rmarkdown::render(paste0("./README.Rmd"),
                  output_dir = "./",
                  output_file = paste0("README.md"))


#' -----------------------------------------------------------------------------
#' title: Create GAP_PRODUCT data 
#' author: EH Markowitz (emily.markowitz AT noaa.gov)
#' start date: 2022-011-21
#' last modified: 2022-011-21
#' Notes: 
#' -----------------------------------------------------------------------------

# source("./code/run.R")
# 1

# sign into google drive -------------------------------------------------------

# googledrive::drive_deauth()
googledrive::drive_auth()
2

## Resources -------------------------------------------------------------------

link_repo <- "https://github.com/afsc-gap-products/gap_products/"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"

# The surveys we will cover in this data are: 
surveys <- 
  data.frame(survey_definition_id = c(143, 98, 47, 52, 78), 
             SRVY = c("NBS", "EBS", "GOA", "AI", "BSS"), 
             SRVY_long = c("northern Bering Sea", 
                           "eastern Bering Sea", 
                           "Gulf of Alaska", 
                           "Aleutian Islands", 
                           "Bering Sea Slope") )

dir_data <- paste0(here::here("data"), "/")
dir_out <- paste0(here::here("output"), "/")

# Support scripts --------------------------------------------------------------

source('./code/functions_oracle.R') # source("https://raw.githubusercontent.com/afsc-gap-products/metadata/main/code/functions_oracle.R")
source('./code/functions.R')
# source("./code/data.R") # Wrangle data
# source('./code/data_dl.R') # run annually -- files from RACEBASE and RACE_DATA you will need to prepare the following files

# Create tables ----------------------------------------------------------------

## Calculate Production Tables -------------------------------------------------

# [Zack you'll add these? https://github.com/afsc-gap-products/gapindex/tree/development/old_scripts]
# [check scripts]


## Metadata --------------------------------------------------------------------

dir_out <- paste0(getwd(), "/metadata/", Sys.Date(), "/")
dir.create(dir_out)

source("./code/metadata.R") 
# source("./code/metadata_current.R") 

## AKFIN Tables ----------------------------------------------------------------

source('./code/peripherals.R') 

# Upload tables to GAP_PRODUCTS -----------------------------------------------

source("./code/load_oracle.R") 

# Save README ------------------------------------------------------------------

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

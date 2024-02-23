##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Update Metadata Tables in Oracle
## Description:   Pull the most recent version of the future oracle spreadsheet
##                google sheet, save locally, then upload to GAP_PRODUCTS. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Libraries and constants, connect to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(googledrive)
library(gapindex)
library(readxl)
library(janitor)
library(dplyr)
source(file = "code/constants.R")

sql_channel <- gapindex::get_connected()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Download the most recent version of the future_oracle.xlsx 
##   google sheet and save locally in the temp folder. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
googledrive::drive_download(
  file = googledrive::as_id("1wgAJPPWif1CC01iT2S6ZtoYlhOM0RSGFXS9LUggdLLA"), 
  path = "temp/future_oracle.xlsx", 
  overwrite = TRUE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Clean up metadata_table: the table that houses the shared sentence 
##   fragments that will describe each table. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
metadata_table <- readxl::read_xlsx(path = "temp/future_oracle.xlsx", 
                                    sheet = "METADATA_TABLE") 
metadata_table$metadata_sentence <- gsub(x = metadata_table$metadata_sentence,
                                         pattern = "INSERT_CODE_BOOK", 
                                         replacement = link_code_books)
AREA <- readxl::read_xlsx(path = "temp/future_oracle.xlsx", 
                          sheet = "AREA") 
STRATUM_GROUPS <- readxl::read_xlsx(path = "temp/future_oracle.xlsx", 
                                    sheet = "STRATUM_GROUPS") 

shared_metadata_comment <-
  with(metadata_table, 
       paste(
         metadata_sentence[metadata_sentence_name == "survey_institution"], 
         gsub(pattern = "INSERT_REPO", replacement = link_repo, 
              x = metadata_sentence[metadata_sentence_name == "github"]), 
         gsub(pattern = "INSERT_DATE", replacement = pretty_date, 
              x = metadata_sentence[metadata_sentence_name == "last_updated"]), 
         metadata_sentence[metadata_sentence_name == "legal_restrict_none"], 
         metadata_sentence[metadata_sentence_name == "codebook"])
  )

metadata_table_comment <- paste(
  "These columns provide the table metadata for all of the tables and ",
  "views in GAP_PRODUCTS. These tables are created", shared_metadata_comment
)

AREA_comment <- paste(
  "This table contains all of the information related to the various strata,",
  "subareas, INPFC and NMFS management areas, and regions for the Aleutian",
  "Islands, Gulf of Alaska, and Bering Sea shelf and slope bottom trawl surveys.",
  "These tables are created", shared_metadata_comment
)

STRATUM_GROUPS_comment <- paste(
  "This table contains all of strata that are contained within a given",
  "subarea, INPFC or NMFS management area, or region for the Aleutian Islands,",
  "Gulf of Alaska, and Bering Sea shelf and slope bottom trawl surveys.",
  "These tables are created", shared_metadata_comment
)


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Clean up metadata_column: df that houses metadata column info
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
metadata_column <- readxl::read_xlsx( ## import spreadsheet
  path = "temp/future_oracle.xlsx", 
  sheet = "METADATA_COLUMN", 
  skip = 1) %>%
  janitor::clean_names() %>% ## clean field names
  ## select fields that start with "metadata_"
  dplyr::select(dplyr::starts_with("metadata_")) %>%
  ## filter out true NAs, "", "NA", and nulls in field "metadata_colname"
  dplyr::filter(!is.na(metadata_colname)) %>%  
  dplyr::filter(!is.null(metadata_colname)) %>% 
  dplyr::filter(!(metadata_colname %in% c("", "NA"))) %>% 
  dplyr::mutate(
    ## input the links to the codebook
    metadata_colname_desc = gsub(pattern = "INSERT_CODE_BOOK", 
                                 replacement = link_code_books, 
                                 x = metadata_colname_desc), 
    ## remove extra spaces?
    metadata_colname_desc = gsub(pattern = "  ", 
                                 replacement = " ", 
                                 x = metadata_colname_desc, 
                                 fixed = TRUE), 
    ## remove extra periods?
    metadata_colname_desc = gsub(pattern = "..", 
                                 replacement = ".", 
                                 x = metadata_colname_desc, 
                                 fixed = TRUE))

metadata_column_comment <- paste0(
  "These tables provide the column metadata for all of the tables and ",
  "views in GAP_PRODUCTS. These tables are created ",
  shared_metadata_comment)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Upload the two tables to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for (isql_table in c("metadata_table", 
                     "metadata_column",
                     "AREA", "STRATUM_GROUPS")) { ## loop over tables -- start
  
  ## Temporary dataframe that houses comment on each field The 
  ## field names in get(x = isql_table) should match those in 
  ## `metadata_column$metadata_colname`. If they don't, modify the future_oracle
  ## spreadsheet and reimport. 
  temp_metadata_column <- subset(x = metadata_column, 
                                 subset = metadata_colname %in% 
                                   toupper(names(x = get(x = isql_table))))
  
  ## In gapindex::upload_oracle, the `table_metadata` argument requires 
  ## specific field names
  names(x = temp_metadata_column) <- gsub(x = names(x = temp_metadata_column),
                                          pattern = "metadata_",
                                          replacement = "")
  
  ## Temporary comment on the table itself
  temp_metadata_comment <- get(x = paste0(isql_table, "_comment"))
  
  ## Upload table: gapindex function will drop the table if it already exists,
  ## saves the table, then adds the comment on the table and each column.
  gapindex::upload_oracle(x = get(x = isql_table), 
                          table_name = toupper(x = isql_table), 
                          metadata_column = temp_metadata_column, 
                          table_metadata = temp_metadata_comment, 
                          channel = sql_channel, 
                          schema = "GAP_PRODUCTS", 
                          share_with_all_users = TRUE)
  
} ## loop over tables -- end

#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-01-01
#' Notes: 
#' -----------------------------------------------------------------------------

# dir_out <- paste0(here::here("metadata", Sys.Date()), "/")
# dir.create(dir_out)

# Load metadata ----------------------------------------------------------------

# https://docs.google.com/spreadsheets/d/1wgAJPPWif1CC01iT2S6ZtoYlhOM0RSGFXS9LUggdLLA/edit?pli=1#gid=65110769
googledrive::drive_download(
  file = googledrive::as_id("1wgAJPPWif1CC01iT2S6ZtoYlhOM0RSGFXS9LUggdLLA"), 
  path = here::here("data", "future_oracle.xlsx"), 
  overwrite = TRUE)

# Clean metadata ----------------------------------------------------------------

## Table -----------------------------------------------------------------------

NEW_metadata_table <- metadata_table <- readxl::read_xlsx(
  path = here::here("data", "future_oracle.xlsx"), 
  sheet = "METADATA_TABLE") %>%
  janitor::clean_names() %>% 
  dplyr::select(-dplyr::starts_with("x"), -dplyr::starts_with("na")) %>% 
  dplyr::filter(!is.na(metadata_sentence_name)) %>% 
  dplyr::mutate(metadata_sentence = gsub(replacement = link_code_books, pattern = "INSERT_CODE_BOOK", x = metadata_sentence))

temp <- paste0(
  "These tables are created ", 
  metadata_table$metadata_sentence[metadata_table$metadata_sentence_name == "survey_institution"], " ", 
  gsub(pattern = "INSERT_REPO", replacement = link_repo, 
       x = metadata_table$metadata_sentence[metadata_table$metadata_sentence_name == "github"]), " ", 
  gsub(pattern = "INSERT_DATE", replacement = pretty_date, 
       x = metadata_table$metadata_sentence[metadata_table$metadata_sentence_name == "last_updated"]), " ", 
  metadata_table$metadata_sentence[metadata_table$metadata_sentence_name == "legal_restrict_none"], " ", 
  metadata_table$metadata_sentence[metadata_table$metadata_sentence_name == "codebook"], " ")

NEW_metadata_table_comment <- paste0("These column provide the column metadata for all GAP oracle tables. ", temp)

## Column ----------------------------------------------------------------------

NEW_metadata_column <- readxl::read_xlsx(
  path = here::here("data", "future_oracle.xlsx"), 
  sheet = "METADATA_COLUMN", 
  skip = 1) %>%
  janitor::clean_names() %>% 
  dplyr::select(dplyr::starts_with("metadata_")) %>% 
  dplyr::filter(!is.na(metadata_colname)) %>% 
  dplyr::filter(!is.null(metadata_colname)) %>% 
  dplyr::filter(!(metadata_colname %in% c("", "NA"))) %>% 
  dplyr::mutate(
    metadata_colname_desc = gsub(pattern = "INSERT_CODE_BOOK", replacement = link_code_books, x = metadata_colname_desc), 
    metadata_colname_desc = gsub(pattern = "  ", replacement = " ", x = metadata_colname_desc, fixed = TRUE), 
    metadata_colname_desc = gsub(pattern = "..", replacement = ".", x = metadata_colname_desc, fixed = TRUE))

NEW_metadata_column_comment <- paste0("These tables provide the column metadata for all GAP oracle tables. ", temp)

# Make metadata sentences for this repo ----------------------------------------

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

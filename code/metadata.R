#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-01-01
#' Notes: 
#' -----------------------------------------------------------------------------

# Table Metadata canned sentences ----------------------------------------------

# bibfiletext <- readLines(con = "https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/bibliography.bib")
# find_start <- grep(pattern = "FOSSAFSCData", x = bibfiletext, fixed = TRUE)
# find_end <- which(bibfiletext == "}")
# find_end <- find_end[find_end>find_start][1]
# a <- bibfiletext[find_start:find_end]
# 
# link_foss <- a[grep(pattern = "howpublished = {", x = a, fixed = TRUE)]
# link_foss <- gsub(pattern = "howpublished = {", replacement = "", x = link_foss, fixed = TRUE)
# link_foss <- gsub(pattern = "},", replacement = "", x = link_foss, fixed = TRUE)
# INSERT_FOSS <- link_foss <- trimws(link_foss)

INSERT_CODE_BOOK <- link_code_books

pretty_date <- format(
  x = as.Date(strsplit(x = dir_out, 
                       split = "/", 
                       fixed = TRUE)[[1]][length(strsplit(x = dir_out, split = "/", fixed = TRUE)[[1]])]), 
  "%B %d, %Y")

# Load metadata ----------------------------------------------------------------

# https://docs.google.com/spreadsheets/d/1wgAJPPWif1CC01iT2S6ZtoYlhOM0RSGFXS9LUggdLLA/edit?pli=1#gid=65110769
googledrive::drive_download(
  file = googledrive::as_id("1wgAJPPWif1CC01iT2S6ZtoYlhOM0RSGFXS9LUggdLLA"), 
  path = paste0(dir_out, "future_oracle.xlsx"), 
  overwrite = TRUE)

# Clean metadata ----------------------------------------------------------------

## Table -----------------------------------------------------------------------

metadata_table <- readxl::read_xlsx(
  path = paste0(dir_out, "/future_oracle.xlsx"),
  sheet = "METADATA_TABLE") %>%
# metadata_table <- xlsx::read.xlsx(
  # path = paste0(dir_out, "/future_oracle.xlsx"), 
  # sheet = "METADATA_TABLE") %>% 
  janitor::clean_names() %>% 
  dplyr::select(-dplyr::starts_with("x"), -dplyr::starts_with("na")) %>% 
  dplyr::filter(!is.na(metadata_sentence_name)) %>% 
  dplyr::mutate(
    # metadata_sentence = gsub(pattern = "INSERT_FOSS", replacement = INSERT_FOSS, x = metadata_sentence), 
    metadata_sentence = gsub(pattern = "INSERT_CODE_BOOK", replacement = INSERT_CODE_BOOK, x = metadata_sentence))


temp <- metadata_table$metadata_sentence[metadata_table$metadata_sentence_name == "github"]
temp <- paste0(gsub(pattern = "INSERT_REPO", replacement = link_repo, x = temp), 
               " These reference tables were last updated on ", pretty_date, "'. ")

readr::write_csv(x = metadata_table, 
                 file = paste0(dir_out, "metadata_table.csv"))

readr::write_lines(x = paste0("These column provide the column metadata for all GAP oracle tables. ", temp), 
                   file = paste0(dir_out, "metadata_table_metadata_table.txt"))


## Column ----------------------------------------------------------------------

metadata_column <- readxl::read_xlsx(
  path = paste0(dir_out, "/future_oracle.xlsx"),
  sheet = "METADATA_COLUMN", 
  skip = 1) %>%
# metadata_column <- xlsx::read.xlsx(
#   file = paste0(dir_out, "future_oracle.xlsx"), 
#   sheetName = "METADATA_COLUMN", 
#   startRow = 2) %>% 
  janitor::clean_names() %>% 
  dplyr::select(dplyr::starts_with("metadata_")) %>% 
  dplyr::filter(!is.na(metadata_colname)) %>% 
  dplyr::filter(!is.null(metadata_colname)) %>% 
  dplyr::filter(!(metadata_colname %in% c("", "NA"))) %>% 
  dplyr::mutate(
    metadata_colname_desc = gsub(pattern = "INSERT_CODE_BOOK", replacement = INSERT_CODE_BOOK, x = metadata_colname_desc), 
    # metadata_colname_desc = gsub(pattern = "link_code_books", replacement = link_code_books, x = metadata_colname_desc), 
    metadata_colname_desc = gsub(pattern = "  ", replacement = " ", x = metadata_colname_desc, fixed = TRUE), 
    metadata_colname_desc = gsub(pattern = "..", replacement = ".", x = metadata_colname_desc, fixed = TRUE))

readr::write_csv(x = metadata_column, 
                 file = paste0(dir_out, "metadata_column.csv"))

readr::write_lines(x = paste0("These tables provide the column metadata for all GAP oracle tables. ", temp), 
                   file = paste0(dir_out, "metadata_column_metadata_column.txt"))



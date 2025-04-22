# Load libaries and funcitons --------------------------------------------------

PKG <- c(
  # Keeping Organized
  "devtools", # Package development tools for R; used here for downloading packages from GitHub
  "gapindex", # devtools::install_github("afsc-gap-products/gapindex")
  "akgfmaps", # devtools::install_github("afsc-gap-products/akgfmaps")
  "dplyr",
  "googledrive",
  "magrittr",
  "readr",
  "tidyr",
  "readxl",
  "janitor",
  "kableExtra",
  "flextable",
  "here",
  "stringr",
  "scales", 
  "badger",
  "ftExtra", 
  "RODBC",
  "DBI",
  "odbc",
  "akfingapdata" # devtools::install_github("MattCallahan-NOAA/akfingapdata")
)

#' Package install
#' 
#' @param p name of package
#' On google workstations you can use the library install bash script Elizabeth created. 
#' Copy that into you working
#' directory, run 'chmod u+x ubuntu_libraries.sh' and then run './ubuntu_libraries.sh'
#' @example 
#' pkgs <- c("dplyr, "nwfscSurvey", "sdmTMB)
#' base::lapply(pkgs, pkg_install)
#' 
pkg_install <- function(p){
  if(grepl("/home/user/", getwd())){
    system("chmod a+x ubuntu_libraries.sh")
    system("./ubuntu_libraries.sh")
  }
  if(!require(p, character.only = TRUE)) {
    if (p == 'coldpool') {
      devtools::install_github("afsc-gap-products/coldpool")
    } else if (p == "akgfmapas") {
      devtools::install_github("afsc-gap-products/akgfmaps", build_vignettes = TRUE)
    } else if (p == 'nwfscSurvey') {
      remotes::install_github("pfmc-assessments/nwfscSurvey")
    } else if (p == "gapctd") {
      devtools::install_github("afsc-gap-products/gapctd")
    } else if (p == 'gapindex') {
      remotes::install_github("afsc-gap-products/gapindex")
    } else if (p == 'akfingapdata') {
      # remotes::install_github("afsc-gap-products/akfingapdata")
      devtools::install_github("MattCallahan-NOAA/akfingapdata")
    } else {
      install.packages(p)
    }
    require(p, character.only = TRUE)}
}

base::lapply(unique(PKG), pkg_install)

# knowns -----------------------------------------------------------------------

if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
  channel <- channel_products
} else {
  channel <- gapindex::get_connected()
}

link_foss <- "https://www.fisheries.noaa.gov/foss"
link_repo <- "https://github.com/afsc-gap-products/gap_products" # paste0(shell("git config --get remote.origin.url"))
link_repo_web <- "https://afsc-gap-products.github.io/gap_products/"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"
pretty_date <- format(Sys.Date(), "%B %d, %Y")
crs_out <- crs.out <- "EPSG:3338"

# Download citations -----------------------------------------------------------

# library(RCurl)
write.table(x = readLines(con = "https://raw.githubusercontent.com/citation-style-language/styles/master/apa-no-ampersand.csl"),
            file = here::here("content/references.csl"),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

write.table(x = readLines(con = "https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/bibliography.bib"),
            file = here::here("content/references.bib"),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

# Write README -----------------------------------------------------------------

# rmarkdown::render(paste0(here::here("content","README.Rmd")),
#                   output_dir = here::here(),
#                   output_file = paste0("README.md"))

# Dynamically identify citations of interest ----------------------------------

find_citation_for <- function(bib_ref = "GAPProducts") {
  bib0 <- readLines(con = here::here("content/references.bib"))
  citation_start_all <- which(grepl(pattern = "@", x = bib0))
  citation_start <- which(grepl(pattern = bib_ref, x = bib0))
  citation_end <- (citation_start_all[citation_start_all>citation_start][1])-1
  citation_end <- ifelse(is.na(citation_end), length(bib0), citation_end)
  citation <- bib0[citation_start:citation_end]
  citation <- citation[citation != ""]
  return(citation)
}

# Functions --------------------------------------------------------------------

# print_table_metadata <- function(channel, locations) {
#   # Query all table comments for each table in `locations`
#   table_info <- RODBC::sqlQuery(
#     channel = channel,
#     query = paste0(
#       "WITH Q_TABLE AS (SELECT MVIEW_NAME AS TABLE_NAME, COMMENTS
#        FROM USER_MVIEW_COMMENTS    
#        UNION
#        SELECT TABLE_NAME, COMMENTS
#        FROM ALL_TAB_COMMENTS 
#        WHERE OWNER = 'GAP_PRODUCTS' AND TABLE_TYPE = 'TABLE')
#        
#        SELECT * FROM Q_TABLE
#        JOIN (SELECT TABLE_NAME, NUM_ROWS 
#              FROM ALL_TABLES WHERE OWNER = 'GAP_PRODUCTS') USING (TABLE_NAME)
#        JOIN (SELECT TABLE_NAME, COUNT(*) AS NUM_COLS
#              FROM ALL_TAB_COLUMNS 
#              WHERE OWNER = 'GAP_PRODUCTS'
#              GROUP BY TABLE_NAME) USING (TABLE_NAME)
#        WHERE TABLE_NAME IN ", gapindex::stitch_entries(locations)))
#   
#   ## Query all fields contained within each table in `locations`
#   field_info <- 
#     RODBC::sqlQuery(
#       channel = channel, 
#       query = 
#         paste0(
#           "SELECT TABLE_NAME, 
#       COLUMN_NAME AS \"Column name from data\", 
#       GP_META.METADATA_colname_long AS \"Descriptive column Name\" ,
#       GP_META.METADATA_units AS \"Units\",
#       GP_META.METADATA_datatype AS \"Oracle data type\",
#       GP_META.METADATA_colname_desc AS \"Column description\"
#       FROM ALL_TAB_COLS 
#       JOIN (GAP_PRODUCTS.METADATA_COLUMN) GP_META 
#           ON GP_META.METADATA_COLNAME = ALL_TAB_COLS.COLUMN_NAME 
#       WHERE OWNER = 'GAP_PRODUCTS' AND TABLE_NAME IN ",
#           gapindex::stitch_entries(table_info$TABLE_NAME)
#         )
#     )
#   
#   # Collect all column metadata for all table locations
#   str00 <- paste0("## Data tables", "\n\n")
#   
#   for (i in 1:length(x = locations)) {
#     str00 <-
#       paste0(
#         str00,
#         "### ", table_info$TABLE_NAME[i], "\n\n",
#         table_info$COMMENTS[i], "\n\n",
#         "Number of rows: ", formatC(x = table_info$NUM_ROWS[i], 
#                                     digits = 0, 
#                                     format = "f", 
#                                     big.mark = ","),
#         "\n\nNumber of columns: ", formatC(x = table_info$NUM_COLS[i], 
#                                            digits = 0, 
#                                            format = "f", 
#                                            big.mark = ","),
#         "\n\n",
#         kableExtra::kable(
#           subset(x = field_info,
#                  subset = TABLE_NAME == table_info$TABLE_NAME[i],
#                  select = -TABLE_NAME), 
#           row.names = FALSE, format = "html"
#         ) %>%
#           kableExtra::kable_styling(bootstrap_options = "striped"),
#         "\n\n\n"
#       )
#   }
#   return(str00)
# }

print_table_metadata <- function(channel, locations, owner = "GAP_PRODUCTS") {
  # Query all table comments for each table in `locations`
  b <- RODBC::sqlQuery(
    channel = channel,
    query = paste0(
      "WITH Q_TABLE AS (SELECT MVIEW_NAME AS TABLE_NAME, COMMENTS
       FROM USER_MVIEW_COMMENTS    
       UNION
       SELECT TABLE_NAME, COMMENTS
       FROM ALL_TAB_COMMENTS 
       WHERE OWNER = '",owner,"' AND TABLE_TYPE = 'TABLE')
       
       SELECT * FROM Q_TABLE
       JOIN (SELECT TABLE_NAME, NUM_ROWS 
             FROM ALL_TABLES WHERE OWNER = '",owner,"') USING (TABLE_NAME)
       JOIN (SELECT TABLE_NAME, COUNT(*) AS NUM_COLS
             FROM ALL_TAB_COLUMNS 
             WHERE OWNER = '",owner,"'
             GROUP BY TABLE_NAME) USING (TABLE_NAME)
       WHERE TABLE_NAME IN ", gapindex::stitch_entries(locations)))
  
  ## Query all fields contained within each table in `locations`
  b_columns <-
    RODBC::sqlQuery(
      channel = channel,
      query =
        paste0(
          "SELECT TABLE_NAME,
      COLUMN_NAME AS \"Column name from data\",
      GP_META.METADATA_colname_long AS \"Descriptive column Name\" ,
      GP_META.METADATA_units AS \"Units\",
      GP_META.METADATA_datatype AS \"Oracle data type\",
      GP_META.METADATA_colname_desc AS \"Column description\"
      FROM ALL_TAB_COLS
      JOIN (GAP_PRODUCTS.METADATA_COLUMN) GP_META
          ON GP_META.METADATA_COLNAME = ALL_TAB_COLS.COLUMN_NAME
      WHERE OWNER = '",owner,"' AND TABLE_NAME IN ",
          gapindex::stitch_entries(b$TABLE_NAME)
        )
    )
  
  # Collect all column metadata for all table locations
  str00 <- paste0("## Data tables", "\n\n")
  
  for (i in 1:length(locations)) {
    
    str000 <- paste0(
      "### ", b$TABLE_NAME[i], "\n\n",
      b$COMMENTS[i], "\n\n",
      "Number of rows: ", formatC(x = b$NUM_ROWS[i],
                                  digits = 0,
                                  format = "f",
                                  big.mark = ","),
      "\n\nNumber of columns: ", formatC(x = b$NUM_COLS[i], 
                                         digits = 0, 
                                         format = "f", 
                                         big.mark = ","),
      "\n\n",
      kableExtra::kable(subset(x = b_columns,
                               subset = TABLE_NAME == b$TABLE_NAME[i],
                               select = -TABLE_NAME),
                        row.names = FALSE, format = "html") %>%
        kableExtra::kable_styling(bootstrap_options = "striped"),
      "\n\n\n"
    )
    
    str00 <- paste0(str00, str000)
    
  }
  return(str00)
}



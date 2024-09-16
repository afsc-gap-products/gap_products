# Load libaries and funcitons --------------------------------------------------

PKG <- c(
  # Keeping Organized
  "devtools", # Package development tools for R; used here for downloading packages from GitHub
  "distill",
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
  "akfingapdata" # devtools::install_github("MattCallahan-NOAA/akfingapdata")
)

PKG <- unique(PKG)
for (p in PKG) {
  # library(p, character.only = TRUE)
  if (!require(p, character.only = TRUE)) {
    install.packages(p)
    require(p, character.only = TRUE)
  }
}

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
crs.out <- "EPSG:3338"
# Functions --------------------------------------------------------------------

print_table_metadata <- function(channel, locations) {
  # Query all table comments for each table in `locations`
  table_info <- RODBC::sqlQuery(
    channel = channel,
    query = paste0(
      "WITH Q_TABLE AS (SELECT MVIEW_NAME AS TABLE_NAME, COMMENTS
       FROM USER_MVIEW_COMMENTS    
       UNION
       SELECT TABLE_NAME, COMMENTS
       FROM ALL_TAB_COMMENTS 
       WHERE OWNER = 'GAP_PRODUCTS' AND TABLE_TYPE = 'TABLE')
       
       SELECT * FROM Q_TABLE
       JOIN (SELECT TABLE_NAME, NUM_ROWS 
             FROM ALL_TABLES WHERE OWNER = 'GAP_PRODUCTS') USING (TABLE_NAME)
       JOIN (SELECT TABLE_NAME, COUNT(*) AS NUM_COLS
             FROM ALL_TAB_COLUMNS 
             WHERE OWNER = 'GAP_PRODUCTS'
             GROUP BY TABLE_NAME) USING (TABLE_NAME)
       WHERE TABLE_NAME IN ", gapindex::stitch_entries(locations)))
  
  ## Query all fields contained within each table in `locations`
  field_info <- 
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
      WHERE OWNER = 'GAP_PRODUCTS' AND TABLE_NAME IN ",
          gapindex::stitch_entries(table_info$TABLE_NAME)
        )
    )
  
  # Collect all column metadata for all table locations
  str00 <- paste0("## Data tables", "\n\n")
  
  for (i in 1:length(x = locations)) {
    str00 <-
      paste0(
        str00,
        "### ", table_info$TABLE_NAME[i], "\n\n",
        table_info$COMMENTS[i], "\n\n",
        "Number of rows: ", formatC(x = table_info$NUM_ROWS[i], 
                                    digits = 0, 
                                    format = "f", 
                                    big.mark = ","),
        "\n\nNumber of columns: ", formatC(x = table_info$NUM_COLS[i], 
                                           digits = 0, 
                                           format = "f", 
                                           big.mark = ","),
        "\n\n",
        kableExtra::kable(
          subset(x = field_info,
                 subset = TABLE_NAME == table_info$TABLE_NAME[i],
                 select = -TABLE_NAME), 
          row.names = FALSE, format = "html"
        ) %>%
          kableExtra::kable_styling(bootstrap_options = "striped"),
        "\n\n\n"
      )
  }
  return(str00)
}

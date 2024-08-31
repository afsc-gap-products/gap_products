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
  gapindex::get_connected()
}

link_foss <- "https://www.fisheries.noaa.gov/foss"
link_repo <- "https://github.com/afsc-gap-products/gap_products" # paste0(shell("git config --get remote.origin.url"))
link_repo_web <- "https://afsc-gap-products.github.io/gap_products/"
link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"
pretty_date <- format(Sys.Date(), "%B %d, %Y")
crs.out <- "EPSG:3338"
# Functions --------------------------------------------------------------------

fix_metadata_table <- function(metadata_table0, name0, dir_out) {
  metadata_table0 <- gsub(pattern = "\n", replacement = " ", x = metadata_table0)
  metadata_table0 <- gsub(pattern = "   ", replacement = " ", x = metadata_table0)
  metadata_table0 <- gsub(pattern = "  ", replacement = " ", x = metadata_table0)
  
  readr::write_lines(
    x = metadata_table0,
    file = paste0(dir_out, name0, "_comment.txt")
  )
  # readr::write_lines(x = metadata_table,
  #                    file = paste0(dir_out, a_name, "_metadata_table.txt", collapse="\n"))
  
  return(metadata_table0)
}



update_metadata <- function(
    schema,
    table_name,
    channel,
    metadata_column,
    table_metadata,
    update_metadata = TRUE,
    share_with_all_users = TRUE) {
  cat("Updating Metadata ...\n")
  
  ## Add column metadata
  if (nrow(x = metadata_column) > 0) {
    for (i in 1:nrow(x = metadata_column)) {
      desc <- gsub(
        pattern = "<sup>2</sup>",
        replacement = "2",
        x = metadata_column$colname_long[i],
        fixed = TRUE
      )
      short_colname <- gsub(
        pattern = "<sup>2</sup>",
        replacement = "2",
        x = metadata_column$colname[i],
        fixed = TRUE
      )
      
      RODBC::sqlQuery(
        channel = channel,
        query = paste0(
          "COMMENT ON COLUMN ",
          schema, ".", table_name, ".",
          short_colname, " is '",
          desc, ". ", # remove markdown/html code
          gsub(
            pattern = "'", replacement = '\"',
            x = metadata_column$colname_desc[i]
          ), "';"
        )
      )
    }
  }
  ## Add table metadata
  RODBC::sqlQuery(
    channel = channel,
    query = paste0(
      "COMMENT ON TABLE ", schema, ".", table_name,
      " is '",
      table_metadata, "';"
    )
  )
  
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##   Grant select access to all users
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (share_with_all_users) {
    cat("Granting select access to all users ... ")
    all_schemas <- RODBC::sqlQuery(
      channel = channel,
      query = paste0("SELECT * FROM all_users;")
    )
    
    for (iname in sort(all_schemas$USERNAME)) {
      RODBC::sqlQuery(
        channel = channel,
        query = paste0(
          "grant select on ", schema, ".", table_name,
          " to ", iname, ";"
        )
      )
    }
  }
}


print_table_metadata <- function(channel, locations) {
  # Find all descriptions of all tables in the GAP_PRODUCTS schema
  b <- dplyr::bind_rows(
    # tables
    RODBC::sqlQuery(
      channel = channel,
      query = "SELECT table_name, comments
FROM all_tab_comments
WHERE owner = 'GAP_PRODUCTS'
ORDER BY table_name") %>% 
      data.frame(), 
    # materialized view
    RODBC::sqlQuery(
      channel = channel,
      query = "SELECT *FROM user_mview_comments") %>% 
      data.frame() %>% 
      dplyr::rename(TABLE_NAME = MVIEW_NAME)
  )
  
  # Collect all column metadata for all table locations
  str00 <- c()
  for (i in 1:length(locations)) {
    metadata_table <- ""
    if (sum(b$TABLE_NAME == locations[i])>0) {
      metadata_table <- b$COMMENTS[b$TABLE_NAME == locations[i]]
    }
    # strsplit(x = locations[i], split = ".", fixed = TRUE)[[1]]]
    
    if (grepl(pattern = "This table was created by", x = metadata_table)) {
      metadata_table <- str_extract(metadata_table, "^.+(?= This table was created by)")
    }
    # Putting universal metadata language at top of page
    if (i == 1) {
      if (!is.na(metadata_table) && length(metadata_table) != 0) {
        data_usage <- str_extract(metadata_table, "This table was created by .+$")
        if(!is.na(data_usage)){
          str00 <- paste0(
            "## Data usage \n\n", data_usage,
            "\n\n", "## Data tables", "\n\n") %>%
            str_replace("This table was", "These tables were") %>%
            str_replace("survey code books \\(https", "[survey code books]\\(https")
        }
      }
      
      if(is.na(metadata_table) || is.na(data_usage)) {
        str00 <- paste0("## Data tables", "\n\n")
      }
    }
    
    metadata_table <- ifelse(is.na(metadata_table) | length(metadata_table) == 0,
                             "[There is currently no description for this table.]",
                             metadata_table
    )
    
    # temp <- file.size(here::here("data", paste0(locations[i], ".csv")))
    temp_rows <- RODBC::sqlQuery(
      channel = channel,
      query = paste0("SELECT COUNT(*) FROM GAP_PRODUCTS.", locations[i], ";")
    )
    
    # temp_data <- RODBC::sqlQuery(channel = channel,
    #                              query = paste0("SELECT *
    # FROM ", locations[i], "
    # FETCH FIRST 3 ROWS ONLY;"))
    #
    # temp_cols <- temp_data %>%
    #   ncol()
    
    temp_colnames <- RODBC::sqlQuery(
      channel = channel,
      query = paste0("SELECT owner, column_name
FROM all_tab_columns
WHERE table_name = '", locations[i], "'
AND owner = 'GAP_PRODUCTS';")
    )
    
    temp_cols <- nrow(temp_colnames)
    
    # get metadata
    temp_data <- RODBC::sqlQuery(
      channel = channel,
      query = "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN"
    ) %>%
      dplyr::right_join(temp_colnames, by = c("METADATA_COLNAME" = "COLUMN_NAME")) %>%
      janitor::clean_names() %>%
      dplyr::arrange(metadata_colname) %>%
      dplyr::select(
        "Column name from data" = metadata_colname,
        "Descriptive column Name" = metadata_colname_long,
        "Units" = metadata_units,
        "Oracle data type" = metadata_datatype,
        "Column description" = metadata_colname_desc
      )
    
    str00 <- paste0(
      str00,
      "### ", locations[i], "\n\n",
      metadata_table, "\n\n",
      "Number of rows: ", formatC(x = unlist(temp_rows), digits = 0, format = "f", big.mark = ","),
      "\n\nNumber of columns: ", formatC(x = unlist(temp_cols), digits = 0, format = "f", big.mark = ","),
      # " | ",
      # formatC(x = temp/ifelse(temp>1e+7, 1e+9, 1),
      #         digits = 1, format = "f", big.mark = ","),
      # " ", ifelse(temp>1e+7, "GB", "B"),
      "\n\n",
      kableExtra::kable(temp_data, row.names = FALSE, format = "html") %>%
        kableExtra::kable_styling(bootstrap_options = "striped"),
      "\n\n\n"
    )
    # cat(str0)
    # # what are the metadata for each column of this table
    # flextable::flextable(metadata_column[metadata_column$METADATA_COLNAME %in% names(a),])
    # # print few first lines of this table for show
    # flextable::flextable(head(a, 3))
  }
  return(str00)
}


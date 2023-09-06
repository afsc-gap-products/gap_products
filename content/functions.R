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
  "badger")

PKG <- unique(PKG)
for (p in PKG) {
  if(!require(p,character.only = TRUE)) {
    install.packages(p)
    require(p,character.only = TRUE)}
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

# Functions --------------------------------------------------------------------

fix_metadata_table <- function(metadata_table0, name0, dir_out) {
  metadata_table0 <- gsub(pattern = "\n", replacement = " ", x = metadata_table0)
  metadata_table0 <- gsub(pattern = "   ", replacement = " ", x = metadata_table0)
  metadata_table0 <- gsub(pattern = "  ", replacement = " ", x = metadata_table0)
  
  readr::write_lines(x = metadata_table0,
                     file = paste0(dir_out, name0, "_comment.txt"))
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
      
      desc <- gsub(pattern = "<sup>2</sup>",
                   replacement = "2",
                   x = metadata_column$colname_long[i], 
                   fixed = TRUE)
      short_colname <- gsub(pattern = "<sup>2</sup>", 
                            replacement = "2",
                            x = metadata_column$colname[i], 
                            fixed = TRUE)
      
      RODBC::sqlQuery(
        channel = channel,
        query = paste0('COMMENT ON COLUMN ', 
                       schema, '.', table_name,'.',
                       short_colname,' is \'',
                       desc, ". ", # remove markdown/html code
                       gsub(pattern = "'", replacement ='\"',
                            x = metadata_column$colname_desc[i]),'\';'))
      
    }
  }
  ## Add table metadata 
  RODBC::sqlQuery(
    channel = channel,
    query = paste0('COMMENT ON TABLE ', schema,'.', table_name,
                   ' is \'',
                   table_metadata,'\';'))
  
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ##   Grant select access to all users
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (share_with_all_users) {
    
    cat("Granting select access to all users ... ")
    all_schemas <- RODBC::sqlQuery(channel = channel,
                                   query = paste0('SELECT * FROM all_users;'))
    
    for (iname in sort(all_schemas$USERNAME)) {
      RODBC::sqlQuery(channel = channel,
                      query = paste0('grant select on ', schema,'.', table_name,
                                     ' to ', iname, ';'))
    }
  }
}


print_table_metadata <- function(channel, locations){
  # Find all descriptions of all tables in the GAP_PRODUCTS schema
  b <- RODBC::sqlQuery(channel = channel, 
                       query = "SELECT table_name, comments 
FROM all_tab_comments 
WHERE owner = 'GAP_PRODUCTS' 
ORDER BY table_name")
  
  # Collect all column metadata for all tables
  str00 <- c()
  for (i in 1:length(locations)) {
    metadata_table <- b$COMMENTS[b$TABLE_NAME == locations[i]]
                                   # strsplit(x = locations[i], split = ".", fixed = TRUE)[[1]]]
    metadata_table <- ifelse(is.na(metadata_table) | length(metadata_table) == 0, 
                             "[There is currently no description for this table.]", 
                             metadata_table)
    
    # temp <- file.size(here::here("data", paste0(locations[i], ".csv")))
    temp_rows <- RODBC::sqlQuery(channel = channel, 
                                 query = paste0("SELECT COUNT(*) FROM " , locations[i], ";"))
    
    temp_data <- RODBC::sqlQuery(channel = channel, 
                                 query = paste0("SELECT *
    FROM ", locations[i], "
    FETCH FIRST 3 ROWS ONLY;"))
    
    temp_cols <- temp_data %>% 
      ncol()
    
    str00 <- paste0(str00, 
                    paste0("### ", locations[i], "\n\n", 
                           metadata_table, "\n\n",
                           "Number of rows: ", temp_rows, 
                           "\n\nNumber of columns: ", temp_cols, 
                           # " | ", 
                           # formatC(x = temp/ifelse(temp>1e+7, 1e+9, 1), 
                           #         digits = 1, format = "f", big.mark = ","), 
                           # " ", ifelse(temp>1e+7, "GB", "B"), 
                           "\n\n", 
                           # flextable::flextable(temp_data) %>% theme_zebra(), 
                           knitr::kable(temp_data, row.names = FALSE),
                           "\n\n\n"
                    ))
    # cat(str0)
    # # what are the metadata for each column of this table
    # flextable::flextable(metadata_column[metadata_column$METADATA_COLNAME %in% names(a),])
    # # print few first lines of this table for show
    # flextable::flextable(head(a, 3))
  }
  return(str00)
}


# Adapted from flextable::theme_vanilla()

#' @importFrom officer fp_border fp_par
#' @export
#' @title Apply vanilla theme
#' @description Apply theme vanilla to a flextable:
#' The external horizontal lines of the different parts of
#' the table (body, header, footer) are black 2 points thick,
#' the external horizontal lines of the different parts
#' are black 0.5 point thick. Header text is bold,
#' text columns are left aligned, other columns are
#' right aligned.
#' @param x a flextable object
#' @param pgwidth a numeric. The width in inches the table should be. Default = 6, which is ideal for A4 (8.5x11 in) portrait paper.
#' @param row_lines T/F. If True, draws a line between each row.
#' @param font0 String. Default = "Times New Roman". Instead, you may want "Arial".
#' @param body_size Numeric. default = 11.
#' @param header_size Numeric. default = 11.
#' @param spacing table spacing. default = 0.8.
#' @param pad padding around each element. default = 0.1
#' @family functions related to themes
#' @examples
#' ft <- flextable::flextable(head(airquality))
#' ft <- theme_flextable_nmfstm(ft)
#' ft
#' @section Illustrations:
#'
#' \if{html}{\figure{fig_theme_vanilla_1.png}{options: width=60\%}}
theme_flextable_nmfstm <- function(x,
                                   pgwidth = 6.5,
                                   row_lines = TRUE,
                                   body_size = 10,
                                   header_size = 10,
                                   font0 = "Times New Roman",
                                   spacing = 0.6,
                                   pad = 2) {
  
  if (!inherits(x, "flextable")) {
    stop("theme_flextable_nmfstm supports only flextable objects.")
  }
  
  FitFlextableToPage <- function(x, pgwidth = 6){
    # https://stackoverflow.com/questions/57175351/flextable-autofit-in-a-rmarkdown-to-word-doc-causes-table-to-go-outside-page-mar
    ft_out <- x %>% flextable::autofit()
    
    ft_out <- flextable::width(ft_out, width = dim(ft_out)$widths*pgwidth /(flextable::flextable_dim(ft_out)$widths))
    return(ft_out)
  }
  
  std_b <- officer::fp_border(width = 2, color = "grey10")
  thin_b <- officer::fp_border(width = 0.5, color = "grey10")
  
  x <- flextable::border_remove(x)
  
  if (row_lines == TRUE) {
    x <- flextable::hline(x = x, border = thin_b, part = "body")
  }
  x <- flextable::hline_top(x = x, border = std_b, part = "header")
  x <- flextable::hline_bottom(x = x, border = std_b, part = "header")
  x <- flextable::hline_bottom(x = x, border = std_b, part = "body")
  x <- flextable::bold(x = x, bold = TRUE, part = "header")
  x <- flextable::align_text_col(x = x, align = "left", header = TRUE)
  x <- flextable::align_nottext_col(x = x, align = "right", header = TRUE)
  x <- flextable::padding(x = x, padding = pad, part = "all") # remove all line spacing in a flextable
  x <- flextable::font(x = x, fontname = font0, part = "all")
  x <- flextable::fontsize(x = x, size = body_size-2, part = "footer")
  x <- flextable::fontsize(x = x, size = body_size, part = "body")
  x <- flextable::fontsize(x = x, size = header_size, part = "header")
  # x <- flextable::fit_to_width(x = x,
  #                         max_width = pgwidth,
  #                         unit = "in")
  x <- FitFlextableToPage(x = x, pgwidth = pgwidth)
  # x <- flextable::line_spacing(x = x, space = spacing, part = "all")
  
  x <- flextable::fix_border_issues(x = x)
  
  return(x)
}

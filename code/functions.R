# Load libaries and funcitons --------------------------------------------------

# PKG <- c(
#   # Keeping Organized
#   "devtools", # Package development tools for R; used here for downloading packages from GitHub
#   "distill",
#   "gapindex", # devtools::install_github("afsc-gap-products/gapindex")
#   "akgfmaps", # devtools::install_github("afsc-gap-products/akgfmaps")
#   "dplyr",
#   "googledrive",
#   "magrittr",
#   "readr",
#   "tidyr",
#   "readxl",
#   "janitor",
#   "kableExtra", 
#   "flextable",
#   "here",
#   "stringr",
#   "badger")
# 
# PKG <- unique(PKG)
# for (p in PKG) {
#   if(!require(p,character.only = TRUE)) {
#     install.packages(p)
#     require(p,character.only = TRUE)}
# }

# knowns -----------------------------------------------------------------------

# if (file.exists("Z:/Projects/ConnectToOracle.R")) {
#   source("Z:/Projects/ConnectToOracle.R")
#   channel <- channel_products
# } else {
#   gapindex::get_connected()
# }

# Functions --------------------------------------------------------------------

# fix_metadata_table <- function(metadata_table0, name0, dir_out) {
#   metadata_table0 <- gsub(pattern = "\n", replacement = " ", x = metadata_table0)
#   metadata_table0 <- gsub(pattern = "   ", replacement = " ", x = metadata_table0)
#   metadata_table0 <- gsub(pattern = "  ", replacement = " ", x = metadata_table0)
#   
#   readr::write_lines(x = metadata_table0,
#                      file = paste0(dir_out, name0, "_comment.txt"))
#   # readr::write_lines(x = metadata_table, 
#   #                    file = paste0(dir_out, a_name, "_metadata_table.txt", collapse="\n"))
#   
#   return(metadata_table0)
# }

#' Update Oracle Table Metadata
#' 
#' @description Updates table and column comments for an existing table or view
#'              in Oracle. Truncated version of gapindex::upload_oracle, which
#'              uploads a table and then populates the comment metadata. 
#'      
#' @param schema string. Oracle schema where the table/view is contained. 
#' @param table_name string Oracle table name. Should be in all-caps
#'                   however the function will automatically do that. 
#' @param table_type string. One of three options: "TABLE", "VIEW",
#'                   or "MATERIALIZED VIEW".
#' @param table_metadata string Description of what the table is. 
#' @param metadata_column data.frame describing the metadata for each of the 
#'                        fields in the table. Must contain these columns: 
#'                        1) colname: name of field
#'                        2) colname_long: longer version of name for printing
#'                           purposes.
#'                        3) units: units of field
#'                        4) dataype: Oracle data type
#'                        5) colname_desc: Full description of field
#' @param channel oracle connection object. Establish your oracle connection using a function like `gapindex::get_connected()`. 
#' @param share_with_all_users boolean. Default = TRUE. Gives all users in 
#'                             Oracle view permissions. 
#' 
update_metadata <- function(schema, 
                            table_name, 
                            table_type, 
                            channel, 
                            metadata_column, 
                            table_metadata,
                            share_with_all_users = TRUE) {
  
  cat("Updating Metadata ...\n")
  
  ## Add column metadata 
  if (nrow(x = metadata_column) > 0) {
    
    for (i in 1:nrow(x = metadata_column)) {
      
      desc <- gsub(pattern = "<sup>2</sup>",
                   replacement = "2",
                   x = metadata_column$METADATA_COLNAME_LONG[i], 
                   fixed = TRUE)
      short_colname <- gsub(pattern = "<sup>2</sup>", 
                            replacement = "2",
                            x = metadata_column$METADATA_COLNAME [i], 
                            fixed = TRUE)
      
      RODBC::sqlQuery(
        channel = channel,
        query = paste0('COMMENT ON COLUMN ', 
                       schema, '.', table_name,'.',
                       short_colname,' is \'',
                       desc, ". ", # remove markdown/html code
                       gsub(pattern = "'", replacement ='\"',
                            x = metadata_column$METADATA_COLNAME_DESC[i]),'\';'))
      
    }
  }
  ## Add table metadata 
  RODBC::sqlQuery(
    channel = channel,
    query = paste0('COMMENT ON ', table_type, " ", schema, '.', table_name, 
                   " IS '", table_metadata, "';"))
  
  
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
                                     ' to ', iname))
    }
  }
}

getSQL <- function(filepath){
  con = file(filepath, "r")
  sql.string <- ""
  
  while (TRUE){
    line <- readLines(con, n = 1)
    
    if ( length(line) == 0 ){
      break
    }
    
    line <- gsub("\\t", " ", line)
    
    if(grepl("--",line) == TRUE){
      line <- paste(sub("--","/*",line),"*/")
    }
    
    sql.string <- paste(sql.string, line)
  }
  
  close(con)
  return(sql.string)
}

# print_table_metadata <- function(channel, locations){
#   # Find all descriptions of all tables in the GAP_PRODUCTS schema
#   b <- RODBC::sqlQuery(channel = channel, 
#                        query = "SELECT table_name, comments 
# FROM all_tab_comments 
# WHERE owner = 'GAP_PRODUCTS' 
# ORDER BY table_name")
#   
#   # Collect all column metadata for all tables
#   str00 <- c()
#   for (i in 1:length(locations)) {
#     metadata_table <- b$COMMENTS[b$TABLE_NAME == 
#                                    strsplit(x = locations[i], split = ".", fixed = TRUE)[[1]]]
#     metadata_table <- ifelse(is.na(metadata_table), 
#                              "[There is currently no description for this table.]", 
#                              metadata_table)
#     
#     # temp <- file.size(here::here("data", paste0(locations[i], ".csv")))
#     temp_rows <- RODBC::sqlQuery(channel = channel, 
#                                  query = paste0("SELECT COUNT(*) FROM " , locations[i], ";"))
#     
#     temp_data <- RODBC::sqlQuery(channel = channel, 
#                                  query = paste0("SELECT *
#     FROM ", locations[i], "
#     FETCH FIRST 3 ROWS ONLY;"))
#     
#     temp_cols <- temp_data %>% 
#       ncol()
#     
#     str00 <- paste0(str00, 
#                     paste0("### ", locations[i], "\n\n", 
#                            metadata_table, "\n\n",
#                            "Number of rows: ", temp_rows, 
#                            "\n\nNumber of columns: ", temp_cols, 
#                            # " | ", 
#                            # formatC(x = temp/ifelse(temp>1e+7, 1e+9, 1), 
#                            #         digits = 1, format = "f", big.mark = ","), 
#                            # " ", ifelse(temp>1e+7, "GB", "B"), 
#                            "\n\n", 
#                            # flextable::flextable(temp_data) %>% theme_zebra(), 
#                            knitr::kable(temp_data, row.names = FALSE),
#                            "\n\n\n"
#                     ))
#     # cat(str0)
#     # # what are the metadata for each column of this table
#     # flextable::flextable(metadata_column[metadata_column$METADATA_COLNAME %in% names(a),])
#     # # print few first lines of this table for show
#     # flextable::flextable(head(a, 3))
#   }
#   return(str00)
# }

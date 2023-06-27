# Load libaries and funcitons --------------------------------------------------

PKG <- c(
  # Keeping Organized
  "devtools", # Package development tools for R; used here for downloading packages from GitHub
  "distill",
  "gapindex", # devtools::install_github("afsc-gap-products/gapindex")
  "dplyr",
  "googledrive",
  "magrittr",
  "readr",
  "tidyr",
  "readxl",
  "janitor",
  "kableExtra", 
  "here",
  "stringr")

PKG <- unique(PKG)
for (p in PKG) {
  if(!require(p,character.only = TRUE)) {
    install.packages(p)
    require(p,character.only = TRUE)}
}

# Set output directory ---------------------------------------------------------

dir_out <- paste0(getwd(), "/output/", Sys.Date(),"/")
dir.create(dir_out)
dir_data <- paste0(getwd(), "/data/")

# Save scripts from each run to output -----------------------------------------
# Just for safe keeping

dir.create(paste0(dir_out, "/code/"))
listfiles<-list.files(path = paste0("./code/"))
listfiles0<-c(listfiles[grepl(pattern = "\\.r",
                              x = listfiles, ignore.case = T)],
              listfiles[grepl(pattern = "\\.rmd",
                              x = listfiles, ignore.case = T)])
listfiles0<-listfiles0[!(grepl(pattern = "~",ignore.case = T, x = listfiles0))]

for (i in 1:length(listfiles0)){
  file.copy(from = paste0("./code/", listfiles0[i]),
            to = paste0(dir_out, "/code/", listfiles0[i]),
            overwrite = T)
}


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
    metadata_table <- b$COMMENTS[b$TABLE_NAME == 
                                   strsplit(x = locations[i], split = ".", fixed = TRUE)[[1]][2]]
    metadata_table <- ifelse(is.na(metadata_table), 
                             "[There is currently no description for this table.]", 
                             metadata_table)
    
    temp <- file.size(here::here("data", paste0(locations[i], ".csv")))
    temp_rows <- RODBC::sqlQuery(channel = channel, 
                                 query = paste0("SELECT COUNT(*) FROM " , locations[i], ";"))
    
    temp_data <- RODBC::sqlQuery(channel = channel, 
                                 query = paste0("SELECT *
    FROM GAP_PRODUCTS.", locations[i], "
    FETCH FIRST 3 ROWS ONLY;"))
    
    temp_cols <- temp_data %>% 
      ncol()
    
    str0 <- paste0("### ", locations[i], "\n\n", 
                   metadata_table, "\n\n",
                   "rows: ", temp_rows, " | cols: ", temp_cols, 
                   # " | ", 
                   # formatC(x = temp/ifelse(temp>1e+7, 1e+9, 1), 
                   #         digits = 1, format = "f", big.mark = ","), 
                   # " ", ifelse(temp>1e+7, "GB", "B"), 
                   "\n\n", 
                   kable(temp_data), 
                   "\n\n\n"
                   )
    
    str00 <- paste0(str00, str0)
    # cat(str0)
    # # what are the metadata for each column of this table
    # flextable::flextable(metadata_column[metadata_column$METADATA_COLNAME %in% names(a),])
    # # print few first lines of this table for show
    # flextable::flextable(head(a, 3))
  }
  return(str00)
}

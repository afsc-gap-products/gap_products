
# Upload data to oracle! -------------------------------------------------------

dir_out <- paste0(here::here("output", Sys.Date()), "/")
dir.create(dir_out)

# Final all objects with "NEW_" prefix, save them and their table metadata, and add them to the que to save to oracle
a <- apropos("NEW_", ignore.case = FALSE) 
a <- a[!grepl(pattern = "_metadata_table", x = a)]
file_paths <- data.frame(file_path = NA, 
                         file_name = NA, 
                         metadata_table = NA)

for (i in 1:length(a)) {
  
  a_name <- gsub(pattern = "NEW_", replacement = "", x = a[i])
  
  write.csv(x = get(a[i]), file = paste0(dir_out, a_name, ".csv"))
  
  # find or create table metadat for table
  metadata_table <- ifelse(exists(paste0(a_name, "_metadata_table", collapse="\n")), 
                           get(paste0(a_name, "_metadata_table", collapse="\n")), 
                           paste0(metadata_sentence_github, 
                                  metadata_sentence_last_updated))
  
  readr::write_lines(x = metadata_table, 
                     file = paste0(dir_out, a_name, "_metadata_table.txt", collapse="\n"))
  
  file_paths <- dplyr::add_row(.data = file_paths, 
                               file_path = paste0(dir_out, a_name, ".csv"),
                               file_name = toupper(a_name), 
                               metadata_table = metadata_table)
}

file_paths <- file_paths[-1,]

metadata_column <- NEW_metadata_column
names(metadata_column) <- gsub(pattern = "metadata_", replacement = "", x = names(metadata_column))

# Save old tables to Oracle
for (i in 1:nrow(file_paths)) {
  print(file_paths$file_name[i])
  gapindex::upload_oracle(
    x = file_paths$file_path[i], 
    table_name = file_paths$file_name[i], 
    metadata_column = metadata_column, 
    table_metadata = file_paths$metadata_table[i], 
    channel = channel_products,
    schema = "GAP_PRODUCTS", 
    append_table = FALSE
  )
}

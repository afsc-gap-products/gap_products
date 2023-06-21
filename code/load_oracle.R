
# Upload data to oracle! -------------------------------------------------------

# Final all objects with "NEW_" prefix, save them and their table metadata, and add them to the que to save to oracle
a <- apropos("NEW_", ignore.case = FALSE) 
a <- a[!grepl(pattern = "_metadata_table", x = a)]
file_paths <- data.frame(file_path = NA, metadata_table = NA)

for (i in 1:length(a)) {
  
  write.csv(x = get(a[i]), file = paste0(dir_out, a[i], ".csv"))
  
  # find or create table metadat for table
  metadata_table <- ifelse(exists(paste0(a[i], "_metadata_table", collapse="\n")), 
                           get(paste0(a[i], "_metadata_table", collapse="\n")), 
                           paste0(metadata_sentence_github, 
                                  metadata_sentence_last_updated))
  
  readr::write_lines(x = metadata_table, 
                     file = paste0(dir_out, a[i], "_metadata_table.txt", collapse="\n"))
  
  file_paths <- dplyr::add_row(.data = file_paths, 
                               file_path = paste0(dir_out, a[i], ".csv"),
                               metadata_table = metadata_table)
}

file_paths <- file_paths[-1,]

# Save old tables to Oracle
for (i in 1:nrow(file_paths)) {
  oracle_upload(
    file_path = file_paths$file_path[i], 
    metadata_table = file_paths$metadata_table[i], 
    metadata_column = metadata_column, 
    channel = channel_products, 
    schema = "GAP_PRODUCTS")
}

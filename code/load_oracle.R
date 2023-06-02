
# Connect to Oracle ------------------------------------------------------------

# This has a specific username and password because I DONT want people to have access to this!
# This has a specific username and password because I DONT want people to have access to this!
locations <- c("Z:/Projects/ConnectToOracle.R")
for (i in 1:length(locations)){
  if (file.exists(locations[i])) {source(locations[i])}
}

# I set up a ConnectToOracle.R that looks like this: 
#   
#   PKG <- c("RODBC")
# for (p in PKG) {
#   if(!require(p,character.only = TRUE)) {  
#     install.packages(p)
#     require(p,character.only = TRUE)}
# }
# 
# channel<-odbcConnect(dsn = "AFSC",
#                      uid = "USERNAME", # change
#                      pwd = "PASSWORD", #change
#                      believeNRows = FALSE)
# 
# odbcGetInfo(channel)

# Upload data to oracle! -------------------------------------------------------

a <- list.files(path = dir_out, full.names = TRUE, pattern = "metadata_")
for (i in 1:length(a)) {
file.copy(from = a, 
          to = gsub(pattern = dir_out, replacement = paste0(getwd(), "/metadata/"), x = a), 
          overwrite = TRUE)
}

file_paths <- data.frame(
  file_path = c(paste0(dir_out, "/METADATA_COLUMN.csv"), 
                paste0(dir_out, "/METADATA_TABLE.csv")), 
  metadata_table = c(
    paste(readLines(con = paste0(dir_out, "metadata_column_metadata_column.txt")), collapse="\n"), 
    paste(readLines(con = paste0(dir_out, "metadata_table_metadata_table.txt")), collapse="\n"))
)

for (i in 1:length(file_paths)) {
oracle_upload(
    file_path = file_paths$file_path[i],
    metadata_table = file_paths$metadata_table[i], 
    metadata_column = metadata_column, 
    channel = channel_products, 
    schema = "GAP_PRODUCTS")
}

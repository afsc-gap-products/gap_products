#' Archive gap_products proudction run 

archive_gap_products <- function(path, archive_path) {
  
  if (!dir.exists(paths = archive_path))
    stop("The provided argument `archive_path` does not exist.")
  
  if (file.exists(paste0(path, "/report_changes.txt"))) {
    ## Copy changelog to news section
    fs::file_copy(
      path = paste0(path, "/report_changes.txt"),
      new_path = paste0("content/intro-news/", 
                        readLines(con = paste0(path, "/timestamp.txt")), ".txt")
    )
  } else (stop("report_changes.txt does not exist within argument `path`"))

  
  ## Create a new directory with the timestamp as the title. This is the 
  ## directory that will store the archive.
  dir.create(path = readLines(con = paste0(path, "/timestamp.txt")))
  
  ## Copy the contents in the code/, functions/, and temp/ directories into the 
  ## archive directory
  file.copy(from = "gap_products.Rproj", 
            to = readLines(con = paste0(path, "/timestamp.txt")))
  fs::dir_copy(path = "code/", 
               new_path = readLines(con = paste0(path, "/timestamp.txt")))
  fs::dir_copy(path = "functions/", 
               new_path = readLines(con = paste0(path, "/timestamp.txt")))
  fs::dir_copy(path = "temp/", 
               new_path = readLines(con = paste0(path, "/timestamp.txt")))
  
  ## Zip archive folder and move to G: drive
  utils::zip(files = readLines(con = paste0(path, "/timestamp.txt")),
             zipfile = paste0(getwd(), "/", 
                              readLines(con = paste0(path, "/timestamp.txt")), 
                              ".zip") )
  
  fs::file_move(path = paste0(readLines(con = paste0(path, "/timestamp.txt")), 
                              ".zip"),
                new_path = archive_path)
  
  ## Remove archive folder from local repo 
  fs::file_delete(path = readLines(con = paste0(path, "/timestamp.txt")))
  
}
#' Output session information, list of install packages, timestamp
#' 
#' 

output_r_session <- function(path) {
  if (!dir.exists(paths = path)) dir.create(path = path)
  
  ## Output time stamp at the start of production
  writeLines(text = as.character(Sys.Date()), 
             con = paste0(path, "/timestamp.txt"))
  
  ## Output R session information (R version, package versions, etc.)
  writeLines(text = capture.output(sessionInfo()), 
             con = paste0(path, "/sessionInfo.txt"))
  
  ## Output more detailed information on package versions
  write.csv(x = as.data.frame(installed.packages()[, c("Package", "Version")], 
                              row.names = F), 
            file = paste0(path, "/installed_packages.csv"), 
            row.names = F)
}

# Load libaries and funcitons --------------------------------------------------

PKG <- c(
  # Keeping Organized
  "devtools", # Package development tools for R; used here for downloading packages from GitHub
  
  # other tidyverse
  "plyr",
  "dplyr",
  # "googledrive",
  "magrittr",
  "readr",
  "tidyr",
  
  # Text Management
  "stringr")


PKG <- unique(PKG)
for (p in PKG) {
  if(!require(p,character.only = TRUE)) {
    install.packages(p)
    require(p,character.only = TRUE)}
}


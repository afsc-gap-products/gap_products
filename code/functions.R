# Load libaries and funcitons --------------------------------------------------

PKG <- c(
  # Keeping Organized
  "devtools", # Package development tools for R; used here for downloading packages from GitHub
  # "plyr",
  "gapindex", # devtools::install_github("afsc-gap-products/gapindex")
  "dplyr",
  "googledrive",
  "magrittr",
  "readr",
  "tidyr",
  "readxl",
  "janitor",
  "here",
  "stringr")

PKG <- unique(PKG)
for (p in PKG) {
  if(!require(p,character.only = TRUE)) {
    install.packages(p)
    require(p,character.only = TRUE)}
}

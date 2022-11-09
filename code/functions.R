# Load libaries and funcitons --------------------------------------------------

PKG <- c(
  # For creating R Markdown Docs
  "knitr", # A general-purpose tool for dynamic report generation in R
  "rmarkdown", # R Markdown Document Conversion
  
  # Keeping Organized
  "devtools", # Package development tools for R; used here for downloading packages from GitHub
  
  
  # Graphics
  # "ggplot2", # Create Elegant Data Visualisations Using the Grammar of Graphics
  # "cowplot",
  # "png",
  # "nmfspalette",  # devtools::install_github("nmfs-general-modeling-tools/nmfspalette")
  # "viridis", 
  
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


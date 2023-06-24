source('./code/functions.R')

load(paste0(dir_out, "FOSS_CPUE_PRESONLY.RData"))
load(paste0(dir_out, "FOSS_CPUE_JOIN.RData"))
load(paste0(dir_out, "FOSS_CPUE_ZEROFILLED.RData"))

# locations <- c(
# "GAP_PRODUCTS.FOSS_CPUE_HAUL",
# "GAP_PRODUCTS.FOSS_CPUE_CATCH"#,
# "GAP_PRODUCTS.AKFIN_HAUL", 
# "GAP_PRODUCTS.AKFIN_CRUISES"
#   "GAP_PRODUCTS.CPUE",
#   "GAP_PRODUCTS.BIOMASS",
#   "GAP_PRODUCTS.AGECOMP",
#   "GAP_PRODUCTS.SIZECOMP",
#   "GAP_PRODUCTS.STRATUM_GROUPS",
#   "GAP_PRODUCTS.AREA",
#   "GAP_PRODUCTS.SURVEY_DESIGN",
#   "GAP_PRODUCTS.TAXONOMICS_WORMS", 
#   "GAP_PRODUCTS.TAXONOMICS_ITIS", 
#   "GAP_PRODUCTS.TAXON_CONFIDENCE", 
#   "GAP_PRODUCTS.METADATA_COLUMN" 
# )
# 
# for (i in 1:length(locations)) {
#   print(locations[i])
#   a <- RODBC::sqlQuery(channel, paste0("SELECT * FROM ", locations[i]))
#   write.csv(x = a, file = here::here("data", paste0(locations[i], ".csv")))
# }

tocTF <- TRUE
rmarkdown::render(input = here::here("docs","README.Rmd"),
                  output_dir = here::here(),
                  output_format = 'md_document',
                  output_file = here::here("README.md"))

# Make README into index
index <- base::readLines(con = here::here("docs","README.Rmd"))
utils::write.table(x = index,
                   file = here::here("docs","index.Rmd"),
                   row.names = FALSE,
                   col.names = FALSE,
                   quote = FALSE)


comb <- list.files(path = "docs/", pattern = ".Rmd", ignore.case = TRUE)
comb <- comb[comb != "footer.Rmd"]
comb <- gsub(pattern = ".Rmd", replacement = "", x = comb, ignore.case = TRUE)

tocTF <- FALSE
## Loop over pages
for (jj in 1:length(comb[comb != "README"])) { 
  rmarkdown::render(
    input = here::here("docs", paste0(comb[jj], ".Rmd")),
    output_dir = here::here("docs"),
    output_file = paste0(comb[jj], ".html") )
}

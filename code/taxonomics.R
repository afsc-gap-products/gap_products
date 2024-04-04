#' -----------------------------------------------------------------------------
#' title: Taxonomic ID Confidence Tables
#' author: EH Markowitz
#' Notes: This script creates the taxonomic identification confidence tables
#'        for each region and survey year used currently for FOSS purposes. 
#'        
#'        Quality Codes:
#'        1 – High confidence and consistency. Taxonomy is stable and reliable 
#'            at this level, and field identification characteristics are well 
#'            known and reliable.
#'        2 – Moderate confidence. Taxonomy may be questionable at this level,
#'            or field identification characteristics may be variable and 
#'            difficult to assess consistently.
#'        3 – Low confidence. Taxonomy is incompletely known, or reliable field
#'            identification characteristics are unknown.
#' -----------------------------------------------------------------------------

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Libraries
##   Connect to Oracle (Make sure to connect to network or VPN)
##   Be sure to use the username and password for the GAP_PRODUCTS schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PKG <- c("dplyr", "magrittr", "readxl", "tidyr", "googledrive")
for (p in PKG) {
  if (!require(p, character.only = TRUE)) {
    install.packages(p)
    require(p, character.only = TRUE)
  }
}

if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
  channel <- channel_products
} else {
  channel <- gapindex::get_connected(check_access = F)
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Download the most recent version of the taxonomic confidence tables
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
googledrive::drive_auth()

a <- googledrive::drive_ls(path = "https://drive.google.com/drive/folders/1s-BKOnfiuF3b0642C_DGhLcuRv-MOPxO")

for (i in 1:nrow(x = a)) {
  googledrive::drive_download(file = a$id[i], 
                              path = paste0("temp/", a$name[i]), 
                              overwrite = TRUE)
}

current_year <- as.integer(format(x = Sys.Date(), format = "%Y"))
survey_years <- 
  RODBC::sqlQuery(channel = channel, 
                  query = "SELECT * FROM GAP_PRODUCTS.SURVEY_DESIGN")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   For each region, 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

TAXONOMIC_CONFIDENCE <- data.frame()

regions <- a$name
for (iregion in 1:length(x = regions)) {
  print(regions[iregion])
  
  ## Import the original taxonomic confidence region for regions[iregion]
  taxon_conf_wide <- 
    readxl::read_xlsx(path = here::here("temp/", regions[iregion]), 
                      skip = 1, col_names = TRUE) %>% 
    dplyr::select(where(~!all(is.na(.x)))) %>% # remove empty columns
    janitor::clean_names() %>% 
    dplyr::rename(species_code = code)
  
  ## If the field 'quality_codes' is not in `taxon_conf_wide`, create the field
  if (!("quality_codes" %in% names(x = taxon_conf_wide))) 
    taxon_conf_wide$quality_codes<-NULL
  
  ## What is the most current year of data?
  last_year <- max(as.numeric(x = gsub(x = grep(x = names(x = taxon_conf_wide), 
                                                pattern = "x", 
                                                value = T),
                                       pattern = "x",
                                       replacement = "")))
  
  ## Extract region name
  region_name <- strsplit(x = gsub(x = gsub(x = regions[iregion], 
                                            pattern = "TAXONOMIC_CONFIDENCE_", 
                                            replacement = ""), 
                                   pattern = ".xlsx", 
                                   replacement = ""), 
                          split = "_")[[1]][[3]]
  
  ## If the taxonomic confidence tables haven't been updated, fill in 
  if (last_year < current_year) {
    imputted_years <- 
      subset(x = survey_years, 
             subset = YEAR > last_year & 
               SURVEY_DEFINITION_ID ==  c("AI" = 52, "GOA" = 47, "EBS" = 98, 
                                          "BSS" = 78, "NBS" = 143)[region_name])
    
    if (nrow(x = imputted_years) > 0) {
      imputted_years$YEAR
    }
  }
  
  
  taxon_conf_wide <- taxon_conf_wide %>% 
    dplyr::select(-scientific_name, -common_name) %>% 
    tidyr::pivot_longer(cols = starts_with("x"), 
                        names_to = "year", 
                        values_to = "TAXONOMIC_CONFIDENCE") %>% 
    dplyr::mutate(year = gsub(pattern = "[a-z]", 
                              replacement = "", 
                              x = year), 
                  year = gsub(pattern = "_0", replacement = "", 
                              x = year), 
                  year = as.numeric(year)) %>% 
    dplyr::distinct() %>% 
    dplyr::mutate(SRVY = region_name)
  
  TAXONOMIC_CONFIDENCE <- TAXONOMIC_CONFIDENCE %>% 
    dplyr::bind_rows(b)
  
  if (cc == "EBS") {
    TAXONOMIC_CONFIDENCE <- TAXONOMIC_CONFIDENCE %>% 
      dplyr::bind_rows(b %>% 
                         dplyr::mutate(SRVY = "NBS"))
  }
}

TAXONOMIC_CONFIDENCE <- TAXONOMIC_CONFIDENCE %>% 
  dplyr::mutate(TAXONOMIC_CONFIDENCE_code = TAXONOMIC_CONFIDENCE, 
                TAXONOMIC_CONFIDENCE = dplyr::case_when(
                  TAXONOMIC_CONFIDENCE_code == 1 ~ "High",
                  TAXONOMIC_CONFIDENCE_code == 2 ~ "Moderate",
                  TAXONOMIC_CONFIDENCE_code == 3 ~ "Low",
                  TRUE ~ "Unassessed")
  ) %>%
  dplyr::left_join(y = 
                     data.frame(survey_definition_id = c(143, 98, 47, 52, 78),
                                SRVY = c("NBS", "EBS", "GOA", "AI", "BSS") ),
                   by = "SRVY") %>% 
  dplyr::select(-SRVY)


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Fill in TAXONOMIC_CONFIDENCE with, if missing, the values from the prior year
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

comb1 <- RODBC::sqlQuery(channel = channel, 
                         query = "SELECT * FROM GAP_PRODUCTS.AKFIN_CRUISE") %>% 
  janitor::clean_names() %>% 
  dplyr::filter(survey_definition_id %in% c(143, 98, 47, 52, 78) & 
                  !is.na(cruisejoin) & 
                  year >= 1982 &
                  !is.na(year)) %>% 
  dplyr::select(year, survey_definition_id) %>% 
  dplyr::distinct()

comb2 <- unique(TAXONOMIC_CONFIDENCE[, c("survey_definition_id", "year")])
comb1$comb <- paste0(comb1$survey_definition_id, "_", comb1$year)
comb2$comb <- paste0(comb2$survey_definition_id, "_", comb2$year)
comb <- strsplit(x = setdiff(comb1$comb, comb2$comb), split = "_")
comb <- data.frame(t(data.frame(comb)))
names(comb) <- c("survey_definition_id", "year")

for (i in 1:nrow(comb)) {
  TAXONOMIC_CONFIDENCE <- dplyr::bind_rows(
    TAXONOMIC_CONFIDENCE, 
    TAXONOMIC_CONFIDENCE %>% 
      dplyr::filter(survey_definition_id == comb$survey_definition_id[i] & 
                      year == max(year, na.rm = TRUE)) %>% 
      dplyr::mutate(year = as.numeric(comb$year[i])) )
}

### Add table and column metadata -------

TAXONOMIC_CONFIDENCE_COMMENT <- paste0(
  "The quality and specificity of field identifications for many taxa have 
    fluctuated over the history of the surveys due to changing priorities and resources. 
    The matrix lists a confidence level for each taxon for each survey year 
    and is intended to serve as a general guideline for data users interested in 
    assessing the relative reliability of historical species identifications 
    on these surveys. ", 
  # "This dataset includes an identification confidence matrix 
  # for all fishes and invertebrates identified ", 
  # metadata_sentence_survey_institution, 
  "Quality Codes: ", 
  "1: High confidence and consistency. Taxonomy is stable and reliable at this level, and field identification characteristics are well known and reliable. ",
  "2: Moderate confidence. Taxonomy may be questionable at this level, or field identification characteristics may be variable and difficult to assess consistently. ", 
  "3: Low confidence. Taxonomy is incompletely known, or reliable field identification characteristics are unknown. ", 
  "NA: Unassessed. Taxonomy quality has not been assessed. ")#, 
# metadata_sentence_legal_restrict, " ",  
# metadata_sentence_github, " ", 
# metadata_sentence_codebook, " ", 
# metadata_sentence_last_updated)

write.csv(x = TAXONOMIC_CONFIDENCE,
          file = paste0("temp/taxonomics_confidence.csv"),
          row.names = F)

write.csv(x = TAXONOMIC_CONFIDENCE_COMMENT,
          file = paste0("temp/taxonomics_confidence.txt"),
          row.names = F)

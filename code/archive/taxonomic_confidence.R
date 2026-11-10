#' -----------------------------------------------------------------------------
#' Title:   Creation of the GAP_PRODUCTS.TAXONOMIC_CONFIDENCE table
#' Authors: EH Markowitz, Zack Oyafuso
#' Notes:   This script creates the taxonomic identification confidence tables
#'          for each region and survey year used currently for FOSS purposes. 
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
#'            
#'        Source for taxonomic tables:    
#' -----------------------------------------------------------------------------

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Import Libraries
##   Connect to Oracle (Make sure to connect to network or VPN)
##   Be sure to use the username and password for the GAP_PRODUCTS schema
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(dplyr)
library(readxl)
library(tidyr)
library(janitor)
library(googledrive)
library(gapindex)

channel <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Download the most recent version of the taxonomic confidence tables for 
##   each region from a googledrive folder. There is no NBS taxonomic 
##   confidence table so we assume that the taxonomic confidence table of the
##   NBS is the same as the EBS. The full link to the folder is:
##   https://drive.google.com/drive/folders/1s-BKOnfiuF3b0642C_DGhLcuRv-MOPxO
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
googledrive::drive_auth()

data_sources <- googledrive::drive_ls(
  path = googledrive::as_id(x = "1s-BKOnfiuF3b0642C_DGhLcuRv-MOPxO"))

if (!dir.exists(paths = "temp/")) dir.create(path = "temp/")

for (idata in 1:nrow(x = data_sources)) {
  googledrive::drive_download(file = data_sources$id[idata], 
                              path = paste0("temp/", data_sources$name[idata]), 
                              overwrite = TRUE)
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   For each region, import the taxonomic confidence spreadsheet, clean up, 
##   and append to a data.frame called `TAXONOMIC_CONFIDENCE`
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
current_year <- as.integer(x = format(x = Sys.Date(), format = "%Y"))
survey_years <- RODBC::sqlQuery(channel = channel,
                                query = "SELECT * 
                                         FROM GAP_PRODUCTS.SURVEY_DESIGN")

TAXONOMIC_CONFIDENCE <- data.frame()
for (iregion in c("GOA", "AI", "EBS", "BSS")) {
  
  ## Import the original taxonomic confidence region for iregion
  taxon_conf_wide <- readxl::read_excel(path = paste0("temp/Taxon_confidence_", 
                                                      iregion, ".xlsx"), 
                                        skip = 1, 
                                        col_names = TRUE) |> 
    dplyr::select(where(~!all(is.na(.x)))) |> # remove empty columns
    janitor::clean_names() |> 
    dplyr::rename(SPECIES_CODE = code)
  
  ## The quality_code field is inconsistently provided across tables so 
  ## we remove it if it exists in the imported spreadsheet
  if ("quality_codes" %in% names(x = taxon_conf_wide))
    taxon_conf_wide <- subset(x = taxon_conf_wide, select = -quality_codes)
  
  ## What is the most current year of taxonomic confidence data?
  last_year <- 
    max(as.numeric(x = substr(x = grep(x = names(x = taxon_conf_wide), 
                                       pattern = "x", 
                                       value = T),
                              start = 2, stop = 5)))
  last_year_idx <- 
    which.max(x = as.numeric(x = substr(x = grep(x = names(x = taxon_conf_wide), 
                                                 pattern = "x", 
                                                 value = T),
                                        start = 2, stop = 5)))
  
  ## If the taxonomic confidence table has not been updated (i.e., last_year <
  ## current_year), impute the taxon confidence for the survey years after the
  ## last_year using the most recent year in the taxonomic confidence table
  if (last_year < current_year) {
    imputted_years <- 
      subset(x = survey_years, 
             subset = YEAR > last_year & YEAR <= current_year &
               SURVEY_DEFINITION_ID ==  c("AI" = 52, "GOA" = 47, "EBS" = 98, 
                                          "BSS" = 78, "NBS" = 143)[iregion])
    
    if (nrow(x = imputted_years) > 0) 
      taxon_conf_wide[, paste0("x", imputted_years$YEAR, "_0")] <- 
        taxon_conf_wide[, last_year_idx]  
  }
  
  ## Lengthen the wide-version taxon_conf_wide, which creates the YEAR field
  taxon_conf_long <- taxon_conf_wide |> 
    dplyr::select(-scientific_name, -common_name) |> 
    tidyr::pivot_longer(cols = starts_with("x"), 
                        names_to = "YEAR", 
                        values_to = "TAXON_CONFIDENCE") |> 
    dplyr::mutate(YEAR = gsub(pattern = "[a-z]", 
                              replacement = "", 
                              x = YEAR), 
                  YEAR = gsub(pattern = "_0", replacement = "", 
                              x = YEAR), 
                  YEAR = as.numeric(YEAR)) |> 
    dplyr::distinct() |> 
    dplyr::mutate(SRVY = iregion)
  
  ## Filter only years where a bottom trawl survey occurred
  taxon_conf_long <- 
    subset(x = taxon_conf_long, 
           subset = YEAR %in% survey_years$YEAR[
             survey_years$SURVEY_DEFINITION_ID == c("AI" = 52, "GOA" = 47, 
                                                    "EBS" = 98,  "BSS" = 78, 
                                                    "NBS" = 143)[iregion]])
  
  ## Append to TAXONOMIC_CONFIDENCE
  TAXONOMIC_CONFIDENCE <- rbind(TAXONOMIC_CONFIDENCE, taxon_conf_long)
  
  ## Since there is no NBS confidence table, duplicate the EBS table
  if (iregion == "EBS") 
    TAXONOMIC_CONFIDENCE <- TAXONOMIC_CONFIDENCE |> 
    dplyr::bind_rows(subset(x = taxon_conf_long,
                            subset = YEAR %in% survey_years$YEAR[
                              survey_years$SURVEY_DEFINITION_ID == 143
                            ]) |> 
                       dplyr::mutate(SRVY = "NBS")
    )
}

## Add TAXON_CONFIDENCE field which is a text version of TAXON_CONFIDENCE_CODE
TAXONOMIC_CONFIDENCE <- TAXONOMIC_CONFIDENCE |> 
  dplyr::mutate(TAXON_CONFIDENCE_CODE = TAXON_CONFIDENCE, 
                TAXON_CONFIDENCE = dplyr::case_when(
                  TAXON_CONFIDENCE_CODE == 1 ~ "High",
                  TAXON_CONFIDENCE_CODE == 2 ~ "Moderate",
                  TAXON_CONFIDENCE_CODE == 3 ~ "Low",
                  TRUE ~ "Unassessed")
  ) |>
  dplyr::left_join(y = 
                     data.frame(SURVEY_DEFINITION_ID = c(143, 98, 47, 52, 78),
                                SRVY = c("NBS", "EBS", "GOA", "AI", "BSS") ),
                   by = "SRVY") |> 
  dplyr::select(-SRVY)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   For survey years without taxonomic confidence data, impute taxonomic 
##   confidence values from the previous survey year for that survey
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
missing_survey_years <- dplyr::anti_join(
  x = subset(survey_years, YEAR <= current_year),
  y = unique(x = TAXONOMIC_CONFIDENCE[, c("SURVEY_DEFINITION_ID", "YEAR")]),
  by = c("SURVEY_DEFINITION_ID", "YEAR"))

for (iyear in 1:nrow(x = missing_survey_years)) {
  
  ## Query unique survey years for a given survey prior to the missing year
  temp_survey_year <- 
    subset(x = unique(x = TAXONOMIC_CONFIDENCE[, c("SURVEY_DEFINITION_ID", 
                                                   "YEAR")]),
           subset = SURVEY_DEFINITION_ID == 
             missing_survey_years$SURVEY_DEFINITION_ID[iyear] &
             YEAR < missing_survey_years$YEAR[iyear])
  
  ## The year to impute the missing year's data will be the survey year prior
  ## to the missing year
  imputted_year <- temp_survey_year[which.max(x = temp_survey_year$YEAR), ]
  
  ## Append the imputted year's taxonomic confidence data for that survey
  ## to the TAXONOMIC_CONFIDENCE data frame.  
  TAXONOMIC_CONFIDENCE <- dplyr::bind_rows(
    TAXONOMIC_CONFIDENCE, 
    TAXONOMIC_CONFIDENCE |> 
      dplyr::filter(SURVEY_DEFINITION_ID == imputted_year$SURVEY_DEFINITION_ID & 
                      YEAR == imputted_year$YEAR) |> 
      dplyr::mutate(YEAR = missing_survey_years$YEAR[iyear]) 
  )
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    Filter for SPECIES_CODE values present in the GROUP_CODE field in 
##    GAP_PRODUCTS.TAXON_GROUPS   
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
spp_codes <- 
  RODBC::sqlQuery(channel = channel, 
                  query = "SELECT DISTINCT (GROUP_CODE) 
                           FROM GAP_PRODUCTS.TAXON_GROUPS 
                           ORDER BY GROUP_CODE")$GROUP_CODE
TAXONOMIC_CONFIDENCE <- subset(x = TAXONOMIC_CONFIDENCE, 
                               subset = SPECIES_CODE %in% spp_codes)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create the table and column metadata
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
TAXONOMIC_CONFIDENCE_COMMENT <- paste0(
  "The quality and specificity of field identifications for many taxa have 
fluctuated over the history of the surveys due to changing priorities and 
resources. The matrix lists a confidence level for each taxon for each survey 
year and is intended to serve as a general guideline for data users interested 
in assessing the relative reliability of historical species identifications on 
these surveys. Quality Codes: ", 
  "1: High confidence and consistency. Taxonomy is stable and reliable at this 
level, and field identification characteristics are well known and reliable. ",
  "2: Moderate confidence. Taxonomy may be questionable at this level, or field 
identification characteristics may be variable and difficult to assess 
  consistently. ", 
  "3: Low confidence. Taxonomy is incompletely known, or reliable field 
identification characteristics are unknown. ", 
  "NA: Unassessed. Taxonomy quality has not been assessed. ")

metadata_column <- 
  RODBC::sqlQuery(channel = channel, 
                  query = paste(
                    "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                WHERE METADATA_COLNAME IN", 
                    gapindex::stitch_entries(names(x = TAXONOMIC_CONFIDENCE) )
                  )
  )
names(x = metadata_column) <- gsub(x = tolower(x = names(x = metadata_column)),
                                   pattern = "metadata_", 
                                   replacement = "")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Upload table: gapindex function will drop the table if it already exists,
##  saves the table, then adds the comment on the table and each column.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gapindex::upload_oracle(x = TAXONOMIC_CONFIDENCE, 
                        schema = "GAP_PRODUCTS", 
                        table_name = "TAXONOMIC_CONFIDENCE", 
                        metadata_column = metadata_column, 
                        table_metadata = TAXONOMIC_CONFIDENCE_COMMENT, 
                        channel = channel,
                        share_with_all_users = TRUE)


# Calculate tables -------------------------------------------------------------

# Descriptions to add to the https://github.com/afsc-gap-products/gapindex/blob/master/code_testing/production.R script 

temp <- paste0(metadata_sentence_survey_institution, " ",
               metadata_sentence_legal_restrict, " ",
               metadata_sentence_github, " ",
               metadata_sentence_codebook, " ",
               metadata_sentence_last_updated)

NEW_AGECOMP_COMMENT <- paste0(
  "Stratum/subarea/management area/region-level abundance by sex/length bin. 
    Sex-specific columns (i.e., MALES, FEMALES, UNSEXED), previously formatted in 
    historical versions of this table, are melted into a single column (called SEX) 
    similar to the AGECOMP tables with values 1/2/3 for M/F/U. The AREA_ID 
    field replaces the STRATUM field name to generalize the description to 
    include different types of areas (strata, subareas, regulatory areas, regions, etc.). 
    Use the GAP_PRODUCTS.AREA table to look up the values of AREA_ID for your particular region. ",
  temp)

NEW_BIOMASS_COMMENT <- paste0(
  "Stratum/subarea/management area/region-level mean/variance CPUE (weight and numbers), 
  total biomass (with variance), total abundance (with variance). The AREA_ID 
  field replaces the STRATUM field name to generalize the description to include 
  different types of areas (strata, subareas, regulatory areas, regions, etc.). 
  Use the GAP_PRODUCTS.AREA table to look up the values of AREA_ID for your particular region. 
  Note confidence intervals are currently not supported in the GAP_PRODUCTS version of the biomass/abundance tables. 
  The associated variance of estimates will suffice as the metric of variability to use. ", 
  temp)

NEW_CPUE_COMMENT <- paste0(
  "All haul-level zero-filled haul-level catch-per-unit-effort (units in kg/km2) data. ",
  temp)

NEW_SIZECOMP_COMMENT <- paste0(
  "All region-level abundance by sex/age. ",
  temp)


# NEW__COMMENT <- paste0(
#   "", 
#   temp)



## Area Reference Tables -------------------------------------------------------

#### Load tables ---------------------------------------------------------------

# https://docs.google.com/spreadsheets/d/1v900jEaSPuWjyHzRJhY2RUFzO_c9FqOunow-RM77bHQ
googledrive::drive_download(
  file = googledrive::as_id("1v900jEaSPuWjyHzRJhY2RUFzO_c9FqOunow-RM77bHQ"), 
  path = here::here("data", "stratum.xlsx"), 
  overwrite = TRUE)

#### Table Metadata ------------------------------------------------------------

# NEW_AREA <- metadata_table <- readxl::read_xlsx(
#   path = here::here("data", "stratum.xlsx"), 
#   sheet = "AREA") %>%
#   janitor::clean_names() 

NEW_AREA_COMMENT <- paste0(
  "This reference table stores all metadata and estimates for all estimates of 
  stratum and subarea area estimates. 
  Use this table with the STRATUM_GROUPS and SURVEY_DESIGN tables. ", 
  temp)

# NEW_SURVEY_DESIGN <- metadata_table <- readxl::read_xlsx(
#   path = here::here("data", "stratum.xlsx"), 
#   sheet = "SURVEY_DESIGN") %>%
#   janitor::clean_names() %>% 
#   dplyr::select(-SURVEY)

NEW_SURVEY_DESIGN_COMMENT <- paste0(
  "This reference table identifies which past year (DESIGN_YEAR) 
  area (km2) estimates should be used to back-calculate production data estimates 
  for a given survey (SURVEY_DEFINIITION_ID) year (YEAR). 
  While the survey areas are generally static in design, there are improvements 
  on the actual estimates of area. These improvments are due to improved 
  resolution between water and land or better understandings of survey design in practice. 
  Use this table with the STRATUM_GROUPS and AREA tables. ",
  temp)

# NEW_STRATUM_GROUPS <- metadata_table <- readxl::read_xlsx(
#   path = here::here("data", "stratum.xlsx"), 
#   sheet = "STRATUM_GROUPS") %>%
#   janitor::clean_names() 

NEW_STRATUM_GROUPS_COMMENT <- paste0(
  "This reference table identifies which STRATUM (the lowest common denominator 
  of statistical area groupings in this survey) relate to what greater statistical 
  areas (AREA_ID), along with what year (DESIGN_YEAR) and survey (SURVEY_DEFINITION_ID) 
  that pairing is relevant to. Use this table with the AREA and SURVEY_DESIGN tables. ", 
  temp)


# Load table metadata for all tables -------------------------------------------

# Will be replaced by and augment what is already in 
# https://github.com/afsc-gap-products/gapindex/blob/master/code_testing/production.R

prod_tables <- data.frame(
  TABLE_NAME = c("AGECOMP", "AREA", 
                 "BIOMASS", "CPUE", 
                 "DESIGN_SURVEY", "METADATA_TABLE", 
                 "STRATUM_GROUPS", "SIZECOMP"), 
  metadata_table = c(NEW_AGECOMP_COMMENT, NEW_AREA_COMMENT, 
                     NEW_BIOMASS_COMMENT, NEW_CPUE_COMMENT, 
                     NEW_SURVEY_DESIGN_COMMENT, NEW_METADATA_TABLE_COMMENT, 
                     NEW_STRATUM_GROUPS_COMMENT, NEW_SIZECOMP_COMMENT))

for (ii in 1:nrow(prod_tables)) {
  print(paste0("\n\n", prod_tables$TABLE_NAME[ii]))
  
  temp <- fix_metadata_table(
    metadata_table0 = prod_tables$metadata_table[ii],
    name0 = prod_tables$TABLE_NAME[ii],
    dir_out = dir_out)
  
  update_metadata(
    schema = "GAP_PRODUCTS",
    table_name = prod_tables$TABLE_NAME[ii],
    channel = channel,
    metadata_column = metadata_column,
    table_metadata = temp)
}




# assuming that they already exist

akfin_views <- RODBC::sqlQuery(
  channel = channel,
  query = "SELECT 'Table' AS object_type, table_name
FROM user_tables
UNION ALL
SELECT 'View', view_name
FROM user_views;") %>% 
  dplyr::filter(grepl(x = TABLE_NAME, pattern = "AKFIN_")) %>% 
  dplyr::mutate(metadata_table = "")

temp <- paste(
  "These data were calculated using all standard hauls that can be applied to 
  production data and abundance calculations. ", 
  "These data are produced by ", metadata_sentence_survey_institution, 
  metadata_sentence_legal_restrict, 
  metadata_sentence_foss, 
  metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated, 
  collapse = " ", sep = " ")

# for (ii in 1:nrow(akfin_views)) {
#   
#   metadata_table0 <- paste0(
#     "This table includes all ",
#     gsub(pattern = "AKFIN_", replacement = "", x = akfin_views$TABLE_NAME[ii]), 
#     " data. ", 
#     metadata_table)
#   
#   metadata_table <- fix_metadata_table(
#   metadata_table0 = metadata_table0,
#   name0 = akfin_views$TABLE_NAME[ii],
#   dir_out = dir_out)
#   
#   update_metadata(
#     schema = "GAP_PRODUCTS", 
#     table_name = akfin_views$TABLE_NAME[ii], 
#     channel = channel, 
#     metadata_column = metadata_column, 
#     table_metadata = metadata_table0)
#   
# }

## Add Table Metdata -----------------------------------------------------------

GAP_PRODUCT_txt <- "These tables are complete copies or subsets of the analagous internal production table in GAP_PRODUCTS, 
but may be subset to relevant, standard, abundance-calculation worthy observations. "

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_AGECOMP"] <- 
  paste0(get("NEW_AGECOMP_COMMENT"), 
         GAP_PRODUCT_txt)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_AREA"] <- 
  paste0(get("NEW_AREA_COMMENT"), 
         GAP_PRODUCT_txt)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_BIOMASS"] <- 
  paste0(get("NEW_BIOMASS_COMMENT"), 
         GAP_PRODUCT_txt)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_CATCH"] <- paste0(
  "All haul-level catch (organism weight and count) data for all relevant, standard hauls. ",
  temp)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_CPUE"] <- 
  paste0(get("NEW_CPUE_COMMENT"), 
         GAP_PRODUCT_txt)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_CRUISES"] <- paste0(
  "All cruise, vessel, and timing data for all relevant, standard cruises. ",
  temp)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_HAUL"] <- paste0(
  "All haul and environmental data for all relevant, standard hauls. ",
  temp)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_LENGTH"] <- paste0(
  "All species length and sex data for all relevant, standard hauls. ",
  temp)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_METADATA_COLUMN"] <- 
  paste0(get("NEW_METADATA_COLUMN_COMMENT"), 
         GAP_PRODUCT_txt)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_SIZECOMP"] <- 
  paste0(get("NEW_SIZECOMP_COMMENT"), 
         GAP_PRODUCT_txt)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_SPECIMEN"] <- paste0(
  "All haul-level specimen length, weight, and sex data for all relevant, standard hauls. ",
  temp)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_STRATUM_GROUPS"] <- 
  paste0(get("NEW_STRATUM_GROUPS_COMMENT"), 
         GAP_PRODUCT_txt)

akfin_views$metadata_table[akfin_views$TABLE_NAME == "AKFIN_SURVEY_DESIGN"] <- 
  paste0(get("NEW_SURVEY_DESIGN_COMMENT"), 
         GAP_PRODUCT_txt)


for (ii in 1:nrow(akfin_views)) {
  metadata_table <- fix_metadata_table(
    metadata_table0 = akfin_views$metadata_table,
    name0 = akfin_views$TABLE_NAME[ii],
    dir_out = dir_out)
  
  update_metadata(
    schema = "GAP_PRODUCTS",
    table_name = akfin_views$TABLE_NAME[ii],
    channel = channel,
    metadata_column = metadata_column,
    table_metadata = metadata_table)
}





# Download current estimates data from oracle ----------------------------------

# The current state of affairs
locations <- c( # data pulled from Oracle for these figures:
  "RACEBASE.HAUL",
  "RACE_DATA.V_CRUISES")

# Download data from oracle ----------------------------------------------------

# Load oracle data --------------------------------------------------------------------

# load_data(dir_in = dir_data, locations)
a <- tolower(gsub(pattern = ".", replacement = "_", x = locations, fixed = TRUE))
for (i in 1:length(a)){
  b <- readr::read_csv(file = paste0(dir_data, a[i], ".csv"), 
                       show_col_types = FALSE)
  b <- janitor::clean_names(b)
  if (names(b)[1] %in% "x1"){
    b$x1 <- NULL
  }
  
  if (names(b)[1] %in% "rownames"){
    b$rownames <- NULL
  }
  
  temp <- strsplit(x = a[i], split = "/")
  temp <- gsub(pattern = "\\.csv", replacement = "", x = temp[[1]][length(temp[[1]])])
  print(paste0(temp, "0"))
  assign(x = paste0(temp, "0"), value = b)
}

## Download data report tables from google drive that should be in oracle ------

library(googledrive)
googledrive::drive_deauth()
googledrive::drive_auth()
1

# Spreadsheets
# https://drive.google.com/drive/folders/1Vbe_mH5tlnE6eheuiSVAFEnsTJvdQGD_?usp=sharing
a <- googledrive::drive_ls(path = googledrive::as_id("1Vbe_mH5tlnE6eheuiSVAFEnsTJvdQGD_"), 
                           type = "spreadsheet")

if (FALSE) {
  for (i in 1:nrow(a)){
    googledrive::drive_download(file = googledrive::as_id(a$id[i]), 
                                type = "xlsx", 
                                overwrite = TRUE, 
                                path = paste0(dir_data, "/", a$name[i]))
  }
}

OLD_SPECIAL_PROJECTS <- dplyr::left_join(
  x = readxl::read_xlsx(path = paste0(dir_data, "0_special_projects.xlsx"), 
                        sheet = "projects", skip = 1), 
  y = readxl::read_xlsx(path = paste0(dir_data, "0_special_projects.xlsx"), 
                        sheet = "solicitation_date", skip = 1), 
  by = "year") |> 
  janitor::clean_names() |> 
  dplyr::select(-in_report)

# affiliations -----------------------------------------------------------------

OLD_AFFILIATIONS <- readxl::read_xlsx(path = paste0(dir_data, "0_special_projects.xlsx"), 
                                      sheet = "affiliations", skip = 1) |> 
  janitor::clean_names() |> 
  dplyr::rename("agency_short" = "agency_2", 
                "agency_abrv" = "agency")  |>
  dplyr::select(-combined) |> 
  dplyr::mutate(agency_join = 1:nrow(.))

# , 
# "project" = "projecttitle", 
# "project_short" = "nickname", 
# "pricipal_investigator" = "pricipalinvestigator"

OLD_OTHER_FIELD_COLLECTIONS <- readxl::read_xlsx(path = paste0(dir_data, "0_other_field_collections.xlsx"), 
                                                 sheet = "Sheet1", skip = 1)  |> 
  janitor::clean_names() |> 
  dplyr::filter(year > 2017) |> 
  dplyr::select(-print_name, -notes)

OLD_COLLECTION_SCHEME <- readxl::read_xlsx(path = paste0(dir_data, "0_collection_scheme.xlsx"), 
                                           sheet = "Sheet1", skip = 1) |> 
  dplyr::filter(year > 2017) |> 
  janitor::clean_names() |> 
  dplyr::rename(species_codes = species_code) |>
  dplyr::select(-print_name, -x12, -notes)

# Wrangle data -----------------------------------------------------------------

## Table metadata ---------------------------------------------------------------

link_repo <- "https://github.com/afsc-gap-products/gap_products"

for (i in 1:nrow(gap_products_metadata_table0)){
  assign(x = paste0("metadata_sentence_", gap_products_metadata_table0$metadata_sentence_name[i]), 
         value = gap_products_metadata_table0$metadata_sentence[i])
}

metadata_sentence_github <- gsub(
  x = metadata_sentence_github, 
  pattern = "INSERT_REPO", 
  replacement = link_repo)

metadata_sentence_last_updated <- gsub(
  x = metadata_sentence_last_updated, 
  pattern = "INSERT_DATE", 
  replacement = format(x = as.Date(strsplit(x = dir_out, split = "/", fixed = TRUE)[[1]][length(strsplit(x = dir_out, split = "/", fixed = TRUE)[[1]])]), "%B %d, %Y") )

## Lookup ----------------------------------------------------------------------

lookup <- c(
  
  SRVY = "survey", 
  SRVY = "survey_region", 
  SRVY = "region",
  
  year = "survey_year", 
  
  station = "gis_station",
  station = "stationid", 
  
  area_km2 = "area", 
  perimeter_km = "perimeter", 
  
  depth_m_min = "min_depth", 
  depth_m_max = "max_depth", 
  
  grid_number = "aigrid_number", 
  grid_id = "aigrid_id", 
  grid = "aigrid", 
  
  cpue_kgkm2 = "cpuewgt_total", 
  cpue_nokm2 = "cpuenum_total",
  cpue_kgkm2 = "wgtcpue", 
  cpue_nokm2 = "numcpue", 
  
  weight_kg = "weight", 
  count_taxon = "number_fish", 
  
  stratum = "regulatory_area_name", 
  stratum = "summary_area", # may be an stratum ID, not an actual depth
  stratum = "summary_area_depth", # may be an stratum ID, not an actual depth
  stratum = "summary_depth", 
  stratum = "regulatory_area_name", 
  
  
  count_length = "lencount", 
  count_length = "len_count",
  count_length = "length_count",
  
  count_catch = "catchcount", 
  count_catch = "catch_count", 
  count_catch = "count_catch", 
  # count_catch = "number_count",
  
  count_number = "number_count",  # what is this?
  
  count_haul = "haulcount", 
  count_haul = "haul_count",
  
  cpue_kgkm2_mean = "mean_wgt_cpue", 
  cpue_kgkm2_mean = "meanwgtcpue", 
  cpue_kgkm2_mean = "cpue_wgtkm2_mean",
  
  cpue_kgkm2_var = "cpue_wgtkm2_var", 
  cpue_kgkm2_var = "var_wgt_cpue", 
  cpue_kgkm2_var = "varmnwgtcpue",
  
  cpue_nokm2_mean = "mean_num_cpue", 
  cpue_nokm2_mean = "meannumcpue", 
  cpue_nokm2_var = "var_num_cpue", 
  cpue_nokm2_var = "varmnnumcpue", 
  
  biomass_mt = "biomass", 
  biomass_mt = "area_biomass", 
  biomass_mt = "stratum_biomass", 
  biomass_mt = "total_biomass", 
  biomass_mt = "biomass_total",
  
  biomass_var = "varbio", 
  biomass_var = "bio_var", 
  
  biomass_ci_lower = "min_biomass", # Is this right?
  biomass_ci_lower = "biomass_lower_ci", 
  
  biomass_ci_upper = "max_biomass",  # is this right?
  biomass_ci_upper = "biomass_upper_ci", 
  
  biomass_df = "degreef_biomass",
  
  population = "abundance", 
  population = "area_pop", 
  population = "stratum_pop", 
  population = "total_pop", 
  
  population_var = "varpop", 
  population_var = "pop_var", 
  population_var = "abundance_var", 
  
  population_ci_lower = "min_pop", # Is this right?
  population_ci_lower = "abundance_lower_ci", 
  population_ci_lower = "abundance_ci_lower", 
  
  population_ci_upper = "abundance_ci_upper", 
  population_ci_upper = "max_pop", 
  population_ci_upper = "abundance_upper_ci", 
  
  population_df = "abundance_df",
  population_df = "degreef_pop", 
  
  area_depth = "summary_area_depth", 
  area_depth = "summary_depth", 
  
  value = "length", 
  
  longitude_dd = "longitude", 
  latitiude_dd = "latitiude", 
  
  vessel_id = "vessel"
)

## Haul data -------------------------------------------------------------------

OLD_HAUL <- racebase_haul0 |> ## Haul events
  dplyr::rename(dplyr::any_of(lookup)) |>
  dplyr::mutate(SRVY = dplyr::case_when(
    region == "BS" & stratum %in% 
      c(1, 2, 3, 4, 5, 11, 12, 13, 14, 15, 21, 22, 23, 24, 25, 
        31, 32, 33, 34, 35, 41, 42, 43, 44, 45, 51, 52, 53, 54, 55, 
        61, 62, 63, 64, 65, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 
        110, 120, 130, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 
        210, 220, 230, 240, 250, 301, 302, 303, 304, 305, 306, 307, 308, 309, 
        401, 402, 403, 404, 405, 406, 407, 408, 409, 
        501, 502, 503, 504, 505, 506, 507, 508, 509) ~ "BSS",
    region == "BS" & stratum %in% c(70, 71, 81) ~ "NBS",
    region == "BS" & stratum %in% c(50, 32, 31, 42, 10, 20, 43, 62, 41, 61, 90, 82, 81, 70, 71) ~ "EBS",
    TRUE ~ region)) |>
  dplyr::filter(!is.na(stratum)) |>
  dplyr::filter(!is.na(station)) |>
  # dplyr::select(hauljoin, stratum, station, SRVY, cruise) |>
  dplyr::distinct()

## CPUE by station data --------------------------------------------------------

OLD_CPUE_STATION <- dplyr::bind_rows(
  # crab EBS + NBS data
  # dplyr::left_join(
  # x = 
  crab_gap_ebs_nbs_crab_cpue0 |> 
    dplyr::rename(dplyr::any_of(lookup)) |>
    dplyr::mutate(
      # hauljoin = hauljoin*-1,
      cpue_kgkm2 = cpue_kgkm2/100, 
      cpue_nokm2 = cpue_nokm2/100,
      file = "crab.gap_ebs_nbs_crab_cpue"), 
  # y = haul, 
  # by = "hauljoin"), 
  # NBS data
  nbsshelf_nbs_cpue0 |> 
    dplyr::rename(dplyr::any_of(lookup)) |>
    dplyr::mutate(
      # SRVY = "NBS", 
      file = "nbsshelf.nbs_cpue"), 
  # EBS data
  ebsshelf_ebsshelf_cpue0 |> 
    dplyr::rename(dplyr::any_of(lookup)) |>
    dplyr::mutate(
      # SRVY = "EBS", 
      file = "ebsshelf.ebsshelf_cpue"), 
  
  # BSS data
  # ebsslope_cpuelistrnk0 |> 
  #   dplyr::rename(dplyr::any_of(lookup), 
  #                 cpue_kgkm2 = cpue) |> # I think? Realy no count data? only has data from 2014:2016, so incomplete
  #   dplyr::mutate(
  #     cpue_kgkm2 = cpue_kgkm2/100, # I think
  #     # cpue_nokm2 = cpue_nokm2/100,
  #     SRVY = "ESS",
  #     file = "ebsslope.cpuelistrnk"), 
  hoffj_cpue_ebsslope_pos0 |> # ESS CPUE data
    dplyr::rename(dplyr::any_of(lookup)) |> # has data fro 2002:2016
    dplyr::mutate(
      # SRVY = "BSS",
      cpue_kgkm2 = cpue_kgkm2/100,
      cpue_nokm2 = cpue_nokm2/100,
      file = "hoffj.cpue_ebsslope_pos"), # PROBLEM
  
  # GOA data
  goa_cpue0 |>
    dplyr::rename(dplyr::any_of(lookup)) |>
    dplyr::mutate(
      # SRVY = "GOA",
      file = "goa.cpue"), # GOA CPUE data
  # AI data
  ai_cpue0 |>
    dplyr::rename(dplyr::any_of(lookup)) |>
    dplyr::mutate(
      # SRVY = "AI", # AI CPUE data
      file = "ai.cpue") )  |> 
  dplyr::group_by(hauljoin, species_code, file) |> 
  dplyr::summarise(cpue_kgkm2 = sum(cpue_kgkm2, na.rm = TRUE), 
                   cpue_nokm2 = sum(cpue_nokm2, na.rm = TRUE), 
                   weight_kg = sum(weight_kg, na.rm = TRUE), 
                   count = sum(count, na.rm = TRUE)) |> 
  dplyr::ungroup() |> 
  dplyr::select(#SRVY, year, 
    species_code, hauljoin, 
    cpue_kgkm2, cpue_nokm2, weight_kg, count, 
    file) 


## Taxonomics ------------------------------------------------------------------

googledrive::drive_download(file = googledrive::as_id("https://docs.google.com/spreadsheets/d/1BF9cBLtGkFt9TYttp2wEyph_fI3yMY8fHjp_ckJ9pQ8"),
                            type = "csv",
                            overwrite = TRUE,
                            path = paste0(dir_data, "/taxonomy_worms.csv"))

OLD_TAXONOMICS_WORMS <- readr::read_csv(file = paste0(dir_data, "/taxonomy_worms.csv")) |> 
  dplyr::mutate(database_id = ifelse(database == "ITIS", NA, database_id), 
                database = ifelse(database == "ITIS", NA, database), 
                database = ifelse(is.na(database_id), NA, database))

OLD_TAXONOMICS_ITIS <- readr::read_csv(file = paste0(dir_data, "/2023_taxonomy_updates_itis.csv")) |> 
  dplyr::mutate(database_id = ifelse(database == "WORMS", NA, database_id), 
                database = ifelse(database == "WORMS", NA, database), 
                database = ifelse(is.na(database_id), NA, database))

OLD_V_TAXONOMICS <- dplyr::full_join(
  OLD_TAXONOMICS_WORMS |> 
    dplyr::select(species_code, scientific_name = accepted_name, common_name, worms = database_id), 
  OLD_TAXONOMICS_ITIS |> 
    dplyr::select(species_code, itis = database_id), 
  by = "species_code")


OLD_TAXONOMICS_TYPECODE <- data.frame(
  market_code = c(1:10), 
  market = c("egg", 
             "juvenile", 
             "adult", 
             "egg case", 
             "immature", 
             "mature", 
             "larvae", 
             NA, NA, NA)
)

## Taxon Confidence -------------------------------------------------------------

df.ls <- list()
a <- list.files(path = paste0("./data/TAXON_CONFIDENCE/"))
# a <- a[a != "OLD_TAXON_CONFIDENCE.csv"]
for (i in 1:length(a)){
  print(a[i])
  b <- readxl::read_xlsx(path = paste0("./data/TAXON_CONFIDENCE/", a[i]), 
                         skip = 1, col_names = TRUE) |> 
    dplyr::select(where(~!all(is.na(.x)))) |> # remove empty columns
    janitor::clean_names() |> 
    dplyr::rename(species_code = code)
  if (sum(names(b) %in% "quality_codes")>0) {
    b$quality_codes<-NULL
  }
  b <- b |> 
    tidyr::pivot_longer(cols = starts_with("x"), 
                        names_to = "year", 
                        values_to = "taxon_confidence") |> 
    dplyr::mutate(year = gsub(pattern = "[a-z]", 
                              replacement = "", 
                              x = year), 
                  year = gsub(pattern = "_0", replacement = "", 
                              x = year), 
                  year = as.numeric(year)) |> 
    dplyr::distinct()
  
  cc <- strsplit(x = gsub(x = gsub(x = a[i], 
                                   pattern = "Taxon_confidence_", replacement = ""), 
                          pattern = ".xlsx", 
                          replacement = ""), 
                 split = "_")[[1]]
  
  if (length(cc) == 1) {
    b$SRVY <- cc
  } else {
    bb <- data.frame()
    for (ii in 1:length(cc)){
      bbb <- b
      bbb$SRVY <- cc[ii]
      bb <- rbind.data.frame(bb, bbb)
    }
    b<-bb
  }
  df.ls[[i]]<-b
  names(df.ls)[i]<-a[i]
}

# Quality Codes
# 1 – High confidence and consistency.  Taxonomy is stable and reliable at this 
#     level, and field identification characteristics are well known and reliable.
# 2 – Moderate confidence.  Taxonomy may be questionable at this level, or field  
#     identification characteristics may be variable and difficult to assess consistently.
# 3 – Low confidence.  Taxonomy is incompletely known, or reliable field  
#     identification characteristics are unknown.

OLD_TAXON_CONFIDENCE <- dplyr::bind_rows(df.ls) |> 
  dplyr::mutate(taxon_confidence_code = taxon_confidence, 
                taxon_confidence = dplyr::case_when(
                  taxon_confidence_code == 1 ~ "High",
                  taxon_confidence_code == 2 ~ "Moderate",
                  taxon_confidence_code == 3 ~ "Low", 
                  TRUE ~ "Unassessed")) 

# fill in OLD_TAXON_CONFIDENCE with, if missing, the values from the year before

cruises <- race_data_v_cruises0 |> #read.csv("./data/race_data_v_cruises.csv") |> 
  janitor::clean_names() |> 
  dplyr::left_join(
    x = surveys, # a data frame of all surveys and survey_definition_ids we want included in the public data, created in the run.R script
    y = ., 
    by  = c("survey_definition_id"))
comb1 <- unique(cruises[, c("SRVY", "year")] )
comb2 <- unique(OLD_TAXON_CONFIDENCE[, c("SRVY", "year")])
# names(comb2) <- names(comb1) <- c("SRVY", "year")
comb1$comb <- paste0(comb1$SRVY, "_", comb1$year)
comb2$comb <- paste0(comb2$SRVY, "_", comb2$year)
comb <- strsplit(x = setdiff(comb1$comb, comb2$comb), split = "_")

OLD_TAXON_CONFIDENCE <- dplyr::bind_rows(
  OLD_TAXON_CONFIDENCE, 
  OLD_TAXON_CONFIDENCE |> 
    dplyr::filter(
      SRVY %in% sapply(comb,"[[",1) &
        year == 2021) |> 
    dplyr::mutate(year = 2022)) |> 
  dplyr::select(-common_name, -scientific_name)
# dplyr::rename(taxon_confidence = taxon_confidence, 
#               taxon_confidence_code = taxon_confidence_code)

OLD_TAXON_CONFIDENCE_metadata_table <- paste0(
  "The quality and specificity of field identifications for many taxa have 
    fluctuated over the history of the surveys due to changing priorities and resources. 
    The matrix lists a confidence level for each taxon for each survey year 
    and is intended to serve as a general guideline for data users interested in 
    assessing the relative reliability of historical species identifications 
    on these surveys. This dataset includes an identification confidence matrix 
    for all fishes and invertebrates identified ", 
  metadata_sentence_survey_institution, 
  metadata_sentence_legal_restrict,  
  metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated)

# Upload data to oracle! -------------------------------------------------------

# Final all objects with "OLD_" prefix, save them and their table metadata, and add them to the que to save to oracle
a <- apropos("OLD_") 
a <- a[!grepl(pattern = "_metadata_table", x = a)]
file_paths <- data.frame(file_path = NA, metadata_table = NA)

for (i in 1:length(a)) {
  
  write.csv(x = get(a[i]), file = paste0(dir_out, a[i], ".csv"))
  
  # find or create table metadat for table
  metadata_table <- ifelse(exists(paste0(a[i], "_metadata_table", collapse="\n")), 
                           get(paste0(a[i], "_metadata_table", collapse="\n")), 
                           paste0(metadata_sentence_github, 
                                  metadata_sentence_last_updated))
  
  readr::write_lines(x = metadata_table, 
                     file = paste0(dir_out, a[i], "_metadata_table.txt", collapse="\n"))
  
  file_paths <- dplyr::add_row(.data = file_paths, 
                               file_path = paste0(dir_out, a[i], ".csv"),
                               metadata_table = metadata_table)
}

file_paths <- file_paths[-1,]

# Save old tables to Oracle
for (i in 1:nrow(file_paths)) {
  oracle_upload(
    file_path = file_paths$file_path[i], 
    metadata_table = file_paths$metadata_table[i], 
    metadata_column = gap_products_metadata_column0, 
    channel = channel_products, 
    schema = "GAP_PRODUCTS")
}

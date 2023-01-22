#' ---------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-11-08
#' Notes: 
#' ---------------------------------------------

# The surveys we will cover in this data are: 
surveys <- 
  data.frame(survey_definition_id = c(143, 98, 47, 52, 78), 
             SRVY = c("NBS", "EBS", "GOA", "AI", "BSS"), 
             SRVY_long = c("northern Bering Sea", 
                           "eastern Bering Sea", 
                           "Gulf of Alaska", 
                           "Aleutian Islands", 
                           "Bering Sea Slope") )

# Tables to create
# Get stomach lab to post tables to oracle
# report back requirements from special projects
# are ai goa grids used correctly
# cpue_other, and *_other tables need to be incorporated into production tables?
# what is up with the aluetians schema?

source('./code/functions.R')
source("https://raw.githubusercontent.com/afsc-gap-products/metadata/main/code/functions_oracle.R")
dir_data <- paste0(getwd(), "/data/")
dir_out <- paste0(getwd(), "/output/", Sys.Date(), "/")
dir.create(dir_out)

# This has a specific username and password because I DONT want people to have access to this!
# source("C:/Users/emily.markowitz/Work/Projects/ConnectToOracle.R")
# source("C:/Users/emily.markowitz/Documents/Projects/ConnectToOracle.R")
source("Z:/Projects/ConnectToOracle.R")

# I set up a ConnectToOracle.R that looks like this: 
#   
#   PKG <- c("RODBC")
# for (p in PKG) {
#   if(!require(p,character.only = TRUE)) {  
#     install.packages(p)
#     require(p,character.only = TRUE)}
# }
# 
# channel<-odbcConnect(dsn = "AFSC",
#                      uid = "USERNAME", # change
#                      pwd = "PASSWORD", #change
#                      believeNRows = FALSE)
# 
# odbcGetInfo(channel)
# 
# ## OR PROMPT CODE TO ASK FOR CONNECTION INFO
# 
# # Define RODBC connection to ORACLE
# get.connected <- function(schema='AFSC'){(echo=FALSE)
#   username <- getPass(msg = "Enter your ORACLE Username: ")
#   password <- getPass(msg = "Enter your ORACLE Password: ")
#   channel  <- RODBC::odbcConnect(paste(schema),paste(username),paste(password), believeNRows=FALSE)
# }
# # Execute the connection
# channel <- get.connected()

# Download current estimates data from oracle ----------------------------------

# The current state of affairs
locations <- c( # data pulled from Oracle for these figures:
  "RACEBASE.HAUL",
  "RACE_DATA.V_CRUISES", 
  
  # metadata
  "GAP_PRODUCTS.METADATA_COLUMN", 
  "GAP_PRODUCTS.METADATA_TABLE", 
  
  # CPUE
  "EBSSHELF.EBSSHELF_CPUE", # "HAEHNR.CPUE_EBS_PLUSNW", 
  "NBSSHELF.NBS_CPUE", # "HAEHNR.CPUE_NBS", 
  # "HAEHNR.cpue_nbs",
  # "HAEHNR.cpue_ebs_plusnw",
  # "HAEHNR.cpue_ebs_plusnw_grouped",
  "AI.CPUE", 
  "GOA.CPUE",
  # "EBSSLOPE.CPUELISTRNK", # 
  "HOFFJ.CPUE_EBSSLOPE_POS", # needs to be peer reviewed
  "crab.gap_ebs_nbs_crab_cpue", 
  
  # BIOMASS/ABUNDANCE
  "EBSSHELF.EBSSHELF_BIOMASS_PLUSNW", # "HAEHNR.biomass_ebs_plusnw",# "HAEHNR.biomass_ebs_plusnw_safe", # no longer used
  "EBSSHELF.EBSSHELF_BIOMASS_STANDARD", # "HAEHNR.biomass_ebs_plusnw_grouped",
  "NBSSHELF.NBS_BIOMASS",     # "HAEHNR.biomass_nbs_safe", 
  "AI.BIOMASS_STRATUM",
  "AI.BIOMASS_TOTAL", 
  "AI.BIOMASS_AREA", 
  "AI.BIOMASS_AREA_DEPTH", 
  "AI.BIOMASS_BY_LENGTH", 
  "AI.BIOMASS_DEPTH", 
  "AI.BIOMASS_INPFC", 
  "AI.BIOMASS_INPFC_DEPTH", 
  "GOA.BIOMASS_AREA",
  # "GOA.BIOMASS_AREA_DEPTH",
  "GOA.BIOMASS_STRATUM",
  "GOA.BIOMASS_TOTAL", 
  "GOA.BIOMASS_BY_LENGTH",
  "GOA.BIOMASS_DEPTH",
  "GOA.BIOMASS_INPFC",
  "GOA.BIOMASS_INPFC_DEPTH",
  "EBSSLOPE.BIOMASS_EBSSLOPE", 
  "EBSSLOPE.MEANCPUE",
  "EBSSLOPE.CPUE_ALL", 
  
  # length data
  "RACE_DATA.V_EXTRACT_FINAL_LENGTHS", 
  "CRAB.EBSCRAB",
  "CRAB.EBSCRAB_NBS",
  
  # Age comps
  "EBSSHELF.EBSSHELF_AGECOMP_PLUSNW", 
  "EBSSHELF.EBSSHELF_AGECOMP_STANDARD", #  "HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM",
  "NBSSHELF.NBS_AGECOMP", #  "HAEHNR.AGECOMP_NBS_STRATUM",
  "AI.AGECOMP_STRATUM", 
  "AI.AGECOMP_TOTAL",
  "GOA.AGECOMP_STRATUM",
  "GOA.AGECOMP_TOTAL",
  # We currently do not know where BSS age comp data are/were ever made?
  
  # size comp - the extrapolated size distributions of each fish
  "EBSSHELF.EBSSHELF_SIZECOMP_PLUSNW",   # "HAEHNR.sizecomp_ebs_plusnw_stratum", 
  "EBSSHELF.EBSSHELF_SIZECOMP_STANDARD", 
  "NBSSHELF.NBS_SIZECOMP",  # "HAEHNR.sizecomp_nbs_stratum",

  # "HAEHNR.sizecomp_ebs_plusnw_stratum_grouped",
  "AI.SIZECOMP_STRATUM", 
  "AI.SIZECOMP_TOTAL", 
  "AI.SIZECOMP_AREA", 
  "AI.SIZECOMP_AREA_DEPTH",
  "AI.SIZECOMP_DEPTH",
  "AI.SIZECOMP_INPFC", 
  "AI.SIZECOMP_INPFC_DEPTH", 
  "AI.STATION_ALLOCATION", 
  "AI.STATIONS_3NM",   
  "GOA.SIZECOMP_STRATUM",
  "GOA.SIZECOMP_TOTAL",
  "GOA.SIZECOMP_AREA",
  "GOA.SIZECOMP_DEPTH",
  # "GOA.SIZECOMP_AREA_DEPTH",
  "GOA.SIZECOMP_DEPTH",
  "GOA.SIZECOMP_INPFC",
  "GOA.SIZECOMP_INPFC_DEPTH",
  "GOA.STATION_ALLOCATION",
  "GOA.STATIONS_3NM", 
  "GOA.GOA_GRID", 
  "crab.gap_ebs_nbs_abundance_biomass", 
  "EBSSLOPE.SIZECOMP_EBSSLOPE", # "HOFFJ.SIZECOMP_EBSSLOPE", # needs to be peer reviewed
  
  # Strata
  "RACEBASE.STRATUM", 
  "GOA.GOA_STRATA",
  "EBSSHELF.EBSSHELF_STRATA", 
  "NBSSHELF.NBS_STRATA",  
  # "EBSSLOPE.STRATLIST" # don't have access to yet
  
  # Station
  "AI.AIGRID_GIS",
  "GOA.GOAFRID", 
  "GOA.GOAGRID_GIS", 
  "GOA.GOA_SURVEY_GRIDPONTS"
)


# locations <- c(
#   "EBSSLOPE.BIOMASS_EBSSLOPE",
#   "EBSSLOPE.CPUE_ALL", # CPUE by station
#   "EBSSLOPE.CPUELISTRNK",
#   "EBSSLOPE.MEANCPUE",
#   "EBSSLOPE.SIZECOMP_EBSSLOPE"
#   # "EBSSLOPE.STRATLIST"
# # "EBSSLOPE.HAUL_EBSSLOPE
# # EBSSLOPE.HAULCOUNT
#   )

# Download data from oracle ----------------------------------------------------

if (FALSE) {
  oracle_dl(
    locations = locations, 
    channel = channel, 
    dir_out = dir_data)
}

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
  by = "year")

OLD_AFFILIATIONS <- readxl::read_xlsx(path = paste0(dir_data, "0_special_projects.xlsx"), 
                                      sheet = "affiliations", skip = 1) %>% 
  dplyr::rename("agency0" = "agency")

OLD_OTHER_FIELD_COLLECTIONS <- readxl::read_xlsx(path = paste0(dir_data, "0_other_field_collections.xlsx"), 
                                                 sheet = "Sheet1", skip = 1)

OLD_COLLECTION_SCHEME <- readxl::read_xlsx(path = paste0(dir_data, "0_collection_scheme.xlsx"), 
                                           sheet = "Sheet1", skip = 1) %>% 
  dplyr::filter(year > 2017)

# Wrangle data -----------------------------------------------------------------

## Table metdata ---------------------------------------------------------------

link_repo <- "https://github.com/afsc-gap-products/gap_products"

for (i in 1:nrow(gap_products_metadata_table0)){
  assign(x = paste0("metadata_sentence_", gap_products_metadata_table0$metadata_sentence_type[i]), 
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
  count = "number_fish", 
  
  area = "regulatory_area_name", 
  area = "summary_area", # may be an stratum ID, not an actual depth
  area_depth = "summary_area_depth", # may be an stratum ID, not an actual depth
  area_depth = "summary_depth", 
  
  count_number = "number_count",  # what is this?
  
  count_length = "lencount", 
  count_length = "len_count",
  count_length = "length_count",
  
  count_catch = "catchcount", 
  count_catch = "catch_count", 
  count_catch = "count_catch", 
  # count_catch = "number_count",
  
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
  
  abundance = "area_pop", 
  abundance = "stratum_pop", 
  abundance = "total_pop", 
  abundance = "population", 
  
  abundance_var = "varpop", 
  abundance_var = "pop_var", 
  
  biomass_ci_lower = "min_biomass", # Is this right?
  biomass_ci_lower = "biomass_lower_ci", 
  
  biomass_ci_upper = "max_biomass",  # is this right?
  biomass_ci_upper = "biomass_upper_ci", 
  
  biomass_df = "degreef_biomass",
  
  abundance_ci_lower = "min_pop", # Is this right?
  abundance_ci_lower = "abundance_lower_ci", 
  
  abundance_ci_upper = "max_pop", 
  abundance_ci_upper = "abundance_upper_ci", 
  
  abundance_df = "degreef_pop", 
  
  area_depth = "summary_area_depth", 
  area_depth = "summary_depth", 
  
  area = "summary_area", 
  
  value = "length", 
  area = "regulatory_area_name", 

  length_mean = "meanlen", 
  length_mean = "mean_length", 
  
  length_sd = "sdev", 
  length_sd = "standard_deviation")

## Haul data -------------------------------------------------------------------

OLD_HAUL <- racebase_haul0 %>% ## Haul events
  dplyr::rename(dplyr::any_of(lookup)) %>%
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
    TRUE ~ region)) %>%
  dplyr::filter(!is.na(stratum)) %>%
  dplyr::filter(!is.na(station)) %>%
  dplyr::select(hauljoin, stratum, station, SRVY, cruise) %>%
  dplyr::distinct()

## CPUE by station data --------------------------------------------------------

OLD_CPUE_STATION <- dplyr::bind_rows(
  # crab EBS + NBS data
  # dplyr::left_join(
  # x = 
  crab_gap_ebs_nbs_crab_cpue0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      # hauljoin = hauljoin*-1,
      cpue_kgkm2 = cpue_kgkm2/100, 
      cpue_nokm2 = cpue_nokm2/100,
      file = "crab.gap_ebs_nbs_crab_cpue"), 
  # y = haul, 
  # by = "hauljoin"), 
  # NBS data
  nbsshelf_nbs_cpue0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      # SRVY = "NBS", 
      file = "nbsshelf.nbs_cpue"), 
  # EBS data
  ebsshelf_ebsshelf_cpue0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      # SRVY = "EBS", 
      file = "ebsshelf.ebsshelf_cpue"), 
  
  # BSS data
  # ebsslope_cpuelistrnk0 %>% 
  #   dplyr::rename(dplyr::any_of(lookup), 
  #                 cpue_kgkm2 = cpue) %>% # I think? Realy no count data? only has data from 2014:2016, so incomplete
  #   dplyr::mutate(
  #     cpue_kgkm2 = cpue_kgkm2/100, # I think
  #     # cpue_nokm2 = cpue_nokm2/100,
  #     SRVY = "ESS",
  #     file = "ebsslope.cpuelistrnk"), 
  hoffj_cpue_ebsslope_pos0 %>% # ESS CPUE data
    dplyr::rename(dplyr::any_of(lookup)) %>% # has data fro 2002:2016
    dplyr::mutate(
      # SRVY = "BSS",
      cpue_kgkm2 = cpue_kgkm2/100,
      cpue_nokm2 = cpue_nokm2/100,
      file = "hoffj.cpue_ebsslope_pos"), # PROBLEM
  
  # GOA data
  goa_cpue0 %>%
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      # SRVY = "GOA",
      file = "goa.cpue"), # GOA CPUE data
  # AI data
  ai_cpue0 %>%
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      # SRVY = "AI", # AI CPUE data
      file = "ai.cpue") )  %>% 
  dplyr::group_by(hauljoin, species_code, file) %>% 
  dplyr::summarise(cpue_kgkm2 = sum(cpue_kgkm2, na.rm = TRUE), 
                   cpue_nokm2 = sum(cpue_nokm2, na.rm = TRUE), 
                   weight_kg = sum(weight_kg, na.rm = TRUE), 
                   count = sum(count, na.rm = TRUE)) %>% 
  dplyr::ungroup() %>% 
  dplyr::select(#SRVY, year, 
    species_code, hauljoin, 
    cpue_kgkm2, cpue_nokm2, weight_kg, count, 
    file) 

## Biomass and Abundance data --------------------------------------------------

OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM <- dplyr::bind_rows(
  # crab EBS + NBS data
  dplyr::left_join(
  x = crab_gap_ebs_nbs_abundance_biomass0 %>% 
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      file = "crab.gap_ebs_nbs_abundance_biomass", 
      stratum = 999) %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  y = dplyr::bind_rows(
    crab_ebscrab0 %>%
      dplyr::filter(!(cruise %in% unique(crab_ebscrab_nbs0$cruise))) %>% # there may be some nbs data in the ebs (201002)%>% 
      dplyr::mutate(file = "CRAB.EBSCRAB", 
                    SRVY = "EBS") , 
    crab_ebscrab_nbs0 %>% 
      dplyr::mutate(file = "CRAB.EBSCRAB_NBS", 
                    SRVY = "NBS")) %>% 
    dplyr::filter(!is.na(length) & length != 999 & !is.na(cruise)) %>% 
    dplyr::mutate(
      year = as.numeric(substr(cruise, start = 1, stop = 4)), 
      length = dplyr::case_when(
                    species_code %in% c(68580, 68590, 68560) ~ width,  # "snow crab"
                    TRUE ~ length),
                  frequency = 1)  %>%
    dplyr::group_by(SRVY, species_code, year) %>%
    dplyr::summarise(count_length = n()) %>% 
    dplyr::ungroup(), 
  by = c("SRVY", "species_code", "year")), 
  
  # NBS data
  nbsshelf_nbs_biomass0  %>%
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::filter(!(species_code %in% c(69323, 69322, 68580, 68560))) %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "NBS", 
      file = "nbsshelf.nbs_biomass"),     
  # haehnr_biomass_nbs_safe0 %>% 
  #   dplyr::mutate(
  #     area_type = "index",
  #     area = "index", 
  #     SRVY = "NBS", 
  #     file = "haehnr.biomass_nbs_safe") %>%
  #   dplyr::rename(dplyr::any_of(lookup)),  
  
  # EBS data
  ebsshelf_ebsshelf_biomass_standard0  %>% 
    dplyr::filter(!(species_code %in% c(69323, 69322, 68580, 68560))) %>%
    dplyr::mutate(
      area_type = "standard",
      area = "index",
      # SRVY = "EBS",
      file = "ebsshelf.ebsshelf_agecomp_standard") %>%
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      SRVY = "EBS"),
  ebsshelf_ebsshelf_biomass_plusnw0  %>% 
    dplyr::filter(!(species_code %in% c(69323, 69322, 68580, 68560))) %>%
    dplyr::mutate(
      area_type = "index",
      area = "index",
      # SRVY = "EBS",
      file = "ebsshelf.ebsshelf_biomass_plusnw") %>%
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      SRVY = "EBS"),
  # haehnr_biomass_ebs_plusnw_grouped0 %>% 
  #   dplyr::mutate(
  #     area_type = "index",
  #     area = "index", 
  #     SRVY = "EBS", 
  #     file = "haehnr.biomass_ebs_plusnw_grouped") %>%
  #   dplyr::rename(dplyr::any_of(lookup)),  
  # haehnr_biomass_ebs_plusnw0 %>% 
  #   dplyr::mutate(
  #     area_type = "index",
  #     area = "index", 
  #     SRVY = "EBS", 
  #     file = "haehnr.biomass_ebs_plusnw") %>%
  #   dplyr::rename(dplyr::any_of(lookup)),  
  
  # BSS
  ebsslope_biomass_ebsslope0  %>%
    dplyr::mutate(
      # SRVY = "BSS", 
      area_type = "index",
      area = "index", 
      file = "ebsslope.biomass_ebsslope") %>%
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(
      SRVY = "BSS"),
  # ebsslope_cpue_all0
  
  # GOA data
  goa_biomass_total0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      # SRVY = "GOA", 
      file = "goa.biomass_total") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_stratum0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      # SRVY = "GOA",
      file = "goa.biomass_stratum") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_area0 %>%
    dplyr::mutate(
      # SRVY = "GOA", 
      file = "goa.biomass_area", 
      area_type = "regulatory") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_by_length0 %>%
    dplyr::mutate(
      # SRVY = "GOA", 
      area_type = "index", # is this right?
      area = "length", 
      file = "goa.biomass_by_length") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_depth0 %>%
    dplyr::mutate(
      # SRVY = "GOA", 
      area_type = "index", # is this right?
      area = "depth",
      file = "goa.biomass_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_inpfc0 %>%
    dplyr::mutate(
      # SRVY = "GOA", 
      file = "goa.biomass_inpfc", 
      area_type = "inpfc", 
      summary_area = as.character(summary_area)) %>% # is this right?/make sense
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_inpfc_depth0 %>%
    dplyr::mutate(
      # SRVY = "GOA", 
      file = "goa.biomass_inpfc_depth", 
      area_type = "inpfc") %>% 
    dplyr::rename(dplyr::any_of(lookup)),
  
  # AI data
  ai_biomass_total0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      # SRVY = "AI", 
      file = "ai.biomass_total") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_stratum0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      # SRVY = "AI", 
      file = "ai.biomass_stratum")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_area0 %>%
    dplyr::mutate(
      # SRVY = "AI", 
      file = "ai.biomass_area", 
      area_type = "regulatory")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_area_depth0 %>%
    dplyr::mutate(
      # SRVY = "AI", 
      file = "ai.biomass_area_depth", 
      area_type = "regulatory") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_by_length0 %>%
    dplyr::mutate(
      # SRVY = "AI", 
      area_type = "index", # is this right?
      area = "length", 
      file = "ai.biomass_by_length")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_depth0 %>%
    dplyr::mutate(
      # SRVY = "AI", 
      area_type = "index", # is this right?
      area = "depth", 
      file = "ai.biomass_depth")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_inpfc_depth0 %>% # are there inpfc regions?
    dplyr::mutate(
      # SRVY = "AI", 
      file = "ai.biomass_inpfc_depth", 
      area_type = "inpfc") %>% 
    dplyr::rename(dplyr::any_of(lookup))
)  %>% 
  dplyr::select(sort(tidyselect::peek_vars())) %>%
  dplyr::select(-common_name, -species_name, -region, -SRVY)

## Comp data -------------------------------------------------------------------

# length comps
size_COMP_AGE_SIZE_STRATUM <- dplyr::bind_rows(
  # NBS data
  nbsshelf_nbs_sizecomp0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "NBS", 
                  area_type = "index", 
                  file = "nbsshelf.nbs_sizecomp") , 
  # haehnr_sizecomp_nbs_stratum0 %>% 
  #   dplyr::mutate(SRVY = "NBS", 
  #                 area_type = "index", 
  #                 file = "haehnr.sizecomp_nbs_stratum") %>% 
  #   dplyr::rename(dplyr::any_of(lookup)) , 
  
  # EBS data
  
  ebsshelf_ebsshelf_sizecomp_plusnw0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "EBS",
                  area_type = "index", # plusnw
                  file = "ebsshelf.ebsshelf_sizecomp_plusnw"),
  ebsshelf_ebsshelf_sizecomp_standard0 %>%
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "EBS",
                  area_type = "standard", # or should this be index? and area = "standard?
                  file = "ebsshelf.ebsshelf_sizecomp_standard"),
  # haehnr_sizecomp_ebs_plusnw_stratum0 %>% 
  #   dplyr::mutate(SRVY = "EBS", 
  #                 file = "haehnr.sizecomp_ebs_plusnw_stratum") %>% 
  #   dplyr::rename(dplyr::any_of(lookup)), 
  # haehnr_sizecomp_ebs_plusnw_stratum_grouped0 %>% 
  #   dplyr::mutate(SRVY = "EBS", 
  #                 area_type = "index",
  #                 file = "haehnr.sizecomp_ebs_plusnw_stratum_grouped") %>% 
  #   dplyr::rename(dplyr::any_of(lookup)),
  # BSS data
  ebsslope_sizecomp_ebsslope0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "BSS", 
                  area_type = "index",
                  file = "ebsslope.sizeecomp_ebsslope"), 
  
  # hoffj_sizecomp_ebsslope0 %>% 
  #   dplyr::mutate(SRVY = "BSS", 
  #                 area_type = "index",
  #                 file = "hoffj.sizecomp_ebsslope") %>% 
  #   dplyr::rename(dplyr::any_of(lookup)),   
  # GOA data
  goa_sizecomp_stratum0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "GOA",
                  area_type = "index", 
                  file = "goa.sizecomp_stratum"), 
  goa_sizecomp_total0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "index",
                  file = "goa.sizecomp_total") %>% 
    dplyr::rename(stratum = area), 
  # goa_sizecomp_area_depth0
  goa_sizecomp_area0  %>% 
    dplyr::rename(dplyr::any_of(lookup))%>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "regulatory", 
                  file = "goa.sizecomp_area"), 
  goa_sizecomp_depth0  %>% 
    dplyr::rename(dplyr::any_of(lookup))%>% 
    dplyr::mutate(SRVY = "GOA", 
                  file = "goa.sizecomp_depth"), 
  goa_sizecomp_inpfc0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "inpfc", 
                  file = "goa.sizecomp_inpfc", 
                  area = as.character(area)), 
  goa_sizecomp_inpfc_depth0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "inpfc", 
                  file = "goa.sizecomp_inpfc_depth"), 
  # AI data
  ai_sizecomp_stratum0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "AI",
                  area_type = "index", 
                  file = "ai.sizecomp_stratum"),
  ai_sizecomp_total0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(SRVY = "AI", 
                  area_type = "index",
                  file = "ai.sizecomp_total") %>% 
    dplyr::rename(stratum = area), 
  ai_sizecomp_area0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "regulatory", 
                  file = "ai.sizecomp_area"), 
  ai_sizecomp_area_depth0 %>% 
    dplyr::mutate(#SRVY = "AI", 
                  area_type = "regulatory", 
                  file = "ai.sizecomp_area_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_depth0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "index", # is this right?
                  file = "ai.sizecomp_depth"), 
  ai_sizecomp_inpfc_depth0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "inpfc", 
                  file = "ai.sizecomp_inpfc_depth"), 
  ai_sizecomp_inpfc0  %>% 
    dplyr::rename(dplyr::any_of(lookup))%>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "inpfc", 
                  area = as.character(area), 
                  file = "ai.sizecomp_inpfc")
) %>% 
  # dplyr::select(SRVY, year, stratum, species_code, area, area_type, depth, length, 
  #               males, females, unsexed, file) %>%
  dplyr::mutate(comp = "length") %>% 
  tidyr::pivot_longer( # rearrange data
    data = ., 
    cols = c("males", "females", "unsexed"), 
    names_to = "sex", 
    values_to = "pop") 

# age comps
age_COMP_AGE_SIZE_STRATUM <- dplyr::bind_rows(
  dplyr::bind_rows(
    # EBS data
    # haehnr_agecomp_ebs_plusnw_stratum0 %>%
    #   dplyr::mutate(
    #     SRVY = "EBS", 
    #     file = "haehnr.agecomp_ebs_plusnw_stratum"), 
    ebsshelf_ebsshelf_agecomp_plusnw0 %>% 
      dplyr::mutate(
        SRVY = "EBS", 
        area_type = "index", # plusnw
        file = "ebsshelf.ebsshelf_agecomp_plusnw"), 
    ebsshelf_ebsshelf_agecomp_standard0  %>% 
      dplyr::rename(dplyr::any_of(lookup)) %>%
      dplyr::mutate(
        SRVY = "EBS", 
        area_type = "standard", # or should this be index? and area = "standard?
        file = "ebsshelf.ebsshelf_agecomp_standard"),
    # NBS data
    # haehnr_agecomp_nbs_stratum0 %>% 
    #   dplyr::mutate(
    #     SRVY = "NBS", 
    #     file = "haehnr.agecomp_nbs_stratum"), 
    nbsshelf_nbs_agecomp0  %>% 
      dplyr::rename(dplyr::any_of(lookup)) %>% 
      dplyr::mutate(
        SRVY = "NBS", 
        area_type = "index", 
        file = "nbsshelf.nbs_agecomp"), 
    # No BSS data
    # AI data
    ai_agecomp_total0  %>%  # only totals because sample size is too small
      dplyr::rename(dplyr::any_of(lookup)) %>%
      dplyr::mutate(
        SRVY = "AI", 
        area_type = "index", 
        file = "ai.agecomp_total"), 
    # GOA data
    goa_agecomp_total0  %>% # only totals because sample size is too small
      dplyr::rename(dplyr::any_of(lookup)) %>% 
      dplyr::mutate(
        SRVY = "GOA", 
        area_type = "index", 
        file = "goa.agecomp_total")) %>%
    
    dplyr::rename(value = age, 
                  pop = agepop ) %>% 
    # dplyr::select(SRVY, species_code, year, value, sex, pop, file) %>% 
    dplyr::mutate(comp = "age", 
                  sex = dplyr::case_when(
                    sex == 1 ~ "males", 
                    sex == 2 ~ "females", 
                    sex == 3 ~ "unsexed")) )

# comp data
OLD_COMP_AGE_SIZE_STRATUM <- dplyr::bind_rows(size_COMP_AGE_SIZE_STRATUM, 
                                              age_COMP_AGE_SIZE_STRATUM) %>%
  dplyr::filter(pop > 0 &
                  value >= 0) %>% 
  dplyr::mutate(sex = str_to_sentence(sex), # this will assure the order of appearance in the plot
                sex = factor(sex, 
                             levels = c("Males", "Females", "Unsexed", "Immature females", "Mature females"), 
                             labels = c("Males", "Females", "Unsexed", "Immature females", "Mature females"),
                             ordered = TRUE)#, 
                # sex_code = as.numeric(sex)
                ) %>% 
  dplyr::arrange(sex) %>% 
  dplyr::mutate(stratum = ifelse(stratum %in% c(999), 999999, stratum)) %>% 
  dplyr::select(-survey)

## Stratum data ----------------------------------------------------------------

lookup <- c(SRVY = "survey", 
            station = "stationid", 
            area_km2 = "area", 
            perimeter_km = "perimeter", 
            depth_m_min = "min_depth", 
            depth_m_max = "max_depth")

# stratum_id	Survey	stratum	stratum_type	details	stratum_desc	stratum_names	year_implimented	area	perimeter

OLD_STRATUM <- dplyr::bind_rows(
  # NBS data
  nbsshelf_nbs_strata0  %>% 
    dplyr::rename(dplyr::any_of(lookup))   %>% 
    dplyr::mutate(
      SRVY = "NBS", 
      file = "nbsshelf.nbs_strata", 
      area_type = "index", 
      area = "index", 
      stratum_type = "SHELF",
      depth_m_min = dplyr::case_when(
        stratum %in% c(70, 71) ~ 1, 
        stratum %in% c(81) ~ 50), 
      depth_m_max = dplyr::case_when(
        stratum %in% c(70, 71) ~ 50, 
        stratum %in% c(81) ~ 200)), 
  
  # EBS data
  ebsshelf_ebsshelf_strata0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(
      SRVY = "EBS", 
      file = "ebsshelf.ebsshelf_strata", 
      area_type = "index", 
      area = "index", 
      stratum_type = "SHELF", 
      depth_m_min = dplyr::case_when(
        stratum %in% c(10, 20, 999) ~ 1, 
        stratum %in% c(31, 32, 41, 42, 43, 82) ~ 50, 
        stratum %in% c(50, 61, 62, 90) ~ 100), 
      depth_m_max = dplyr::case_when(
        stratum %in% c(10, 20) ~ 50, 
        stratum %in% c(31, 32, 41, 42, 43, 82) ~ 100, 
        stratum %in% c(50, 61, 62, 90, 999) ~ 200)), 
  
  # BSS data
  
  # AI and GOA data
  goa_goa_strata0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(
      year = 2022, 
      file = "goa.goa_strata", 
      area_type = "index", 
      area = "index") %>% 
    # dplyr::select(
    #   SRVY, stratum, area_km2, perimeter, depth_m_min, depth_m_max, description, stratum_type, 
    #   summary_depth) %>% 
    dplyr::rename(area_depth = summary_depth), 
  
  goa_goa_strata0 %>% # is this nescesary, or redundant? can we just use the index areas?
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(
      year = 2022, 
      file = "goa.goa_strata", 
      area_type = "inpfc", 
      summary_area = as.numeric(summary_area)) %>% 
    # dplyr::select(
    #   SRVY, stratum, area_km2, perimeter, depth_m_min, depth_m_max, description, stratum_type, 
    #   inpfc_area, summary_area_depth, summary_depth) %>% 
    dplyr::rename(
      area_depth = summary_area_depth, 
      area = inpfc_area), # summary_area), 
  
  goa_goa_strata0 %>% # is this nescesary, or redundant? can we just use the index areas?
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(
      year = 2022, 
      file = "goa.goa_strata", 
      area_type = "regulatory") %>% 
    # dplyr::select(
    #   SRVY, stratum, area_km2, perimeter, depth_m_min, depth_m_max, description, stratum_type, 
    #   summary_area, summary_area_depth, regulatory_area_name) %>% 
    dplyr::rename(
      area_depth = summary_area_depth, 
      area = regulatory_area_name) 
  
) %>% 
  dplyr::mutate(stratum_join = cur_group_id()) %>% 
  dplyr::select(
    SRVY, year, stratum, description, area_type, area, 
    stratum_type, area_km2, perimeter_km, depth_m_min, depth_m_max, 
    auditjoin, area_depth)


##  Station Allocation (GOA/AI) ------------------------------------------------

OLD_STATION_ALLOCATION <- dplyr::bind_rows(
  ai_station_allocation0 %>% 
    dplyr::mutate(file = "ai.station_allocation"), 
  goa_station_allocation0 %>% 
    dplyr::mutate(file = "goa.station_allocation")) %>%
  dplyr::rename(SRVY = survey)

## Station data ----------------------------------------------------------------

# station	station_id	stratum_id			station_type	details	station_desc		year_implimented	area	perimeter
# "AI.AIGRID_GIS", "GOA.GOAFRID", "GOA.GOAGRID_GIS", "GOA.GOA_SURVEY_GRIDPONTS"
temp <- dplyr::bind_rows(
  # AI data
  dplyr::full_join(
    x = ai_aigrid_gis0 %>% 
      dplyr::mutate(file = "ai.aigrid_gis", 
                    SRVY = "AI"), 
    y = ai_stations_3nm0 %>% 
      dplyr::select(-area, -perimeter) %>% # TOLEDO! Why are there aigrid aigrid_id in this table? 
      dplyr::mutate(file_3nm0 = "ai_stations_3nm0", 
                    mi3 = TRUE), 
    by = c("stratum", "stationid", "aigrid_id")) %>% 
    dplyr::rename(grid_id = aigrid_id) , 
    # GOA data
    dplyr::left_join(
      x = goa_goagrid_gis0 %>% 
        dplyr::rename(grid_id = goagrid_id) %>%
        dplyr::mutate(file = "goa.goagrid_gis", 
                      SRVY = "GOA"), 
      y = goa_stations_3nm0 %>% 
        dplyr::rename(grid_id = aigrid_id) %>%
        dplyr::select(-area, -perimeter, -aigrid) %>% # TOLEDO! Why are there aigrid aigrid_id in this table? 
        dplyr::mutate(file_3nm0 = "goa_stations_3nm0", 
                      mi3 = TRUE), 
      by = c("stratum", "stationid", "grid_id")) 
) %>% 
  dplyr::rename(dplyr::any_of(lookup))

OLD_STATION <- 
  racebase_haul0 %>% 
  dplyr::rename(dplyr::any_of(lookup)) %>%
  dplyr::filter(abundance_haul == "Y", 
                haul_type == 3) %>% 
  dplyr::filter(!is.na(stratum)) %>%
  dplyr::filter(!is.na(station)) %>% 
  dplyr::mutate(
    SRVY = dplyr::case_when(
      region == "BS" & stratum %in% c(70, 71, 81) ~ "NBS", 
      region == "BS" & stratum %in% c(50, 32, 31, 42, 10, 20, 43, 62, 41, 61, 90, 82, 81, 70, 71) ~ "EBS", 
      TRUE ~ region)) %>% 
  dplyr::select(stratum, station, SRVY) %>% 
  dplyr::distinct() %>%
  dplyr::left_join(x = ., 
                   y = temp, 
                   by = c("stratum", "station", "SRVY")) %>%
  dplyr::mutate(
    station_join = cur_group_id(), 
    mi3 = ifelse((station %in% c("HG2221", "HG2120", "F-20", "H-16") & 
                    SRVY %in% c("NBS", "EBS")), 
                 TRUE, FALSE), 
    file_3nm0 = ifelse((station %in% c("HG2221", "HG2120", "F-20", "H-16") & 
                          SRVY %in% c("NBS", "EBS")), 
                       "user_added", NA), 
    year = 1982, 
    trawlable = ifelse(trawlable == "Y", TRUE, FALSE))  
  
  




    # %>%
  
  # EBS data
  
  # NBS data
  
  # BSS data


# OLD_STATION <- 
#   racebase_haul0 %>% 
#   dplyr::rename(dplyr::any_of(lookup)) %>%
#   dplyr::mutate(SRVY = dplyr::case_when(
#     region == "BS" & stratum %in% c(70, 71, 81) ~ "NBS", 
#     region == "BS" & stratum %in% c(50, 32, 31, 42, 10, 20, 43, 62, 41, 61, 90, 82, 81, 70, 71) ~ "EBS", 
#     TRUE ~ region)) %>% 
#   dplyr::filter(!is.na(stratum)) %>%
#   dplyr::filter(!is.na(station)) %>% 
#   dplyr::select(stratum, station, SRVY) %>% 
#   dplyr::distinct() %>%
#   dplyr::mutate(station_join = cur_group_id(),
#                 station_description = NA,
#                 area = NA,
#                 perimeter = NA) # %>%
  # dplyr::left_join(
  #   x = ., 
  #   y = goa_stations_3nm0 %>% 
  #     , 
  #   by = c("SRVY"))

## Length ----------------------------------------------------------------------

OLD_LENGTH <- 
  # crab NBS and EBS
  dplyr::bind_rows(
    crab_ebscrab0 %>%
      dplyr::filter(!(cruise %in% unique(crab_ebscrab_nbs0$cruise))) %>% # there may be some nbs data in the ebs (201002)%>% 
      dplyr::mutate(file = "CRAB.EBSCRAB", 
                    SRVY = "EBS") , 
    crab_ebscrab_nbs0 %>% 
      dplyr::mutate(file = "CRAB.EBSCRAB_NBS", 
                    SRVY = "NBS") ) %>% 
  # dplyr::rename(dplyr::any_of(lookup))  %>% 
  dplyr::mutate(
    # sex_code = sex, 
    #             sex = dplyr::case_when(
    #               sex == 1 ~ "males",
    #               sex == 0 ~ "unsexed",
    #               (clutch_size == 0 & sex == 2) ~ "immature females", 
    #               (clutch_size >= 1 & sex == 2) ~ "mature females"), 
                length_type = dplyr::case_when( # what are other crabs?
                  species_code %in% c(68580, 68590, 68560) ~ 8,  # 8 - Width of carapace 
                  TRUE ~ 7),  # 7 - Length of carapace from back of right eye socket to end of carapace # species_code %in% c(69322, 69323, 69400, 69401) ~ 7, 
                length = dplyr::case_when(
                  species_code %in% c(68580, 68590, 68560) ~ width,  # "snow crab"
                  TRUE ~ length),
                frequency = 1)  %>%
  dplyr::select(-width) %>% 
  dplyr::filter(!is.na(length) & length != 999 & !is.na(cruise)) %>% 
  dplyr::group_by(hauljoin, species_code, sex, length) %>% # sex_code, 
  dplyr::summarise(frequency = n()) %>% 
  dplyr::ungroup() %>% 
  
  # all other lengths
  dplyr::bind_rows(
    ., 
    race_data_v_extract_final_lengths0 %>%
      dplyr::mutate(file = "RACE_DATA.V_EXTRACT_FINAL_LENGTHS"#, 
                    # sex_code = sex, 
                    # sex = dplyr::case_when(
                    #   sex_code == 1 ~ "Males", 
                    #   sex_code == 2 ~ "Females", 
                    #   sex_code == 3 ~ "Unsexed")
                    ) ) #%>% 
  # dplyr::select(hauljoin, species_code, sex, length, frequency, length_type, file) # sex_code, 


## Taxonomics ------------------------------------------------------------------

# OLD_TAXONOMICS <- data.frame(
#   species_join = 1, 
#   species_code = "Will be added by S. Friedman.", 
#            itis = NA, 
#            worms = NA, 
#            type_code = NA, 
#            genus = NA, 
#            species = NA, 
#            year_retired = NA, 
#            current_species = NA, 
#            comment = "typo/superseded/synonymized") 

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
                         skip = 1, col_names = TRUE) %>% 
    dplyr::select(where(~!all(is.na(.x)))) %>% # remove empty columns
    janitor::clean_names() %>% 
    dplyr::rename(species_code = code)
  if (sum(names(b) %in% "quality_codes")>0) {
    b$quality_codes<-NULL
  }
  b <- b %>% 
    tidyr::pivot_longer(cols = starts_with("x"), 
                        names_to = "year", 
                        values_to = "OLD_TAXON_CONFIDENCE") %>% 
    dplyr::mutate(year = gsub(pattern = "[a-z]", 
                              replacement = "", 
                              x = year), 
                  year = gsub(pattern = "_0", replacement = "", 
                              x = year), 
                  year = as.numeric(year)) %>% 
    dplyr::distinct()
  
  cc <- strsplit(x = gsub(x = gsub(x = a[i], 
                                   pattern = "OLD_TAXON_CONFIDENCE_", replacement = ""), 
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

OLD_TAXON_CONFIDENCE <- dplyr::bind_rows(df.ls) %>% 
  dplyr::mutate(taxon_confidence_code = OLD_TAXON_CONFIDENCE, 
                taxon_confidence = dplyr::case_when(
                  taxon_confidence_code == 1 ~ "High",
                  taxon_confidence_code == 2 ~ "Moderate",
                  taxon_confidence_code == 3 ~ "Low", 
                  TRUE ~ "Unassessed")) %>% 
  dplyr::select(-OLD_TAXON_CONFIDENCE)

# fill in OLD_TAXON_CONFIDENCE with, if missing, the values from the year before

cruises <- race_data_v_cruises0 %>% #read.csv("./data/race_data_v_cruises.csv") %>% 
  janitor::clean_names() %>% 
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
  OLD_TAXON_CONFIDENCE %>% 
    dplyr::filter(
      SRVY %in% sapply(comb,"[[",1) &
        year == 2021) %>% 
    dplyr::mutate(year = 2022)) %>% 
  dplyr::select(-common_name, -scientific_name)
  # dplyr::rename(taxon_confidence = taxon_confidence, 
  #               taxon_confidence_code = taxon_confidence_code)

OLD_TAXON_CONFIDENCE_table_metadata <- paste0(
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
a <- a[!grepl(pattern = "_table_metadata", x = a)]
file_paths <- data.frame(file_path = NA, table_metadata = NA)

for (i in 1:length(a)) {
  
  write.csv(x = get(a[i]), file = paste0(dir_out, a[i], ".csv"))
  
  # find or create table metadat for table
  table_metadata <- ifelse(exists(paste0(a[i], "_table_metadata", collapse="\n")), 
                                get(paste0(a[i], "_table_metadata", collapse="\n")), 
                                paste0(metadata_sentence_github, 
                                       metadata_sentence_last_updated))
  
  readr::write_lines(x = table_metadata, 
                     file = paste0(dir_out, a[i], "_table_metadata.txt", collapse="\n"))
  
  file_paths <- dplyr::add_row(.data = file_paths, 
                               file_path = paste0(dir_out, a[i], ".csv"),
                               table_metadata = table_metadata)
}
file_paths <- file_paths[-1,]

# Save old tables to Oracle
oracle_upload(
  file_paths = file_paths, 
  metadata_column = gap_products_metadata_column0, 
  channel = channel_products, 
  schema = "GAP_PRODUCTS")

#' ---------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-11-08
#' Notes: 
#' ---------------------------------------------


# Tables to create
# Get stomach lab to post tables to oracle
# report back requirements from special projects
# are ai goa grids used correctly
# cpue_other, and *_other tables need to be incorporated into production tables?
# what is up with the aluetians schema?


source('./code/functions.R')

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
  # CPUE
  "EBSSHELF.EBSSHELF_CPUE", # "HAEHNR.CPUE_EBS_PLUSNW", 
  "NBSSHELF.NBS_CPUE", # "HAEHNR.CPUE_NBS", 
  # "HAEHNR.cpue_nbs",
  # "HAEHNR.cpue_ebs_plusnw",
  # "HAEHNR.cpue_ebs_plusnw_grouped",
  "AI.CPUE", 
  "GOA.CPUE",
  "HOFFJ.CPUE_EBSSLOPE_POS", # needs to be peer reviewed
  "crab.gap_ebs_nbs_crab_cpue", 
  
  # BIOMASS/ABUNDANCE
  "AI.BIOMASS_STRATUM",
  "AI.BIOMASS_TOTAL", 
  "GOA.BIOMASS_STRATUM",
  "GOA.BIOMASS_TOTAL", 
  "HAEHNR.biomass_ebs_plusnw",# "HAEHNR.biomass_ebs_plusnw_safe", # no longer used
  "HAEHNR.biomass_ebs_plusnw_grouped",
  "HAEHNR.biomass_nbs_safe", 
  "GOA.BIOMASS_AREA",
  # "GOA.BIOMASS_AREA_DEPTH", 
  "GOA.BIOMASS_BY_LENGTH",
  "GOA.BIOMASS_DEPTH",
  "GOA.BIOMASS_INPFC",
  "GOA.BIOMASS_INPFC_DEPTH",
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
  
  # LENGTH
  "RACE_DATA.V_EXTRACT_FINAL_LENGTHS", 
  "CRAB.EBSCRAB",
  "CRAB.EBSCRAB_NBS",
  
  # Age comps
  "HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM",
  "HAEHNR.AGECOMP_NBS_STRATUM", 
  "AI.AGECOMP_STRATUM", 
  "AI.AGECOMP_TOTAL",
  "GOA.AGECOMP_STRATUM",
  "GOA.AGECOMP_TOTAL",
  # We currently do not know where BSS age comp data are/were ever made?
  
  # size comp - the extrapolated size distributions of each fish
  "HAEHNR.sizecomp_nbs_stratum",
  "HAEHNR.sizecomp_ebs_plusnw_stratum", 
  "HAEHNR.sizecomp_ebs_plusnw_stratum_grouped",
  "AI.SIZECOMP_STRATUM", 
  "AI.SIZECOMP_TOTAL", 
  "GOA.SIZECOMP_STRATUM",
  "GOA.SIZECOMP_TOTAL",
  "HOFFJ.SIZECOMP_EBSSLOPE", # needs to be peer reviewed
  
  # "AI.AIGRID_GIS", 
  # "GOA.GOAGRID_GIS", 
  "RACEBASE.STRATUM", 
  "GOA.GOA_STRATA",
  
  "AI.BIOMASS_AREA", 
  "AI.BIOMASS_AREA_DEPTH", 
  "AI.BIOMASS_BY_LENGTH", 
  "AI.BIOMASS_DEPTH", 
  "AI.BIOMASS_INPFC", 
  "AI.BIOMASS_INPFC_DEPTH", 
  "AI.SIZECOMP_AREA", 
  "AI.SIZECOMP_AREA_DEPTH",
  "AI.SIZECOMP_DEPTH",
  "AI.SIZECOMP_INPFC", 
  "AI.SIZECOMP_INPFC_DEPTH", 
  "AI.STATION_ALLOCATION", 
  "AI.STATIONS_3NM", 
  
  "racebase.haul", 
  
  "EBSSHELF.EBSSHELF_AGECOMP_PLUSNW", 
  "EBSSHELF.EBSSHELF_AGECOMP_STANDARD", 
  "EBSSHELF.EBSSHELF_BIOMASS_PLUSNW", 
  "EBSSHELF.EBSSHELF_BIOMASS_STANDARD", 
  "EBSSHELF.EBSSHELF_SIZECOMP_PLUSNW", 
  "EBSSHELF.EBSSHELF_SIZECOMP_STANDARD", 
  "EBSSHELF.EBSSHELF_CPUE", 
  "EBSSHELF.EBSSHELF_STRATA", 
  "NBSSHELF.NBS_AGECOMP", 
  "NBSSHELF.NBS_BIOMASS", 
  "NBSSHELF.NBS_CPUE", 
  "NBSSHELF.NBS_SIZECOMP",
  "NBSSHELF.NBS_STRATA", 
  
  "AI.AIGRID_GIS", "GOA.GOAFRID", "GOA.GOAGRID_GIS", "GOA.GOA_SURVEY_GRIDPONTS")

if (FALSE) {
  error_loading <- c()
  for (i in 1:length(locations)){
    print(locations[i])
    if (locations[i] == "RACEBASE.HAUL") { # that way I can also extract TIME
      
      a <- RODBC::sqlQuery(channel, paste0("SELECT * FROM ", locations[i]))
      
      a <- RODBC::sqlQuery(channel, 
                           paste0("SELECT ",
                                  paste0(names(a)[names(a) != "START_TIME"], 
                                         sep = ",", collapse = " "),
                                  " TO_CHAR(START_TIME,'MM/DD/YYYY HH24:MI:SS') START_TIME  FROM ", 
                                  locations[i]))
    } else {
      a <- RODBC::sqlQuery(channel, paste0("SELECT * FROM ", locations[i]))
    }
    
    
    filename <- tolower(gsub(x = locations[i], 
                             pattern = ".", 
                             replacement = "_", 
                             fixed = TRUE))
    
    # if (length(a)>0) {
    # error_loading <- c(error_loading, locations[i])
    # } else { 
    write.csv(x=a, 
              paste0("./data/",
                     filename,
                     ".csv"))
    remove(a)
    # }
  }
  error_loading
}



# Load data --------------------------------------------------------------------

a <- tolower(gsub(pattern = ".", replacement = "_", x = locations, fixed = TRUE))

for (i in 1:length(a)){
  b <- readr::read_csv(file = paste0("./data/", a[i], ".csv"), 
                       show_col_types = FALSE)
  b <- janitor::clean_names(b)
  if (names(b)[1] %in% "x1"){
    b$x1<-NULL
  }
  temp <- strsplit(x = a[i], split = "/")
  temp <- gsub(pattern = "\\.csv", replacement = "", x = temp[[1]][length(temp[[1]])])
  assign(x = paste0(temp, "0"), value = b)
}


## Download data report tables from google drive that should be in oracle -------

library(googledrive)
googledrive::drive_deauth()
googledrive::drive_auth()
1

# Spreadsheets
# https://drive.google.com/drive/folders/1Vbe_mH5tlnE6eheuiSVAFEnsTJvdQGD_?usp=sharing
a <- googledrive::drive_ls(path = googledrive::as_id("1Vbe_mH5tlnE6eheuiSVAFEnsTJvdQGD_"), 
                           type = "spreadsheet")


for (i in 1:nrow(a)){
  googledrive::drive_download(file = googledrive::as_id(a$id[i]), 
                              type = "xlsx", 
                              overwrite = TRUE, 
                              path = paste0(dir_data, "/", a$name[i]))
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

# Wrangle data ----------------------------------------------------------------

## CPUE data -----------------------------------------------------------------

lookup <- c(
  year = "survey_year", 
  cpue_kgkm2 = "cpuewgt_total", 
  cpue_nokm2 = "cpuenum_total",
  cpue_kgkm2 = "wgtcpue", 
  cpue_nokm2 = "numcpue", 
  station = "stationid", 
  weight_kg = "weight", 
  count = "number_fish"
)

haul <- racebase_haul0 %>% 
  dplyr::rename(dplyr::any_of(lookup)) %>%
  dplyr::mutate(SRVY = dplyr::case_when(
    region == "BS" & stratum %in% c(70, 71, 81) ~ "NBS", 
    region == "BS" & stratum %in% c(50, 32, 31, 42, 10, 20, 43, 62, 41, 61, 90, 82, 81, 70, 71) ~ "EBS", 
    TRUE ~ region)) %>% 
  dplyr::filter(!is.na(stratum)) %>%
  dplyr::filter(!is.na(station)) %>% 
  dplyr::select(hauljoin, stratum, station, SRVY, cruise) %>% 
  dplyr::distinct()


## Haul events -----------------------------------------------------------------

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
      file = "ebsshelf.ebsshelf_cpue0"), 
  # BSS data
  hoffj_cpue_ebsslope_pos0 %>% # ESS CPUE data
    dplyr::rename(dplyr::any_of(lookup)) %>%
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
    file)  #%>%
# # define 'standard' tows
# dplyr::left_join(
#   x = .,
#   y = haul0,
#   by = "hauljoin") %>%
# dplyr::filter(abundance_haul == "Y" &
#                 performance >= 0 &
#                 !(is.null(stationid))) %>%
# dplyr::select(SRVY, year, species_code, cpue_kgha, number_fish, stationid, start_latitude, start_longitude)

## Biomass and Abundance data --------------------------------------------------

lookup <- c(
  SRVY = "survey_region", 
  year = "survey_year", 
  area = "regulatory_area_name", 
  area = "summary_area", # may be an stratum ID, not an actual depth
  area_depth = "summary_area_depth", # may be an stratum ID, not an actual depth
  area_depth = "summary_depth", 
  
  number_count = "count_number", # what is this?
  
  count_length = "lencount", 
  count_length = "len_count",
  count_length = "length_count",
  
  count_catch = "catchcount", 
  count_catch = "catch_count", 
  count_catch = "count_catch", 
  # count_catch = "number_count",
  
  count_haul = "haulcount", 
  count_haul = "haul_count",
  
  cpue_wgtkm2_mean = "mean_wgt_cpue", 
  cpue_wgtkm2_mean = "meanwgtcpue", 
  cpue_wgtkm2_var = "var_wgt_cpue", 
  cpue_wgtkm2_var = "varmnwgtcpue",
  
  cpue_nokm2_mean = "mean_num_cpue", 
  cpue_nokm2_mean = "meannumcpue", 
  cpue_nokm2_var = "var_num_cpue", 
  cpue_nokm2_var = "varmnnumcpue", 
  
  biomass = "area_biomass", 
  biomass = "stratum_biomass", 
  biomass = "total_biomass", 
  biomass = "biomass_total",
  
  biomass_var = "varbio", 
  varbio = "bio_var", 
  
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
  
  abundance_df = "degreef_pop")

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
  nbsshelf_nbs_biomass0 %>% 
    dplyr::filter(!(species_code %in% c(69323, 69322, 68580, 68560))) %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "NBS", 
      file = "nbsshelf.nbs_biomass") %>%
    dplyr::rename(dplyr::any_of(lookup)),     
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
      SRVY = "EBS",
      file = "ebsshelf.ebsshelf_agecomp_standard") %>%
    dplyr::rename(dplyr::any_of(lookup)),
  ebsshelf_ebsshelf_biomass_plusnw0  %>% 
    dplyr::filter(!(species_code %in% c(69323, 69322, 68580, 68560))) %>%
    dplyr::mutate(
      area_type = "index",
      area = "index",
      SRVY = "EBS",
      file = "ebsshelf.ebsshelf_biomass_plusnw") %>%
    dplyr::rename(dplyr::any_of(lookup)),
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
  
  # BSS data doesnt exist
  
  # GOA data
  goa_biomass_total0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "GOA", 
      file = "goa.biomass_total") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_stratum0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "GOA",
      file = "goa.biomass_stratum") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_area0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa.biomass_area", 
      area_type = "regulatory") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_by_length0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      area_type = "index", # is this right?
      area = "length", 
      file = "goa.biomass_by_length") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_depth0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      area_type = "index", # is this right?
      area = "depth",
      file = "goa.biomass_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_inpfc0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa.biomass_inpfc", 
      area_type = "inpfc", 
      summary_area = as.character(summary_area)) %>% # is this right?/make sense
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_inpfc_depth0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa.biomass_inpfc_depth", 
      area_type = "inpfc") %>% 
    dplyr::rename(dplyr::any_of(lookup)),
  
  # AI data
  ai_biomass_total0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "AI", 
      file = "ai.biomass_total") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_stratum0 %>%
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "AI", 
      file = "ai.biomass_stratum")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_area0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai.biomass_area", 
      area_type = "regulatory")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_area_depth0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai.biomass_area_depth", 
      area_type = "regulatory") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_by_length0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      area_type = "index", # is this right?
      area = "length", 
      file = "ai.biomass_by_length")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_depth0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      area_type = "index", # is this right?
      area = "depth", 
      file = "ai.biomass_depth")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_inpfc_depth0 %>% # are there inpfc regions?
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai.biomass_inpfc_depth", 
      area_type = "inpfc") %>% 
    dplyr::rename(dplyr::any_of(lookup))
)  %>% 
  dplyr::select(sort(tidyselect::peek_vars())) %>%
  dplyr::select(-common_name, -species_name, -region, -survey)



# print("Total Biomass")
# 
# # calc_cpue_bio <- function(catch_haul_cruises0){
#   
#   # for tech memo table: calculate biomass for fish and invert taxa in table 7
#   # Created by: Rebecca Haehn
#   # Contact: rebecca.haehn@noaa.gov
#   # Created: 13 January 2022
#   # script modifed from biomass script for stock assessments
#   # Modified: 
#   
#   ### fiter to EBS only data by innerjoin (catch and haul) --------------------
#   
#   ## to test this I filtered for YEAR = 2017 in the haul data, row count matches prebiocatch table in Oracle (after running legacy ebs_plusnw script) **do not run with filter to get match
#   ## 
#   ## the filter removes empty banacles, empty bivalve/gastropod shell, invert egg unid, unsorted catch and debris, Polychaete tubes, and unsorted shab 
#   
#   ### create zeros table for CPUE calculation ---------------------------------
#   # zeros table so every haul/vessel/year combination includes a row for every species caught (combine)
#   
#   temp1 <- catch_haul_cruises0 #%>% 
#   # dplyr::group_by(year, SRVY, cruisejoin, hauljoin, stationid, stratum, haul, cruise, 
#   #                 species_code, distance_fished, net_width) %>% 
#   # dplyr::summarise(weight = sum(weight, na.rm = TRUE), 
#   #                  number_fish = sum(number_fish, na.rm = TRUE))
#   
#   if (is.numeric(catch_haul_cruises0$species_code)) {
#     temp1 <- temp1 %>%
#       dplyr::filter(species_code < 99991)
#   }
#   
#   z <-  temp1 %>% 
#     tidyr::complete(species_code, 
#                     nesting(SRVY, cruise, haul, #vessel, 
#                             year, hauljoin, stratum, stationid, 
#                             distance_fished, net_width)) %>%
#     dplyr::select(SRVY, cruise, hauljoin, haul, #vessel, 
#                   year, species_code, weight, number_fish, stratum, 
#                   stationid, distance_fished, net_width) %>%
#     tidyr::replace_na(list(weight = 0, number_fish = 0))
#   
#   
#   catch_with_zeros <- 
#     dplyr::full_join(x = temp1, 
#                      y = z, 
#                      by = c("SRVY", "cruise", "hauljoin", "haul", 
#                             "year", "species_code", "stratum", "stationid", 
#                             "distance_fished", "net_width")) %>%
#     dplyr::select(-weight.y, -number_fish.y, -gear_depth, 
#                   -duration, -net_height) %>%
#     dplyr::arrange(year, haul, species_code) %>%
#     dplyr::rename(weight_kg = weight.x, number_fish = number_fish.x) %>%
#     tidyr::replace_na(list(weight_kg = 0, number_fish = 0))
#   
#   ### calculate CPUE (mean CPUE by strata) ----------------------------------------------------------
#   
#   # num <- temp1 %>%
#   #   dplyr::distinct(SRVY, year, hauljoin, species_code) %>%
#   #   dplyr::group_by(SRVY, year, species_code) %>%
#   #   dplyr::summarize(num = n())
#   
#   cpue_by_stratum <- catch_with_zeros %>%
#     dplyr::select(SRVY, species_code, year, stratum, stationid,
#                   distance_fished, net_width, weight_kg) %>%
#     dplyr::mutate(
#       effort = distance_fished * net_width/10,
#       cpue_kgha = weight_kg/effort) %>% 
#     dplyr::left_join(x = .,
#                      y = stratum_info %>%
#                        dplyr::select(stratum, area, SRVY),
#                      by = c("SRVY", "stratum")) %>%
#     dplyr::arrange(stratum, species_code) %>%
#     dplyr::group_by(SRVY, species_code, year, stratum, area) %>%
#     dplyr::summarise( 
#       cpue_kgha_strat = mean(cpue_kgha, na.rm = TRUE), #weight_kg/effort, 
#       cpue_kgha_var = ifelse(n() <= 1, 0, var(cpue_kgha)/n()),
#       num_hauls = n(),     # num_hauls = ifelse(num == 1, 1, (num-1)),
#       total_area = sum(unique(area))) %>%
#     dplyr::mutate(strata = dplyr::case_when(
#       (stratum == 31 | stratum == 32) ~ 30,
#       (stratum == 41 | stratum == 42) | stratum == 43 ~ 40,
#       (stratum == 61 | stratum == 62) ~ 60, 
#       TRUE ~ as.numeric(stratum)))
#   
#   # 
# #   
# #   # ## CANNOT use biomass_*** tables bc they don't contain the info for all species (ie: no poachers, blennies, lumpsuckers, eelpouts, etc.)
# #   
# #   biomass_by_stratum <- biomass_cpue_by_stratum <- cpue_by_stratum %>%
# #     dplyr::mutate(
# #       biomass_mt = cpue_kgha_strat * (area * 0.1), 
# #       bio_var = (area^2 * cpue_kgha_var/100), 
# #       fi = area * (area - num_hauls)/num_hauls,
# #       ci = qt(p = 0.025, df = num_hauls - 1, lower.tail = F) * sqrt(bio_var), 
# #       up_ci_bio = biomass_mt + ci,
# #       low_ci_bio = ifelse(biomass_mt - ci <0, 0, biomass_mt - ci) )
# #   
# #   
# #   total_biomass <- biomass_by_stratum %>%
# #     dplyr::filter((species_code >= 40000 &
# #                      species_code < 99991) |
# #                     (species_code > 1 & 
# #                        species_code < 35000)) %>% 
# #     ungroup() %>%
# #     dplyr::group_by(SRVY, year) %>% 
# #     dplyr::summarise(total = sum(biomass_mt, na.rm = TRUE))
# #   
# #   return(list("biomass_cpue_by_stratum" = biomass_cpue_by_stratum, 
# #               "total_biomass" = total_biomass))
# #   
# # }
# # 
# # a <- calc_cpue_bio(catch_haul_cruises0 = catch_haul_cruises_maxyr)
# # b <- calc_cpue_bio(catch_haul_cruises0 = catch_haul_cruises_compareyr)
# # 
# # biomass_cpue_by_stratum <- cpue_by_stratum <- biomass_by_stratum <- 
# #   a$biomass_cpue_by_stratum %>%  # remove crab totals, as they use different stratum
# #   dplyr::filter(!(species_code %in% c(69323, 69322, 68580, 68560)))
# # 
# # # subtract our-calculated crab totals so we can add the right total from SAP
# # cc <- dplyr::bind_rows(a$biomass_cpue_by_stratum, 
# #                        b$biomass_cpue_by_stratum) %>% 
# #   dplyr::filter((species_code %in% c(69323, 69322, 68580, 68560))) %>%
# #   ungroup() %>%
# #   dplyr::group_by(SRVY, year) %>%
# #   dplyr::summarise(total_crab_wrong = sum(biomass_mt, na.rm = TRUE))
# # 
# # total_biomass <- 
# #   dplyr::left_join(x = dplyr::bind_rows(a$total_biomass, 
# #                                         b$total_biomass), 
# #                    y = cc) %>% 
# #   dplyr::left_join(x = ., 
# #                    y = biomass_tot_crab %>% 
# #                      dplyr::filter(stratum == 999) %>%
# #                      ungroup() %>%
# #                      dplyr::group_by(SRVY, year) %>% 
# #                      dplyr::summarise(total_crab_correct = sum(biomass, na.rm = TRUE))) %>% 
# #   dplyr::mutate(total = total - total_crab_wrong + total_crab_correct) %>% 
# #   dplyr::select(-total_crab_wrong, -total_crab_correct)

## Comp data -------------------------------------------------------------------

lookup <- c(
  area_depth = "summary_area_depth", 
  area_depth = "summary_depth", 
  area = "summary_area", 
  value = "length", 
  area = "regulatory_area_name", 
  year = "survey_year", 
  meanlen = "mean_length", 
  sdev = "standard_deviation")


# length comps
sizeOLD_COMP_AGE_SIZE_STRATUM <- dplyr::bind_rows(
  # NBS data
  nbsshelf_nbs_sizecomp0 %>% 
    dplyr::mutate(SRVY = "NBS", 
                  area_type = "index", 
                  file = "nbsshelf.nbs_sizecomp") %>% 
    dplyr::rename(dplyr::any_of(lookup)) , 
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
                  file = "ebsshelf.ebsshelf_sizecomp_standard") %>%
    dplyr::rename(dplyr::any_of(lookup)),
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
  hoffj_sizecomp_ebsslope0 %>% 
    dplyr::mutate(SRVY = "BSS", 
                  area_type = "index",
                  file = "hoffj.sizecomp_ebsslope") %>% 
    dplyr::rename(dplyr::any_of(lookup)),   
  # GOA data
  goa_sizecomp_stratum0 %>% 
    dplyr::mutate(SRVY = "GOA",
                  area_type = "index", 
                  file = "goa.sizecomp_stratum") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_total0 %>%
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "index",
                  file = "goa.sizecomp_total") %>% 
    dplyr::rename(stratum = summary_area) %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  # goa_sizecomp_area_depth0
  goa_sizecomp_area0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "regulatory", 
                  file = "goa.sizecomp_area") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_depth0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  file = "goa.sizecomp_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_inpfc0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "inpfc", 
                  file = "goa.sizecomp_inpfc", 
                  summary_area = as.character(summary_area)) %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_inpfc_depth0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "inpfc", 
                  file = "goa.sizecomp_inpfc_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  # AI data
  ai_sizecomp_stratum0 %>% 
    dplyr::mutate(SRVY = "AI",
                  area_type = "index", 
                  file = "ai.sizecomp_stratum") %>% 
    dplyr::rename(dplyr::any_of(lookup)),
  ai_sizecomp_total0  %>%
    dplyr::mutate(SRVY = "AI", 
                  area_type = "index",
                  file = "ai.sizecomp_total") %>% 
    dplyr::rename(stratum = summary_area) %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_area0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "regulatory", 
                  file = "ai.sizecomp_area") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_area_depth0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "regulatory", 
                  file = "ai.sizecomp_area_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_depth0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "index", # is this right?
                  file = "ai.sizecomp_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_inpfc_depth0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "inpfc", 
                  file = "ai.sizecomp_inpfc_depth") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_inpfc0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "inpfc", 
                  summary_area = as.character(summary_area), 
                  file = "ai.sizecomp_inpfc") %>% 
    dplyr::rename(dplyr::any_of(lookup))
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
ageOLD_COMP_AGE_SIZE_STRATUM <- dplyr::bind_rows(
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
OLD_COMP_AGE_SIZE_STRATUM <- dplyr::bind_rows(sizeOLD_COMP_AGE_SIZE_STRATUM, ageOLD_COMP_AGE_SIZE_STRATUM) %>%
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
  dplyr::mutate(stratum = ifelse(stratum %in% c(999), 999999, stratum))

## Stratum data ----------------------------------------------------------------
lookup <- c(SRVY = "survey", 
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
  
  # BSS datas
  
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

lookup <- c(
  year = "survey_year", 
  station = "stationid", 
  grid_number = "aigrid_number", 
  grid_id = "aigrid_id", 
  grid = "aigrid"
)

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

lookup <- c(
  station = "gis_station")

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

OLD_TAXONOMICS <- data.frame(
  species_join = 1, 
  species_code = "Will be added by S. Friedman.", 
           itis = NA, 
           worms = NA, 
           type_code = NA, 
           genus = NA, 
           species = NA, 
           year_retired = NA, 
           current_species = NA, 
           comment = "typo/superseded/synonymized") 

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

# Check work -------------------------------------------------------------------

# Load to Oracle ---------------------------------------------------------------

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

upload_to_oracle <- function(
    file_paths, 
    column_metadata, 
    channel, 
    channel_name,
    update_table = TRUE, 
    update_metadata = TRUE) {
  
  column_metadata$colname <- toupper(column_metadata$colname)
  
  all_schemas <- RODBC::sqlQuery(channel = channel,
                                 query = paste0('SELECT * FROM all_users;'))
  
  # Loop through each table to add to oracle -------------------------------------
  
  for (ii in 1:nrow(file_paths)) {
    
    print(file_paths$file_path[ii])
    file_name <- strsplit(x = file_paths$file_path[ii], split = "/", fixed = TRUE)[[1]]
    file_name <- strsplit(x = file_name[length(file_name)], split = ".", fixed = TRUE)
    file_name <- file_name[[1]][1]
    
    a <- read.csv(file_paths$file_path[ii])
    names(a) <- toupper(names(a))
    assign(x = file_name, value = a)
    
    names(a) <- toupper(names(a))
    
    if (update_table) {
      
      ## Drop old table from oracle -------------------------------------------------
      # if the table is currently in the schema, drop the table before re-uploading
      if (file_name %in% 
          unlist(RODBC::sqlQuery(channel = channel, 
                                 query = "SELECT table_name FROM user_tables;"))) {
        RODBC::sqlDrop(channel = channel,
                       sqtable = file_name)
      }
      
      ## Add the table to the schema ------------------------------------------------
      eval( parse(
        text = paste0("RODBC::sqlSave(channel = channel,
                 dat = ",file_name,")") ))
    }
    
    if (update_metadata) {
      ## Add column metadata --------------------------------------------------------
      column_metadata0 <- column_metadata[which(column_metadata$colname %in% names(a)),]
      if (nrow(column_metadata0)>0) {
        for (i in 1:nrow(column_metadata0)) {
          
          desc <- gsub(pattern = "<sup>2</sup>",
                       replacement = "2",
                       x = column_metadata0$colname_desc[i], fixed = TRUE)
          short_colname <- gsub(pattern = "<sup>2</sup>", replacement = "2",
                                x = column_metadata0$colname[i], fixed = TRUE)
          
          RODBC::sqlQuery(channel = channel,
                          query = paste0('comment on column ',channel_name,'.',file_name,'.',
                                         short_colname,' is \'',
                                         desc, ". ", # remove markdown/html code
                                         gsub(pattern = "'", replacement ='\"',
                                              x = column_metadata0$desc[i]),'\';'))
          
        }
      }
      ## Add table metadata ---------------------------------------------------------
      RODBC::sqlQuery(channel = channel,
                      query = paste0('comment on table ',channel_name,'.',file_name,
                                     ' is \'',
                                     file_paths$table_metadata[ii],'\';'))
    }
    ## grant access to all schemes ------------------------------------------------
    for (iii in 1:length(sort(all_schemas$USERNAME))) {
      RODBC::sqlQuery(channel = channel,
                      query = paste0('grant select on ',channel_name,'.',file_name,
                                     ' to ', all_schemas$USERNAME[iii],';'))
    }
    
  }
}

# Upload data to oracle! -------------------------------------------------------

# Production tables
write.csv(x = OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM, file = paste0(dir_out, "OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM.csv"))
write.csv(x = OLD_CPUE_STATION, file = paste0(dir_out, "OLD_CPUE_STATION.csv"))
write.csv(x = OLD_COMP_AGE_SIZE_STRATUM, file = paste0(dir_out, "OLD_COMP_AGE_SIZE_STRATUM.csv"))
write.csv(x = OLD_SPECIAL_PROJECTS, file = paste0(dir_out, "OLD_SPECIAL_PROJECTS.csv"))
write.csv(x = OLD_OTHER_FIELD_COLLECTIONS, file = paste0(dir_out, "OLD_OTHER_FIELD_COLLECTIONS.csv"))
write.csv(x = OLD_LENGTH, file = paste0(dir_out, "OLD_LENGTH.csv"))

# Reference tables
write.csv(x = OLD_AFFILIATIONS, file = paste0(dir_out, "OLD_AFFILIATIONS.csv"))
write.csv(x = OLD_COLLECTION_SCHEME, file = paste0(dir_out, "OLD_COLLECTION_SCHEME.csv"))
write.csv(x = OLD_STATION, file = paste0(dir_out, "OLD_STATION.csv"))
write.csv(x = OLD_STRATUM, file = paste0(dir_out, "OLD_STRATUM.csv"))
write.csv(x = OLD_TAXONOMICS, file = paste0(dir_out, "OLD_TAXONOMICS.csv"))
write.csv(x = OLD_TAXONOMICS, file = paste0(dir_out, "OLD_TAXONOMICS_TYPECODE.csv"))

file_paths <- data.frame(
  file_path = 
    # c(paste0(paste0(getwd(), "/data/"), 
    #          c("TAXON_CONFIDENCE", 
    #            paste0("AFSC_ITIS_WORMS", option)), 
    #          ".csv"), 
    paste0(dir_out, 
           c("OLD_TAXONOMICS",
             "OLD_TAXONOMICS_TYPECODE",
             "OLD_STATION", 
             "OLD_STRATUM",
             "OLD_SPECIAL_PROJECTS", 
             "OLD_AFFILIATIONS", 
             "OLD_OTHER_FIELD_COLLECTIONS", 
             "OLD_COLLECTION_SCHEME", 
             "OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM", 
             "OLD_CPUE_STATION",
             "OLD_COMP_AGE_SIZE_STRATUM",
             "OLD_LENGTH"), 
           ".csv"), 
  "table_metadata" = c(Sys.Date()) 
)

# file_paths <- file_paths[-1,]

dir_out <- paste0("./output/", Sys.Date())
source("https://raw.githubusercontent.com/afsc-gap-products/gap_public_data/main/code/metadata.r")

# column_metadata <- data.frame(matrix(
#   ncol = 4, byrow = TRUE, 
#   data = c(
#     "dummy", "Dummy", "dummy units", "dummy description."
#   )))
# 
# names(column_metadata) <- c("colname", "colname_desc", "units", "desc")


upload_to_oracle(
  file_paths = file_paths, 
  column_metadata = column_metadata, 
  channel = channel_products, 
  channel_name = "GAP_PRODUCTS")

#

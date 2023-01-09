#' ---------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-11-08
#' Notes: 
#' ---------------------------------------------

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
  "crab.gap_ebs_nbs_abundance_biomass",  
  
  # Age comps
  "HAEHNR.AGECOMP_EBS_PLUSNW_STRATUM",
  "HAEHNR.AGECOMP_NBS_STRATUM", 
  "AI.AGECOMP_STRATUM", 
  "GOA.AGECOMP_STRATUM",
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
  "NBSSHELF.NBS_STRATA"
)


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

## Download data report tables from google drive that should be in oracle -------

library(googledrive)
googledrive::drive_deauth()
googledrive::drive_auth()
1

  # Spreadsheets
  # https://drive.google.com/drive/folders/1Vbe_mH5tlnE6eheuiSVAFEnsTJvdQGD_?usp=sharing
  a <- googledrive::drive_ls(path = googledrive::as_id("1Vbe_mH5tlnE6eheuiSVAFEnsTJvdQGD_"), 
                             type = "spreadsheet")
    locations <- c(locations, paste0(a$name, ".xlsx"))
    
  for (i in 1:nrow(a)){
    googledrive::drive_download(file = googledrive::as_id(a$id[i]), 
                                type = "xlsx", 
                                overwrite = TRUE, 
                                path = paste0(dir_out_rawdata, "/", a$name[i]))
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

cpue_data <- dplyr::bind_rows(
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
  
  count_length = "lencount", 
  count_length = "len_count", 
  count_catch = "catchcount", 
  count_catch = "catch_count", 
  count_haul = "haulcount", 
  count_haul = "haul_count",
  
  cpue_nokm2_mean = "mean_wgt_cpue", 
  cpue_nokm2_mean = "meanwgtcpue", 
  cpue_nokm2_var = "var_wgt_cpue", 
  cpue_nokm2_var = "varmnwgtcpue",
  
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
  
  abundnace = "area_pop", 
  abundnace = "stratum_pop", 
  abundnace = "total_pop", 
  abundnace = "population", 
  
  abundnace_var = "varpop", 
  abundnace_var = "pop_var", 
  
  biomass_ci_lower = "min_biomass", # Is this right?
  biomass_ci_lower = "biomass_lower_ci", 
  
  biomass_ci_upper = "max_biomass",  # is this right?
  biomass_ci_upper = "biomass_upper_ci", 
  
  abundnace_ci_lower = "min_pop", # Is this right?
  abundnace_ci_lower = "abundance_lower_ci", 
  
  abundnace_ci_upper = "max_pop", 
  abundnace_ci_upper = "abundance_upper_ci")

bio_abund_data <- dplyr::bind_rows(
  # crab EBS + NBS data
  crab_gap_ebs_nbs_abundance_biomass0 %>% 
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      file = "crab.gap_ebs_nbs_abundance_biomass") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  # NBS data
  haehnr_biomass_nbs_safe0 %>% 
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "NBS", 
      file = "haehnr.biomass_nbs_safe") %>%
    dplyr::rename(dplyr::any_of(lookup)),  
  # EBS data
  haehnr_biomass_ebs_plusnw_grouped0 %>% 
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "EBS", 
      file = "haehnr.biomass_ebs_plusnw_grouped") %>%
    dplyr::rename(dplyr::any_of(lookup)),  
  haehnr_biomass_ebs_plusnw0 %>% 
    dplyr::mutate(
      area_type = "index",
      area = "index", 
      SRVY = "EBS", 
      file = "haehnr.biomass_ebs_plusnw") %>%
    dplyr::rename(dplyr::any_of(lookup)),  
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
    dplyr::rename(dplyr::any_of(lookup))
)
# ) %>%
#   dplyr::select(SRVY, year, species_code, stratum, area, area_type, depth, length_class,
#                 biomass, varbio, lowerb, upperb, degreefwgt,
#                 population, varpop, lowerp, upperp, degreefnum,
#                 meanwgtcpue, varmnwgtcpue, meannumcpue, varmnnumcpue,
#                 haulcount, catcount, numcount, lencount, 
#                 file)

# "SRVY", "year", "area", "depth", 
# "count_length", "count_catch", "count_haul", 
# "cpue_nokm2_mean", "cpue_nokm2_var", 
# "biomass", "biomass_var", "varbio", "biomass_ci_lower", "biomass_ci_upper", 
# "abundnace", "abundnace_var", "abundnace_ci_lower", "abundnace_ci_upper"

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
sizecomp_data <- dplyr::bind_rows(
  # NBS data
  haehnr_sizecomp_nbs_stratum0 %>% 
    dplyr::mutate(SRVY = "NBS", 
                  area_type = "index", 
                  file = "haehnr.sizecomp_nbs_stratum") %>% 
    dplyr::rename(dplyr::any_of(lookup)) , 
  # EBS data
  # haehnr_sizecomp_ebs_plusnw_stratum0 %>% 
  #   dplyr::mutate(SRVY = "EBS", 
  #                 file = "haehnr.sizecomp_ebs_plusnw_stratum") %>% 
  #   dplyr::rename(dplyr::any_of(lookup)), 
  ebsshelf_ebsshelf_sizecomp_plusnw0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "EBS",
                  area_type = "index", # plusnw
                  file = "ebsshelf.ebsshelf_sizecomp_plusnw") %>%
    ebsshelf_ebsshelf_sizecomp_standard0  %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(SRVY = "EBS",
                  area_type = "standard", # or should this be index? and area = "standard?
                  file = "ebsshelf.ebsshelf_sizecomp_standard") %>%
    dplyr::rename(dplyr::any_of(lookup)),
  haehnr_sizecomp_ebs_plusnw_stratum_grouped0 %>% 
    dplyr::mutate(SRVY = "EBS", 
                  area_type = "index",
                  file = "haehnr.sizecomp_ebs_plusnw_stratum_grouped") %>% 
    dplyr::rename(dplyr::any_of(lookup)),
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
agecomp_data <- dplyr::bind_rows(
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
comp_data <- dplyr::bind_rows(sizecomp_data, agecomp_data) %>%
  dplyr::filter(pop > 0 &
                  value >= 0) %>% 
  dplyr::mutate(sex = str_to_sentence(sex), # this will assure the order of appearance in the plot
                sex = factor(sex, 
                             levels = c("Males", "Females", "Unsexed", "Immature females", "Mature females"), 
                             labels = c("Males", "Females", "Unsexed", "Immature females", "Mature females"),
                             ordered = TRUE), 
                sex_code = as.numeric(sex)) %>% 
  dplyr::arrange(sex) %>% 
  dplyr::mutate(stratum = ifelse(stratum %in% c(999), 999999, stratum))

## Stratum data ----------------------------------------------------------------
lookup <- c(SRVY = "survey", 
            area_km2 = "area", 
            perimeter_km = perimeter, 
            depth_m_min = "min_depth", 
            depth_m_max = "max_depth")

# stratum_id	Survey	stratum	stratum_type	details	stratum_desc	stratum_names	year_implimented	area	perimeter

stratum_data <- dplyr::bind_rows(
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
    dplyr::select(
      SRVY, stratum, area_km2, perimeter, depth_m_min, depth_m_max, description, stratum_type, 
      summary_depth) %>% 
    dplyr::rename(area_depth = summary_depth), 
  
  goa_goa_strata0 %>% # is this nescesary, or redundant? can we just use the index areas?
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(
      year = 2022, 
      file = "goa.goa_strata", 
      area_type = "inpfc", 
      summary_area = as.character(summary_area)) %>% 
    dplyr::select(
      SRVY, stratum, area_km2, perimeter, depth_m_min, depth_m_max, description, stratum_type, 
      inpfc_area, summary_area_depth, summary_depth) %>% 
    dplyr::rename(
      area_depth = summary_area_depth, 
      area = inpfc_area), # summary_area), 
  
  goa_goa_strata0 %>% # is this nescesary, or redundant? can we just use the index areas?
    dplyr::rename(dplyr::any_of(lookup)) %>% 
    dplyr::mutate(
      year = 2022, 
      file = "goa.goa_strata", 
      area_type = "regulatory") %>% 
    dplyr::select(
      SRVY, stratum, area_km2, perimeter, depth_m_min, depth_m_max, description, stratum_type, 
      summary_area, summary_area_depth, regulatory_area_name) %>% 
    dplyr::rename(
      area_depth = summary_area_depth, 
      area = regulatory_area_name) 
  
) %>% 
  dplyr::mutate(stratum_join = cur_group_id()) %>% 
  dplyr::select(
    SRVY, year, stratum, description, area_type, area, 
    stratum_type, area_km2, perimeter_km, depth_m_min, depth_m_max, 
    auditjoin, area_depth)


## Station data ----------------------------------------------------------------

lookup <- c(
  year = "survey_year", 
  station = "stationid"
)

# station	station_id	stratum_id			station_type	details	station_desc		year_implimented	area	perimeter

station_data <- 
  racebase_haul0 %>% 
    dplyr::rename(dplyr::any_of(lookup)) %>%
    dplyr::mutate(SRVY = dplyr::case_when(
      region == "BS" & stratum %in% c(70, 71, 81) ~ "NBS", 
      region == "BS" & stratum %in% c(50, 32, 31, 42, 10, 20, 43, 62, 41, 61, 90, 82, 81, 70, 71) ~ "EBS", 
      TRUE ~ region)) %>% 
    dplyr::filter(!is.na(stratum)) %>%
    dplyr::filter(!is.na(station)) %>% 
    dplyr::select(stratum, station, SRVY) %>% 
    dplyr::distinct() %>% 
    dplyr::mutate(station_join = cur_group_id(), 
                  station_description = NA,
                  area = NA, 
                  perimeter = NA) %>% 
  dplyr::left_join(
    x = ., 
    y = stratum_data %>% 
      dplyr::select()
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

## BIOMASS_ABUNDANCE -----------------------------------------------------------
OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM <- bio_abund_data
names(OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM) <- tolower(names(OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM))
readr::write_csv(x = OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM, 
                 file = tolower(paste0(dir_out, "OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM.csv")))
names(OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM) <- toupper(names(OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM))

RODBC::sqlDrop(channel = channel_products,
               sqtable = "OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM")

RODBC::sqlSave(channel = channel_products, 
               dat = OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM)

## CPUE --------------------------------------------------------------
OLD_CPUE_STATION <- cpue_data
names(OLD_CPUE_STATION) <- tolower(names(OLD_CPUE_STATION))
readr::write_csv(x = OLD_CPUE_STATION, 
                 file = tolower(paste0(dir_out, "OLD_CPUE_STATION.csv")))
names(OLD_CPUE_STATION) <- toupper(names(OLD_CPUE_STATION))

RODBC::sqlDrop(channel = channel_products,
               sqtable = "OLD_CPUE_STATION")

RODBC::sqlSave(channel = channel_products, 
               dat = OLD_CPUE_STATION)

## LD_COMP_AGE_SIZE_STRATUM --------------------------------------------------------------
OLD_COMP_AGE_SIZE_STRATUM <- comp_data
names(OLD_COMP_AGE_SIZE_STRATUM) <- tolower(names(OLD_COMP_AGE_SIZE_STRATUM))
readr::write_csv(x = OLD_COMP_AGE_SIZE_STRATUM, 
                 file = tolower(paste0(dir_out, "OLD_COMP_AGE_SIZE_STRATUM.csv")))
names(OLD_COMP_AGE_SIZE_STRATUM) <- toupper(names(OLD_COMP_AGE_SIZE_STRATUM))

RODBC::sqlDrop(channel = channel_products,
               sqtable = "OLD_COMP_AGE_SIZE_STRATUM")

RODBC::sqlSave(channel = channel_products, 
               dat = OLD_COMP_AGE_SIZE_STRATUM)
# Grant access to data to all schemas ------------------------------------------

locations <- c("OLD_COMP_AGE_SIZE_STRATUM", "OLD_CPUE_STATION", "OLD_BIOMASS_ABUNDANCE_CPUE_STRATUM")
all_schemas <- RODBC::sqlQuery(channel = channel_products,
                               query = paste0('SELECT * FROM all_users;'))
for (i in 1:length(sort(all_schemas$USERNAME))) {
  for (ii in 1:length(locations)){
    RODBC::sqlQuery(channel = channel_products,
                    query = paste0('grant select on GAP_PRODUCTS.',locations[ii],' to ',all_schemas$USERNAME[i],';'))
  }
}

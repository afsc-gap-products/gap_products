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


# DOWNLOAD CURRENT ESTIMATE DATASETS -------------------------------------------

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
  
  "AI.AIGRID_GIS", 
  "GOA.GOAGRID_GIS", 
  "RACEBASE.STRATUM", 
  
  
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
  "GOA.GOA_GRID"
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

# Load data --------------------------------------------------------------------

a <- tolower(gsub(pattern = ".", replacement = "_", x = a, fixed = TRUE))

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
cpue_data <- dplyr::bind_rows(
  # crab EBS + NBS data
  crab_gap_ebs_nbs_crab_cpue0 %>% 
    dplyr::rename(year = survey_year) %>% 
    dplyr::mutate(cpue_kgha = cpuewgt_total, 
                  cpue_noha = cpuenum_total), 
  # NBS data
  nbsshelf_nbs_cpue0 %>% 
    dplyr::mutate(SRVY = "NBS", 
                  cpue_kgha = wgtcpue/100, 
                  cpue_noha = numcpue/100), 
  # EBS data
  ebsshelf_ebsshelf_cpue0 %>% 
    dplyr::mutate(SRVY = "EBS", 
                  cpue_kgha = wgtcpue/100, 
                  cpue_noha = numcpue/100), 
  # BSS data
  hoffj_cpue_ebsslope_pos0 %>% # ESS CPUE data
    dplyr::mutate(SRVY = "ESS", 
                  number_fish = NA) %>% # PROBLEM
    dplyr::rename(cpue_noha = numcpue, 
                  cpue_kgha = wgtcpue), 
  # GOA data
  goa_cpue0 %>%
    dplyr::mutate(SRVY = "AI") %>% # GOA CPUE data
    dplyr::rename(cpue_noha = numcpue, 
                  cpue_kgha = wgtcpue),
  # AI data
  ai_cpue0 %>%
    dplyr::mutate(SRVY = "AI") %>% # AI CPUE data
    dplyr::rename(cpue_noha = numcpue, 
                  cpue_kgha = wgtcpue) ) %>% 
  dplyr::select(SRVY, year, species_code, hauljoin, cpue_noha, cpue_kgha, number_fish)  #%>% 
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
  "area" = "regulatory_area_name", 
  area = "summary_area", 
  "depth" = "summary_area_depth", 
  depth = "summary_depth", 
  "haulcount" = "haul_count", 
  "catcount" = "catch_count", 
  "meanwgtcpue" = "mean_wgt_cpue", 
  "varmnwgtcpue" = "var_wgt_cpue", 
  "meannumcpue" = "mean_num_cpue", 
  "varmnnumcpue" = "var_num_cpue", 
  "biomass" = "area_biomass", 
  "biomass" = "stratum_biomass", 
  "biomass" = "total_biomass", 
  biomass = "biomass_total",
  "varbio" = "biomass_var", 
  "population" = "area_pop", 
  "population" = "stratum_pop", 
  "population" = "total_pop", 
  population = "abundance", 
  "varpop" = "pop_var", 
  "lowerb" = "min_biomass", 
  "lowerb" = "min_biomass", # Is this right?
  "upperb" = "max_biomass",  # is this right?
  lowerb = "biomass_lower_ci", 
  upperb = "biomass_upper_ci", 
  "lowerp" = "min_pop", # Is this right?
  "upperp" = "max_pop", 
  lowerp = "abundance_lower_ci", 
  upperp = "abundance_upper_ci")

bio_abund_data <- dplyr::bind_rows(
  # crab EBS + NBS data
  crab_gap_ebs_nbs_abundance_biomass0 %>% 
    dplyr::mutate(
      file = "crab_gap_ebs_nbs_abundance_biomass0") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  # NBS data
  haehnr_biomass_nbs_safe0 %>% 
    dplyr::mutate(
      SRVY = "NBS", 
      file = "haehnr_biomass_nbs_safe0") %>%
    dplyr::rename(dplyr::any_of(lookup)),  
  # EBS data
  haehnr_biomass_ebs_plusnw_grouped0 %>% 
    dplyr::mutate(
      SRVY = "EBS", 
      file = "haehnr_biomass_ebs_plusnw_grouped0") %>%
    dplyr::rename(dplyr::any_of(lookup)),  
  haehnr_biomass_ebs_plusnw0 %>% 
    dplyr::mutate(
      SRVY = "EBS", 
      file = "haehnr_biomass_ebs_plusnw0") %>%
    dplyr::rename(dplyr::any_of(lookup)),  
  # BSS data doesnt exist
  # GOA data
  goa_biomass_total0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa_biomass_total0") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_stratum0 %>%
    dplyr::mutate(
      SRVY = "GOA",
      file = "goa_biomass_stratum0") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  # AI data
  ai_biomass_total0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai_biomass_total0") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_stratum0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai_biomass_stratum0")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
    ai_biomass_area0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai_biomass_area0", 
      area_type = "regulatory")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_area_depth0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai_biomass_area_depth0", 
      area_type = "regulatory") %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_by_length0 %>%
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai_biomass_by_length0")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_depth0 %>%
    dplyr::mutate(
      SRVY = "AI", 
                  file = "ai_biomass_depth0")  %>%
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_biomass_inpfc_depth0 %>% # are there inpfc regions?
    dplyr::mutate(
      SRVY = "AI", 
      file = "ai_biomass_inpfc_depth0", 
      area_type = "inpfc") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_area0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa_biomass_area0", 
      area_type = "regulatory") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_by_length0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa_biomass_by_length0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_depth0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa_biomass_depth0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_inpfc0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa_biomass_inpfc0", 
      area_type = "inpfc", 
      summary_area = as.character(summary_area)) %>% # is this right?/make sense
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_biomass_inpfc_depth0 %>%
    dplyr::mutate(
      SRVY = "GOA", 
      file = "goa_biomass_inpfc_depth0", 
      area_type = "inpfc") %>% 
    dplyr::rename(dplyr::any_of(lookup))
 ) %>%
  dplyr::select(SRVY, year, species_code, stratum, area, area_type, depth, length_class,
                biomass, varbio, lowerb, upperb, degreefwgt,
                population, varpop, lowerp, upperp, degreefnum,
                meanwgtcpue, varmnwgtcpue, meannumcpue, varmnnumcpue,
                haulcount, catcount, numcount, lencount)


## Comp data -------------------------------------------------------------------

lookup <- c(
  depth = "summary_area_depth", 
  depth = "summary_depth", 
  area = "summary_area", 
  value = "length", 
                area = "regulatory_area_name")


# length comps
sizecomp_data <- dplyr::bind_rows(
  # NBS data
  haehnr_sizecomp_nbs_stratum0 %>% 
    dplyr::mutate(SRVY = "NBS", 
                  file = "haehnr_sizecomp_nbs_stratum0") %>% 
    dplyr::rename(dplyr::any_of(lookup)) , 
  # EBS data
  haehnr_sizecomp_ebs_plusnw_stratum0 %>% 
    dplyr::mutate(SRVY = "EBS", 
                  file = "haehnr_sizecomp_ebs_plusnw_stratum0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  haehnr_sizecomp_ebs_plusnw_stratum_grouped0 %>% 
    dplyr::mutate(SRVY = "EBS", 
                  file = "haehnr_sizecomp_ebs_plusnw_stratum_grouped0") %>% 
    dplyr::rename(dplyr::any_of(lookup)),
  # BSS data
  hoffj_sizecomp_ebsslope0 %>% 
    dplyr::mutate(SRVY = "BSS", 
                  file = "hoffj_sizecomp_ebsslope0") %>% 
    dplyr::rename(dplyr::any_of(lookup)),   
  # GOA data
  goa_sizecomp_stratum0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  file = "goa_sizecomp_stratum0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_total0 %>%
    dplyr::mutate(SRVY = "GOA", 
                  file = "goa_sizecomp_total0") %>% 
    dplyr::rename(stratum = summary_area) %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  # AI data
  ai_sizecomp_stratum0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  file = "ai_sizecomp_stratum0") %>% 
    dplyr::rename(dplyr::any_of(lookup)),
  ai_sizecomp_total0  %>%
    dplyr::mutate(SRVY = "AI", 
                  file = "ai_sizecomp_total0") %>% 
    dplyr::rename(stratum = summary_area) %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_area0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "regulatory", 
                  file = "ai_sizecomp_area0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_area_depth0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "regulatory", 
                  file = "ai_sizecomp_area_depth0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_depth0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  file = "ai_sizecomp_depth0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_inpfc_depth0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "inpfc", 
                  file = "ai_sizecomp_inpfc_depth0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  ai_sizecomp_inpfc0 %>% 
    dplyr::mutate(SRVY = "AI", 
                  area_type = "inpfc", 
                  summary_area = as.character(summary_area), 
                  file = "ai_sizecomp_inpfc0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  # goa_sizecomp_area_depth0
  goa_sizecomp_area0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "regulatory", 
                  file = "goa_sizecomp_area0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_depth0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  file = "goa_sizecomp_depth0") %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_inpfc0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "inpfc", 
                  file = "goa_sizecomp_inpfc0", 
                  summary_area = as.character(summary_area)) %>% 
    dplyr::rename(dplyr::any_of(lookup)), 
  goa_sizecomp_inpfc_depth0 %>% 
    dplyr::mutate(SRVY = "GOA", 
                  area_type = "inpfc", 
                  file = "goa_sizecomp_inpfc_depth0") %>% 
    dplyr::rename(dplyr::any_of(lookup))
) %>% 
  dplyr::select(SRVY, year, stratum, species_code, area, area_type, depth, length, males, females, unsexed) %>%
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
    haehnr_agecomp_ebs_plusnw_stratum0 %>% 
      dplyr::mutate(SRVY = "EBS"), 
    # NBS data
    haehnr_agecomp_nbs_stratum0 %>% 
      dplyr::mutate(SRVY = "NBS"), 
    # No BSS data
    # AI data
    ai_agecomp_total0 %>% # only totals because sample size is too small
      dplyr::rename(
        year = survey_year, 
        meanlen = mean_length, 
        sdev = standard_deviation)  %>% 
      dplyr::mutate(SRVY = "AI"), 
    # GOA data
    goa_agecomp_total0 %>% # only totals because sample size is too small
      dplyr::rename(
        year = survey_year, 
        meanlen = mean_length, 
        sdev = standard_deviation)  %>% 
      dplyr::mutate(SRVY = "GOA"))  %>% 
    dplyr::rename(value = age, 
                  pop = agepop ) %>% 
    dplyr::select(SRVY, species_code, year, value, sex, pop) %>% 
    dplyr::mutate(comp = "age", 
                  sex = dplyr::case_when(
                    sex == 1 ~ "males", 
                    sex == 2 ~ "females", 
                    sex == 3 ~ "unsexed")) )

# comp data
comp_data <- dplyr::bind_rows(
  sizecomp_data, agecomp_data) %>%
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

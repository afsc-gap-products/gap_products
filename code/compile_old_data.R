
# Load data --------------------------------------------------------------------

# from code/data_dl_compile_old_data.R
a <- c( 
  # CPUE Haul by Haul for all species zero filled
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
  "AI.AGECOMP_TOTAL", 
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
  
  # Stratum info
  "AI.AIGRID_GIS", 
  "GOA.GOAGRID_GIS", 
  "RACEBASE.STRATUM"
)

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
bio_abund_data <- dplyr::bind_rows(
  # crab EBS + NBS data
  crab_gap_ebs_nbs_abundance_biomass0 %>% 
    dplyr::rename(SRVY = survey_region, 
                  year = survey_year, 
                  biomass = biomass_total,
                  lowerb = biomass_lower_ci, 
                  upperb = biomass_upper_ci, 
                  population = abundance, 
                  lowerp = abundance_lower_ci, 
                  upperp = abundance_upper_ci), 
  # NBS data
  haehnr_biomass_nbs_safe0 %>% 
    dplyr::mutate(SRVY = "NBS"), 
  # EBS data
  haehnr_biomass_ebs_plusnw_grouped0 %>% 
    dplyr::mutate(SRVY = "EBS"), 
  haehnr_biomass_ebs_plusnw0 %>% 
    dplyr::mutate(SRVY = "EBS"), 
  # BSS data doesnt exist
  # GOA data
  goa_biomass_total0 %>%
    dplyr::mutate(SRVY = "GOA") %>% 
    dplyr::rename(haulcount = haul_count, 
                  catcount = catch_count, 
                  meanwgtcpue = mean_wgt_cpue, 
                  varmnwgtcpue = var_wgt_cpue, 
                  meannumcpue = mean_num_cpue, 
                  varmnnumcpue = var_num_cpue, 
                  biomass = total_biomass, 
                  varbio = biomass_var, 
                  population = total_pop, 
                  varpop = pop_var),
  goa_biomass_stratum0 %>%
    dplyr::mutate(SRVY = "GOA") %>% 
    dplyr::rename(haulcount = haul_count, 
                  catcount = catch_count, 
                  meanwgtcpue = mean_wgt_cpue, 
                  varmnwgtcpue = var_wgt_cpue, 
                  meannumcpue = mean_num_cpue, 
                  varmnnumcpue = var_num_cpue, 
                  biomass = stratum_biomass, 
                  varbio = biomass_var, 
                  population = stratum_pop, 
                  varpop = pop_var),
  # AI data
  ai_biomass_total0 %>%
    dplyr::mutate(SRVY = "AI") %>% 
    dplyr::rename(haulcount = haul_count, 
                  catcount = catch_count, 
                  meanwgtcpue = mean_wgt_cpue, 
                  varmnwgtcpue = var_wgt_cpue, 
                  meannumcpue = mean_num_cpue, 
                  varmnnumcpue = var_num_cpue, 
                  biomass = total_biomass, 
                  varbio = biomass_var, 
                  population = total_pop, 
                  varpop = pop_var), 
  ai_biomass_stratum0 %>%
    dplyr::mutate(SRVY = "AI") %>% 
    dplyr::rename(haulcount = haul_count, 
                  catcount = catch_count, 
                  meanwgtcpue = mean_wgt_cpue, 
                  varmnwgtcpue = var_wgt_cpue, 
                  meannumcpue = mean_num_cpue, 
                  varmnnumcpue = var_num_cpue, 
                  biomass = stratum_biomass, 
                  varbio = biomass_var, 
                  population = stratum_pop, 
                  varpop = pop_var)) %>% 
  dplyr::select(SRVY, year, species_code, stratum, 
                haulcount, catcount, numcount, lencount, 
                meanwgtcpue, varmnwgtcpue, meannumcpue, varmnnumcpue, 
                biomass, varbio, lowerb, upperb, degreefwgt, 
                population, varpop, lowerp, upperp, degreefnum)  

## Comp data -------------------------------------------------------------------

# length comps
sizecomp_data <- dplyr::bind_rows(
  # NBS data
  haehnr_sizecomp_nbs_stratum0 %>% 
    dplyr::mutate(SRVY = "NBS"), 
  # EBS data
  haehnr_sizecomp_ebs_plusnw_stratum0 %>% 
    dplyr::mutate(SRVY = "EBS"), 
  haehnr_sizecomp_ebs_plusnw_stratum_grouped0 %>% 
    dplyr::mutate(SRVY = "EBS"),
  # BSS data
  hoffj_sizecomp_ebsslope0 %>% 
    dplyr::mutate(SRVY = "BSS"),   
  # GOA data
  goa_sizecomp_stratum0 %>% 
    dplyr::mutate(SRVY = "GOA"), 
  goa_sizecomp_total0 %>%
  dplyr::mutate(SRVY = "GOA"), 
  # AI data
  ai_sizecomp_stratum0 %>% 
    dplyr::mutate(SRVY = "AI"),
  ai_sizecomp_total0  %>%
    dplyr::mutate(SRVY = "AI")
  ) %>% 
  dplyr::select(SRVY, stratum, species_code, year, length, males, females, unsexed)%>% 
  dplyr::mutate(comp = "length") %>% 
  dplyr::rename(value = length) %>% 
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
BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD <- bio_abund_data
names(BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD) <- tolower(names(BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD))
readr::write_csv(x = BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD, 
                 file = tolower(paste0(dir_out, "BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD.csv")))
names(BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD) <- toupper(names(BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD))

# RODBC::sqlDrop(channel = channel_products, 
#                sqtable = "BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD")

RODBC::sqlSave(channel = channel_products, 
               dat = BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD)

## CPUE --------------------------------------------------------------
CPUE_STATION_OLD <- cpue_data
names(CPUE_STATION_OLD) <- tolower(names(CPUE_STATION_OLD))
readr::write_csv(x = CPUE_STATION_OLD, 
                 file = tolower(paste0(dir_out, "CPUE_STATION_OLD.csv")))
names(CPUE_STATION_OLD) <- toupper(names(CPUE_STATION_OLD))

# RODBC::sqlDrop(channel = channel_products, 
#                sqtable = "CPUE_STATION_OLD")

RODBC::sqlSave(channel = channel_products, 
               dat = CPUE_STATION_OLD)

## COMP_AGE_SIZE_STRATUM_OLD --------------------------------------------------------------
COMP_AGE_SIZE_STRATUM_OLD <- comp_data
names(COMP_AGE_SIZE_STRATUM_OLD) <- tolower(names(COMP_AGE_SIZE_STRATUM_OLD))
readr::write_csv(x = COMP_AGE_SIZE_STRATUM_OLD, 
                 file = tolower(paste0(dir_out, "COMP_AGE_SIZE_STRATUM_OLD.csv")))
names(COMP_AGE_SIZE_STRATUM_OLD) <- toupper(names(COMP_AGE_SIZE_STRATUM_OLD))

# RODBC::sqlDrop(channel = channel_products, 
#                sqtable = "COMP_AGE_SIZE_STRATUM_OLD")

RODBC::sqlSave(channel = channel_products, 
               dat = COMP_AGE_SIZE_STRATUM_OLD)
# Grant access to data to all schemas ------------------------------------------

locations <- c("COMP_AGE_SIZE_STRATUM_OLD", "CPUE_STATION_OLD", "BIOMASS_ABUNDANCE_CPUE_STRATUM_OLD")
all_schemas <- RODBC::sqlQuery(channel = channel_products,
                               query = paste0('SELECT * FROM all_users;'))
for (i in 1:length(sort(all_schemas$USERNAME))) {
  for (ii in 1:length(locations)){
    RODBC::sqlQuery(channel = channel_products,
                    query = paste0('grant select on GAP_PRODUCTS.',locations[ii],' to ',all_schemas$USERNAME[i],';'))
  }
}

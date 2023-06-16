#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-04-01
#' Notes: 
#' -----------------------------------------------------------------------------

# Load Data --------------------------------------------------------------------

## LOAD Data -----------------------------------------------------------------
a <- c(list.files(path = dir_data, pattern = "racebase."), 
       list.files(path = dir_data, pattern = "race_data."), 
       "spp_info.csv", 
       "taxon_confidence.csv")
for (i in 1:length(a)){
  print(a[i])
  b <- readr::read_csv(file = paste0(dir_data, a[i])) %>% 
    janitor::clean_names(.)
  if (names(b)[1] %in% "x1"){
    b$x1<-NULL
  }
  assign(x = gsub(pattern = "\\.csv", replacement = "", x = paste0(a[i], "0")), value = b) # 0 at the end of the name indicates that it is the orig unmodified file
}

## Taxonomic confidence data ---------------------------------------------------

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
                        values_to = "taxon_confidence") %>% 
    dplyr::mutate(year = gsub(pattern = "[a-z]", 
                              replacement = "", 
                              x = year), 
                  year = gsub(pattern = "_0", replacement = "", 
                              x = year), 
                  year = as.numeric(year)) %>% 
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

OLD_TAXON_CONFIDENCE <- dplyr::bind_rows(df.ls) %>% 
  dplyr::mutate(taxon_confidence_code = taxon_confidence, 
                taxon_confidence = dplyr::case_when(
                  taxon_confidence_code == 1 ~ "High",
                  taxon_confidence_code == 2 ~ "Moderate",
                  taxon_confidence_code == 3 ~ "Low", 
                  TRUE ~ "Unassessed")) %>%
  dplyr::left_join(y = surveys, 
                   by = "SRVY") 

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
  # metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated)

OLD_TAXON_CONFIDENCE <- OLD_TAXON_CONFIDENCE %>% 
  dplyr::select(-SRVY_long, -SRVY)
#     
#     readr::write_csv(x = tax_conf, 
#                      file = paste0(getwd(), "/data/taxon_confidence.csv"))
#     
#     save(tax_conf, file = paste0(getwd(), "/data/taxon_confidence.rdata"))
#     
#   }
#   # Wrangle Data -----------------------------------------------------------------
#   
#   ## Species info ----------------------------------------------------------------
#   if (taxize0){
#     spp_info <-
#       # dplyr::left_join(
#       # x =
#       racebase_species0 %>%
#       dplyr::select(species_code, common_name, species_name) %>% # ,
#       # y = species_taxonomics0 %>%
#       # dplyr::select(),
#       # by = c("")) %>%
#       dplyr::rename(scientific_name = species_name) %>%
#       dplyr::mutate( # fix rouge spaces in species names
#         common_name = ifelse(is.na(common_name), "", common_name),
#         common_name = gsub(pattern = "  ", replacement = " ",
#                            x = trimws(common_name), fixed = TRUE),
#         scientific_name = ifelse(is.na(scientific_name), "", scientific_name),
#         scientific_name = gsub(pattern = "  ", replacement = " ",
#                                x = trimws(scientific_name), fixed = TRUE), 
#         itis = NA, 
#         worms = NA) # made if taxize0 == TRUE
#   } else {
#     load(file = "./data/spp_info.rdata")
#     spp_info <- spp_info %>% 
#       dplyr::select(-notes_itis, -notes_worms)
#   }

## cruises ---------------------------------------------------------------------
cruises <-  
  dplyr::left_join(
    x = surveys, # a data frame of all surveys and survey_definition_ids we want included in the public data, created in the run.R script
    y = race_data_v_cruises0, 
    by  = c("survey_definition_id")) %>% 
  dplyr::select(SRVY, SRVY_long, region, cruise_id,  year, survey_name, 
                vessel_id, cruise, survey_definition_id, 
                vessel_name, start_date, end_date, cruisejoin) %>% 
  dplyr::filter(year != 2020 & # no surveys happened this year because of COVID
                  (year >= 1982 & SRVY %in% c("EBS", "NBS") | # 1982 BS inclusive - much more standardized after this year
                     SRVY %in% "BSS" | # keep all years of the BSS
                     year >= 1991 & SRVY %in% c("AI", "GOA")) & # 1991 AI and GOA (1993) inclusive - much more standardized after this year
                  survey_definition_id %in% surveys$survey_definition_id) %>% 
  dplyr::rename(vessel = "vessel_id")

# # Looking for 0s in years we dont want data to make sure the years we want removed are gone 
# table(cruises[,c("SRVY", "year")]) # 2021
# # year
# # SRVY  1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 ...
# # AI     0    0    0    0    0    0    0    0    0    2    0    0    2   ... 
# # EBS    2    3    2    2    2    2    2    2    2    2    2    2    2   ...
# # GOA    0    0    0    0    0    0    0    0    0    0    0    4    0   ...
# # NBS    0    0    0    0    0    0    0    0    0    0    0    0    0   ...
# 
# dim(cruises)
# # > dim(cruises)
# # [1] 156  13

## haul ------------------------------------------------------------------------

haul <- racebase_haul0 %>%
  dplyr::filter(
    abundance_haul == "Y" & # defined historically as being good tows for abundance estimates
      haul_type == 3 & # standard non-retow or special proj tows
      performance >= 0 # &
  ) %>% 
  dplyr::select(-auditjoin, -net_measured) # not valuable to us, here

## catch -----------------------------------------------------------------------

# ## there should only be one species_code observation per haul event, however
# ## there are occassionally multiple (with unique catchjoins). 
# ## I suspect that this is because a species_code was updated or changed, 
# ## so we will need to sum those counts and weights
# 
# catch0 %>%
#     dplyr::filter(region != "WC") %>% 
#   dplyr::mutate(id = paste0(region, "_", cruisejoin, "_", hauljoin, "_", species_code)) %>%
#   dplyr::select(id) %>%
#   table() %>%
#   data.frame() %>%
#   dplyr::rename("id" = ".") %>%
#   dplyr::filter(Freq > 1)

catch <- racebase_catch0 %>% 
  dplyr::group_by(region, cruisejoin, hauljoin, vessel, haul, species_code) %>% 
  dplyr::summarise(weight = sum(weight, na.rm = TRUE), 
                   number_fish = sum(number_fish, na.rm = TRUE))

# dim(catch) # 2021
# [1] 1613670       8

## catch_haul_cruises ----------------------------------------------------------

catch_haul_cruises <-
  dplyr::inner_join(
    x = cruises %>% 
      dplyr::select(cruisejoin, vessel, region,  
                    survey_definition_id, SRVY, SRVY_long, survey_name, year, cruise),  
    y = haul %>% 
      dplyr::select(cruisejoin, vessel, region, 
                    hauljoin, stationid, stratum, haul, start_time, 
                    start_latitude, start_longitude, end_latitude, end_longitude, 
                    bottom_depth, gear_temperature, surface_temperature, performance, 
                    duration, distance_fished, net_width, net_height), 
    by = c("cruisejoin", "vessel", "region")) %>% 
  dplyr::left_join(
    x= ., 
    y = catch %>% 
      dplyr::select(cruisejoin, hauljoin, region, vessel, haul, 
                    species_code, weight, number_fish), 
    by = c("hauljoin", "cruisejoin", "region", "vessel", "haul"))


# fill in tax_conf with, if missing, the values from the year before
comb1 <- unique(catch_haul_cruises[, c("SRVY", "year")] )
comb2 <- unique(tax_conf[, c("SRVY", "year")])
# names(comb2) <- names(comb1) <- c("SRVY", "year")
comb1$comb <- paste0(comb1$SRVY, "_", comb1$year)
comb2$comb <- paste0(comb2$SRVY, "_", comb2$year)
comb <- strsplit(x = setdiff(comb1$comb, comb2$comb), split = "_")

for (i in 1:length(comb)) {
  srvy0 <- comb[[i]][1]
  year0 <- as.numeric(comb[[i]][2])
  
  yr_prev <- tax_conf %>% 
    dplyr::filter(SRVY == srvy0)
  
  # if there is one entry for all years of the survey
  if (length(unique(yr_prev$year)) == 1) {
    if (is.na(unique(yr_prev$year))) {
      tax_conf <- dplyr::bind_rows(tax_conf, 
                                 yr_prev %>% 
                                   dplyr::mutate(year = year0))
    }
  } else {
  
  # missing year - find closest previous year
    tax_conf <- dplyr::bind_rows(tax_conf, 
                                yr_prev %>% 
      dplyr::filter(year < year0) %>% 
      dplyr::filter(year == max(year, na.rm = TRUE)) %>% 
      dplyr::mutate(year = year0) )
  }

}

catch_haul_cruises <- catch_haul_cruises %>% 
  {if(taxize0) dplyr::left_join(x = ., 
                   y = tax_conf %>% 
                     dplyr::select(year, tax_conf, SRVY, species_code), 
                   by = c("species_code", "SRVY", "year")) else .}  %>%
  dplyr::left_join(
    x = .,
    y = race_data_race_data_vessels0 %>%
      dplyr::select(vessel_id, name) %>%
      dplyr::rename(vessel_name = name) %>% 
      dplyr::mutate(vessel_name = stringr::str_to_title(vessel_name)), 
    by = c("vessel" = "vessel_id")) %>%
  dplyr::left_join(
    x = .,
    y = spp_info %>%
      dplyr::select(species_code, scientific_name, common_name, itis, worms),
    by = "species_code")

# dim(catch_haul_cruises) # 2021
# [1] 831342     33 


# *** haul_cruises_vess_ + _maxyr + _compareyr -------------------------------------

temp <- function(cruises_, haul_){
  haul_cruises_vess_ <- 
    dplyr::left_join(x = cruises_ ,
                     y = haul_ %>% 
                       dplyr::select(cruisejoin, hauljoin, stationid, stratum, haul, 
                                     gear_depth, duration, distance_fished, net_width, net_height,
                                     start_time) %>% 
                       dplyr::group_by(cruisejoin, hauljoin, stationid, stratum, haul, 
                                       gear_depth, duration, distance_fished, net_width, net_height) %>% 
                       dplyr::summarise(start_date_haul = min(start_time),
                                        end_date_haul = max(start_time), 
                                        stations_completed = length(unique(stationid))),
                     by = c("cruisejoin")) %>% 
    dplyr::left_join(x = . , 
                     y = race_data_vessels0 %>%
                       dplyr::rename(vessel = vessel_id) %>%
                       dplyr::select(vessel, length, tonnage), 
                     by = "vessel") %>% 
    dplyr::rename(length_ft = length) %>% 
    dplyr::mutate(length_m = round(length_ft/3.28084, 
                                   digits = 1)) %>% 
    dplyr::ungroup()
}

haul_cruises_vess <- temp(cruises, haul) 

## stratum ---------------------------------------------------------------------

# temp <- function(strat_yr) {#yr) {
  
  # # unique  and sort are not necessary, just easier for troubleshooting
  # if (sum(yr<unique(stratum0$year)) == 0) {
  # # if (sum((yr - stratum0$year)<0 %in% TRUE) == 0) {
  #   # if there are no stratum years greater than yr, use the most recent stratum year
  # strat_yr <- max(stratum0$year)
  # } else {
  #   # if the yr is less than the max stratum year, use the stratum yr next less
  #   temp <- sort(unique(stratum0$year))
  #   strat_yr <- temp[which((yr - temp)>-1)[length(which((yr - temp)>-1))]]
  #   # strat_yr <- sort(unique(stratum0$year))[which.min((yr - sort(unique(stratum0$year)))[(yr - sort(unique(stratum0$year)))>=0])]
  # }
  # 

library(akgfmaps)

akgfmaps::get_base_layers(
  select.region = "bs.south")$Stratum

stratum_info <- dplyr::bind_rows(
  racebase_stratum0 %>% 
    dplyr::filter(
      # stratum %in% reg_dat$survey.strata$Stratum &
        year == strat_yr) %>%
    dplyr::mutate(depth = gsub(pattern = "> 1", 
                               replacement = ">1", 
                               x = description), 
                  depth =
                    gsub(pattern = "[a-zA-Z]+",
                         replacement = "",
                         x = sapply(X = strsplit(
                           x = depth,
                           split = " ",
                           fixed = TRUE),
                           function(x) x[1])
                    )) %>% 
    dplyr::select(-auditjoin, -portion) %>%
    dplyr::mutate(SRVY = dplyr::case_when(
      stratum %in% as.numeric(report_types$EBS$reg_dat$survey.strata$Stratum) ~ "EBS", 
      stratum %in% as.numeric(report_types$NBS$reg_dat$survey.strata$Stratum) ~ "NBS" 
    )) %>% 
    dplyr::filter(SRVY %in% SRVY1) %>% 
    dplyr::mutate(type = dplyr::case_when( 
      SRVY == "NBS" ~ "Shelf",
      depth %in% "<50" ~ "Inner Shelf", 
      depth %in% c("50-100", ">50") ~ "Middle Shelf", 
      depth %in% c("100-200", ">100") ~ "Outer Shelf"
    )) %>% 
    dplyr::mutate(area_km2 = area, 
                  area_ha = area/divkm2forha, 
                  area_nmi2 = area/divkm2fornmi2)
)

for (i in 1:nrow(survey)) {

  
  
  
  
  strat_yr <- max(racebase_stratum0[racebase_stratum0$, "year"])
  
  stratum_info <- 
  
  # return(stratum_info)
  
}

stratum_info <- temp()#yr = strat_yr)

stratum_info <- 
  dplyr::left_join(
    x = stratum_info, 
    y = haul_maxyr %>% 
      dplyr::distinct(stratum, stationid, stationid) %>% 
      dplyr::select(stratum, stationid) %>% 
      dplyr::group_by(stratum) %>% 
      dplyr::summarise(stations_completed = length(unique(stationid))) %>% 
      dplyr::select(stratum, stations_completed), 
    by = "stratum") %>% 
  dplyr::left_join(
    x = ., 
    y = station_info %>% 
      dplyr::select(stratum, stationid) %>% 
      dplyr::group_by(stratum) %>% 
      dplyr::summarise(stations_avail = length(unique(stationid))) %>% 
      dplyr::select(stratum, stations_avail), 
    by = "stratum") %>% 
  dplyr::left_join(
    x = ., 
    y = haul_maxyr %>% 
      dplyr::select(stratum, stationid, bottom_depth) %>% 
      dplyr::group_by(stratum) %>% 
      dplyr::summarise(depth_mean = mean(bottom_depth, na.rm = TRUE), 
                       depth_min = min(bottom_depth, na.rm = TRUE), 
                       depth_max = max(bottom_depth, na.rm = TRUE)), 
    by = "stratum") 



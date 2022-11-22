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

tax_conf <- taxon_confidence0%>% 
  dplyr::rename(SRVY = srvy)
if (FALSE) {
    df.ls <- list()
    a <- list.files(path = here::here("data", "taxon_confidence"))
    a <- a[a != "taxon_confidence.csv"]
    for (i in 1:length(a)){
      print(a[i])
      b <- readxl::read_xlsx(path = paste0(here::here("data", "taxon_confidence", a[i])), 
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
                            values_to = "tax_conf") %>% 
        dplyr::mutate(year = 
                        as.numeric(gsub(pattern = "[a-z]", 
                                        replacement = "", 
                                        x = year))) %>% 
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
    
    # any duplicates in any taxon confidence tables?
    # SameColNames(df.ls) %>%
    #        dplyr::group_by(srvy) %>%
    #        dplyr::filter(year == min(year)) %>%
    #        dplyr::ungroup() %>%
    #        dplyr::select(species_code, srvy) %>%
    #        table() %>% # sets up frequency table
    #        data.frame() %>%
    #        dplyr::filter(Freq > 1)
    
    # Quality Codes
    # 1 – High confidence and consistency.  Taxonomy is stable and reliable at this 
    #     level, and field identification characteristics are well known and reliable.
    # 2 – Moderate confidence.  Taxonomy may be questionable at this level, or field  
    #     identification characteristics may be variable and difficult to assess consistently.
    # 3 – Low confidence.  Taxonomy is incompletely known, or reliable field  
    #     identification characteristics are unknown.
    
    tax_conf <- SameColNames(df.ls) %>% 
      dplyr::rename(SRVY = srvy) %>%
      dplyr::mutate(tax_conf0 = tax_conf, 
                    tax_conf = dplyr::case_when(
                      tax_conf == 1 ~ "High",
                      tax_conf == 2 ~ "Moderate",
                      tax_conf == 3 ~ "Low", 
                      TRUE ~ "Unassessed"))
    
    readr::write_csv(x = tax_conf, 
                     file = paste0(getwd(), "/data/taxon_confidence.csv"))
    
    save(tax_conf, file = paste0(getwd(), "/data/taxon_confidence.rdata"))
    
  }
  # Wrangle Data -----------------------------------------------------------------
  
  ## Species info ----------------------------------------------------------------
  if (taxize0){
    spp_info <-
      # dplyr::left_join(
      # x =
      racebase_species0 %>%
      dplyr::select(species_code, common_name, species_name) %>% # ,
      # y = species_taxonomics0 %>%
      # dplyr::select(),
      # by = c("")) %>%
      dplyr::rename(scientific_name = species_name) %>%
      dplyr::mutate( # fix rouge spaces in species names
        common_name = ifelse(is.na(common_name), "", common_name),
        common_name = gsub(pattern = "  ", replacement = " ",
                           x = trimws(common_name), fixed = TRUE),
        scientific_name = ifelse(is.na(scientific_name), "", scientific_name),
        scientific_name = gsub(pattern = "  ", replacement = " ",
                               x = trimws(scientific_name), fixed = TRUE), 
        itis = NA, 
        worms = NA) # made if taxize0 == TRUE
  } else {
    load(file = "./data/spp_info.rdata")
    spp_info <- spp_info %>% 
      dplyr::select(-notes_itis, -notes_worms)
  }

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


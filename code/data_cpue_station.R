#' -----------------------------------------------------------------------------
#' title: Create CPUE-station level estimates
#' author: EH Markowitz
#' start date: 2022-01-01
#' Notes: 
#' -----------------------------------------------------------------------------

# Calculate 0-filled station-level CPUE estimates ------------------------------

cpue_station_0filled <- data.frame()

for (i in 1:length(surveys$SRVY)) {
  # need to use a loop here and split up the effort because the 
  # dplyr::crossing() can otherwise overwhelm the computer computing power  
  
  print(surveys$SRVY[i])
  
  # subset data to survey
  temp <- catch_haul_cruises %>% 
    dplyr::filter(SRVY == surveys$SRVY[i]) 
  
  cpue_station_0filled <- 
    tidyr::crossing( # create all possible haul event x species_code combinations
      temp %>% 
        dplyr::select(SRVY, hauljoin, cruisejoin) %>% # unique haul event
        dplyr::distinct(),
      temp %>%
        dplyr::distinct(., species_code)) %>% # unique species_codes
    dplyr::left_join( # overwrite NAs where data exists for CPUE calculation
      x = .,
      y = temp %>%
        dplyr::select(SRVY, cruisejoin, hauljoin, species_code,
                      distance_fished, net_width, weight, number_fish),
      by = c("species_code", "hauljoin", "cruisejoin", "SRVY")) %>%
    # summarize weight and count - already summarized catch data earlier so this step is now obsolete, but wouldnt hurt anything
    # dplyr::group_by(SRVY, hauljoin, cruisejoin, species_code, 
    #                 distance_fished, net_width) %>% 
    # dplyr::summarise(
    #   weight = sum(weight, na.rm = TRUE),
    #   number_fish = sum(number_fish, na.rm = TRUE)) %>%  
    # dplyr::ungroup() %>% 
    dplyr::mutate(# calculates CPUE for each species group by station
      area_swept_ha = distance_fished * (net_width/10), # both in units of km
      cpue_kgha = weight/area_swept_ha, 
      cpue_noha = ifelse(weight > 0 & number_fish == 0, 
                         NA, (number_fish/area_swept_ha))) %>% 
    dplyr::bind_rows(cpue_station_0filled, .)
  
  gc()
}

cpue_station_0filled_clean <- cpue_station_0filled



# print(dim(cpue_station_0filled)) # 2021
# [1] 34344063       11

# Calculate simple station-level CPUE estimates --------------------------------

# Lookup vector to only rename/select if that column is present:
lookup <- c(station = "stationid", 
            weight_kg = "weight", 
            count = "number_fish", 
            srvy = "SRVY",
            survey = "survey_name",
            survey_id = "survey_definition_id", 
            vessel_id = "vessel",
            taxon_confidence = "tax_conf",
            date_time = "start_time", 
            # latitude_dd = "start_latitude", 
            # longitude_dd = "start_longitude", 
            latitude_dd_start = "start_latitude", 
            longitude_dd_start = "start_longitude", 
            latitude_dd_end = "end_latitude", 
            longitude_dd_end = "end_longitude", 
            bottom_temperature_c = "gear_temperature", 
            surface_temperature_c = "surface_temperature",
            distance_fished_km = "distance_fished", 
            duration_hr = "duration", 
            net_width_m = "net_width",
            net_height_m = "net_height",
            depth_m = "bottom_depth")

cpue_station_0filled <- 
  dplyr::left_join( # bind with the rest of the cruise and haul data
    x = cpue_station_0filled, 
    y = catch_haul_cruises %>% 
      dplyr::select(-distance_fished, -net_width, -number_fish, -weight),
    by = c("SRVY", "cruisejoin", "hauljoin", "species_code"))  %>%
  dplyr::rename(dplyr::any_of(lookup)) %>% 
  dplyr::mutate(cpue_kgkm2 = cpue_kgha * 100, 
                cpue_nokm2 = cpue_noha * 100, 
                # cpue_no1000km2 = cpue_nokm2 * 1000, 
                # cpue_kg1000km2 = cpue_kgkm2 * 1000, 
                dplyr::across(dplyr::starts_with("cpue_"), round, digits = 6), 
                weight_kg = round(weight_kg, digits = 6)) %>% 
  dplyr::select(any_of(
    c(as.character(expression(
      year, srvy, survey, survey_id, cruise, haul, hauljoin, stratum, station, vessel_name, vessel_id, # survey data
      date_time, latitude_dd, longitude_dd, latitude_dd_start, longitude_dd_start, latitude_dd_end, longitude_dd_end, # when/where
      species_code, itis, worms, common_name, scientific_name, taxon_confidence, # species info
      cpue_kgha, cpue_kgkm2, #cpue_kg1000km2, # cpue weight
      cpue_noha, cpue_nokm2, #cpue_no1000km2, # cpue num
      weight_kg, count, # summed catch data
      bottom_temperature_c, surface_temperature_c, depth_m, #environmental data
      distance_fished_km, net_width_m, net_height_m, area_swept_ha, duration_hr, performance # gear data
  ))))) %>% 
  dplyr::arrange(srvy, date_time, cpue_kgha)

names(cpue_station_0filled) <- stringr::str_to_upper(names(cpue_station_0filled))

# print(dim(cpue_station_0filled)) # 2021
# [1] 831340     11

# Metadata ---------------------------------------------------------------------

table_metadata <- paste0("This dataset includes zero-filled (presence and absence) observations and catch-per-unit-effort (CPUE) estimates for most identified species at a standard set of stations in the Northern Bering Sea (NBS), Eastern Bering Sea (EBS), Bering Sea Slope (BSS), Gulf of Alaska (GOA), and Aleutian Islands (AI) Surveys conducted by the esource Assessment and Conservation Engineering Division (RACE) Groundfish Assessment Program (GAP) of the Alaska Fisheries Science Center (AFSC). 
There are no legal restrictions on access to the data. 
The data from this dataset are shared on the Fisheries One Stop Stop (FOSS) platform (",link_foss,"). 
The GitHub repository for the scripts that created this code can be found at ",link_repo,
                         " These data were last updated ", file.info(paste0(dir_out, "cpue_station_0filled.csv"))$ctime, ".")

table_metadata <- gsub(pattern = "\n", replacement = "", x = table_metadata)
readr::write_lines(x = table_metadata, 
                   file = paste0(dir_out, "table_metadata_cpue_station_0filled.txt"))

# names(column_metadata) <- c("Column name from data", "Descriptive Column Name", "Units", "Description")

# make data NOT 0-filled -------------------------------------------------------

cpue_station <- cpue_station_0filled 


cpue_station <- cpue_station %>%
  dplyr::filter(
    !(COUNT %in% c(NA, 0) & # this will remove 0-filled values
        WEIGHT_KG %in% c(NA, 0)) | 
      !(CPUE_KGHA %in% c(NA, 0) & # this will remove usless 0-cpue values, 
          CPUE_NOKM2 %in% c(NA, 0)) ) # which shouldn't happen, but good to double check

# print(dim(cpue_station)) # 2021
# [1] 831340     11


# Save public data output ------------------------------------------------------

files_to_save <- list("cpue_station" = cpue_station, 
                      "cpue_station_0filled_clean" = cpue_station_0filled_clean,
                      "cpue_station_0filled" = cpue_station_0filled)

# base::save(cpue_station_0filled, 
#            column_metadata, 
#            table_metadata, 
#            file = paste0(dir_out,"cpue_station_0filled.RData"))
# 
# base::save(cpue_station_0filled, 
#            column_metadata, 
#            table_metadata, 
#            file = paste0(dir_out,"cpue_station_0filled.RData"))

for (i in 1:length(files_to_save)) {
  
  table_metadata0 <- table_metadata
  if (names(files_to_save)[i] != "cpue_station") {
    table_metadata0 <- gsub(replacement = "non-zero (presence)", 
                            pattern = "all (presence and absence)", 
                            x = table_metadata)
  }
  
  x <- files_to_save[i][[1]]
  
  base::save(
    x, 
    column_metadata, 
    table_metadata0, 
    file = paste0(dir_out, names(files_to_save)[i], ".RData"))
  
  readr::write_csv(
    x = files_to_save[i][[1]], 
    file = paste0(dir_out, names(files_to_save)[i], ".csv"), 
    col_names = TRUE)
}

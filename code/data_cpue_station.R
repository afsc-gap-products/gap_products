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

column_metadata <- data.frame(matrix(
  ncol = 4, byrow = TRUE, 
  data = c(
    "year", "Year", "numeric", "Year the survey was conducted in.", 
    
    "srvy", "Survey", "Abbreviated text", "Abbreviated survey names. The column 'srvy' is associated with the 'survey' and 'survey_id' columns. Northern Bering Sea (NBS), Southeastern Bering Sea (EBS), Bering Sea Slope (BSS), Gulf of Alaska (GOA), Aleutian Islands (AI). ", 
    
    "survey", "Survey Name", "text", "Name and description of survey. The column 'survey' is associated with the 'srvy' and 'survey_id' columns. ", 
    
    "survey_id", "Survey ID", "ID code", paste0("This number uniquely identifies a survey. Name and description of survey. The column 'survey_id' is associated with the 'srvy' and 'survey' columns. For a complete list of surveys, review the [code books](", link_code_books ,"). "), 
    
    "cruise", "Cruise ID", "ID code", "This is a six-digit number identifying the cruise number of the form: YYYY99 (where YYYY = year of the cruise; 99 = 2-digit number and is sequential; 01 denotes the first cruise that vessel made in this year, 02 is the second, etc.). ", 
    
    "haul", "Haul Number", "ID code", "This number uniquely identifies a sampling event (haul) within a cruise. It is a sequential number, in chronological order of occurrence. ", 
    
    "hauljoin", "hauljoin", "ID Code", "This is a unique numeric identifier assigned to each (vessel, cruise, and haul) combination.", 
    
    "stratum", "Stratum ID", "ID Code", "RACE database statistical area for analyzing data. Strata were designed using bathymetry and other geographic and habitat-related elements. The strata are unique to each survey series. Stratum of value 0 indicates experimental tows.", 
    
    "station", "Station ID", "ID code", "Alpha-numeric designation for the station established in the design of a survey. ", 
    
    "vessel_id", "Vessel ID", "ID Code", paste0("ID number of the vessel used to collect data for that haul. The column 'vessel_id' is associated with the 'vessel_name' column. Note that it is possible for a vessel to have a new name but the same vessel id number. For a complete list of vessel ID codes, review the [code books](", link_code_books ,")."), 
    
    "vessel_name", "Vessel Name", "text", paste0("Name of the vessel used to collect data for that haul. The column 'vessel_name' is associated with the 'vessel_id' column. Note that it is possible for a vessel to have a new name but the same vessel id number. For a complete list of vessel ID codes, review the [code books](", link_code_books ,"). "), 
    
    "date_time", "Date and Time of Haul", "MM/DD/YYYY HH::MM", "The date (MM/DD/YYYY) and time (HH:MM) of the beginning of the haul. ", 
    
    "longitude_dd_start", "Start Longitude (decimal degrees)", "decimal degrees, 1e-05 resolution", "Longitude (one hundred thousandth of a decimal degree) of the start of the haul. ", 
    
    "latitude_dd_start", "Start Latitude (decimal degrees)", "decimal degrees, 1e-05 resolution", "Latitude (one hundred thousandth of a decimal degree) of the start of the haul. ",

    "longitude_dd_end", "End Longitude (decimal degrees)", "decimal degrees, 1e-05 resolution", "Longitude (one hundred thousandth of a decimal degree) of the end of the haul. ", 
    
    "latitude_dd_end", "End Latitude (decimal degrees)", "decimal degrees, 1e-05 resolution", "Latitude (one hundred thousandth of a decimal degree) of the end of the haul. ",
    
    "species_code", "Taxon Code", "ID code", paste0("The species code of the organism associated with the 'common_name' and 'scientific_name' columns. For a complete species list, review the [code books](", link_code_books ,")."), 
    
    "common_name", "Taxon Common Name", "text", paste0("The common name of the marine organism associated with the 'scientific_name' and 'species_code' columns. For a complete species list, review the [code books](", link_code_books ,")."), 
    
    "scientific_name", "Taxon Scientific Name", "text", paste0("The scientific name of the organism associated with the 'common_name' and 'species_code' columns. For a complete taxon list, review the [code books](", link_code_books ,")."), 
    
    "taxon_confidence", "Taxon Confidence Rating", "rating", "Confidence in the ability of the survey team to correctly identify the taxon to the specified level, based solely on identification skill (e.g., not likelihood of a taxon being caught at that station on a location-by-location basis). Quality codes follow: **'High'**: High confidence and consistency. Taxonomy is stable and reliable at this level, and field identification characteristics are well known and reliable. **'Moderate'**: Moderate confidence. Taxonomy may be questionable at this level, or field identification characteristics may be variable and difficult to assess consistently. **'Low'**: Low confidence. Taxonomy is incompletely known, or reliable field identification characteristics are unknown. Documentation: [Species identification confidence in the eastern Bering Sea shelf survey (1982-2008)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2009-04.pdf), [Species identification confidence in the eastern Bering Sea slope survey (1976-2010)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2014-05.pdf), and [Species identification confidence in the Gulf of Alaska and Aleutian Islands surveys (1980-2011)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2014-01.pdf). ", 
    
    "cpue_kgha", "Weight CPUE (kg/ha)", "kilograms/hectare", "Relative Density. Catch weight (kilograms) divided by area (hectares) swept by the net.", 
    
    "cpue_kgkm2", "Weight CPUE (kg/km<sup>2</sup>)", "kilograms/kilometers<sup>2</sup>", "Relative Density. Catch weight (kilograms) divided by area (squared kilometers) swept by the net. ", 
    
    # "cpue_kg1000km2", "Weight CPUE (kg/1,000 km<sup>2</sup>)", "kilograms/1000 kilometers<sup>2</sup>", "Relative Density. Catch weight (kilograms) divided by area (thousand square kilometers) swept by the net. ", 
    
    "cpue_noha", "Number CPUE (no./ha)", "count/hectare", "Relative Abundance. Catch number (in number of organisms) per area (hectares) swept by the net. ", 
    
    "cpue_nokm2", "Number CPUE (no./km<sup>2</sup>)", "count/kilometers<sup>2</sup>", "Relative Abundance. Catch number (in number of organisms) per area (squared kilometers) swept by the net. ", 
    
    # "cpue_no1000km2", "Number CPUE (no./1,000 km<sup>2</sup>)", "count/1000 kilometers<sup>2</sup>", "Relative Abundance. Catch weight (in number of organisms) divided by area (thousand square kilometers) swept by the net. ", 
    
    "weight_kg", "Taxon Weight (kg)", "kilograms, thousandth resolution", "Weight (thousandths of a kilogram) of individuals in a haul by taxon. ",
    
    "count", "Taxon Count", "count, whole number resolution", "Total number of individuals caught in haul by taxon, represented in whole numbers. ", 
    
    "bottom_temperature_c", "Bottom Temperature (Degrees Celsius)", "degrees Celsius, tenths of a degree resolution", "Bottom temperature (tenths of a degree Celsius); NA indicates removed or missing values. ", 
    
    "surface_temperature_c", "Surface Temperature (Degrees Celsius)", "degrees Celsius, tenths of a degree resolution", "Surface temperature (tenths of a degree Celsius); NA indicates removed or missing values. ", 
    
    "bottom_temperature_c", "Bottom Temperature (Degrees Celsius)", "degrees Celsius, tenths of a degree resolution", "Bottom temperature (tenths of a degree Celsius); NA indicates removed or missing values. ", 
    
    "depth_m", "Depth (m)", "meters, tenths of a meter resolution", "Bottom depth (tenths of a meter). ", 
    
    "distance_fished_km", "Distance Fished (km)", "kilometers, thousandths of kilometer resolution", "Distance the net fished (thousandths of kilometers). ", 
    
    "net_width_m", "Net Width (m)", "meters", "Measured or estimated distance (meters) between wingtips of the trawl. ", 
    
    "net_height_m", "Net Height (m)", "meters", "Measured or estimated distance (meters) between footrope and headrope of the trawl. ", 
    
    "area_swept_ha", "Area Swept (ha)", "hectares", "The area the net covered while the net was fishing (hectares), defined as the distance fished times the net width.", 
    
    "duration_hr", "Tow Duration (decimal hr)", "decimal hours", "This is the elapsed time between start and end of a haul (decimal hours).", 

    "performance", "Haul Performance Code (rating)", "rating", paste0("This denotes what, if any, issues arose during the haul. For more information, review the [code books](", link_code_books ,")."), 
    
    "performance", "Haul Performance Code (rating)", "rating", paste0("This denotes what, if any, issues arose during the haul. For more information, review the [code books](", link_code_books ,")."), 
    
    "itis", "ITIS Taxonomic Serial Number", "ID code", paste0("Species code as identified in the Integrated Taxonomic Information System (https://itis.gov/). Codes were last updated ", file.info(paste0("./data/spp_info.csv"))$ctime, "."), 
    # "", "", "", "", 
    "worms", "World Register of Marine Species Taxonomic Serial Number", "ID code", paste0("Species code as identified in the World Register of Marine Species (WoRMS) (https://www.marinespecies.org/). Codes were last updated ", file.info(paste0("./data/spp_info.csv"))$ctime, ".")
  )))


names(column_metadata) <- c("colname", "colname_desc", "units", "desc")
column_metadata <- column_metadata[match(names(cpue_station_0filled), toupper(column_metadata$colname)),]  
readr::write_csv(x = column_metadata, file = paste0(dir_out, "column_metadata.csv"))

# setdiff(as.character(column_metadata$`Column name from data`), names(cpue_station_0filled))
# setdiff(names(cpue_station_0filled), as.character(column_metadata$`colname`))


table_metadata <- paste0("This dataset includes zero-filled (presence and absence) observations and catch-per-unit-effort (CPUE) estimates for most identified species at a standard set of stations in the Northern Bering Sea (NBS), Eastern Bering Sea (EBS), Bering Sea Slope (BSS), Gulf of Alaska (GOA), and Aleutian Islands (AI) Surveys conducted by the esource Assessment and Conservation Engineering Division (RACE) Groundfish Assessment Program (GAP) of the Alaska Fisheries Science Center (AFSC). 
There are no legal restrictions on access to the data. 
The data from this dataset are shared on the Fisheries One Stop Stop (FOSS) platform (",link_foss,"). 
The GitHub repository for the scripts that created this code can be found at ",link_repo,
                         "These data were last updated ", file.info(paste0(dir_out, "cpue_station_0filled.csv"))$ctime, ".")

# table_metadata <- paste0("This dataset includes non-zero (presence) observations and catch-per-unit-effort (CPUE) estimates for most identified species at a standard set of stations in the Northern Bering Sea (NBS), Eastern Bering Sea (EBS), Bering Sea Slope (BSS), Gulf of Alaska (GOA), and Aleutian Islands (AI) Surveys conducted by the esource Assessment and Conservation Engineering Division (RACE) Groundfish Assessment Program (GAP) of the Alaska Fisheries Science Center (AFSC). 
# There are no legal restrictions on access to the data. 
# The data from this dataset are shared on the Fisheries One Stop Stop (FOSS) platform (",link_foss,"). 
# The GitHub repository for the scripts that created this code can be found at ",link_repo,
# "These data were last updated ", file.info(paste0(dir_out, "cpue_station_0filled.csv"))$ctime, ".")
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


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

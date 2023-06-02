#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-01-01
#' Notes: 
#' -----------------------------------------------------------------------------

# Table Metadata canned sentences ----------------------------------------------

bibfiletext <- readLines(con = "https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/bibliography.bib")
find_start <- grep(pattern = "FOSSAFSCData", x = bibfiletext, fixed = TRUE)
find_end <- which(bibfiletext == "}")
find_end <- find_end[find_end>find_start][1]
a <- bibfiletext[find_start:find_end]

link_foss <- a[grep(pattern = "howpublished = {", x = a, fixed = TRUE)]
link_foss <- gsub(pattern = "howpublished = {", replacement = "", x = link_foss, fixed = TRUE)
link_foss <- gsub(pattern = "},", replacement = "", x = link_foss, fixed = TRUE)
link_foss <- trimws(link_foss)

link_code_books <- "https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual"
link_repo <- "https://github.com/afsc-gap-products/gap_public_data"

metadata_sentence_survey_institution <- paste0("in the ", paste0(surveys$SRVY_long, " (", surveys$SRVY, ")", collapse = ", "), " Surveys conducted by the Resource Assessment and Conservation Engineering Division (RACE) Groundfish Assessment Program (GAP) of the Alaska Fisheries Science Center (AFSC). ")
metadata_sentence_legal_restrict <- paste0("There are no legal restrictions on access to the data. ")
metadata_sentence_foss <- paste0("The data from this dataset are shared on the Fisheries One Stop Stop (FOSS) platform (",link_foss,"). ") 
metadata_sentence_github <- paste0("The GitHub repository for the scripts that created this code can be found at ",
                                   "INSERT_REPO", # link_repo
                                   ". ")
metadata_sentence_last_updated <- paste0("These data were last updated ", 
                                         "INSERT_DATE", # format(x = as.Date(strsplit(x = dir_out, split = "/", fixed = TRUE)[[1]][length(strsplit(x = dir_out, split = "/", fixed = TRUE)[[1]])]), "%B %d, %Y"), 
                                         ". ")
metadata_sentence_codebook <- paste0("For more information about codes used in the tables, please refer to the survey code books (", link_code_books, "). ")

metadata_table <- data.frame(matrix(
  ncol = 2, byrow = TRUE, 
  data = c(
  "survey_institution", metadata_sentence_survey_institution, 
  "legal_restrict", metadata_sentence_legal_restrict, 
  "foss", metadata_sentence_foss, 
  "github", metadata_sentence_github, 
  "last_updated", metadata_sentence_last_updated, 
  "codebook", metadata_sentence_codebook) 
) )

names(metadata_table) <- c("metadata_sentence_type", "metadata_sentence")

readr::write_csv(x = metadata_table, 
                 file = paste0(dir_out, "metadata_table.csv"))

# Column Metadata --------------------------------------------------------------

metadata_column <- data.frame(matrix(
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
    
    "taxon_confidence0", "Taxon Confidence Rating", "numeric rating", "Confidence in the ability of the survey team to correctly identify the taxon to the specified level, based solely on identification skill (e.g., not likelihood of a taxon being caught at that station on a location-by-location basis). Quality codes follow: **'High'**: High confidence and consistency. Taxonomy is stable and reliable at this level, and field identification characteristics are well known and reliable. **'Moderate'**: Moderate confidence. Taxonomy may be questionable at this level, or field identification characteristics may be variable and difficult to assess consistently. **'Low'**: Low confidence. Taxonomy is incompletely known, or reliable field identification characteristics are unknown. Documentation: [Species identification confidence in the eastern Bering Sea shelf survey (1982-2008)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2009-04.pdf), [Species identification confidence in the eastern Bering Sea slope survey (1976-2010)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2014-05.pdf), and [Species identification confidence in the Gulf of Alaska and Aleutian Islands surveys (1980-2011)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2014-01.pdf). ", 
    
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
    
    "itis", "ITIS Taxonomic Serial Number", "ID code", paste0("Species code as identified in the Integrated Taxonomic Information System (https://itis.gov/). Codes were last updated ", file.info(paste0("./data/AFSC_ITIS_WORMS.csv"))$ctime, "."), 
    
    "worms", "World Register of Marine Species Taxonomic Serial Number", "ID code", paste0("Species code as identified in the World Register of Marine Species (WoRMS) (https://www.marinespecies.org/). Codes were last updated ", file.info(paste0("./data/AFSC_ITIS_WORMS.csv"))$ctime, "."), 
    
    
    
    # metadata tables:
    "metadata_colname", "Column name", "text", "Name of the column in a table", 
    "metadata_colname_long", "Column name spelled out", "text", "Long name for the column", 
    "metadata_units", "Units", "text", "units the column is in", 
    "metadata_colname_desc", "column description", "text", "Descritpion of the column", 
    "metadata_sentence_type", "Sentence type", "text", "Type of sentence to have in table metadata",  
    "metadata_sentence", "Sentence", "text", "Table metadata sentence", 
    
    "dummy", "dummy", "dummy", "dummy"
    
    
    
  )))

names(metadata_column) <- c("metadata_colname", "metadata_colname_long", "metadata_units", "metadata_colname_desc")
readr::write_csv(x = metadata_column, 
                 file = paste0(dir_out, "metadata_column.csv"))




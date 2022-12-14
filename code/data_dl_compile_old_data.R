#' ---------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-11-08
#' Notes: 
#' ---------------------------------------------



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

# sinks the data into connection as text file

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

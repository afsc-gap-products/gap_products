
# Connect to Oracle ------------------------------------------------------------

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

# Find Oracle Metadata currently used ------------------------------------------

locations <- c("RACE_LOADER", "RACEBASE_DEV", 
               "RACE_ATSEA", "RACE_ATSEA_CODE", "RACE_DATA", 
               "RACEBASE", "GAP_PRODUCT", "RACEBASE_FOSS", "RACEBASE_AKFIN", 
               "RACE", "RACE_DRAFT", "RACE_EDIT", "RACEBASE_SEC", "RACEBASE2", 
               
               "EBSSHELF", "EBSSHELF_UNLOADER", "NBSSHELF", "NBSSHELF_UNLOADER", 
               "EBSSLOPE", "AI", "GOA", "GOA_UNLOADER", 
               
               "HAEHNR", "HOFFJ", 
               
               "AGE_SUMMARY", "AIGOA_WORK_DATA", "AIGOA_WORK_PROG", "AKFISH_PROD", "ALEUTIANS", 
               # CRAB
               "CRAB", "CRABBASE", "CRABBASE2014", "CRABBASENPR2012", 
               "EBSCRAB", "EBSCRAB_UNLOADER", 
               # SAFE
               "SAFE")


oracle_dl_metadata(
  locations = locations, 
  channel = channel_products, 
  dir_out = dir_out)



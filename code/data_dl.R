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


# DOWNLOAD GENERAL BASE DATA SETS ----------------------------------------------

locations<-c(
  #General Tables of data
  "RACEBASE.CATCH", 
  "RACEBASE.HAUL", 
  "RACE_DATA.V_CRUISES",
  "RACEBASE.SPECIES", 
  "RACE_DATA.SPECIES_TAXONOMICS", 
  "RACE_DATA.VESSELS"
)

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
  
  write.csv(x=a, 
            paste0("./data/",
                   filename,
                   ".csv"))
  remove(a)
}

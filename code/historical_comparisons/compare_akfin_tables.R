##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       Compare AKFIN Tables
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

library(gapindex)
library(RODBC)

sql_channel <- gapindex::get_connected()

table_names <- data.frame(
  gp = c("AGECOMP", "SIZECOMP", "BIOMASS", "CPUE"),
  akfin = c("AKFIN_AGECOMP", "AKFIN_SIZECOMP", "AKFIN_BIOMASS", "AKFIN_CPUE")
)

for (itable in 1:nrow(x = table_names)) {
  
  table_names$same_size[itable] <- 
    RODBC::sqlQuery(channel = sql_channel, 
                    query = paste0("SELECT COUNT(*) FROM GAP_PRODUCTS.", 
                                   table_names$akfin[itable])) == 
    RODBC::sqlQuery(channel = sql_channel, 
                    query = paste0("SELECT COUNT(*) FROM GAP_PRODUCTS.", 
                                   table_names$gp[itable]))
  
  table_names$same_spp[itable] <- 
    nrow(RODBC::sqlQuery(channel = sql_channel, 
                         query = paste0("SELECT DISTINCT SPECIES_CODE ",
                                        "FROM GAP_PRODUCTS.", 
                                        table_names$gp[itable]))) ==
    nrow(RODBC::sqlQuery(channel = sql_channel, 
                         query = paste0("SELECT DISTINCT SPECIES_CODE ",
                                        "FROM GAP_PRODUCTS.", 
                                        table_names$akfin[itable])))
  
  table_names$same_records_by_spp[itable] <-
    identical(RODBC::sqlQuery(channel = sql_channel, 
                              query = paste0("SELECT SPECIES_CODE, COUNT(*) ",
                                             "FROM GAP_PRODUCTS.", 
                                             table_names$gp[itable],
                                             " GROUP BY SPECIES_CODE")),
              
              RODBC::sqlQuery(channel = sql_channel, 
                              query = paste0("SELECT SPECIES_CODE, COUNT(*) ",
                                             "FROM GAP_PRODUCTS.", 
                                             table_names$akfin[itable],
                                             " GROUP BY SPECIES_CODE"))
    )
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:       
## Author:        Zack Oyafuso (zack.oyafuso@noaa.gov)
## Description:   
## 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Load mismatch object
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mismatches <- readRDS(file = "temp/mismatches.RDS")

today_date <- Sys.Date()

"A new version of gapindex (v2.1.1) was used to produced these data. There was a slight change to how subarea biomass totals are calculated. The modified biomass records reflect this change."

"New 2022 otolith data were available since the last iteration of the GAP_PRODUCTS for Aleutian Island Pacific ocean perch and northern rockifsh and Eastern Bering Sea northern rock sole."

"Zero-filled CPUE records for four GOA taxonomic codes were added due to how the 1990 data were integrated in the last production run of GAP_PRODUCTS."

"Two Arctic cod and one plain sculpin count records were modified in the NBS data. This changes the numerical CPUE estimates for those hauls, which modifies the population abundance and size composition for those species."

for (iregion in c("AI", "GOA", "EBS", "NBS", "BSS")) {
  cat(iregion, "Region: \n")
  for (idata in c("cpue", "biomass", "sizecomp", "agecomp")) {
    cat(idata, ": \n")
    cat("There are", nrow(mismatches[[iregion]][[idata]]$new_records), 
        "new", idata, "records.\n")
    cat("There are", nrow(mismatches[[iregion]][[idata]]$removed_records),
        idata, "records that were removed.\n")
    cat("There are", nrow(mismatches[[iregion]][[idata]]$modified_records),
        "modified", idata, "records.\n")
  }
  cat("\n\n")
}



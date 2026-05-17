# Create Load Packages ---------------------------------------------------------

library(crabpack) # pak::pak("AFSC-Shellfish-Assessment-Program/crabpack") # https://github.com/AFSC-Shellfish-Assessment-Program/crabpack
library(gapindex)
library(dplyr)
maxyr <- 2025
minyr <- 1982

# channel <- gapindex::get_connected(check_access = F)
source("Z:/Projects/ConnectToOracle.R")

## Pull all data for crabs from gapindex ---------------------------------------
# follow instructions from https://afsc-gap-products.github.io/gapindex/articles/ex_species_complex.html

# Create species complex tables ------------------------------------------------
temp1 <- 
  data.frame(
    GROUP_CODE = c(69322, 69323, 68560, 68580, 68590, 69400),
    SPECIES_CODE = c(69322, 69323, 68560, 68580, 68590, 69400),
    TAXON = "invert",
    SPECIES_NAME = c("Paralithodes camtschaticus", "Paralithodes platypus", "Chionoecetes bairdi", "Chionoecetes opilio", "Chionoecetes hybrid", "Erimacrus isenbeckii"),
    GROUP_NAME = c("red king crab", "blue king crab", "Tanner crab", "snow crab", "hybrid Tanner crab", "horsehair crab") )

## Pull data. Note the format of the spp_codes argument with the GROUP column
gapindex_data <- gapindex_data0 <- gapindex::get_data(
  year_set = 1982:maxyr,
  survey_set = c("EBS", "NBS"),
  spp_codes = temp1[,c("GROUP_CODE", "SPECIES_CODE")],
  pull_lengths = FALSE, 
  haul_type = 3, 
  abundance_haul = "Y", 
  taxonomic_source = "GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION", # "RACEBASE.SPECIES", 
  channel = channel)

save(x = gapindex_data , file = here::here("data/gapindex_data_raw.rdata"))
# load(here::here("data/gapindex_data_raw.rdata"))

## Find all (and potential retow) stations --------------------------------------------------------------
hauls <- RODBC::sqlQuery(channel = channel,
                         query = paste0("SELECT *FROM RACEBASE.HAUL WHERE HAUL_TYPE IN (17, 3) AND PERFORMANCE >= 0; "))
# cruises <- RODBC::sqlQuery(channel = channel,
#                                  query = paste0("SELECT *FROM RACEBASE.CRUISE; "))
surveys <- RODBC::sqlQuery(channel = channel,
                           query = paste0("SELECT *FROM GAP_PRODUCTS.AKFIN_CRUISE WHERE SURVEY_DEFINITION_ID IN (98, 143); "))

hauls_retow <- surveys |>
  dplyr::select(-CRUISE) |>
  # dplyr::left_join(cruises) |>
  dplyr::left_join(hauls) |>
  dplyr::filter(!is.na(HAULJOIN))  |>
  # dplyr::select(HAULJOIN, STATION = STATIONID, HAUL_TYPE, YEAR, CRUISEJOIN, SURVEY_DEFINITION_ID) |>
  dplyr::mutate(
    STATION = STATIONID,
    REGION = ifelse(SURVEY_DEFINITION_ID == 98, "EBS", "NBS"),
    key = paste0(STATION, YEAR, REGION)) |>
  dplyr::distinct()

hauls_retow <- hauls_retow |>
  dplyr::mutate(dup = ifelse(key %in% hauls_retow$key[duplicated(hauls_retow$key)], 1, 0))

write.csv(x = hauls_retow, file = here::here("data/hauls_retow.csv"))

# Pull crab data from `crabpack`------------------------------------------------
spp_list <- tidyr::crossing(
  spp = c("RKC", "BKC", "TANNER", "SNOW", "HYBRID", "HAIR"), 
  reg = c("EBS", "NBS"))
crabpack_specimen0 <- crabpack_sizegroups0 <- crabpack_haul0 <- c()
# crabpack data pull does a funny thing where the channel *needs* to be called 'channel' even though it says it can accept other names
channel <- "API"

for (i in 1:nrow(spp_list)) {
  spp <- spp_list$spp[i]
  reg <- spp_list$reg[i]
  print(paste0(reg, " ", spp))
  
  dat <- crabpack::get_specimen_data(species = spp,
                                     region = reg,
                                     years = c(1982:maxyr)) 
  
  
  # Bind haul info to add hauljoins later
  crabpack_haul0 <- dat$haul |> 
    dplyr::mutate(spp = spp, 
                  reg = reg) |> 
    dplyr::bind_rows(crabpack_haul0)
  crabpack_specimen0 <- dat$specimen |> 
    dplyr::mutate(spp = spp, 
                  reg = reg) |> 
    dplyr::bind_rows(crabpack_specimen0)
  crabpack_sizegroups0 <- dat$sizegroups |> 
    dplyr::mutate(spp = spp, 
                  reg = reg) |> 
    dplyr::bind_rows(crabpack_sizegroups0)
}  
save(x = crabpack_specimen0, crabpack_haul0, crabpack_sizegroups0, file = here::here("data/crabpack_pull_for_gapindex_run.rdata"))
# load(here::here("data/crabpack_pull_for_gapindex_run.rdata"))  

crab_specimen <- crabpack_specimen0 |> 
  dplyr::mutate(LENGTH_TYPE = dplyr::case_when(
    SPECIES_CODE %in% c(68541, 68550, 68560) ~ 8,
    TRUE ~ 7
  )) |> 
  dplyr::select(HAULJOIN, 
                SPECIES_CODE, 
                SEX, 
                LENGTH_MM = SIZE_1MM, 
                LENGTH_TYPE, 
                WEIGHT_G = CALCULATED_WEIGHT, # CALCULATED_WEIGHT_1MM, 
                CONDITION_SHELL = SHELL_CONDITION, 
                CONDITION_EGG = EGG_CONDITION, 
                CONDITION_CLUTCH = CLUTCH_SIZE, 
                CONDITION_DISEASE = DISEASE_CODE,
                MERUS_LENGTH_MM = MERUS_LENGTH, 
                CHELA_LENGTH_MM = CHELA_HEIGHT, 
                FREQUENCY = SAMPLING_FACTOR, 
                HAUL_TYPE # temporarily need
  )  |>
  dplyr::left_join(crabpack_haul0 |> 
                     dplyr::select(STATION_ID, HAULJOIN, HAUL_TYPE, YEAR, REGION) |>
                     dplyr::distinct() |> 
                     dplyr::mutate(key = paste0(STATION_ID, YEAR, REGION)) )

## Identify retow stations -----------------------------------------------------
aaa <- crab_specimen |> 
  dplyr::ungroup()  |>
  dplyr::mutate(dup = ifelse(key %in% hauls_retow$key[duplicated(hauls_retow$key)], 1, 0)) |> 
  # dplyr::filter(SEX == 2 & SPECIES_CODE == 69322)  |>
  dplyr::group_by(HAULJOIN, SPECIES_CODE, SEX, HAUL_TYPE, key, STATION_ID, YEAR, dup) |>
  dplyr::summarise(WEIGHT_KG = sum(WEIGHT_G, na.rm = TRUE)/1000,
                   COUNT = sum(FREQUENCY, na.rm = TRUE)) |> 
  dplyr::ungroup() |> 
  # dplyr::filter(!is.na(STATION_ID)) |> 
  # dplyr::filter(key %in% aaa$key[!duplicated(aaa$key)]) |> 
  dplyr::mutate(
    # dup  = ifelse(key %in% aaa$key[duplicated(aaa$key)], 1, 0), 
    include = dplyr::case_when(
      HAUL_TYPE == 17 & SEX == 2 & SPECIES_CODE == 69322 & dup == 1 ~ 1, 
      HAUL_TYPE == 3 & SEX == 2 & SPECIES_CODE == 69322 & dup == 1 ~ 0, 
      SEX == 4 ~ 0, # remove unisex
      HAUL_TYPE == 17 ~ 0, 
      HAUL_TYPE == 3 ~ 1, 
      TRUE ~ 0))

# NOTES
# sex = dplyr::case_when(
#   sex == 1 ~ "males",
#   sex == 0 ~ "unsexed",
#   (clutch_size == 0 & sex == 2) ~ "immature females", 
#   (clutch_size >= 1 & sex == 2) ~ "mature females"), 
#   
# SEX = ifelse(SEX == 2 & CONDITION_CLUTCH == 0, 5, SEX), # "immature females" 
#             SEX = ifelse(SEX == 2 & CONDITION_CLUTCH != 0, 6, SEX) # "mature females" 

crab_specimen <- crab_specimen |> 
  dplyr::left_join(aaa) |> 
  dplyr::mutate(
    SEX0 = SEX, 
    SEX = dplyr::case_when(
      SEX0 == 2 & CONDITION_CLUTCH == 0 ~ 5, # "immature females" 
      SEX0 == 2 & CONDITION_CLUTCH != 0 ~ 6, # "mature females" 
      TRUE ~ SEX0
    )
  )

write.csv(x = crab_specimen, 
          file = here::here("data/crab_specimen_preinclude.csv"), 
          row.names = FALSE)

crab_specimen <- crab_specimen |> 
  dplyr::filter(include == 1) |>
  dplyr::distinct()

gapindex_data$catch <- crab_specimen |> 
  dplyr::mutate(WEIGHT = (WEIGHT_G * FREQUENCY)/1000) |>  # convert from grams to kg
  dplyr::group_by(HAULJOIN, SPECIES_CODE) |> 
  dplyr::summarise(WEIGHT = sum(WEIGHT, na.rm = TRUE), 
                   NUMBER_FISH = sum(FREQUENCY, na.rm = TRUE)) |> 
  dplyr::ungroup() |> 
  data.table::data.table(key = c("HAULJOIN", "SPECIES_CODE")) 

gapindex_data$specimen <- crab_specimen #|>
#   dplyr::select(WEIGHT_G, SEX, SPECIES_CODE, HAULJOIN, LENGTH_MM)  |>  
#   # dplyr::mutate(WEIGHT_KG = WEIGHT_G / 1000) |>   # convert from grams to kg
#   dplyr::group_by(HAULJOIN, SPECIES_CODE, SEX, LENGTH_MM) |> 
#   dplyr::summarise(WEIGHT_KG = sum(WEIGHT_KG, na.rm = TRUE)) |> 
#   dplyr::ungroup() |>
#   dplyr::mutate(AGE = NA)  |> 
#   data.table::data.table(key = c("HAULJOIN", "SPECIES_CODE", "SEX", "AGE", "LENGTH_MM")) 

gapindex_data$size <- crab_specimen |>
  dplyr::select(SEX, SPECIES_CODE, HAULJOIN, LENGTH = LENGTH_MM, FREQUENCY)  |>
  dplyr::group_by(HAULJOIN, SPECIES_CODE, SEX, LENGTH) |>
  dplyr::summarise(
    FREQUENCY = sum(FREQUENCY, na.rm = TRUE)) |>
  dplyr::ungroup() |>
  # dplyr::mutate(LENGTH = LENGTH_MM) |> 
  data.table::data.table(key = c("HAULJOIN", "SPECIES_CODE", "SEX", "LENGTH")) #|>

temp <- gapindex_data$haul

gapindex_data$haul <- hauls_retow |> 
  dplyr::rename_all(toupper) |> 
  dplyr::select(dplyr::all_of(names(temp))) |>
  # dplyr::select(-key, -dup) |> 
  dplyr::mutate(ABUNDANCE_HAUL = 'Y', 
                REGION = 'BS') |>
  dplyr::ungroup() |>
  data.table::data.table(key = c("HAULJOIN"))

## Calculate Zero-fill CPUE ----------------------------------------------------

crab_cpue <- gapindex::calc_cpue(gapdata = gapindex_data)  |> 
  dplyr::select(HAULJOIN, SPECIES_CODE, WEIGHT_KG, COUNT, AREA_SWEPT_KM2, CPUE_KGKM2, CPUE_NOKM2, 
                STRATUM, YEAR, SURVEY, SURVEY_DEFINITION_ID, DESIGN_YEAR) # temporarily needed - but why??

## Calculate Biomass, abundance, mean CPUE, and associated variances by stratum ----

crab_biomass_stratum <-
  gapindex::calc_biomass_stratum(gapdata = gapindex_data,
                                 cpue = crab_cpue)

crab_cpue <- crab_cpue |> 
  dplyr::select(-STRATUM, -YEAR, -SURVEY, -SURVEY_DEFINITION_ID, -DESIGN_YEAR) 

crab_biomass_subarea <-
  gapindex::calc_biomass_subarea(gapdata = gapindex_data,
                                 biomass_stratum = crab_biomass_stratum)

crab_biomass <- crab_biomass_stratum |>
  dplyr::rename(AREA_ID = STRATUM) |>
  dplyr::bind_rows(crab_biomass_subarea) 

## Calculate Size composition by stratum and area ---------------------------------------

# Calculate size composition by stratum. See ?gapindex::calc_sizecomp_stratum for details on arguments
# Calculate aggregated size composition across subareas, management areas, and regions

# Note fill_NA_method == "BS" because our region is EBS, NBS, or BSS. If the survey region of interest is AI or
# GOA, use "AIGOA". See ?gapindex::gapindex::calc_sizecomp_stratum for more details.

# Aggregate size composition to stratum
crab_sizecomp_stratum <- gapindex::calc_sizecomp_stratum(
  gapdata = gapindex_data,
  cpue = crab_cpue,
  abundance_stratum = crab_biomass_stratum,
  spatial_level = "stratum",
  fill_NA_method = "BS")

# Aggregate size composition to subareas/region
crab_sizecomp_subarea <- gapindex::calc_sizecomp_subarea(
  gapdata = gapindex_data,
  sizecomp_stratum = crab_sizecomp_stratum)

# rbind stratum and subarea/region biomass estimates into one dataframe
crab_sizecomp <- crab_sizecomp_stratum |>
  dplyr::rename(AREA_ID = STRATUM) |>
  dplyr::bind_rows(crab_sizecomp_subarea) |> 
  dplyr::select(-SURVEY)

# Upload Tables to GAP_PRODUCTS ---------------------------------------------

# Temporarily dump these tables in MARKOWITZE so they can be pulled into production tables ------------
# source("Z:/Projects/ConnectToOracle.R")

quantity <- c("crab_sizecomp", "crab_biomass", "crab_cpue", "crab_specimen")

for (idata in quantity) { ## Loop over data types -- start
  
  write.csv(x = get(x = idata), 
            file = here::here(paste0("data/",idata,".csv")), 
            row.names = FALSE)
  
  if (FALSE) {
    data_table <- read.csv(file = here::here(paste0("data/", idata, ".csv"))) |>
      dplyr::rename_all(toupper)
    
    ## Pull field descriptions from GAP_PRODUCTS.METADATA_COLUMN
    metadata_column <-
      RODBC::sqlQuery(channel = channel,
                      query = paste(
                        "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
                       WHERE METADATA_COLNAME IN",
                        gapindex::stitch_entries(names(x = data_table))))
    
    ## Clean up field names to be consistent with the data input format for
    ## gapindex::upload_oracle
    names(x = metadata_column) <-
      gsub(x = tolower(x = names(x = metadata_column)),
           pattern = "metadata_",
           replacement = "")
    
    ## Upload to Oracle
    gapindex::upload_oracle(channel = channel,
                            x = data_table,
                            schema = "MARKOWITZE", # "GAP_PRODUCTS",
                            table_name = toupper(x = idata),
                            table_metadata = "compiled from crabpack",
                            metadata_column = metadata_column)
  }
}

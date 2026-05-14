# Create Load Packages ---------------------------------------------------------

# devtools::install_github("AFSC-Shellfish-Assessment-Program/crabpack")
library(crabpack) # https://github.com/AFSC-Shellfish-Assessment-Program/crabpack
library(gapindex)
library(dplyr)
maxyr <- 2025
# channel <- gapindex::get_connected(check_access = F)
source("Z:/Projects/ConnectToOracle.R")

# Create species complex tables ------------------------------------------------

temp1 <- 
  data.frame(
    GROUP_CODE = c(69322, 69323, 68560, 68580, 68590, 69400),
    SPECIES_CODE = c(69322, 69323, 68560, 68580, 68590, 69400),
    TAXON = "invert",
    SPECIES_NAME = c("Paralithodes camtschaticus", "Paralithodes platypus", "Chionoecetes bairdi", "Chionoecetes opilio", "Chionoecetes hybrid", "Erimacrus isenbeckii"),
    GROUP_NAME = c("red king crab", "blue king crab", "Tanner crab", "snow crab", "hybrid Tanner crab", "horsehair crab") )

## Pull all data for crabs from gapindex ---------------------------------------

# follow instructions from https://afsc-gap-products.github.io/gapindex/articles/ex_species_complex.html
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
# 
# test <- gapindex::get_data(
#   year_set = maxyr,
#   survey_set = c("EBS", "NBS"),
#   spp_codes = 10285,
#   pull_lengths = FALSE,
#   haul_type = 3,
#   abundance_haul = "Y",
#   taxonomic_source = "GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION", # "RACEBASE.SPECIES",
#   channel = channel)

## Pull crab data --------------------------------------------------------------

# List of species and survey regions to add to GAP data

# crabpack data pull does a funny thing where the channel *needs* to be called 'channel' even though it says it can accept other names
source("Z:/Projects/ConnectToOracle.R")
# channel <- channel_akfin

spp_list <- tidyr::crossing(
  spp = c("RKC", "BKC", "TANNER", "SNOW", "HYBRID", "HAIR"), 
  reg = c("EBS", "NBS"))

# Pull crab data from `crabpack`
crabpack_specimen0 <- c()
for (i in 1:nrow(spp_list)) {
  source("Z:/Projects/ConnectToOracle.R")
  # channel <- channel_akfin
  
  spp <- spp_list$spp[i]
  reg <- spp_list$reg[i]
  print(paste0(reg, " ", spp))
  
  specimen_data <- crabpack::get_specimen_data(species = spp,
                                               region = reg,
                                               years = c(1982:maxyr)) 
  
  crabpack_specimen0 <- crabpack_specimen0 |> 
    dplyr::bind_rows(specimen_data$specimen |> 
                       dplyr::mutate(spp = spp, 
                                     reg = reg))
}

crabpack_specimen00 <- crabpack_specimen0 # safekeeping

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
                )

# NOTES
# sex = dplyr::case_when(
#   sex == 1 ~ "males",
#   sex == 0 ~ "unsexed",
#   (clutch_size == 0 & sex == 2) ~ "immature females", 
#   (clutch_size >= 1 & sex == 2) ~ "mature females"), 

# find which hauls need to be replaced with retow data
crab_specimen <- dplyr::bind_rows(
  # data from retow stations - female RKC
  crab_specimen |> 
    dplyr::filter(HAUL_TYPE == 17) |> 
    dplyr::filter(SEX == 2 & SPECIES_CODE == 69322), 
  # data from not retow stations - male and unsexed RKC, and everything else
  crab_specimen |> 
    dplyr::filter(HAUL_TYPE == 3) |> 
    dplyr::filter(!(SEX == 2 & SPECIES_CODE == 69322))  )  |> 
  dplyr::mutate(SEX = ifelse(SEX == 2 & CONDITION_CLUTCH == 0, 5, SEX), # "immature females" 
                SEX = ifelse(SEX == 2 & CONDITION_CLUTCH != 0, 6, SEX)) |> # "mature females" 
  dplyr::filter(SEX != 4) |> # unisex
  dplyr::select(-HAUL_TYPE) |> 
  dplyr::distinct() |> 
  dplyr::mutate(AREA_SWEPT = AREA_SWEPT*3.4299) # nmi2 to km2? # TOLEDO!

gapindex_data$catch <- crab_specimen |> 
  dplyr::mutate(WEIGHT = (WEIGHT_G * FREQUENCY)/1000) |>  # convert from grams to kg
  dplyr::group_by(HAULJOIN, SPECIES_CODE) |> 
  dplyr::summarise(WEIGHT = sum(WEIGHT, na.rm = TRUE), 
                   NUMBER_FISH = sum(FREQUENCY, na.rm = TRUE)) |> 
  dplyr::ungroup() |> 
  data.table::data.table(key = c("HAULJOIN", "SPECIES_CODE")) 

# gapindex_data$specimen <- crab_specimen |> 
#   dplyr::select(WEIGHT_G, SEX, SPECIES_CODE, HAULJOIN, LENGTH_MM)  |>  
#   # dplyr::mutate(WEIGHT_KG = WEIGHT_G / 1000) |>   # convert from grams to kg
#   dplyr::group_by(HAULJOIN, SPECIES_CODE, SEX, LENGTH_MM) |> 
#   dplyr::summarise(WEIGHT_KG = sum(WEIGHT_KG, na.rm = TRUE)) |> 
#   dplyr::ungroup() |>
#   dplyr::mutate(AGE = NA)  |> 
#   data.table::data.table(key = c("HAULJOIN", "SPECIES_CODE", "SEX", "AGE", "LENGTH_MM")) 
# 
gapindex_data$size <- crab_specimen |>
  dplyr::select(SEX, SPECIES_CODE, HAULJOIN, LENGTH_MM, FREQUENCY)  |>
  dplyr::group_by(HAULJOIN, SPECIES_CODE, SEX, LENGTH_MM) |>
  dplyr::summarise(
    FREQUENCY = sum(FREQUENCY, na.rm = TRUE)) |>
  dplyr::ungroup() |>
  data.table::data.table(key = c("HAULJOIN", "SPECIES_CODE", "SEX", "LENGTH_MM")) #|>

## Calculate Zero-fill CPUE ----------------------------------------------------

crab_cpue <- gapindex::calc_cpue(gapdata = gapindex_data) |> 
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

# Calculate size composition by stratum. See ?gapindex::calc_sizecomp_stratum
# for details on arguments
# Calculate aggregated size composition across subareas, management areas, and
# regions

# Note fill_NA_method == "BS" because
# our region is EBS, NBS, or BSS. If the survey region of interest is AI or
# GOA, use "AIGOA". See ?gapindex::gapindex::calc_sizecomp_stratum for more
# details.

# Aggregate size composition to stratum
gapindex_data$size$LENGTH <- gapindex_data$size$LENGTH_MM
 
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

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Upload Tables to GAP_PRODUCTS
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Temporarily dump these tables in MARKOWITZE so they can be pulled into production tables ------------
# source("Z:/Projects/ConnectToOracle.R")

quantity <- c("crab_sizecomp", "crab_biomass", "crab_cpue", "crab_specimen")

for (idata in quantity) { ## Loop over data types -- start
  
  write.csv(x = get(x = idata), 
            file = here::here(paste0("data/",idata,".csv")), 
            row.names = FALSE)
  
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

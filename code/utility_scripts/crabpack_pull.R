


## Crab Pack Method

# This is an R Markdown document. Markdown is a simple formatting syntax for authoring HTML, PDF, and MS Word documents. For more details on using R Markdown see <http://rmarkdown.rstudio.com>.
# 
# When you click the **Knit** button a document will be generated that includes both content as well as the output of any embedded R code chunks within the document. You can embed an R code chunk like this:
  

# Crabpack data ----------------------------------------------------------------

# Load libraries
library(crabpack) # pak::pak("AFSC-Shellfish-Assessment-Program/crabpack")

library(dplyr)
library(tidyr)

# Setup
channel <- "API"

# lookup for species codes
maxyr <- 2025
minyr <- 1982
species_lookup <- tibble(SPECIES_CODE = c(68560, 68580, 68590, 69322, 69323, 69400),
                         SPECIES = c("TANNER", "SNOW", "HYBRID", "RKC", "BKC", "HAIR"))

bioabund_out <- cpue_out <- NBS_pop1mm_out <- EBS_pop1mm_out <- specimen_out <- sizegroups_out <- c()

# Loop through species and combine estimates
for(i in 1:length(species_lookup$SPECIES)){
  # Set species
  species <- species_lookup$SPECIES[i]
  print(species)
  
  ## Specimen data -------------------------------------------------------------
  dat_EBS <- crabpack::get_specimen_data(species = species,
                                         region = "EBS",
                                         channel = channel) 
  # dat_EBS$haul$AREA_SWEPT <- dat_EBS$haul$AREA_SWEPT*3.4299 # nmi2 to km2
  # dat_EBS$specimen$AREA_SWEPT <- dat_EBS$specimen$AREA_SWEPT*3.4299 # nmi2 to km2
  # dat_EBS$specimen$CALCULATED_WEIGHT <- dat_EBS$specimen$CALCULATED_WEIGHT/2.205 # lb to kg
  
  dat_NBS <- crabpack::get_specimen_data(species = species,
                                         region = "NBS",
                                         channel = channel)
  # dat_NBS$haul$AREA_SWEPT <- dat_NBS$haul$AREA_SWEPT*3.4299 # nmi2 to km2
  # dat_NBS$specimen$AREA_SWEPT <- dat_NBS$specimen$AREA_SWEPT*3.4299 # nmi2 to km2
  # dat_NBS$specimen$CALCULATED_WEIGHT <- dat_NBS$specimen$CALCULATED_WEIGHT/2.205 # lb to kg
  
  # Bind haul info to add hauljoins later
  haul <- bind_rows(dat_EBS$haul, dat_NBS$haul)
  specimen <- bind_rows(dat_EBS$specimen, dat_NBS$specimen) |> 
    dplyr::select(-REGION, -YEAR, -STATION_ID, -HAUL_TYPE, -LATITUDE, -LONGITUDE, -DISTRICT, -STRATUM, -TOTAL_AREA) # -AREA_SWEPT, 
  specimen_out <- rbind(specimen_out, specimen)
  sizegroups_out <- bind_rows(dat_EBS$sizegroups, dat_NBS$sizegroups) |> bind_rows(sizegroups_out)
    
  ## Biomass/Abundance ---------------------------------------------------------
  EBS_bioabund <- crabpack::calc_bioabund(crab_data = dat_EBS,
                                          species = species,
                                          region = "EBS",
                                          years = c(minyr:maxyr),
                                          spatial_level = "region")
  ## ^^ this isn't working correctly for BKC because of a bug (see Issue 10) --
  ##    doing some janky coding below to get the estimates to combine correctly for now, 
  ##    but this will be fixed in crabpack eventually and just these few lines 
  ##    will eventually be all you need!
  
  NBS_bioabund <- crabpack::calc_bioabund(crab_data = dat_NBS,
                                          species = species,
                                          region = "NBS",
                                          years = c(minyr:maxyr),
                                          spatial_level = "region")
  
  # bind regions and format
  bioabund_combined <- rbind(EBS_bioabund, NBS_bioabund) |>
    dplyr::left_join(species_lookup) |>
    dplyr::select(YEAR, SPECIES_CODE, SPECIES, REGION,
                  ABUNDANCE, ABUNDANCE_CV, ABUNDANCE_CI,
                  BIOMASS_MT, BIOMASS_MT_CV, BIOMASS_MT_CI)
  bioabund_out <- rbind(bioabund_out, bioabund_combined)
  
  
  ## CPUE ----------------------------------------------------------------------
  # **Need to convert from mt/nmi2 to kg/km2
  EBS_cpue <- crabpack::calc_cpue(crab_data = dat_EBS,
                                  species = species,
                                  region = "EBS",
                                  years = c(minyr:maxyr))
  NBS_cpue <- crabpack::calc_cpue(crab_data = dat_NBS,
                                  species = species,
                                  region = "NBS",
                                  years = c(minyr:maxyr))
  
  # bind regions and format
  cpue_combined <- rbind(EBS_cpue, NBS_cpue) |>
    dplyr::left_join(species_lookup) |>
    dplyr::left_join(haul) # |>
    # dplyr::select(YEAR, SPECIES_CODE, SPECIES, REGION,
    #               HAULJOIN, STATION_ID, LATITUDE, LONGITUDE,
    #               DISTRICT, STRATUM, TOTAL_AREA,
    #               COUNT, CPUE, CPUE_MT)
  cpue_out <- rbind(cpue_out, cpue_combined)
  
  
  ## NBS 1mm abundance -------------------------------- ------------------------
  NBS_pop1mm_male <- crabpack::calc_bioabund(crab_data = dat_NBS,
                                             species = species,
                                             region = "NBS",
                                             years = c(minyr:maxyr),
                                             spatial_level = "region",
                                             sex = "male",
                                             bin_1mm = TRUE) |>
    rename(CATEGORY = SEX_TEXT)
  NBS_pop1mm_female <- crabpack::calc_bioabund(crab_data = dat_NBS,
                                               species = species,
                                               region = "NBS",
                                               years = c(minyr:maxyr),
                                               spatial_level = "region",
                                               crab_category = c("mature_female", "immature_female"),
                                               bin_1mm = TRUE)
  
  # bind regions and format
  NBS_pop1mm <- dplyr::bind_rows(NBS_pop1mm_male, NBS_pop1mm_female) |>
    dplyr::left_join(species_lookup) |>
    dplyr::select(YEAR, SPECIES_CODE, SPECIES, REGION, SIZE_1MM, CATEGORY, ABUNDANCE) |>
    tidyr::pivot_wider(names_from = CATEGORY, values_from = ABUNDANCE) |>
    dplyr::rename(NUMBER_MALES = male,
                  NUMBER_IMMATURE_FEMALES = immature_female,
                  NUMBER_MATURE_FEMALES = mature_female)
  NBS_pop1mm_out <- rbind(NBS_pop1mm_out, NBS_pop1mm)
  
  
  ## EBS 1mm abundance ---------------------------------------------------------
  EBS_pop1mm_male <- crabpack::calc_bioabund(crab_data = dat_EBS,
                                             species = species,
                                             region = "EBS",
                                             years = c(1982:maxyr),
                                             spatial_level = "region",
                                             sex = "male",
                                             bin_1mm = TRUE) |>
    rename(CATEGORY = SEX_TEXT)
  EBS_pop1mm_female <- crabpack::calc_bioabund(crab_data = dat_EBS,
                                               species = species,
                                               region = "EBS",
                                               years = c(1982:maxyr),
                                               spatial_level = "region",
                                               crab_category = c("mature_female", "immature_female"),
                                               bin_1mm = TRUE)
  
  # bind regions and format
  EBS_pop1mm <- dplyr::bind_rows(EBS_pop1mm_male, EBS_pop1mm_female) |>
    dplyr::left_join(species_lookup) |>
    dplyr::select(YEAR, SPECIES_CODE, SPECIES, REGION, SIZE_1MM, CATEGORY, ABUNDANCE) |>
    tidyr::pivot_wider(names_from = CATEGORY, values_from = ABUNDANCE) |>
    dplyr::rename(NUMBER_MALES = male, 
                  NUMBER_IMMATURE_FEMALES = immature_female,
                  NUMBER_MATURE_FEMALES = mature_female)
  
  ## 1mm abundance -------------------------------------------------------------
  EBS_pop1mm_out <- rbind(EBS_pop1mm_out, EBS_pop1mm)
  
}

save(bioabund_out, cpue_out, NBS_pop1mm_out, EBS_pop1mm_out, specimen_out, sizegroups_out, file = "data/crabpack_data.rdata")

write.csv(x = specimen_out, 
          file = here::here("data/crab_specimen_pack.csv"), 
          row.names = FALSE)

crab_spp <- data.frame(
  species_code = c(69322, 69323, 68560, 68580, 68590, 69400),
  taxon = "invert",
  common_name = c("red king crab", "blue king crab", "Tanner crab", "snow crab", "hybrid Tanner crab", "horsehair crab"), 
  species_name = c("Paralithodes camtschaticus", "Paralithodes platypus", "Chionoecetes bairdi", "Chionoecetes opilio", "Chionoecetes hybrid", "Erimacrus isenbeckii"),
  species = c("RKC", "BKC", "TANNER", "SNOW", "HYBRID", "HAIR")  )

crab_sizecomp <- 
  dplyr::bind_rows(EBS_pop1mm_out, NBS_pop1mm_out)  |> 
  dplyr::rename_all(tolower)  |> 
  tidyr::pivot_longer(cols = c("number_males", "number_immature_females", "number_mature_females"), 
                      names_to = "sex", 
                      values_to = "population_count") |>
  dplyr::left_join(crab_spp) |> 
  dplyr::mutate(
    sex = gsub(pattern = "number_", replacement = "", x = sex),
    sex = gsub(pattern = "_", replacement = " ", x = sex),
    srvy = region, 
    length_mm = size_1mm, 
    population_count = ifelse(is.na(population_count), 0, population_count),
    survey_definition_id = dplyr::case_when(
      region == "NBS" ~ 143, 
      region == "EBS" ~ 98)) |> 
  dplyr::select(-region, -size_1mm, -species, -taxon, -species_name, -common_name, -srvy) |> 
  dplyr::rename(sex_description = sex) |> 
  dplyr::mutate(sex = dplyr::case_when( # TOLEDO would need to add new codes to code table
    sex_description == "males" ~ 1, 
    sex_description == "immature females" ~ 5, 
    sex_description == "mature females" ~ 6
                )) |> 
  dplyr::select(-sex_description)

write.csv(x = crab_sizecomp, 
          file = here::here("data/crab_sizecomp_pack.csv"), 
          row.names = FALSE)

crab_cpue <- cpue_out |> 
  dplyr::rename_all(tolower)  |> 
  dplyr::left_join(crab_spp) |> 
  dplyr::mutate(
    area_swept_km2 = area_swept*3.4299, # nmi2 to km2? # TOLEDO!|>
    cpue_nokm2 = cpue/1000 * 3.4299, # nmi2 to km2
    cpue_kgkm2 = (cpue_mt) * 3.4299, # nmi2 to km2
    srvy = region, 
    weight_kg = (cpue_mt*area_swept)*1000,
    # weight_kg = NA, 
    survey_definition_id = dplyr::case_when(
      region == "NBS" ~ 143, 
      region == "EBS" ~ 98)) |> 
  dplyr::select(species_code, hauljoin, count, weight_kg, cpue_nokm2, cpue_kgkm2, area_swept_km2, area_swept) # |>  
  # dplyr::left_join(specimen |> 
  # dplyr::mutate(weight_g = (CALCULATED_WEIGHT * SAMPLING_FACTOR)) |> 
  # dplyr::group_by(hauljoin = HAULJOIN, 
  #                 species_code = SPECIES_CODE) |> 
  # dplyr::summarise(weight_g = sum(weight_g, na.rm = TRUE)) |> 
  #   dplyr::ungroup() |> 
  #   dplyr::mutate(weight_kg0 = weight_g/1000) |> 
  # dplyr::select(-weight_g))

write.csv(x = crab_cpue, 
          file = here::here("data/crab_cpue_pack.csv"), 
          row.names = FALSE)

crab_biomass <- bioabund_out |> 
  dplyr::rename_all(tolower)  |> 
  dplyr::mutate(
    n_weight = 1, # TOLEDO - doesn't come from crabpack!
    biomass_up = biomass_mt + biomass_mt_ci, # TOLEDO - still need to check these are calculated the same way
    biomass_dw = biomass_mt - biomass_mt_ci, 
    population_up = abundance + abundance_ci,
    population_dw = abundance - abundance_ci,
    srvy = region, 
    survey_definition_id = dplyr::case_when(
      region == "NBS" ~ 143, 
      region == "EBS" ~ 98)) |> 
  dplyr::left_join(crab_spp) |> 
  dplyr::select(year, species_code, species, 
                population_count = abundance, # abundance_cv abundance_ci 
                biomass_mt = biomass_mt, # biomass_mt_cv biomass_mt_ci, 
                biomass_up, 
                biomass_dw, 
                population_up,
                population_dw, 
                n_weight, 
                taxon, common_name, species_name, 
                srvy, survey_definition_id)  |> # does not have population_var or biomass_var, cpue_kgkm2_mean cpue_nokm2_mean n_haul n_weight n_count n_length 
  dplyr::select(-species, -taxon, -species_name, -common_name, -srvy)

write.csv(x = crab_biomass, 
          file = here::here("data/crab_biomass_pack.csv"), 
          row.names = FALSE)


crab_specimen <- specimen |> 
  dplyr::mutate(LENGTH_TYPE = dplyr::case_when(
    SPECIES_CODE %in% c(68541, 68550, 68560) ~ 8,
    TRUE ~ 7
  )) |> 
  dplyr::select(HAULJOIN, SPECIES_CODE, SEX, LENGTH_MM = SIZE_1MM, LENGTH_TYPE, 
                SHELL_CONDITION, EGG_CONDITION, CLUTCH_SIZE, MERUS_LENGTH, 
                CHELA_HEIGHT, DISEASE_CODE, 
                WEIGHT_G = CALCULATED_WEIGHT, 
                SAMPLING_FACTOR)

write.csv(x = crab_specimen, 
          file = here::here("data/crab_specimen_pack.csv"), 
          row.names = FALSE)

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ##   Upload Tables to GAP_PRODUCTS
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ##
# # Temporarily dump these tables in MARKOWITZE so they can be pulled into production tables ------------
# source("Z:/Projects/ConnectToOracle.R")
# quantity <- c("crab_sizecomp", "crab_biomass", "crab_cpue", "crab_specimen")
# 
# for (idata in quantity) { ## Loop over data types -- start
#   
#   data_table <- read.csv(file = here::here(paste0("data/", gsub(pattern = "crab_", replacement = "crabpack_", x = idata), ".csv"))) |> 
#     dplyr::rename_all(toupper)
# 
#   ## Pull field descriptions from GAP_PRODUCTS.METADATA_COLUMN
#   metadata_column <-
#     RODBC::sqlQuery(channel = channel,
#                     query = paste(
#                       "SELECT * FROM GAP_PRODUCTS.METADATA_COLUMN
#                        WHERE METADATA_COLNAME IN",
#                       gapindex::stitch_entries(names(x = data_table))))
# 
#   ## Clean up field names to be consistent with the data input format for
#   ## gapindex::upload_oracle
#   names(x = metadata_column) <-
#     gsub(x = tolower(x = names(x = metadata_column)),
#          pattern = "metadata_",
#          replacement = "")
#   
#   ## Upload to Oracle
#   gapindex::upload_oracle(channel = channel,
#                           x = data_table,
#                           schema = "MARKOWITZE", # "GAP_PRODUCTS",
#                           table_name = toupper(x = idata),
#                           table_metadata = "compiled from crabpack",
#                           metadata_column = metadata_column)
#   
# } ## Loop over data types -- start
# 
# 
# 

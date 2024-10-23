# -- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_SAMPLESIZE
# --
# -- Created by summarizing many tables from RACE_DATA and GAP_PRODUCTS, 
# -- for AKFIN. This is maintained in the gap_products GitHub repo
# -- (github.com/afsc-gap-products/gap_products). 
# --
# -- Contributors: Ned Laman (ned.laman@noaa.gov), 
# --               Zack Oyafuso (zack.oyafuso@noaa.gov), 
# --               Emily Markowitz (emily.markowitz@noaa.gov)
# --
# 
# CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_AREA AS 
# SELECT * FROM GAP_PRODUCTS.AREA
# 
# 
# -- ### Ex. Calculate survey haul and specimen summaries 
# 
#  -- Here we will find the number of hauls where specimen types were collected (_H) and counts of how many total specimens were collected (_S). These estimates are summarized by survey (SURVEY_DEFINITION_ID), year (YEAR), and species (SPECIES_CODE). The metrics calculated below include: 
# 
#  -- **N_AGE_S**: Total number of otolith samples that have been aged from all stations. 
#  -- **N_COUNT_H**: Total number of hauls with positive count data.
#  -- **N_GENETICS_H**: Total number of hauls where genetic samples were collected from all stations 
#  -- **N_GENETICS_S**: Total number of genetic samples that were collected from all stations. 
#  -- **N_LENGTH_H**: Total number of hauls with length data.
#  -- **N_LENGTH_S**: Total number of length samples that were collected from all stations. 
#  -- **N_OTOLITHS_H**: Total number of hauls where otolith samples were collected from. 
#  -- **N_OTOLITHS_S**: Total number of otolith samples that were collected from all stations. 
#  -- **N_WEIGHT_H**: Total number of hauls with positive catch biomass.

# haul level summaries ---------------------------------------------------------

dat_haul <- RODBC::sqlQuery(channel = channel,
                       query =
paste0("
-- Select columns for output data
SELECT 
SURVEY_DEFINITION_ID, 
AREA_ID, 
SPECIES_CODE, 
YEAR, 
N_HAUL -- Total number of hauls for whole survey.
N_WEIGHT AS N_WEIGHT_H, -- Total number of hauls with positive catch biomass.
N_COUNT AS N_COUNT_H, -- Total number of hauls with positive count data.
N_LENGTH AS N_LENGTH_H -- Total number of hauls with length data.

-- Identify what tables to pull data from
FROM GAP_PRODUCTS.AKFIN_BIOMASS;"))

# number of specimen per haul -----------------------------------------------------------

dat_specimen <- RODBC::sqlQuery(channel = channel,
                       query =
paste0("
-- Select columns for output data
SELECT
ss.SPECIES_CODE,
cc.YEAR,
cc.SURVEY_DEFINITION_ID,
aa.AREA_ID,
ss.specimen_sample_type, 
st.NAME AS specimen_sample_name, 
COUNT(DISTINCT ss.HAULJOIN) AS N_, -- The number of hauls with specimens collected
COUNT(ss.specimen_sample_type) AS S_ -- The number of specimens collected

-- Identify what tables to pull data from
FROM GAP_PRODUCTS.AKFIN_SPECIMEN ss
LEFT JOIN GAP_PRODUCTS.AKFIN_HAUL hh
ON ss.HAULJOIN = hh.HAULJOIN
LEFT JOIN GAP_PRODUCTS.AKFIN_CRUISE cc
ON hh.CRUISEJOIN = cc.CRUISEJOIN
LEFT JOIN GAP_PRODUCTS.AKFIN_STRATUM_GROUPS aa
ON hh.STRATUM = aa.STRATUM
AND cc.SURVEY_DEFINITION_ID = aa.SURVEY_DEFINITION_ID
LEFT JOIN RACE_DATA.SPECIMEN_SAMPLE_TYPES st
ON ss.specimen_sample_type = st.SPECIMEN_SAMPLE_TYPE_ID
AND cc.SURVEY_DEFINITION_ID = aa.SURVEY_DEFINITION_ID

-- Group for COUNT() or SUM() functions in SELECT call
GROUP BY ss.SPECIES_CODE, cc.YEAR, cc.SURVEY_DEFINITION_ID, aa.AREA_ID, ss.specimen_sample_type--, st.NAME 
ORDER BY cc.SURVEY_DEFINITION_ID, cc.YEAR, ss.SPECIES_CODE, ss.specimen_sample_type;")) %>% #  --, st.NAME;

  dplyr::mutate(SPECIMEN_SAMPLE_TYPE = gsub(pattern = " ", replacement = "_", x = SPECIMEN_SAMPLE_TYPE)), 
SPECIMEN_SAMPLE_TYPE = gsub(pattern = ")", replacement = "", x = SPECIMEN_SAMPLE_TYPE), 
SPECIMEN_SAMPLE_TYPE = gsub(pattern = "(", replacement = "", x = SPECIMEN_SAMPLE_TYPE))) %>% 
  tidyr::pivot_wider(id_cols = c("SPECIES_CODE", "YEAR", "SURVEY_DEFINITION_ID", "AREA_ID"), 
                     names_from = "SPECIMEN_SAMPLE_TYPE", 
                     values_from = c("N_", "S_"))
names(dat_specimen)[grepl(pattern = "S__", x = names(dat_specimen), fixed = TRUE)] <- 
  paste0(names(dat_specimen)[grepl(pattern = "S__", x = names(dat_specimen), fixed = TRUE)], "_S")
names(dat_specimen)[grepl(pattern = "N__", x = names(dat_specimen), fixed = TRUE)] <- 
  paste0(names(dat_specimen)[grepl(pattern = "N__", x = names(dat_specimen), fixed = TRUE)], "_H")
names(dat_specimen)[grepl(pattern = "N__", x = names(dat_specimen), fixed = TRUE)] <- 
  gsub(pattern = "N__", replacement = "N_", 
       x = names(dat_specimen)[grepl(pattern = "N__", x = names(dat_specimen), fixed = TRUE)]) 
names(dat_specimen)[grepl(pattern = "S__", x = names(dat_specimen), fixed = TRUE)] <- 
  gsub(pattern = "S__", replacement = "N_", 
       x = names(dat_specimen)[grepl(pattern = "S__", x = names(dat_specimen), fixed = TRUE)]) 

# number of AGED specimen -----------------------------------------------------------

dat_specimen_aged <- RODBC::sqlQuery(channel = channel,
                       query =
paste0("
-- Select columns for output data
SELECT
ss.SPECIES_CODE,
cc.YEAR,
cc.SURVEY_DEFINITION_ID,
aa.AREA_ID,
COUNT(*) AS N_AGE_S

-- Identify what tables to pull data from
FROM GAP_PRODUCTS.AKFIN_SPECIMEN ss
LEFT JOIN GAP_PRODUCTS.AKFIN_HAUL hh
ON ss.HAULJOIN = hh.HAULJOIN
LEFT JOIN GAP_PRODUCTS.AKFIN_CRUISE cc
ON hh.CRUISEJOIN = cc.CRUISEJOIN
LEFT JOIN GAP_PRODUCTS.AKFIN_STRATUM_GROUPS aa
ON hh.STRATUM = aa.STRATUM
AND cc.SURVEY_DEFINITION_ID = aa.SURVEY_DEFINITION_ID

-- Filter data results
WHERE ss.specimen_sample_type = 1
AND ss.AGE IS NOT NULL

-- Group for COUNT() or SUM() functions in SELECT call
GROUP BY ss.SPECIES_CODE, cc.YEAR, cc.SURVEY_DEFINITION_ID, aa.AREA_ID
ORDER BY cc.SURVEY_DEFINITION_ID, cc.YEAR, ss.SPECIES_CODE;")) 

## number of lengths -----------------------------------------------------------

dat_length <- RODBC::sqlQuery(channel = channel,
                       query =
paste0("
-- Select columns for output data
SELECT 
C.SPECIES_CODE,
cc.YEAR,
cc.SURVEY_DEFINITION_ID,
aa.AREA_ID,
SUM(C.FREQUENCY) AS N_LENGTH_S

-- Identify what tables to pull data from
FROM RACE_DATA.CRUISES A
JOIN RACE_DATA.SURVEYS S
ON (S.SURVEY_ID = A.SURVEY_ID)
JOIN RACE_DATA.SURVEY_DEFINITIONS SD
ON (SD.SURVEY_DEFINITION_ID = S.SURVEY_DEFINITION_ID)
JOIN RACE_DATA.HAULS B
ON (B.CRUISE_ID = A.CRUISE_ID)
JOIN RACE_DATA.LENGTHS C
ON (C.HAUL_ID = B.HAUL_ID)
JOIN GAP_PRODUCTS.AKFIN_HAUL hh
ON B.HAUL = hh.HAUL
JOIN GAP_PRODUCTS.AKFIN_CRUISE cc
ON A.CRUISE = cc.CRUISE
LEFT JOIN GAP_PRODUCTS.AKFIN_STRATUM_GROUPS aa
ON hh.STRATUM = aa.STRATUM
AND cc.SURVEY_DEFINITION_ID = aa.SURVEY_DEFINITION_ID

-- Group for COUNT() or SUM() functions in SELECT call
GROUP BY C.SPECIES_CODE, cc.YEAR, cc.SURVEY_DEFINITION_ID, aa.AREA_ID
ORDER BY cc.SURVEY_DEFINITION_ID, cc.YEAR, C.SPECIES_CODE;"))

# Bind data together -----------------------------------------------------------

AKFIN_SAMPLESIZE <- dplyr::full_join(dat_haul, dat_specimen) %>% 
  dplyr::full_join(dat_length)  %>% 
  dplyr::full_join(dat_specimen_aged) %>% 
  dplyr::select(order(colnames(.))) %>% 
  dplyr::relocate(SURVEY_DEFINITION_ID, AREA_ID, YEAR, SPECIES_CODE) %>% 
  dplyr::arrange(SURVEY_DEFINITION_ID, AREA_ID, SPECIES_CODE, YEAR) %>% 
  tidyr::pivot_longer(cols = dplyr::starts_with("N_"), names_to = "N_SAMPLE_TYPE", values_to = "N") %>% 
  dplyr::mutate(N_SAMPLE_TYPE = gsub(pattern = "N_", replacement = "", x = N_SAMPLE_TYPE)) %>% 
  dplyr::filter(!is.na(N))


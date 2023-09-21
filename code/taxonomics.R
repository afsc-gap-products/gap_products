#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2023-06-01
#' Notes: 
#' -----------------------------------------------------------------------------

## Taxon Confidence ------------------------------------------------------------

# Quality Codes
# 1 – High confidence and consistency.  Taxonomy is stable and reliable at this 
#     level, and field identification characteristics are well known and reliable.
# 2 – Moderate confidence.  Taxonomy may be questionable at this level, or field  
#     identification characteristics may be variable and difficult to assess consistently.
# 3 – Low confidence.  Taxonomy is incompletely known, or reliable field  
#     identification characteristics are unknown.

### Load taxon confidence data -------------------------------------------------

TAXON_CONFIDENCE <- data.frame()
a <- list.files(path = paste0("./data/TAXON_CONFIDENCE/"))
for (i in 1:length(a)){
  print(a[i])
  b <- readxl::read_xlsx(path = paste0("./data/TAXON_CONFIDENCE/", a[i]), 
                         skip = 1, col_names = TRUE) %>% 
    dplyr::select(where(~!all(is.na(.x)))) %>% # remove empty columns
    janitor::clean_names() %>% 
    dplyr::rename(species_code = code)
  if (sum(names(b) %in% "quality_codes")>0) {
    b$quality_codes<-NULL
  }
  b <- b %>% 
    tidyr::pivot_longer(cols = starts_with("x"), 
                        names_to = "year", 
                        values_to = "TAXON_CONFIDENCE") %>% 
    dplyr::mutate(year = gsub(pattern = "[a-z]", 
                              replacement = "", 
                              x = year), 
                  year = gsub(pattern = "_0", replacement = "", 
                              x = year), 
                  year = as.numeric(year)) %>% 
    dplyr::distinct()
  
  cc <- strsplit(x = gsub(x = gsub(x = a[i], 
                                   pattern = "TAXON_CONFIDENCE_", replacement = ""), 
                          pattern = ".xlsx", 
                          replacement = ""), 
                 split = "_")[[1]]
  
  if (length(cc) == 1) {
    b$SRVY <- cc
  } else {
    bb <- data.frame()
    for (ii in 1:length(cc)){
      bbb <- b
      bbb$SRVY <- cc[ii]
      bb <- rbind.data.frame(bb, bbb)
    }
    b<-bb
  }
  TAXON_CONFIDENCE <- TAXON_CONFIDENCE %>% 
    dplyr::bind_rows(b)
}

TAXON_CONFIDENCE <- TAXON_CONFIDENCE %>% 
  dplyr::mutate(TAXON_CONFIDENCE_code = TAXON_CONFIDENCE#, 
                #TAXON_CONFIDENCE = dplyr::case_when(
                #   TAXON_CONFIDENCE_code == 1 ~ "High",
                #   TAXON_CONFIDENCE_code == 2 ~ "Moderate",
                #   TAXON_CONFIDENCE_code == 3 ~ "Low", 
                #   TRUE ~ "Unassessed")
  ) %>%
  dplyr::left_join(y = 
                     data.frame(survey_definition_id = c(143, 98, 47, 52, 78),
                                SRVY = c("NBS", "EBS", "GOA", "AI", "BSS") ),
                   by = "SRVY") %>% 
  dplyr::select(-scientific_name, -common_name, -SRVY)

### fill in TAXON_CONFIDENCE with, if missing, the values from the year before

cruises <- RODBC::sqlQuery(channel = channel_products, "SELECT * FROM RACE_DATA.V_CRUISES") %>% 
  janitor::clean_names() %>% 
  dplyr::filter(survey_definition_id %in% c(143, 98, 47, 52, 78) & 
                  !is.na(cruisejoin) & 
                  year >= 1982) 
# write.csv(x = cruises, file = "RACE_DATA.V_CRUISES.csv")

comb1 <- unique(cruises[, c("survey_definition_id", "year")] )
comb2 <- unique(TAXON_CONFIDENCE[, c("survey_definition_id", "year")])
comb1$comb <- paste0(comb1$survey_definition_id, "_", comb1$year)
comb2$comb <- paste0(comb2$survey_definition_id, "_", comb2$year)
comb <- strsplit(x = setdiff(comb1$comb, comb2$comb), split = "_")

NEW_TAXON_CONFIDENCE <- dplyr::bind_rows(
  TAXON_CONFIDENCE, 
  TAXON_CONFIDENCE %>% 
    dplyr::filter(
      survey_definition_id %in% sapply(comb,"[[",1) &
        year == 2021) %>% 
    dplyr::mutate(year = 2022), 
  TAXON_CONFIDENCE %>% 
    dplyr::filter(
      survey_definition_id %in% sapply(comb,"[[",1) &
        year == 2021) %>% 
    dplyr::mutate(year = 2023))  

NEW_TAXON_CONFIDENCE_COMMENT <- paste0(
  "The quality and specificity of field identifications for many taxa have 
    fluctuated over the history of the surveys due to changing priorities and resources. 
    The matrix lists a confidence level for each taxon for each survey year 
    and is intended to serve as a general guideline for data users interested in 
    assessing the relative reliability of historical species identifications 
    on these surveys. This dataset includes an identification confidence matrix 
    for all fishes and invertebrates identified ", 
  metadata_sentence_survey_institution, 
  "Quality Codes: ", 
  "1: High confidence and consistency. Taxonomy is stable and reliable at this level, and field identification characteristics are well known and reliable. ",
  "2: Moderate confidence. Taxonomy may be questionable at this level, or field identification characteristics may be variable and difficult to assess consistently. ", 
  "3: Low confidence. Taxonomy is incompletely known, or reliable field identification characteristics are unknown. ", 
  "NA: Unassessed. Taxonomy quality has not been assessed. ", 
  metadata_sentence_legal_restrict, " ",  
  metadata_sentence_github, " ", 
  metadata_sentence_codebook, " ", 
  metadata_sentence_last_updated)


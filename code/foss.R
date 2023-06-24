
# # The surveys we will cover in this data are: 
# surveys <-
#   data.frame(survey_definition_id = c(143, 98, 47, 52, 78),
#              SRVY = c("NBS", "EBS", "GOA", "AI", "BSS"),
#              SRVY_long = c("northern Bering Sea",
#                            "eastern Bering Sea",
#                            "Gulf of Alaska",
#                            "Aleutian Islands",
#                            "Bering Sea Slope") )

metadata_column0 <- NEW_metadata_column[match(names(FOSS_CPUE_ZEROFILLED), 
                                                       toupper(NEW_metadata_column$metadata_colname)),]  
metadata_column0$metadata_colname <- toupper(metadata_column0$metadata_colname)

## Zero-fill join tables -------------------------------------------------------
metadata_table <- paste(
  "These datasets, JOIN_FOSS_CPUE_CATCH and JOIN_FOSS_CPUE_HAUL, 
when full joined by the HAULJOIN variable, 
includes zero-filled (presence and absence) observations and
catch-per-unit-effort (CPUE) estimates for all identified species at for index stations ", 
  metadata_sentence_survey_institution, 
  metadata_sentence_legal_restrict_none, 
  metadata_sentence_foss, 
  metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated, 
  collapse = " ", sep = " ")
metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table, 
  name0 = "JOIN_FOSS_CPUE", 
  dir_out = dir_out)

base::save(
  JOIN_FOSS_CPUE_HAUL, 
  JOIN_FOSS_CPUE_CATCH, 
  metadata_column0, 
  metadata_table, 
  file = paste0(dir_out, "FOSS_CPUE_JOIN.RData"))

## Zero filled full table ------------------------------------------------------

metadata_table <- paste(
  "This dataset includes zero-filled (presence and absence) observations and
catch-per-unit-effort (CPUE) estimates for all identified species at for index stations ", 
  metadata_sentence_survey_institution,
  metadata_sentence_legal_restrict_none, 
  metadata_sentence_foss, 
  metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated, 
  collapse = " ", sep = " ")
metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table, 
  name0 = "FOSS_CPUE_ZEROFILLED", 
  dir_out = dir_out)

base::save(
  FOSS_CPUE_ZEROFILLED, 
  metadata_column0, 
  metadata_table, 
  file = paste0(dir_out, "FOSS_CPUE_ZEROFILLED.RData"))

## Pres-only data --------------------------------------------------------------

FOSS_CPUE_PRESONLY <- FOSS_CPUE_ZEROFILLED %>%
  dplyr::filter(
    !(COUNT %in% c(NA, 0) & # this will remove 0-filled values
        WEIGHT_KG %in% c(NA, 0)) | 
      !(CPUE_KGKM2 %in% c(NA, 0) & # this will remove usless 0-cpue values, 
          CPUE_NOKM2 %in% c(NA, 0)) ) # which shouldn't happen, but good to double check

metadata_table <- gsub(pattern = "zero-filled (presence and absence)", 
                       replacement = "presence-only",
                       x = paste(readLines(con = paste0(dir_out, "FOSS_CPUE_ZEROFILLED_metadata_table.txt")), collapse="\n"))
metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table, 
  name0 = "FOSS_CPUE_PRESONLY", 
  dir_out = dir_out)

base::save(
  FOSS_CPUE_PRESONLY, 
  metadata_column0, 
  metadata_table, 
  file = paste0(dir_out, "FOSS_CPUE_PRESONLY.RData"))

## Save CSV's ------------------------------------------------------------------

list_to_save <- c(
  "JOIN_FOSS_CPUE_CATCH", 
  "JOIN_FOSS_CPUE_HAUL",
  "FOSS_CPUE_PRESONLY", 
  "FOSS_CPUE_ZEROFILLED")

for (i in 1:length(list_to_save)) {
  readr::write_csv(
    x = get(list_to_save[i]), 
    file = paste0(dir_out, list_to_save[i], ".csv"), 
    col_names = TRUE)
}

## Make Taxonomic grouping searching table -----------------------------------------------

TAXON_GROUPS <- gap_products_old_taxonomics_worms0 %>%
  dplyr::select(species_code, genus, family, order, class, phylum, kingdom) %>%
  tidyr::pivot_longer(data = .,
                      cols = c("genus", "family", "order", "class", "phylum", "kingdom"),
                      names_to = "id_rank", values_to = "classification") %>%
  dplyr::relocate(id_rank, classification, species_code) %>%
  dplyr::arrange(id_rank, classification, species_code) %>%
  dplyr::filter(!is.na(classification))

# only keep groups that have more than one member
TAXON_GROUPS <- TAXON_GROUPS[duplicated(x = TAXON_GROUPS$id_rank),]

metadata_table <- paste(
  "This dataset contains suggested search groups for simplifying species selection in the FOSS data platform. This was developed ", 
  metadata_sentence_survey_institution,
  metadata_sentence_legal_restrict_none, 
  metadata_sentence_foss, 
  metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated, 
  collapse = " ", sep = " ")
metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table, 
  name0 = "TAXON_GROUPS", 
  dir_out = dir_out)

metadata_column0 <- NEW_metadata_column[match(names(TAXON_GROUPS), 
                                                       toupper(NEW_metadata_column$metadata_colname)),]  
metadata_column0$metadata_colname <- toupper(metadata_column0$metadata_colname)

base::save(
  TAXON_GROUPS,
  metadata_column0,
  metadata_table,
  file = paste0(dir_out, "TAXON_GROUPS.RData"))

readr::write_csv(
  x = TAXON_GROUPS, 
  file = paste0(dir_out, "TAXON_GROUPS.csv"), 
  col_names = TRUE)




metadata_table <- paste(
  "These datasets, FOSS_CATCH and FOSS_HAUL, 
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

### FOSS_CATCH -----------------------------------------------------------------

metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table,
  name0 = "FOSS_CATCH",
  dir_out = dir_out)

update_metadata(
  schema = "GAP_PRODUCTS", 
    table_name = "FOSS_CATCH", 
    channel = channel, 
    metadata_column = metadata_column, 
    table_metadata = metadata_table)

### FOSS_HAUL ------------------------------------------------------------------

metadata_table <- fix_metadata_table(
  metadata_table0 = metadata_table,
  name0 = "FOSS_HAUL",
  dir_out = dir_out)

update_metadata(
  schema = "GAP_PRODUCTS", 
  table_name = "FOSS_HAUL", 
  channel = channel, 
  metadata_column = metadata_column, 
  table_metadata = metadata_table)

## Make Taxonomic grouping searching table -----------------------------------------------

TAXON_GROUPS <- NEW_TAXONOMICS_ITIS %>%
  dplyr::select(species_code, genus, family, order, class, phylum, kingdom) %>%
  tidyr::pivot_longer(data = .,
                      cols = c("genus", "family", "order", "class", "phylum", "kingdom"),
                      names_to = "id_rank", values_to = "classification") %>%
  dplyr::relocate(id_rank, classification, species_code) %>%
  dplyr::arrange(id_rank, classification, species_code) %>%
  dplyr::filter(!is.na(classification))

# only keep groups that have more than one member
NEW_TAXON_GROUPS <- TAXON_GROUPS[duplicated(x = TAXON_GROUPS$id_rank),]

NEW_TAXON_GROUPS_COMMENT <- paste(
  "This dataset contains suggested search groups for simplifying species selection in the FOSS data platform. This was developed ", 
  metadata_sentence_survey_institution,
  metadata_sentence_legal_restrict_none, 
  metadata_sentence_foss, 
  metadata_sentence_github, 
  metadata_sentence_codebook, 
  metadata_sentence_last_updated, 
  collapse = " ", sep = " ")

# NEW_TAXON_GROUPS_TABLE <- fix_metadata_table(
#   metadata_table0 = NEW_METADATA_TABLE,
#   name0 = "TAXON_GROUPS",
#   dir_out = dir_out)


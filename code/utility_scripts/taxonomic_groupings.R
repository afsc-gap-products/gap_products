##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:     Creation of GAP_PRODUCTS.TAXON_GROUPS
## Description: This table is based on GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
##              with the inclusion of a GROUP_CODE field that indicates whether
##              a SPECIES_CODE belongs to an aggregate SPECIES_CODE. Taxon
##              aggregations are generally based on the minimum identification
##              levels used on deck for most invertebrate and fish taxa with
##              some exceptions noted in the comments throughout the script. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Connect to Oracle using GAP_PRODUCTS credentials
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gapindex)
chl <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Query all records from GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
current_gp_taxonomic_classification <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1")
current_gp_taxonomic_changes <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT OLD_SPECIES_CODE, NEW_SPECIES_CODE
                           FROM GAP_PRODUCTS.TAXONOMIC_CHANGES
                           WHERE OLD_SPECIES_CODE != NEW_SPECIES_CODE
                           ORDER BY NEW_SPECIES_CODE")
current_gp_taxon_groups <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "select * from gap_products.taxon_groups 
                           order by GROUP_CODE, SPECIES_CODE")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Append updated taxonomic classification info to the OLD_SPECIES_CODE
##   in current_gp_taxonomic_changes 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Subset the corrected classification information for the new species codes
taxon_changes_classification <- 
  subset(x = current_gp_taxonomic_classification,
         subset = SPECIES_CODE %in% 
           current_gp_taxonomic_changes$NEW_SPECIES_CODE)

## Merge the OLD_SPECIES_CODE field from taxon changes to 
## taxon_changes_classification 
taxon_changes_classification <- 
  merge(x = taxon_changes_classification, by.x = "SPECIES_CODE",
        y = current_gp_taxonomic_changes, by.y = "NEW_SPECIES_CODE")

taxon_changes_classification$SPECIES_CODE <- 
  taxon_changes_classification$OLD_SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Remove the classification information for the old species codes from
##   gp_taxon_class and tehn append the classification information of the 
##   updated SPECIES_CODES
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
updated_gp_taxonomic_classification <- 
  rbind(
    subset(x = current_gp_taxonomic_classification, 
           subset = !SPECIES_CODE %in% 
             taxon_changes_classification$SPECIES_CODE),
    taxon_changes_classification[, names(x = current_gp_taxonomic_classification)])

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   The taxa in grouped_taxa are those invertebrate groups that are minimally
##   identified at the same taxonomic resolution that defines the taxon, e.g., 
##    Phylum Porifera which is also minimally field-identified to phylum. These 
##   coarse aggregations mask many of the varieties in the levels of taxonomic 
##   confidence for individual species codes and thus is a conservative approach
##   to reporting data products for many of the invertebrate taxa observed in 
##   our bottom trawl surveys. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa <- 
  RODBC::sqlQuery(
    channel = chl, 
    query = paste(
      "SELECT * 
       FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
       WHERE SURVEY_SPECIES = 1 
       AND SPECIES_CODE IN", 
      gapindex::stitch_entries(
        c(
          ## Phylum Athropoda
          60100, ## amphipods (Order Amphipoda)
          65000, ## cirripedia (Subclass Cirripedia)
          63000, ## cumacea (Order Cumacea)
          62000, ## isopods (Order Isopoda)
          64100, ## mysids (Family Mysidae)
          69900, ## sea spiders (Class Pycnogonida)
          
          ## Phylum Byrozoa 
          95000, ## byozoans (Phylum Bryozoa)
          
          ## Phylum Brachiopoda
          97000, ## brachiopods (Phylum Brachiopoda)
          
          ## Phylum Cnidaria
          43000, ## anemones (Order Actiniaria)
          
          40011, ## hydroids (Subclass Hydroidolina)
          41099, ## octocorals (Class Octocorallia but includes sea whips)
          44000, ## stony corals (Order Scleractinia but includes cup corals)
          40500, ## jellyfish (Class Scyphozoa)
          
          ## Phylum Ctenophora
          45000, ## comb jellies (Phylum ctenophora)
          
          ## Phylum Echinodermata
          83000, ## brittle stars (Class Ophiuroidea but includes basket stars)
          85000, ## sea cucumbers (Class Holothuroidea)
          82750, ## Crinoids (Class Crinoidea)
          
          ## Phylum Hirudinea
          59100, ## sea leaches (Subclass Hirudinea)
          
          ## Phylum Mollusca
          70049, ## Solenogastres (Superclass Aplacophora)
          71010, ## nudibranchs (Order Nudibranchia)
          70100, ## chitons (Class Polyplacophora)
          
          ## Phylum Polychaeta
          50000, ## polychaetes (Class Polychaeta but includes echiuroid worms)
          
          ## Phylum Porifera
          91000, ## sponges (Phylum Porifera)
          
          ## Phylum Sipuncula
          94000, ## peanut worms (Order Sipuncula)
          
          ## Phylum Urochordata, 
          98000, ## tunicates (Class Ascidiacea)
          98070, ## salps (Class Thaliacea)
          
          ## Genera Henricia and Lycodapus,
          ## Genera in families Myctophidae and Liparidae,
          ## and genera within bivalves, sea urchins, octopuses, shrimps
          RODBC::sqlQuery(channel = chl,
                          query = "SELECT SPECIES_CODE
          FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
          WHERE SURVEY_SPECIES = 1 
          AND (FAMILY_TAXON in ('Myctophidae', -- nyctophids
                                'Liparidae'   -- snailfishes
                                ) 
               OR GENUS_TAXON IN ('Lycodapus', 'Henricia', 'Pteraster')
               OR CLASS_TAXON IN 'Bivalvia' -- bivalves
               OR ORDER_TAXON IN ('Camarodonta', 'Spatangoida') -- sea urchins
               OR INFRAORDER_TAXON = 'Caridea' -- shrimps
               OR ORDER_TAXON = 'Octopoda' -- octopuses
               OR (CLASS_TAXON = 'Gastropoda'             -- snails
                   AND ORDER_TAXON != 'Nudibranchia') -- excl. nudibranchs
              )
          AND ID_RANK = 'genus'")$SPECIES_CODE
        )
      )
    )
  )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   For each taxon record in grouped_taxa, query the species codes that are 
##   contained in that taxon by using the taxonomic classification information 
##   contained in grouped_taxa, and then assign it the group code of the taxon 
##   in grouped_taxa, e.g., assign all records where PHYLUM_TAXON = 'Porifera' 
##   a GROUP_CODE value of 91000, the code for Porifera.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df <- data.frame()
for (irow in 1:nrow(x = grouped_taxa)) { ## Loop through grouped taxa -- start
  
  ## Pull the name of the taxon 
  temporary_taxon_name <- 
    grouped_taxa[irow, paste0(toupper(x = grouped_taxa$ID_RANK[irow]), 
                              "_TAXON")]
  
  ## String together the text used in the subset
  subset_text <- paste0(toupper(x = grouped_taxa$ID_RANK[irow]), "_TAXON == '", 
                        temporary_taxon_name, "'")
  
  ## Subset records from the updated taxonomic classification
  subsetted_records <- subset(x = updated_gp_taxonomic_classification,
                              subset = eval(parse(text = subset_text)))
  
  ## Append to grouped_taxa_df
  grouped_taxa_df <- 
    rbind(grouped_taxa_df, 
          data.frame(GROUP_CODE = grouped_taxa$SPECIES_CODE[irow], 
                     subsetted_records)
    )
} ## Loop through grouped taxa -- end

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   There are some grouped taxa that are paraphyletic to the groups formed
##   in the previous step. Reassign the GROUP_CODE values of these paraphyllia.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Sea pens (Family Pennatuloidea, 42000) is a paraphyly within CLass 
## Octocorallia (41099).
grouped_taxa_df$GROUP_CODE[
  grouped_taxa_df$SUPERFAMILY_TAXON == 'Pennatuloidea'] <- 42000

## Basketstars (Gorgonocephalus eucnemis, 83020) is a paraphyly within 
## Class Ophiuroidea (83000). 
grouped_taxa_df$GROUP_CODE[
  grouped_taxa_df$SPECIES_CODE == 83020
] <- 83020

## Spoon worms (Subclass Echiura, 94500) is a paraphyly within Phylum 
## Polychaeta (50000).
grouped_taxa_df$GROUP_CODE[
  grouped_taxa_df$SUBCLASS_TAXON == "Echiura"] <- 94500

## Cup corals (Family Caryophylliidae, 44004) is a paraphyly within Order
## Scleractinia (44000).
grouped_taxa_df$GROUP_CODE[
  grouped_taxa_df$FAMILY_TAXON == "Caryophylliidae"] <- 44004

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Merge the GROUP_CODE field from grouped_taxa_df to gp_taxon_class using
##  SPECIES_CODE as the key
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
updated_gp_taxon_groups <- 
  merge(x = subset(x = updated_gp_taxonomic_classification, 
                   select = -SURVEY_SPECIES),
        y = grouped_taxa_df[, c("SPECIES_CODE", "GROUP_CODE")],
        all.x = TRUE,
        by = "SPECIES_CODE")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   For SPECIES_CODES that have been changed and are not a part of the
##   grouped_taxa_df, set the value of the GROUP_CODE to the updated SPECIES_CODE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Any SPECIES_CODES that are not a part of a larger taxon group
single_spp_codes <- 
  current_gp_taxonomic_changes$OLD_SPECIES_CODE[
    !current_gp_taxonomic_changes$OLD_SPECIES_CODE %in% 
      grouped_taxa_df$SPECIES_CODE
  ] 

synonyms <- 
  merge(x = subset(updated_gp_taxon_groups, 
                   subset = SPECIES_CODE %in% single_spp_codes, 
                   select = SPECIES_CODE), by.x = "SPECIES_CODE",
        y = current_gp_taxonomic_changes, by.y = "OLD_SPECIES_CODE")

## For these species codes that do not belong to a larger group, 
## set the GROUP_CODE of these records to the updated species code
updated_gp_taxon_groups[
  match(x = synonyms$SPECIES_CODE, 
        table = updated_gp_taxon_groups$SPECIES_CODE), "GROUP_CODE"
]<- synonyms$NEW_SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Any remaining records that do not have a GROUP_CODE value are 
##   assigned the SPECIES_CODE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
single_taxon <- is.na(x = updated_gp_taxon_groups$GROUP_CODE)
updated_gp_taxon_groups$GROUP_CODE[single_taxon] <-
  updated_gp_taxon_groups$SPECIES_CODE[single_taxon]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Check this newly created gp_groups with the current version of 
##   GAP_PRODUCTS.TAXON_GROUPS
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Check that the number of rows are the same
nrow(current_gp_taxon_groups) == nrow(updated_gp_taxon_groups)

## Check that SPECIES_CODEs are unique
table(table(updated_gp_taxon_groups$SPECIES_CODE))
table(table(current_gp_taxon_groups$SPECIES_CODE))

## Merge the two tables together using SPECIES_CODE as the key, and using the 
## suffixes _OLD as the current version and _NEW as the update. 
test_check <- merge(x = updated_gp_taxon_groups, 
                    y = current_gp_taxon_groups,
                    by = "SPECIES_CODE", 
                    suffixes = c("_UPDATE", "_CURRENT"))

## Reorder columns
test_check <- 
  test_check[, c("SPECIES_CODE", 
                 as.vector(sapply(X = names(current_gp_taxon_groups)[-2], 
                                  FUN = function(x) 
                                    paste0(x, c("_UPDATE", "_CURRENT")))))]
## Check for differences in each non-key field
for (icol in names(current_gp_taxon_groups)[-2]) {
  test_check[, paste0(icol, "_DIFF")] <- 
    test_check[, paste0(icol, "_UPDATE")] != 
    test_check[, paste0(icol, "_CURRENT")]
}

## Reorder columns
test_check <- 
  test_check[, c("SPECIES_CODE", 
                 as.vector(sapply(X = names(current_gp_taxon_groups)[-2], 
                                  FUN = function(x) 
                                    paste0(x, c("_UPDATE", 
                                                "_CURRENT",
                                                "_DIFF")))))]

## Print any differences
any_differences <- test_check$GROUP_CODE_DIFF

test_check[any_differences, ]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Upload to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Assemble column metadata
metadata_column_info <- RODBC::sqlQuery(
  channel = chl,
  query = paste0("SELECT *
                  FROM GAP_PRODUCTS.METADATA_COLUMN
                  WHERE METADATA_COLNAME IN ",
                 gapindex::stitch_entries(names(x = updated_gp_taxon_groups))))
names(x = metadata_column_info) <-
  gsub(x = tolower(x = names(x = metadata_column_info) ),
       pattern = "metadata_",
       replacement = "")

## Upload to Oracle
gapindex::upload_oracle(x = updated_gp_taxon_groups,
                        table_name = "TAXON_GROUPS",
                        metadata_column = metadata_column_info,
                        table_metadata = "",
                        channel = chl,
                        schema = "GAP_PRODUCTS",
                        share_with_all_users = TRUE)

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
##   The taxa in GROUPED_TAXA are those invertebrate groups that are minimally
##   identified at the same taxonomic resolution that defines the taxon, e.g., 
##   the Phylum Porifera which is also minimally identified to phylum. These 
##   coarse aggregations mask many of the varieties in the levels of taxonomic 
##   confidence for individual species codes and thus is a conservative approach
##   to reporting data products for many of the invertebrate taxa recorded in 
##   our bottom trawl surveys. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
GROUPED_TAXA <- 
  RODBC::sqlQuery(
    channel = chl, 
    query = paste(
      "SELECT * 
       FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
       WHERE SURVEY_SPECIES = 1 
       AND SPECIES_CODE IN", 
      gapindex::stitch_entries(
        c(59100, ## leaches (Subclass Hirudinea)
          60100, ## amphipods (Order Amphipoda)
          65000, ## cirripedia (Subclass Cirripedia)
          63000, ## cumacea (Order Cumacea)
          62000, ## isopods (Order Isopoda)
          64100, ## mysids (Family Mysidae)
          69900, ## pycnogonida (Class Pycnogonida)
          97000, ## brachiopods (Phylum Brachiopoda)
          95000, ## byozoans (Phylum Bryozoa)
          98070, ## salps (Class Thaliacea)
          98000, ## tunicates (Class Ascidiacea)
          43000, ## anemones (Order Actiniaria)
          45000, ## comb jellies (Phylum ctenophora)
          44004, ## cup corals (Family Caryophylliidae)
          40011, ## hydroids (Subclass Hydroidolina)
          40500, ## jellyfish (Class Scyphozoa)
          41099, ## octocorals (Class Octocorallia but includes sea whips)
          83000, ## brittle stars (Class Ophiuroidea but includes basket stars)
          85000, ## sea cucumbers (Class Holothuroidea)
          70100, ## chitons (Class Polyplacophora)
          70049, ## neomaniids (Superclass Aplacophora)
          71010, ## nudibranchs (Order Nudibranchia)
          50000, ## polychaetes (Class Polychaeta but includes echiuroid worms)
          91000, ## sponges (Phylum Porifera)
          94000, ## peanut worms (Order Sipuncula)
          92500  ## ribbon worms (Phylum Nemertea)
        )
      )
    )
  )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   For each taxon record in GROUPED_TAXA, query the species codes that are 
##   contained in that taxon by using the taxonomic classification information 
##   contained in GROUPED_TAXA, and then assign it the group code of the taxon 
##   in GROUPED_TAXA, e.g., assign all records where PHYLUM_TAXON = 'Porifera' 
##   a GROUP_CODE value of 91000, the code for Porifera.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df <- data.frame()

for (irow in 1:nrow(x = GROUPED_TAXA)) {
  if (!is.na(x = GROUPED_TAXA$SPECIES_NAME[irow])) {
    temp_grab <- 
      RODBC::sqlQuery(
        channel = chl,
        query = paste0("SELECT *
                        FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                        WHERE SURVEY_SPECIES = 1 AND ", 
                       GROUPED_TAXA$ID_RANK[irow], "_TAXON = '",
                       GROUPED_TAXA$SPECIES_NAME[irow], "'"))
    
    temp_grab$GROUP_CODE <- GROUPED_TAXA$SPECIES_CODE[irow]
    grouped_taxa_df <- rbind(grouped_taxa_df, temp_grab)
  }
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Separate sea pens from Octocorallia 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df$GROUP_CODE[
  grouped_taxa_df$SUPERFAMILY_TAXON == 'Pennatuloidea'] <- 42000

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Separate basket stars from brittle stars
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df$GROUP_CODE[
  grouped_taxa_df$SUBORDER_TAXON == "Euryalina"] <- 83020

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Separate echiuroid worm unid. from Polychaeta
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df$GROUP_CODE[
  grouped_taxa_df$SUBCLASS_TAXON == "Echiura"] <- 94500

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query taxon records for all fishes except for Myctophids, 
##   Lycodapus spp. and snailfishes which will be grouped to genus
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fish_taxa <- RODBC::sqlQuery(
  channel = chl,
  query = "
SELECT SPECIES_CODE AS GROUP_CODE, 
GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
WHERE SURVEY_SPECIES = 1
AND SUBPHYLUM_TAXON = 'Vertebrata'
AND CLASS_TAXON != 'Mammalia'

-- Remove Lycodapus spp.
MINUS 
SELECT SPECIES_CODE AS GROUP_CODE, 
GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
WHERE SURVEY_SPECIES = 1
AND GENUS_TAXON = 'Lycodapus'

-- Remove myctophids and snailfishes
MINUS
SELECT SPECIES_CODE AS GROUP_CODE, 
GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
WHERE SURVEY_SPECIES = 1
AND FAMILY_TAXON IN ('Myctophidae', 'Liparidae') "
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Group Myctophids, Lycodapus spp., and Liparidae records to genus where
##   a SPECIES_CODE for those genus-level codes exist
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fish_genera <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT *
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

           JOIN 

           (SELECT SPECIES_CODE AS GROUP_CODE, SPECIES_NAME, 
            COMMON_NAME, GENUS_TAXON
            
            FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
            
            WHERE SURVEY_SPECIES = 1 
            AND (FAMILY_TAXON in ('Myctophidae', 'Liparidae') 
            OR GENUS_TAXON = 'Lycodapus')
            AND ID_RANK = 'genus')

           USING (GENUS_TAXON)

           WHERE SURVEY_SPECIES = 1
           
           ORDER BY GROUP_CODE")[, names(x = fish_taxa)]

## Query individual species codes for myctophids and snailfishes that do not 
## have genus-level species codes and append to the fish_genera df.
fish_genera <- 
  rbind(fish_genera,
        RODBC::sqlQuery(
          channel = chl, 
          query = paste("SELECT 
                         SPECIES_CODE AS GROUP_CODE, 
                         GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
                         FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

                         WHERE SPECIES_CODE NOT IN", 
                        gapindex::stitch_entries(fish_genera$SPECIES_CODE),
                        "AND (FAMILY_TAXON in ('Myctophidae', 'Liparidae') 
                         OR GENUS_TAXON = 'Lycodapus')
                         AND ID_RANK = 'species'
                         AND SURVEY_SPECIES = 1
                         
                         ORDER BY GROUP_CODE"))[, names(x = fish_taxa)])

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all squid records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
squids <- RODBC::sqlQuery(
  channel = chl,
  query = "SELECT SPECIES_CODE AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND SUPERORDER_TAXON = 'Decapodiformes'"
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all crinoid records (Class Crinoidea)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
crinoids <- RODBC::sqlQuery(
  channel = chl,
  query = "SELECT 82750 AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND CLASS_TAXON = 'Crinoidea'"
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query hermit crab records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hermit_crabs <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT SPECIES_CODE AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND SUPERFAMILY_TAXON = 'Paguroidea'"
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query "true" crab records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
true_crabs <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT SPECIES_CODE AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND INFRAORDER_TAXON = 'Brachyura'"
) 

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query sand dollar records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sand_dollars <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT SPECIES_CODE AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND SUPERORDER_TAXON = 'Luminacea'"
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all sea star records except for Henricia spp. which will be grouped
##   to the genus Henricia
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sea_stars <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT SPECIES_CODE AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND CLASS_TAXON = 'Asteroidea'
           AND GENUS_TAXON != 'Henricia'")

## Query Henricia spp. and assign GROUP_CODE for the genus-level Henricia code
henricia <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT *
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

           JOIN 

           (SELECT SPECIES_CODE AS GROUP_CODE, SPECIES_NAME, 
            COMMON_NAME, GENUS_TAXON
                            
            FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
            WHERE SURVEY_SPECIES = 1 
            AND GENUS_TAXON = 'Henricia'
            AND ID_RANK = 'genus')

           USING (GENUS_TAXON)
 
           WHERE SURVEY_SPECIES = 1
           ORDER BY GROUP_CODE")[, names(x = sea_stars)]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Aggregate taxa to genus for: sea urchins, bivalves, octopuses, and shrimps
##   where genus-level codes exist
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
invert_genera <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT *
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

           JOIN 

           (SELECT SPECIES_CODE AS GROUP_CODE, COMMON_NAME, GENUS_TAXON
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1 
           AND (CLASS_TAXON IN 'Bivalvia'
               OR ORDER_TAXON IN ('Camarodonta', 'Spatangoida')
               OR INFRAORDER_TAXON = 'Caridea' 
               OR ORDER_TAXON = 'Octopoda')
           AND ID_RANK = 'genus')

           USING (GENUS_TAXON)

           WHERE SURVEY_SPECIES = 1

           ORDER BY GROUP_CODE")[, names(x = fish_taxa)]

## Query individual species codes for the taxa in invert_genera that do not have 
## genus-level species codes and append to the invert_genera df
invert_genera <- 
  rbind(
    invert_genera,
    RODBC::sqlQuery(
      channel = chl,
      query = paste(
        "SELECT SPECIES_CODE AS GROUP_CODE, 
         GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
         FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
         WHERE SURVEY_SPECIES = 1 
         AND (CLASS_TAXON IN 'Bivalvia'
              OR ORDER_TAXON IN ('Camarodonta', 'Spatangoida')
              OR INFRAORDER_TAXON = 'Caridea' 
              OR ORDER_TAXON = 'Octopoda')
         AND ID_RANK = 'species'
         AND SPECIES_CODE NOT IN", 
        gapindex::stitch_entries(invert_genera$SPECIES_CODE)))[
          , names(x = invert_genera)]
  )

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query snail records that are Class Gastropoda except for nudibranchs 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
snails <- RODBC::sqlQuery(
  channel = chl, 
  query = "
SELECT *
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

JOIN 

(SELECT SPECIES_CODE AS GROUP_CODE, SPECIES_NAME, COMMON_NAME, GENUS_TAXON
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
WHERE SURVEY_SPECIES = 1 
AND CLASS_TAXON = 'Gastropoda'
AND ORDER_TAXON != 'Nudibranchia'
AND ID_RANK = 'genus')

USING (GENUS_TAXON)

WHERE SURVEY_SPECIES = 1
ORDER BY GROUP_CODE
")[, names(x = fish_taxa)]

## Query individual species codes for snails that do not have genus-level 
## species codes and append to the snails df
snails <- rbind(
  snails,
  RODBC::sqlQuery(
    channel = chl,
    query = paste("SELECT SPECIES_CODE AS GROUP_CODE, 
                   GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
                   FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                   WHERE SURVEY_SPECIES = 1 
                   AND CLASS_TAXON = 'Gastropoda'
                   AND ORDER_TAXON != 'Nudibranchia'
                   AND ID_RANK = 'species'
                   AND SPECIES_CODE NOT IN", 
                  gapindex::stitch_entries(snails$SPECIES_CODE)))[
                    , names(x = snails)]
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query stony coral records minus cup corals
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stony_corals <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT *
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

JOIN 

(SELECT SPECIES_CODE AS GROUP_CODE, SPECIES_NAME, COMMON_NAME, GENUS_TAXON
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
WHERE SURVEY_SPECIES = 1 
AND ORDER_TAXON = 'Scleractinia'
AND FAMILY_TAXON != 'Caryophylliidae'
AND ID_RANK = 'genus')

USING (GENUS_TAXON)

WHERE SURVEY_SPECIES = 1
ORDER BY GROUP_CODE"
)[, names(x = fish_taxa)]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query pinch bug records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pinch_bugs <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT SPECIES_CODE AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND FAMILY_TAXON IN ('Munidopsidae', 'Sternostylidae')"
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query black corals records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
black_coral <-RODBC::sqlQuery(
  channel = chl,
  query = "SELECT SPECIES_CODE AS GROUP_CODE, 
           GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION.*
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1
           AND ORDER_TAXON = 'Antipatharia'"
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Query all records from GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
##  except for certain commercial crabs that SAP are responsible for. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_spp_codes <- RODBC::sqlQuery(
  channel = chl, 
  query = "SELECT *
           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
           WHERE SURVEY_SPECIES = 1"
)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  rbind all taxa gorups together and merge taxonomic information 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_taxa <- rbind(grouped_taxa_df, 
                  fish_taxa, 
                  fish_genera, invert_genera,
                  squids, hermit_crabs, true_crabs, sand_dollars, black_coral, 
                  snails, pinch_bugs, stony_corals, crinoids,
                  sea_stars, henricia)
all_taxa <- merge(x = all_spp_codes,
                  y = all_taxa[, c("SPECIES_CODE", "GROUP_CODE")],
                  by = "SPECIES_CODE",
                  all.x = TRUE)
all_taxa <- 
  all_taxa[, names(all_taxa)[c(ncol(x = all_taxa), 1:(ncol(x = all_taxa) - 1))]]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Attach any old SPECIES_CODES that were synonymized with SPECIES currently
##   in GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
taxon_changes <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT OLD_SPECIES_CODE AS SPECIES_CODE, 
                           NEW_SPECIES_CODE 
                           FROM GAP_PRODUCTS.TAXONOMIC_CHANGES
                           WHERE OLD_SPECIES_CODE != NEW_SPECIES_CODE")

## attach updated taxonomic information to the old species codes
taxon_changes <- merge(x = taxon_changes, by.x = "NEW_SPECIES_CODE",
                       y = all_taxa, by.y = "SPECIES_CODE")
taxon_changes <- taxon_changes[!is.na(x = taxon_changes$GROUP_CODE), 
                               names(x = all_taxa)]

all_taxa <- rbind(subset(x = all_taxa, 
                         subset = !(SPECIES_CODE %in% 
                                      taxon_changes$SPECIES_CODE)),
                  taxon_changes)

## Any remaining SPECIES_CODE records that don't belong to a group is reported
## as the are
all_taxa$GROUP_CODE[is.na(x = all_taxa$GROUP_CODE)] <- 
  all_taxa$SPECIES_CODE[is.na(x = all_taxa$GROUP_CODE)]

## Sort and remove SURVEY_SPECIES column
all_taxa <- all_taxa[order(all_taxa$GROUP_CODE), ]
all_taxa <- subset(x = all_taxa, select = -SURVEY_SPECIES)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Upload to Oracle
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Assemble column metadata
metadata_column_info <-   
  RODBC::sqlQuery(channel = chl, 
                  query = paste0("SELECT *
                                  FROM GAP_PRODUCTS.METADATA_COLUMN
                                  WHERE METADATA_COLNAME IN ",
                                 gapindex::stitch_entries(names(x = all_taxa))))
names(x = metadata_column_info) <- 
  gsub(x = tolower(x = names(x = metadata_column_info) ),
       pattern = "metadata_", 
       replacement = "")

metadata_column_info <- 
  rbind(data.frame(colname = "GROUP_CODE",
                   colname_long = "SPECIES_CODE or COMPLEX_CODE",
                   units = "ID key code",
                   datatype = "NUMBER(38,0)",
                   colname_desc = "Code that is either associated with an indivdual species code or the complex to which that taxon belongs."),
        metadata_column_info)

## Upload to Oracle
gapindex::upload_oracle(x = all_taxa,
                        table_name = "TAXON_GROUPS", 
                        metadata_column = metadata_column_info, 
                        table_metadata = "This lookup table is based on GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION but with an added field GROUP_CODE to identify species complexes. To be used in the production of the GAP_PRODUCTS tables.", 
                        channel = chl, 
                        schema = "GAP_PRODUCTS", 
                        share_with_all_users = TRUE)

gp_groups <- RODBC::sqlQuery(channel = chl, query = "select * from gap_products.taxon_groups")
akfin_groups <- RODBC::sqlQuery(channel = chl, query = "select * from gap_products.akfin_taxonomic_groups")

nrow(gp_groups)
nrow(akfin_groups)

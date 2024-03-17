##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:     Create Taxonomic Groups Table GAP_PRODUCTS production run   
## Description: 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

library(googledrive)
library(gapindex)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Connect to Oracle using GAP_PRODUCTS credentials
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
chl <- gapindex::get_connected(check_access = F)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Download spreadsheet where the tables currently exist (in the future,
##   these tables will live somewhere in Oracle). 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
data_url <- "https://docs.google.com/spreadsheets/d/1wgAJPPWif1CC01iT2S6ZtoYlhOM0RSGFXS9LUggdLLA/edit#gid=689332364"
data_id <- googledrive::as_id(x = data_url)

data_spreadsheet <- googledrive::drive_download(file = data_id,
                                                path = "temp/data.xlsx", 
                                                overwrite = TRUE)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Extract tables from different sheets in data_spreadsheet
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
GROUPED_TAXA <- 
  subset(x = as.data.frame(readxl::read_excel(path = "temp/data.xlsx", 
                                              sheet = "TAXONOMIC_GROUPING_GP")),
         subset = STAGE == 1)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Create groups for taxa where the minimum ID level on deck is the same
##   as how you would define the taxon. e.g., Bryozoans, Polychaetes. These
##   are the taxa with a STAGE == 1 in the GROUPED_TAXA df. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df <- data.frame()

for (irow in 1:nrow(x = GROUPED_TAXA)) {
  temp_grab <- 
    RODBC::sqlQuery(channel = chl,
                    query = paste0("SELECT *
                                    FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                                    WHERE SURVEY_SPECIES = 1 AND ", 
                                   GROUPED_TAXA$LOWEST_TAXONOMIC_ID[irow],
                                   "_TAXON = '",
                                   GROUPED_TAXA$LOWEST_TAXONOMIC_NAME[irow], 
                                   "'"))
  
  temp_grab$GROUP_CODE <- GROUPED_TAXA$SPECIES_CODE[irow]
  grouped_taxa_df <- rbind(grouped_taxa_df, temp_grab)
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Separate sea pens from Octocorallia 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df$GROUP_CODE[grouped_taxa_df$SUPERFAMILY_TAXON == 'Pennatuloidea'] <- 42000

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Separate basket stars from brittle stars
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df$GROUP_CODE[grouped_taxa_df$SUBORDER_TAXON == "Euryalina"] <- 83020

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Separate echiuroid worm unid. from Polychaeta
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df$GROUP_CODE[grouped_taxa_df$SUBCLASS_TAXON == "Echiura"] <- 94500

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all SPECIES_ records for all fishes except for Myctophids and
##   Lycodapus
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fish_taxa <-
  RODBC::sqlQuery(channel = chl,
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1
                           AND SUBPHYLUM_TAXON = 'Vertebrata'
                           AND NOT (FAMILY_TAXON = 'Myctophidae' 
                                    OR GENUS_TAXON = 'Lycodapus')")
fish_taxa$GROUP_CODE = fish_taxa$SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Group Myctophids and Lycodapus spp. to genus
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fish_genera <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

JOIN 

(SELECT SPECIES_CODE AS GROUP_CODE, SPECIES_NAME, COMMON_NAME, GENUS_TAXON
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
WHERE SURVEY_SPECIES = 1 
AND (FAMILY_TAXON = 'Myctophidae' OR GENUS_TAXON = 'Lycodapus')
AND ID_RANK = 'genus')

USING (GENUS_TAXON)

WHERE SURVEY_SPECIES = 1
ORDER BY GROUP_CODE")[, names(x = fish_taxa)]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all squid records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
squids <- 
  RODBC::sqlQuery(channel = chl,
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1
                           AND SUPERORDER_TAXON = 'Decapodiformes'")  
squids$GROUP_CODE <- squids$SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all hermit crab records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hermit_crabs <-
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1
                           AND SUPERFAMILY_TAXON = 'Paguroidea'")
hermit_crabs$GROUP_CODE <- hermit_crabs$SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all true crab records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Extract true crabs minus the commercial ones
true_crabs <-
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1
                           AND INFRAORDER_TAXON = 'Brachyura'")  
true_crabs$GROUP_CODE <- true_crabs$SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all sand dollar records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sand_dollars <-
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1
                           AND SUPERORDER_TAXON = 'Gnathostomata'")
sand_dollars$GROUP_CODE <- sand_dollars$SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query all sea star records
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sea_stars <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1
                           AND CLASS_TAXON = 'Asteroidea'")
sea_stars$GROUP_CODE <- sea_stars$SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Aggregate taxa to genus for: sea urchins, bivalves, octopuses, and shrimps
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
genera_taxa <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION

JOIN 

(SELECT SPECIES_CODE AS GROUP_CODE, COMMON_NAME, GENUS_TAXON
FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
WHERE SURVEY_SPECIES = 1 
AND (CLASS_TAXON IN('Echinoidea', 'Bivalvia') 
    OR INFRAORDER_TAXON = 'Caridea' 
    OR ORDER_TAXON = 'Octopoda')
AND ID_RANK = 'genus')


USING (GENUS_TAXON)

WHERE SURVEY_SPECIES = 1

ORDER BY GROUP_CODE;")[, names(x = fish_taxa)]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query snail records that are Class Gastropoda except for nudibranchs 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
snails <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
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
ORDER BY GROUP_CODE")[, names(x = fish_taxa)]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Query stony coral records minus cup corals
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stony_corals <- 
  RODBC::sqlQuery(channel = chl, 
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
ORDER BY GROUP_CODE")[, names(x = fish_taxa)]

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  Query all records from GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
##  except for certain commercial crabs that SAP are responsible for. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_spp_codes <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION
                           WHERE SURVEY_SPECIES = 1
                           -- REMOVE CERTAIN COMMERCIAL CRABS FOR SAP
                           AND SPECIES_CODE NOT IN (69323, 69322, 68580, 68560, 68590)
                  ")

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##  rbind all taxa gorups together and merge taxonomic information 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_taxa <- rbind(grouped_taxa_df, fish_taxa, fish_genera, squids, hermit_crabs, 
                  true_crabs, sand_dollars, sea_stars, snails, stony_corals, 
                  genera_taxa)
all_taxa <- merge(x = all_spp_codes,
                  all.x = TRUE,
                  y = all_taxa[, c("SPECIES_CODE", "GROUP_CODE")],
                  by = "SPECIES_CODE")
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
                           WHERE YEAR_CHANGED = 2024
                           AND OLD_SPECIES_CODE != NEW_SPECIES_CODE
                  ")

## attach updated taxonomic information to the old species codes
taxon_changes <- merge(x = taxon_changes, by.x = "NEW_SPECIES_CODE",
                       y = all_taxa, by.y = "SPECIES_CODE")
taxon_changes <- taxon_changes[!is.na(x = taxon_changes$GROUP_CODE), 
                               names(x = all_taxa)]

all_taxa <- rbind(subset(x = all_taxa, 
                         subset = !(SPECIES_CODE %in% 
                                      taxon_changes$SPECIES_CODE)),
                  taxon_changes)

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

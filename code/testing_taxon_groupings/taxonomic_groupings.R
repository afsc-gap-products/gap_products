##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:     DRAFT--taxonomic groupings for production run
## Author:        
## Description: Create the taxon groupings for major invertebrate taxa 
##              Currently, this leaves out shrimps, stony corals, sea urchins,
##              bivalves, octopuses, and snails, misc. groups like fish eggs,
##              shab, empty shells.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

library(googledrive)
library(gapindex)

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
                                              sheet = "TAXONOMIC_GROUPING_RB")),
         subset = stage == 1)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Stage One: Grouped taxa where the minimum ID level on deck is the same
##   as how you would define the taxon. e.g., Bryozoans, Polychaetes. THese
##   are the taxa with a stage == 1 in the GROUPED_TAXA df. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
grouped_taxa_df <- data.frame()

for (irow in 1:nrow(x = GROUPED_TAXA)) {
  temp_grab <- 
    RODBC::sqlQuery(channel = chl,
                    query = paste0("SELECT *
                                    FROM RACEBASE.SPECIES_CLASSIFICATION 
                                    WHERE ", 
                                   GROUPED_TAXA$LOWEST_TAXONOMIC_ID[irow],
                                   "_TAXON = '",
                                   GROUPED_TAXA$LOWEST_TAXONOMIC_NAME[irow], 
                                   "'"))
  
  temp_grab$GROUP_CODE <- GROUPED_TAXA$SPECIES_CODE[irow]
  grouped_taxa_df <- rbind(grouped_taxa_df, temp_grab)
}


## Separate sea pens from Octocorallia 
grouped_taxa_df$GROUP_CODE[grouped_taxa_df$SUPERFAMILY_TAXON == 'Pennatuloidea'] <- 42000
## Separate basket stars from brittle stars
grouped_taxa_df$GROUP_CODE[grouped_taxa_df$SUBORDER_TAXON == "Euryalina"] <- 83020

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Stage Two: All fish species_codes and invertebrates where the minimum
##   ID standard on deck is to species. First, fish.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Extract all vertebrates from RACEBASE.SPECIES_CLASSIFICATION
fish_taxa <-
  RODBC::sqlQuery(channel = chl,
                  query = "SELECT *
                           FROM RACEBASE.SPECIES_CLASSIFICATION 
                           WHERE SUBPHYLUM_TAXON = 'Vertebrata'")
fish_taxa$GROUP_CODE = fish_taxa$SPECIES_CODE

# Remove Myctophids
fish_taxa <- subset(fish_taxa,
                    subset = FAMILY_TAXON != "Myctophidae" | is.na(x = FAMILY_TAXON))

## Separate Lycodapus eelpouts and group into Lycodapus sp. (24230), then
## remove from fish_taxa
lycodapus <- subset(x = fish_taxa, 
                    subset = GENUS_TAXON == "Lycodapus")
lycodapus$GROUP_CODE <- 24230
fish_taxa <- subset(fish_taxa,
                    subset = GENUS_TAXON != "Lycodapus" | is.na(x = GENUS_TAXON))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Then, invertebrates.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Extract all squids
squids <- 
  RODBC::sqlQuery(channel = chl,
                  query = "SELECT *
                           FROM RACEBASE.SPECIES_CLASSIFICATION
                           WHERE SUPERORDER_TAXON = 'Decapodiformes'")  
squids$GROUP_CODE <- squids$SPECIES_CODE

## Extract hermit crabs
hermit_crabs <-
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM RACEBASE.SPECIES_CLASSIFICATION 
                           WHERE FAMILY_TAXON = 'Paguridae'")
hermit_crabs$GROUP_CODE <- hermit_crabs$SPECIES_CODE

## Extract true crabs minus the commercial ones
true_crabs <-
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM RACEBASE.SPECIES_CLASSIFICATION 
                           WHERE INFRAORDER_TAXON = 'Brachyura'
                           AND GENUS_TAXON != 'Chionoecetes'")  
true_crabs$GROUP_CODE <- true_crabs$SPECIES_CODE

## Extract sand dollar SPECIES_CODEs
sand_dollars <-
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM RACEBASE.SPECIES_CLASSIFICATION 
                           WHERE SUPERORDER_TAXON = 'Gnathostomata'")
sand_dollars$GROUP_CODE <- sand_dollars$SPECIES_CODE

## Extract sea star SPECIES_CODEs
sea_stars <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM RACEBASE.SPECIES_CLASSIFICATION 
                           WHERE CLASS_TAXON = 'Asteroidea'")
sea_stars$GROUP_CODE <- sea_stars$SPECIES_CODE

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##   Which SPECIES_CODEs in RACEBASE.SPECIES_CLASSIFICATION belong to a 
##   GROUP_CODE (i.e., either in a complex or presented individually) and which
##   SPECIES_CODEs are left out for now. 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all_spp_codes <- 
  RODBC::sqlQuery(channel = chl, 
                  query = "SELECT *
                           FROM RACEBASE.SPECIES_CLASSIFICATION")

all_taxa <- rbind(grouped_taxa_df, fish_taxa, lycodapus, squids, hermit_crabs, 
                  true_crabs, sand_dollars, sea_stars)
all_taxa <- merge(x = all_spp_codes,
                  all.x = TRUE,
                  y = all_taxa[, c("SPECIES_CODE", "GROUP_CODE")],
                  by = "SPECIES_CODE")
all_taxa <- 
  all_taxa[, names(all_taxa)[c(ncol(x = all_taxa), 1:(ncol(x = all_taxa) - 1))]]

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
                        table_metadata = "This lookup table is a copy of RACEBASE.SPECIES_CLASSIFICATION but with an added field GROUP_CODE to identify species complexes. To be used in the production of the GAP_PRODUCTS tables.", 
                        channel = chl, 
                        schema = "GAP_PRODUCTS", 
                        share_with_all_users = TRUE)

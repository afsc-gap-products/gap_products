##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Project:     DRAFT--taxonomic groupings for production run
## Author:        
## Description: 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Restart R Session before running
rm(list = ls())

library(googledrive)
library(gapindex)

chl <- gapindex::get_connected()

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
                                              sheet = "TAXONOMIC_GROUPING")),
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
                                    FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                    WHERE SURVEY_SPECIES = 1 AND ", 
                                    GROUPED_TAXA$LOWEST_TAXONOMIC_ID[irow],
                                   "_TAXON = '", GROUPED_TAXA$LOWEST_TAXONOMIC_NAME[irow], "'"))
  
  temp_grab$GROUP <- GROUPED_TAXA$SPECIES_CODE[irow]
  grouped_taxa_df <- rbind(grouped_taxa_df, temp_grab)
}


## Separate sea pens from Octocorallia 
grouped_taxa_df$GROUP[grouped_taxa_df$SUPERFAMILY_TAXON == 'Pennatuloidea'] <- 42000
## Seprate Echiura from Polychaetes
grouped_taxa_df$GROUP[grouped_taxa_df$SUBCLASS_TAXON == 'Echiura'] <- 94500
## Separate basket stars from brittle stars
grouped_taxa_df$GROUP[grouped_taxa_df$ORDER_TAXON == "Euryalida"] <- 83020

## Extract all vertebrates 
fish_taxa <-
  RODBC::sqlQuery(channel = chl,
                  query = paste0("SELECT *
                                FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                WHERE SURVEY_SPECIES = 1 AND SUBPHYLUM_TAXON = 'Vertebrata' 
                                   "))
fish_taxa$GROUP = fish_taxa$SPECIES_CODE

# Remove Lycodes and myctophids
fish_taxa <- subset(fish_taxa,
                    subset = GENUS_TAXON != 'Lycodes')
fish_taxa <- subset(fish_taxa,
                    subset = FAMILY_TAXON != "Myctophidae")

lycodes <-
  RODBC::sqlQuery(channel = chl,
                  query = paste0("SELECT *
                                FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                WHERE SURVEY_SPECIES = 1 AND GENUS_TAXON = 'Lycodes'"))    
lycodes$GROUP = 24180

# myctophids <-
#   RODBC::sqlQuery(channel = chl,
#                   query = paste0("SELECT *
#                                 FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
#                                 WHERE SURVEY_SPECIES = 1 AND FAMILY_TAXON = 'Myctophidae'"))    

## Extract all squids
squids <- 
  RODBC::sqlQuery(channel = chl,
                  query = paste0("SELECT *
                                FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                WHERE SURVEY_SPECIES = 1 AND SUPERORDER_TAXON = 'Decapodiformes'"))  
squids$GROUP <- squids$SPECIES_CODE

## Extract hermit crabs minus the commercial ones
hermit_crabs <-
  RODBC::sqlQuery(channel = chl, 
                  query = paste0("SELECT *
                                 FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                 WHERE SURVEY_SPECIES = 1 AND SUPERFAMILY_TAXON = 'Paguroidea' 
                                 AND GENUS_TAXON != 'Paralithodes'"))  
hermit_crabs$GROUP <- hermit_crabs$SPECIES_CODE

## Extract true crabs minus the commercial ones
true_crabs <-
  RODBC::sqlQuery(channel = chl, 
                  query = paste0("SELECT *
                                 FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                 WHERE SURVEY_SPECIES = 1 AND Infraorder_TAXON = 'Brachyura'
                                 AND GENUS_TAXON != 'Chionoecetes'"))  
true_crabs$GROUP <- true_crabs$SPECIES_CODE

sand_dollars <-
  RODBC::sqlQuery(channel = chl, 
                  query = paste0("SELECT *
                                 FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                 WHERE SURVEY_SPECIES = 1 AND order_TAXON = 'Echinolampadacea'"))
sand_dollars$GROUP <- sand_dollars$SPECIES_CODE

sea_stars <- 
  RODBC::sqlQuery(channel = chl, 
                  query = paste0("SELECT *
                                 FROM GAP_PRODUCTS.TAXONOMIC_CLASSIFICATION 
                                 WHERE SURVEY_SPECIES = 1 AND CLASS_TAXON = 'Asteroidea'"))
sea_stars$GROUP <- sea_stars$SPECIES_CODE

nrow(rbind(grouped_taxa_df, fish_taxa, lycodes, squids, hermit_crabs, 
           true_crabs, sand_dollars, sea_stars))

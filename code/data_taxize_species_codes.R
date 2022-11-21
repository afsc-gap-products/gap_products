#' -----------------------------------------------------------------------------
#' title: Create public data 
#' author: EH Markowitz
#' start date: 2022-04-01
#' Notes: 
#' -----------------------------------------------------------------------------

# Functions --------------------------------------------------------------------

library(taxize)


find_taxize <- function(dat,
                      known = NULL, 
                      db0 = "itis") {
  
  dat1 <- data.frame(dat, 
                     id = NA, 
                     notes = paste0(db0, " species ID was not defined."))
  
  if (is.null(known)) {
    known <- list(0, "")
  }
  
  for (i in 1:nrow(dat1)){
    print(i)
    
    # does this scientific name occur (matching exactly) anywhere else in the scientific_name column? Where?
    # I suspect that this will help save time in processing
    double_listings <- which(dat1$scientific_name == dat1$scientific_name[i])
    
    if (dat1$scientific_name[i]!="" & # if there is a scientific name
        is.na(dat1$id[i])) { # if there isn't a ID already listed there
      
        if (dat1$scientific_name[i] %in% names(lapply(X = known,"[", 1))) { # if already known
          
        dat1$id[double_listings] <- lapply(X = known,"[", 1)[names(lapply(X = known,"[", 1)) %in% dat1$scientific_name[i]][[1]]
        dat1$notes[double_listings] <- paste0(
          "ID defined by user", 
          ifelse(lapply(X = known,"[", 2)[names(lapply(X = known,"[", 1)) %in% 
                                            dat1$scientific_name[i]][[1]]=="", "", ": "),
          lapply(X = known,"[", 2)[names(lapply(X = known,"[", 1)) %in% dat1$scientific_name[i]][[1]] )
      } else { # if we don't already know
        id_indata <- taxize::classification(sci_id = dat1$scientific_name[i], db = db0)
        a <- lapply(X = id_indata,"[", 3)[[1]]
        
        if (sum(unlist(!is.na(a[1])))>0) { # A taxon was successfully identified
          
          a <- a$id[nrow(a)]
          
          dat1$id[double_listings] <- a
          dat1$notes[double_listings] <- paste0("Species ID was defined directly by ", db0, ". ",
                                               ifelse(test = nrow(id_indata) == 1, 
                                                      yes = " This species name is likely invalid.", 
                                                      no = ""))
        } else { # A taxon was NOT successfully identified
          
          # if this is a species (if there are two words, the first word is the genus) use the genus to define this entry instead. 
          if (grepl(pattern = " ", x = dat1$scientific_name[i], fixed = TRUE)) {
            
            genus_name <- strsplit(x = dat1$scientific_name[i], split = " ", fixed = TRUE)[[1]][1]
            
            if (genus_name %in% names(lapply(X = known,"[", 1))) { # if already known
              
              print("Genus defined by user.")
              
              dat1$id[double_listings] <- lapply(X = known,"[", 1)[names(lapply(X = known,"[", 1)) %in% genus_name][[1]]
              dat1$notes[double_listings] <- paste0(
                "Species was not defined directly by ", db0, 
                ", so genus was used to define the species. ID defined by user", 
                ifelse(lapply(X = known,"[", 2)[names(lapply(X = known,"[", 1)) %in% 
                                                  genus_name][[1]]=="", "", ": "),
                lapply(X = known,"[", 2)[names(lapply(X = known,"[", 1)) %in% genus_name][[1]] )
            } else {
            
            id_indata <- taxize::classification(sci_id = genus_name,
                                                db = db0)
            a <- lapply(X = id_indata,"[", 3)[[1]] 
            
            if (sum(unlist(!is.na(a[1])))>0) { #(!is.na(a[1])) { # A genus was successfully identified
              print("Genus defined by database.")
              
              a <- a$id[nrow(a)]
              
              dat1$id[double_listings] <- a
              dat1$notes[double_listings] <- paste0("Species was not defined directly by ", db0, 
                                                    ", but ",db0," was able to use genus to define the entry. ",
                                                    ifelse(test = nrow(id_indata) == 1, 
                                                           yes = " This species name is likely invalid.", 
                                                           no = ""))
            } else { # there is nothing more to do or test - the genus couldnt be found. 
              dat1$id[double_listings] <- NA
              dat1$notes[double_listings] <- "Species was not found in the database or defined by user."
            }
            }
          } else { # there is nothing more to do or test - the species couldnt be found. 
          dat1$id[double_listings] <- NA
          dat1$notes[double_listings] <- "Species was not found in the database or defined by user."
          }
        }
      }
    }
  }
  
  still_missing <- 
    data.frame(dat1[is.na(dat1[,"id"]), ]) %>% 
    dplyr::select(-species_name, -common_name, -species_code) %>% 
    dplyr::distinct() %>% 
    dplyr::arrange(scientific_name, notes)
  
  names(dat1)[names(dat1) == "id"] <- db0
  names(dat1)[names(dat1) == "notes"] <- paste0("notes_", db0)
  
  return(list("spp_info" = dat1, 
              "still_missing" = still_missing ) )
  
}

# Load Data --------------------------------------------------------------------

## Oracle Data -----------------------------------------------------------------
a <- list.files(path = here::here("data", "oracle"), pattern = "species")
for (i in 1:length(a)){
  print(a[i])
  b <- readr::read_csv(file = paste0(here::here("data", "oracle", a[i]))) %>% 
    janitor::clean_names(.)
  if (names(b)[1] %in% "x1"){
    b$x1<-NULL
  }
  assign(x = gsub(pattern = "\\.csv", replacement = "", x = paste0(a[i], "0")), value = b) # 0 at the end of the name indicates that it is the orig unmodified file
}

# Wrangle ----------------------------------------------------------------------

spp_info0 <- species0 %>% 
  dplyr::select(species_code, common_name, species_name) %>% # ,
  # dplyr::filter(species_name == "Careproctus sp. cf. gilberti (Orr)") %>%
  dplyr::rename(scientific_name = species_name) %>%
  dplyr::mutate( 
    
    # fix rouge spaces in species names
    common_name = ifelse(is.na(common_name), "", common_name), 
    common_name = gsub(pattern = "  ", replacement = " ", 
                       x = trimws(common_name), fixed = TRUE), 
    scientific_name = ifelse(is.na(scientific_name), "", scientific_name), 
    scientific_name = gsub(pattern = "  ", replacement = " ", 
                           x = trimws(scientific_name), fixed = TRUE), 
    
    scientific_name1 = scientific_name, 
    scientific_name1 = gsub(pattern = "\\s*\\([^\\)]+\\)", # remove parentheses and anything within
                            replacement = "", 
                            x = scientific_name1), 
    scientific_name1 = gsub(pattern = "[0-9]+", # remove all numbers
                            replacement = "", 
                            x = scientific_name1), 
    scientific_name1 = ifelse(is.na(scientific_name1), "", scientific_name1), 
    scientific_name1 = gsub(pattern = "  ", replacement = " ", 
                           x = trimws(scientific_name1), fixed = TRUE) 
    )


remove0 <- c(" sp.", " spp.", 
             " cf.", " n.", 
             " larvae", " egg case", " eggs", " egg")
for (i in 1:length(remove0)) {
  spp_info0$scientific_name1 <- 
    gsub(pattern = remove0[i], 
         replacement = "", 
         x = spp_info0$scientific_name1, 
         fixed = TRUE)
}

remove0 <- paste0(" ", c(LETTERS))
for (i in 1:length(remove0)) {
  spp_info0 <- spp_info0 %>% 
    dplyr::mutate(scientific_name1 = 
                    ifelse(substr(x = scientific_name1, 
                                  start = (nchar(scientific_name1)-1), 
                                  stop = nchar(scientific_name1)) == remove0[i], 
                           substr(x = scientific_name1, 
                                  start = 1, 
                                  stop = (nchar(scientific_name1)-1)), 
                           scientific_name1))
}

spp_info0 <- spp_info0 %>% 
  dplyr::mutate(
    scientific_name1 = ifelse(is.na(scientific_name1), "", scientific_name1), 
    scientific_name1 = gsub(pattern = "  ", replacement = " ", 
                            x = trimws(scientific_name1), fixed = TRUE) ) %>% 
  dplyr::arrange(scientific_name1)

# Create data ------------------------------------------------------------------

known_tsn <- list( # will have to check these each year
  # ITIS returned more than one option
  'Anthozoa' = c(51938, "ITIS returned more than one option."),
  'Aplidium' = c(159038, "ITIS returned more than one option."),
  'Ascidian' = c(158854, "ITIS returned more than one option."), 
  'Astyris' = c(205062, "ITIS returned more than one option."),
  'Chondrichthyes' = c(159785, "ITIS returned more than one option."), 
  'Cnemidocarpa finmarkiensis' = c(159253, "ITIS returned more than one option."), 
  "Colus" = c(73892, "ITIS returned more than one option."), 
  "Cranopsis" = c(566965, "ITIS returned more than one option."),
  "Ctenophora" = c(118845, "ITIS returned more than one option."), 
  'Cucumaria' = c(158191, "ITIS returned more than one option."), 
  'gastropod' = c(69459, "ITIS returned more than one option."),
  'Halichondria panicea' = c(48396, "ITIS returned more than one option."),
  "Hippolytidae" = c(1173151, "ITIS returned more than one option."), 
  "Hirudinea" = c(69290, "ITIS returned more than one option. Could also be 914192, but all options were invalid."), 
  "Hyas" = c(98421, "ITIS returned more than one option."), 
  "Musculus" = c(79472, "ITIS returned more than one option."), 
  "Polychaeta" = c(64358, "ITIS returned more than one option."), 
  'Psolus squamatus' = c(1081156, "ITIS returned more than one option."), 
  'Lepidopsetta' = c(172879, "ITIS returned more than one option."),
  'Lepidozona' = c(78909, "ITIS returned more than one option."),
  'Liparidae' = c(555701, "ITIS returned more than one option."), 
  'Liparis' = c(167550, "ITIS returned more than one option."), 
  "Lumpenus fabricii" = c(631020, "ITIS returned more than one option."), 
  'Suberites ficus' = c(48488, "ITIS returned more than one option."), 
  "Scorpaenichthys marmoratus" = c(692068, "ITIS returned more than one option."), 
  'Tellina modesta' = c(81086, "ITIS returned more than one option."),
  'Serpula' = c(68243, "ITIS returned more than one option."),
  'Weberella' = c(659295, "ITIS returned more than one option."),

  # '' = c(, "ITIS returned more than one option."), 
  # '' = c(, "ITIS returned more than one option."), 
  
  "Admete virdula" = c(205086, "Code for Admete viridula (Fabricius, 1780) (slight misspelling)"), 
  "Alaskagorgia aleutiana" = c(NA, "Not available in ITIS."), 
  "Argentiformes" = c(553133, "Used code for Osmeriformes, as this is likely what this name is refering to."),
  "Artemisina arcigera" = c(204017, "Used code for Artemisina arciger (Schmidt, 1870) (similar (synonym) spelling)."),
  # 'Astronebris tatafilius' = c(NA, "Not available in ITIS."), 
  'Astronebris tatafilius' = c(NA, "Not available in ITIS."),
  'Esperiopsis flagrum' = c(48280, "Worms unaccepted 233110. Used code for Abyssocladia (Levi, 1964)."), 
  'Chionoecetes hybrid' = c(98427, "Code for Chionoecetes (Krøyer, 1838) because this is a AFSC custom name."), 
  "Chlamys pseudoislandica" = c(79625, "Code for Chlamys pseudislandica  MacNeil, 1967 (old name)"),
  'Ciliatoclinocardium ciliatum' = c(NA, "Could not find in WoRMS or ITIS."), 
  "Colus datuzenbergii" = c(656335, "Used code for Colus verkruezeni (Kobelt, 1876) (old name)"), 
  "Colus oceandromae" = c(74038, "Plicifusus oceanodromae  Dall, 1919 (new name)."), 
  "Colossendeis dofleini" = c(1138931, "Hedgpethia dofleini (Loman, 1911) (new name)."), 
  'Compsomyax subdiaphanus' = c(81450, "Compsomyax subdiaphana (Carpenter, 1864) (similar spelling)."), 
  'Grandicrepidula grandis' = c(72621, 'Used code for Crepidula grandis (old name)'),
  'Glebocarcinus oregonensis' = c(98677, "Cancer oregonensis (Dana, 1852) (possible old name?)."), 
  'Grandicrepidula grandis' = c(72621, 'Used code for Crepidula grandis (old name)'),
  "Halipteris finmarchia" = c(719237,"Possible similar name Halipteris finmarchica (Sars, 1851)"), 
  # 'Metacarcinus gracilis' = c(NA, "Cancer gracilis (Dana, 1852) (old name)."), 
  # 'Metacarcinus magister' = c(98675, "Cancer magister (Dana, 1852)."), 
  'Neoiphinoe coronata' = c(72601, "Used code for Trichotropis coronata (old name)"), 
  "Neoiphinoe kroyeri" = c(72602, "Code for Trichotropis kroyeri (old name)"),
  # 'Neomenia efgamatoi' = c(205397, "Couldn't find in ITIS or WoRMS, so used Neomenia genus."), 
  "Nipponotrophon stuarti" = c(73274, "Code for Trophonopsis stuarti (E. A. Smith, 1880) (old name)"), 
  "Olivella beatica" = c(74229, "Olivella baetica (Carpenter, 1864) (similar spelling)."), 
  "Peltodoris lentiginosa" = c(78186, "Anisodoris lentiginosa (Millen, 1982) (old name)."), 
  'Retifusus roseus' = c(72621, "Crepidula grandis (Middendorff, 1849) (old name)"),
  'Laqueus vancouverensis' = c(156850, "Laqueus vancouveriensis (Davidson, 1887) (possibly misspelled). ITIS code 156851 (invalid), so using Laqueus californianus (Koch in Chemnitz, 1848) ITIS code 156850"), 
  # "Limneria prolongata" = c(72722, ""), 
  "Leukoma staminea" = c(NA, "Not available in ITIS."),
  'Liocyma fluctosa' = c(81452, "Liocyma fluctuosum (Gould, 1841) (similar spelling)."), 
  'Ophiura sarsii' = c(157424, "Ophiura sarsi (Lütken, 1855) (Similar spelling)"),
  "Scabrotrophon rossicus" = c(655972, "Used code for Scabrotrophon rossica  (Egorov, 1993) (similar spelling)"), 
  'Selachii' = c(NA, "Couldn't find what this was refering to."),
  "Tochuina gigantea" = c(78486, "Used code for Tochuina tetraquetra  (Pallas, 1788) (old name)."), 
  "Torellivelutina ammonia" = c(72591, "Code for Torellia ammonia (old name)"), 
  
  
  "Psolus" = c(1077949, "ITIS returned more than one option."), 
  "Porella" = c(156418, "ITIS returned more than one option."), 
  "Polychaete" = c(64358, "ITIS returned more than one option."), 
  "Pectinaria" = c(67706, "ITIS returned more than one option."), 
  "Mallotus" = c(162034, "ITIS returned more than one option."), 
  "Echiura" = c(914211, "ITIS returned more than one option."), 
  "Echinacea" = c(157891, "ITIS returned more than one option."), 
  'Cyanea' = c(51669, "ITIS returned more than one option."), 
  "Caryophylliidae" = c(571698, "ITIS returned more than one option."), 
  "Parophrys vetulus X Platichthys stellatus hybrid" = c(NA, "AFSC defined species."), 
  "Platichthys stellatus X Pleuronectes quadrituberculatus hybrid" = c(NA, "AFSC defined species."), 
  
   "Rhynocrangon sharpi" = c(1187507, "ITIS returned more than one option.")
  # "Labidochirusendescens" = c(NA, "Not available in ITIS or WoRMS, though may be a misspelling of something like 'Labidochirus endescens'."), 
  # "Myriapora subgracilis" = c(156608, "Typo: Used code for Leieschara subgracilis (d'Orbigny, 1852), new name for Myriapora subgracilis (d'Orbigny, 1853)."), 


#    "Calliostoma titanium" = c(NA, ""), 
#   "Otukaia beringensis" = c(NA, ""), 
#    "Oligomeria conoidea" = c(NA, ""), 
#   "Ancistrolepis bicinctus" = c(NA, ""), 
#    "Arctomelonstearnsii" = c(NA, ""), 
#   "Neadmete circumcenta" = c(NA, ""), 
#    "Chlamysunalaskae" = c(NA, ""), 
#   "Cyclopecten uschakovi" = c(NA, ""), 
#    "Cyclopectenbenthalis" = c(NA, ""), 
#   "Propeleda conceptionis" = c(NA, ""), 
#    "Clavularia incrustans" = c(NA, ""), 
#   "Buccinum transliratum" = c(NA, ""), 
#    "Marginoproctus djakonovi" = c(NA, ""), 
#   "Ptilocrinus pinnatus" = c(NA, ""), 
#    "Florometra inexpectata" = c(NA, ""), 
#   "Psathyrometra profundorum" = c(NA, ""), 
#    "Fariometra" = c(NA, ""), 
#   "Gorgonocephalusarcticus" = c(NA, ""), 
#    "Astrophyton pardalis" = c(NA, ""), 
#   "Ophiura luetkenii" = c(NA, ""), 
#    "Ophiophthalmus normani" = c(NA, ""), 
#   "Buccinum triplostephanum" = c(NA, ""), 
#    "Parastenella" = c(NA, ""), 
#   "Plumarella superba" = c(NA, ""), 
#    "Thouarella cristata" = c(NA, ""), 
#   "Primnoa wingi" = c(NA, ""), 
#    "Heteropolypus" = c(NA, ""), 
#   "Chrysopathesciosa" = c(NA, ""), 
#    "Calcigorgiaculifera" = c(NA, ""), 
#    "Mycale bellabellensis" = c(NA, ""), 
#   "Histodermella kagigunensis" = c(NA, ""), 
#    "Tedania kagalaskai" = c(NA, ""), 
#   "Mycale carlilei" = c(NA, ""), 
#    "Polymastia pachymastia" = c(NA, ""), 
#   "Halocynthia hispidus" = c(NA, ""), 
#    "Calinaticina oldroyi" = c(NA, ""), 
#   "Poraniopsis flexilius" = c(NA, ""), 
#    "Pseudarchaster pussillus" = c(NA, ""), 
#   "Decapodiform" = c(NA, ""), 
#    "Plumarella nuttingi" = c(NA, ""), 
#   "Tripoplax trifida" = c(NA, ""), 
#    "Tripoplax abyssicola" = c(NA, ""), 
#   "Neptunea middendorffii" = c(NA, ""), 
#    "Neomeniayamamoti" = c(NA, ""), 
#   "Stenosemus sharpii" = c(NA, ""), 
#    "Dirona pellucida" = c(NA, ""), 
#   "Thieleella baxteri" = c(NA, ""), 
#    "Amphissa colmbiana" = c(NA, ""), 
#   "Alia gausapata" = c(NA, ""), 
#    "Astyris elegens" = c(NA, ""), 
#   "Onchidiopsis brevipes" = c(NA, ""), 
#    "Onchidiopsis clarki" = c(NA, ""), 
#   "Neptunea alexeyevi" = c(NA, ""), 
#    "Rectiplanes" = c(NA, ""), 
#   "Epitoneum indianorum" = c(NA, ""), 
#    "Neoiphinoe permabilis" = c(NA, ""), 
#   "Torellia lineata" = c(NA, ""), 
#    "Polychaete tubes" = c(NA, ""), 
#   "Florometra acririma" = c(NA, ""), 
#    "Beringraja binoculata" = c(NA, ""), 
#   "Urticina coriacea" = c(NA, ""), 
#    "Tripoplax beringiana" = c(NA, ""), 
#   "Buccinum moarchianum" = c(NA, ""), 
#    "Leptasterias truculenta" = c(NA, ""), 
#   "Henricia aleutica" = c(NA, ""), 
#    "Leptasterias katharinae" = c(NA, ""), 
#   "Solasterctabilis" = c(NA, ""), 
#    "Bothrocarabrunneum group" = c(NA, ""), 
#   "Bathyrajanosissima" = c(NA, ""), 
#    "Ophiophthalmus cataleimmoidus" = c(NA, ""), 
#   "Ophiacantharhachophora" = c(NA, ""), 
#    "Ophiosphalmajolliensis" = c(NA, ""), 
#   "Ophiosemnotes pachybactra" = c(NA, ""), 
#    "Ophiosemnotes brevispina" = c(NA, ""), 
#   "Ophiosemnotes tylota" = c(NA, ""), 
#    "Psolus" = c(NA, ""), 
#   "Cerebratulus californienesis" = c(NA, ""), 
#    "Myriapora orientalis" = c(NA, ""), 
#   "Hippoporina insculpta" = c(NA, ""), 
#    "Amaroucium soldatovi" = c(NA, ""), 
#   "Bathyraja panthera" = c(NA, ""), 
#    "Allocareproctus kallaion" = c(NA, ""), 
#   "Allocareproctus ungak" = c(NA, ""), 
#    "Allocareproctus unangas" = c(NA, ""), 
#   "Paraliparispectoralis" = c(NA, ""), 
#    "Careproctus faunus" = c(NA, ""), 
#   "Paraliparis penicillus" = c(NA, ""), 
#    "Paraliparisdactylosus" = c(NA, ""), 
#   "Paraliparisulochir" = c(NA, ""), 
#    "Paraliparisgrandis" = c(NA, ""), 
#   "Paraliparis adustus" = c(NA, ""), 
#    "Paraliparis bullacephalus" = c(NA, ""), 
#   "Sebastes melanostictus" = c(NA, ""), 
#    "Lillipathes lilliei" = c(NA, ""), 
#   "Lillipathes" = c(NA, ""), 
#   "Alaskagorgia" = c(NA, ""), 
#    "Paragorgia nodosa" = c(NA, ""), 
#   "Cryogorgia koolsae" = c(NA, ""), 
#    "Echinacea" = c(NA, ""), 
#   "Psolus" = c(NA, ""), 
#    "Echiura" = c(NA, ""), 
#   "Sasakiopus salebrosus" = c(NA, ""), 
#    "Careproctus lerikimae" = c(NA, ""), 
#   "Stylaroides plumosa" = c(NA, ""), 
#    "Arthrogorgia otsukai" = c(NA, ""), 
#   "Arthrogorgia kinoshitai" = c(NA, ""), 
#    "Serpula columbiana" = c(NA, ""), 
#   "Serpula" = c(NA, ""), 
#    "Anuropus bathypelagica" = c(NA, ""), 
#   "Pandalopsislamelligera" = c(NA, ""), 
#    "Gadus chalcogrammus larva" = c(NA, ""), 
#   "Stylaster repandus" = c(NA, ""), 
#    "Pseudosuberites montiniger" = c(NA, ""), 
#   "Heterochone tenera" = c(NA, ""), 
#   "Crella brunnea" = c(NA, ""), 
#   "Polymastia fluegeli" = c(NA, ""), 
#   "Oscarella lobularis" = c(NA, ""), 
#   "Stylocordyla eous" = c(NA, ""), 
#   "Plakina tanaga" = c(NA, ""), 
#   "Latrunculia oparinae" = c(NA, ""), 
#   "Cornulum clathriata" = c(NA, ""), 
#   "Chondrocladia concrescens" = c(NA, ""), 
#   "Aulosaccus schulzei" = c(NA, ""), 
#   "Farrea beringiana" = c(NA, ""), 
#   "Craniella craniana" = c(NA, ""), 
#   "Craniellanosa" = c(NA, ""), 
#   "Craniellatnika" = c(NA, ""), 
#   "Craniella sigmoancoratum" = c(NA, ""), 
#   "Cyclocardiaborealis" = c(NA, ""), 
#   "Heterochone calyx" = c(NA, ""), 
#   "Amphilectus lobatus" = c(NA, ""), 
#   "Weberella bursa" = c(NA, ""), 
#   "Tedania dirhaphis" = c(NA, ""), 
#   "Caryophylliidae" = c(NA, ""), 
#   "Aforia kinkaidi" = c(NA, ""), 
#   "Buccinum costatum" = c(NA, ""), 
#   "Clinopegma unicum" = c(NA, ""), 
#   "Lycodes beringi" = c(NA, ""), 
#   "Errinopora disticha" = c(NA, ""), 
#   "Eusergestes similis" = c(NA, ""), 
#   "Porifera erect" = c(NA, ""), 
#   "Porifera encrusting" = c(NA, ""), 
#   "Porifera ball" = c(NA, ""), 
#   "Porifera tubular" = c(NA, ""), 
#   "Poromitra cristiceps" = c(NA, ""), 
#   "Neptunea gyroscopoides" = c(NA, ""), 
#   "Marginoproctus" = c(NA, ""), 
#   "Rectiplanes" = c(NA, ""), 
#   "Ciona savignyi" = c(NA, ""), 
#   "Buccinum ectomycina" = c(NA, ""), 
#   "Plumarella echinata" = c(NA, ""), 
#   "Alaskagorgia" = c(NA, ""), 
#   "Asbestopluma ramosa" = c(NA, ""), 
#   "Plumarella aleutiana" = c(NA, ""), 
#   "Umbellula lindahli" = c(NA, ""), 
#   "Haliclona primitiva" = c(NA, ""), 
#   "Cladocroce infundibulum" = c(NA, ""), 
#   "Thouarella trilineata" = c(NA, ""), 
#   "Liparis bathyarcticus" = c(NA, ""), 
#   "Arctomelon ryosukei" = c(NA, ""), 
#   "Elassodiscus nyctereutes" = c(NA, ""), 
#   "Onchidiopsis carnea" = c(NA, ""), 
#   "Buccinum obsoletum" = c(NA, ""), 
#   "Suberites montalbidus" = c(NA, ""), 
#   "Plumarella hapala" = c(NA, ""), 
#   "Artemisina amlia" = c(NA, ""), 
#   "Aplidium" = c(NA, ""), 
#   "Myriapora" = c(NA, ""), 
#   "Neptunea meridionalis" = c(NA, ""), 
#   "Haliclona bucina" = c(NA, ""), 
#   "Japelion aleutica" = c(NA, ""), 
#   "Gastropteron pacifica" = c(NA, ""), 
#   "Plumarellacata" = c(NA, ""), 
#   "Stylaster leptostylus" = c(NA, ""), 
#   "Melonanchora globogilva" = c(NA, ""), 
#   "Gersemia lambi" = c(NA, ""), 
#   "Careproctusmelanurus" = c(NA, ""), 
#   "Stelodoryx jamesorri" = c(NA, ""), 
#   "Stelodoryx strongyloxeata" = c(NA, ""), 
#   "Boltenia ecinata" = c(NA, ""), 
#   "Solaster arcticus" = c(NA, ""), 
#   "Onchidiopsis maculata" = c(NA, ""), 
#   "Isidella tentaculum" = c(NA, ""), 
#   "Staurostoma mertensii" = c(NA, ""), 
#   "Stylaster parageus" = c(NA, ""), 
#   "Errinopora fisheri" = c(NA, ""), 
#   "Errinopora dichotoma" = c(NA, ""), 
#   "Stylaster crassiseptum" = c(NA, ""), 
#   "Stylaster trachystomus" = c(NA, ""), 
#   "Cavernularia vansyoci" = c(NA, ""), 
#   "Leucandra tuba" = c(NA, ""), 
#   "Plakina atka" = c(NA, ""), 
#   "Haliclona digitata" = c(NA, ""), 
#   "Artemisina arcigera" = c(NA, ""), 
#   "Monanchora alaskensis" = c(NA, ""), 
#   "Calcigorgia beringi" = c(NA, ""), 
#   "Porella" = c(NA, ""), 
#   "Chrysopathes" = c(NA, ""), 
#   "Monanchora laminachela" = c(NA, ""), 
#   "Careproctus nelsoni" = c(NA, ""), 
#   "Cladocroce kiska" = c(NA, ""), 
#   "Sebastes diaconus" = c(NA, ""), 
#   "Bathyraja panthera" = c(NA, ""), 
#   "Bathyraja mariposa" = c(NA, ""), 
#   "Pectinaria" = c(NA, ""), 
#   "Neoiphinoe echinata" = c(NA, ""), 
#   "Argentiformes" = c(NA, ""), 
#   "Halichondria oblonga" = c(NA, ""), 
#   "Myxilla pedunculata" = c(NA, ""), 
#   "Latrunculia velera" = c(NA, ""), 
#   "Plumarella robusta" = c(NA, ""), 
#   "Ophiopholis japonica" = c(NA, ""), 
#   "Ophiopholis kennerleyi" = c(NA, ""), 
#   "Ancorina buldira" = c(NA, ""), 
#   # '' = c(NA, ""),
#   # '' = c(NA, ""),
#   # '' = c(NA, ""),
#   # '' = c(NA, ""),
#   # '' = c(NA, ""),
)


known_worms <- list( # will have to check these each year
  "Neptunea neptunea" = c(NA, 
                          "Did not find this species in WoRMS"),
  "Neptunea vermii" = c(NA, 
                        "Did not find this species in WoRMS"), 
  "Alcyonidium" = c(110993, "WoRMS returned more than one option."),
  "Alcyonium" = c(125284, "WoRMS returned more than one option."),
  'Anonyx nugax' = c(102514, "WoRMS returned more than one option."), 
  "Ascidian" = c(562518, "WoRMS returned more than one option."), # selected Ascidianibacter ?
  'Axinella' = c(131774, "WoRMS returned more than one option."), 
  'Axinella rugosa' = c(132491, "WoRMS returned more than one option."), 
  'Beroe' = c(1434803, "WoRMS returned more than one option."), 
  'Buccinum costatum' = c(1023579, "WoRMS returned more than one option."), # unaccepted
  'Buccinum obsoletum' = c(877185, "WoRMS returned more than one option."), 
  'Buccinum scalariforme' = c(138875, "WoRMS returned more than one option."), 
  'Calliostoma canaliculatum' = c(467171, "WoRMS returned more than one option."), 
  'Careproctus gilberti' = c(367288, "WoRMS returned more than one option."), 
  'Chaetopterus' = c(129229, "WoRMS returned more than one option."), 
  'Chlamys' = c(138315, "WoRMS returned more than one option."), 
  'Chrysaora' = c(135261, "WoRMS returned more than one option."), 
  'Clavularia' = c(125286, "WoRMS returned more than one option."), # could also be 602367
  'Ctenophora' = c(1248, "WoRMS returned more than one option."), # could also be 163921
  'Flabellina' = c(138019, "WoRMS returned more than one option."), 
  'Gadus' = c(125732, "WoRMS returned more than one option."), 
  'gastropod' = c(101, "WoRMS returned more than one option."), # Gastropoda  Cuvier, 1795
  'Geodia mesotriaena' = c(134035, "WoRMS returned more than one option."), 
  'Glycera' = c(129296, "WoRMS returned more than one option."), 
  'Gonostomatidae' = c(125601, "WoRMS returned more than one option."),  
  'Haliclona digitata' = c(184508, "WoRMS returned more than one option."), 
  'Henricia sanguinolenta' = c(123974, "WoRMS returned more than one option."), 
  'Heteropora' = c(248342, "WoRMS returned more than one option."), 
  'Hiatella' = c(138068, "WoRMS returned more than one option."), 
  'Hippodiplosia' = c(146979, "WoRMS returned more than one option."), # not accepted
  'Liparis' = c(126160, "WoRMS returned more than one option."), 
  'Lumpenus fabricii' = c(127073 , "WoRMS returned more than one option."),  
  'Lycodes concolor' = c(367289, "WoRMS returned more than one option."), 
  'Molpadia' = c(123540, "WoRMS returned more than one option."),  
  'Musculus' = c(138225, "WoRMS returned more than one option."), 
  'Myxicola infundibulum' = c(130932, "WoRMS returned more than one option."),  
  'Natica russa' = c(749499, "WoRMS returned more than one option."), # 254470 Natica russa Gould, 1859 unaccepted/749499 Natica russa  Dall, 1874 unaccepted
  'Nucula tenuis' = c(152323, "WoRMS returned more than one option."),  # 1 152989             Nucula tenuis  Philippi, 1836 unaccepted/607396             Nucula tenuis (Montagu, 1808) unaccepted/152323             Nucula tenuis  (Powell, 1927) unaccepted
  'Pagurus setosus' = c(366787, "WoRMS returned more than one option."), 
  'Pandalopsis' = c(107044, "WoRMS returned more than one option."), # now Pandalus Leach, 1814 [in Leach, 1813-1815]
  'Pectinaria' = c(129437, "WoRMS returned more than one option."), 
  'Platichthys' = c(126119, "WoRMS returned more than one option."), 
  'Polymastia pacifica' = c(170653, "WoRMS returned more than one option."), 
  'Polyorchis' = c(267759, "WoRMS returned more than one option."), 
  'Psolidae' = c(123189, "WoRMS returned more than one option."), 
  'Psolus peroni' = c(529651, "WoRMS returned more than one option."), 
  'Rectiplanes' = c(432545, "WoRMS returned more than one option."), # accepted now as Antiplanes Dall, 1902 432398
  'Scorpaenichthys marmoratus' = c(282726, "WoRMS returned more than one option."), 
  'Serpula vermicularis' = c(131051, "WoRMS returned more than one option."), 
  'Stylatula elongata' = c(286695, "WoRMS returned more than one option."), 
  'Themisto' = c(101800, "WoRMS returned more than one option."), 
  'Vulcanella' = c(170325, "WoRMS returned more than one option."), # could also be 602186
  'Yoldia hyperborea' = c(141989, "WoRMS returned more than one option."), 
  "Iphinoe" = 110391, 
  # '' = c(, "WoRMS returned more than one option."), 
  # '' = c(, "WoRMS returned more than one option."), 
  # '' = c(, "WoRMS returned more than one option."), 
  # '' = c(, "WoRMS returned more than one option."), 
  # '' = c(, "WoRMS returned more than one option."), 
  # '' = c(, "WoRMS returned more than one option."), 
  # '' = c(, "WoRMS returned more than one option."), 
  'Buccinum ectomycina' = c(NA, "WoRMS could not find."), 
  'Esperiopsis flagrum' = c(864174, "Worms unaccepted 233110. Used code for Abyssocladia flagrum (Lehnert, Stone & Heimler, 2006).")
  
  # "" = c(NA, 
  #        ""), 
)

# Run function -----------------------------------------------------------------

# ITIS
rnge <- 1:nrow(spp_info0) # rnge <- 329:350
spp_info00 <- find_taxize(dat = data.frame(species_name = spp_info0$scientific_name[rnge], 
                                       scientific_name = spp_info0$scientific_name1[rnge], 
                                       common_name = spp_info0$common_name[rnge],
                                       species_code = spp_info0$species_code[rnge]), 
                      known = known_tsn,
                      db0 = "itis")

still_missing_itis <- spp_info00$still_missing 
still_missing_itis

spp_info <- spp_info00$spp_info
# taxize::classification(
#   sci_id = "Sicyonis",
#   db = "itis")



# WoRMS
rnge <- 1:nrow(spp_info0) # rnge <- 329:350
spp_info00 <- find_taxize(dat = data.frame(species_name = spp_info0$scientific_name[rnge], 
                                           scientific_name = spp_info0$scientific_name1[rnge], 
                                           common_name = spp_info0$common_name[rnge],
                                           species_code = spp_info0$species_code[rnge]), 
                          known = known_worms,
                          db0 = "worms")

still_missing_worms <- spp_info00$still_missing 
still_missing_worms

spp_info <- dplyr::full_join(x = spp_info, 
                             y = spp_info00$spp_info, 
                             by = c("species_name", "scientific_name", "common_name", "species_code"))
# taxize::classification(
#   sci_id = "Sicyonis",
#   db = "itis")

save(spp_info, file = "./data/spp_info.rdata")
readr::write_csv(x = spp_info, file = "./data/spp_info.csv")


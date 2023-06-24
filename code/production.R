# For table metadata

temp <- paste0(metadata_sentence_survey_institution, " ",
               metadata_sentence_legal_restrict, " ",
               metadata_sentence_github, " ",
               metadata_sentence_codebook, " ",
               metadata_sentence_last_updated)

NEW_CPUE_comment <- paste0("Zero-filled haul-level catch per unit effort (units in kg/km2).", 
                           temp)
BIOMASS_comment <- paste0("Stratum/subarea/management area/region-level mean/variance CPUE (weight and numbers), total biomass (with variance), total abundance (with variance). The 'AREA_ID' field replaces the 'STRATUM' field name to generalize the description to include different types of areas (strata, subareas, regulatory areas, regions, etc.). Use the GAP_PRODUCTS.AREA table to look up the values of AREA_ID for your particular region. Note confidence intervals are currently not supported in the GAP_PRODUCTS version of the biomass/abundance tables. The associated variance of estimates will suffice as the metric of variability to use.", 
                          temp)
AGECOMP_comment <- paste0("Stratum/subarea/management area/region-level abundance by sex/length bin. Sex-specific columns (i.e., MALES, FEMALES, UNSEXED), previously formatted in historical versions of this table, are melted into a single column (called 'SEX') similar to the AGECOMP tables with values 1/2/3 for M/F/U. The 'AREA_ID' field replaces the 'STRATUM' field name to generalize the description to include different types of areas (strata, subareas, regulatory areas, regions, etc.). Use the GAP_PRODUCTS.AREA table to look up the values of AREA_ID for your particular region. ", 
                          temp)
SIZECOMP_comment <- paste0("Region-level abundance by sex/age. ", 
                           temp)
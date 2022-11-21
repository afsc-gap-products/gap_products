#' -----------------------------------------------------------------------------
#' title: Create biomass and abundance estimates
#' author: EH Markowitz
#' start date: 2022-01-01
#' Notes: 
#' -----------------------------------------------------------------------------

# *** Calculate Biomass and CPUE -----------------------------------------------------------
cpue_biomass_station <- tidyr::crossing(
  haul_cruises_vess %>%
    dplyr::filter(SRVY %in% c("NBS", "EBS")),
  dplyr::distinct(
    catch_haul_cruises %>%
      dplyr::filter(SRVY %in% c("NBS", "EBS"))  %>%
      dplyr::left_join(
        x = .,
        y = spp_info %>% 
          # dplyr::mutate(group = species_name) %>% 
          dplyr::select(species_code, group, species_name, species_name1, print_name, taxon),
        by = "species_code"),
    species_code, species_name, species_name1, group, print_name, taxon)) %>%
  dplyr::left_join(
    x = .,
    y = catch_haul_cruises %>%
      dplyr::select("cruisejoin", "hauljoin", "cruisejoin", "species_code",
                    "weight", "number_fish", "SRVY"),
    by = c("species_code", "hauljoin", "cruisejoin", "SRVY")) %>%
  #### a check for species with weights greater then 0
  ## sum catch weight (by groups) by station and join to haul table (again) to add on relevent haul data
  dplyr::group_by(year, stationid, SRVY, species_name, species_name1, print_name, taxon, #species_code,
                  group, hauljoin, stratum, distance_fished, net_width) %>%
  dplyr::summarise(wt_kg_summed_by_station = sum(weight, na.rm = TRUE), # overwrite NAs in assign_group_zeros where data exists
                   num_summed_by_station = sum(number_fish, na.rm = TRUE)) %>% # overwrite NAs in
  
  ## checks catch_and_zeros table for species that are not in groups, if species are not grouped
  #### add group to assign_groups table
  ## calculates CPUE for each species group by station
  dplyr::mutate(effort = distance_fished * net_width/10) %>%
  dplyr::mutate(cpue_kgha = wt_kg_summed_by_station/effort) %>%
  dplyr::mutate(cpue_noha = ifelse(wt_kg_summed_by_station > 0 & num_summed_by_station == 0, NA,
                                   (cpue_no = num_summed_by_station/effort))) %>%
  #### this is to check CPUEs by group, station and year against the SQL code
  ## add area to CPUE table
  dplyr::ungroup() %>% 
  dplyr::left_join(x = .,
                   y = stratum_info %>%
                     dplyr::select(stratum, area),
                   by = 'stratum')  %>% 
  dplyr::left_join(x = ., 
                   y = station_info, 
                   by = c("stationid", "SRVY", "stratum")) %>% 
  dplyr::rename(latitude = start_latitude, 
                longitude = start_longitude) %>% 
  dplyr::filter(!is.na(stationid))
#   # total biomass excluding empty shells and debris for each year
#   dplyr::filter(group != 'empty shells and debris')  %>%
#   dplyr::mutate(type = ifelse(
#     grepl(pattern = "@", x = (group), fixed = TRUE),
#     # species_name == paste0(genus_taxon, " ", species_taxon),
#     "ital", NA)) %>%
#   tidyr::separate(group, c("group", "species_name", "extra"), sep = "_") %>%
#   dplyr::select(-extra) %>%
#   dplyr::mutate(species_name = gsub(pattern = "@", replacement = " ",
#                                     x = species_name, fixed = TRUE)) %>% 
#   dplyr::ungroup()

# bb <- dplyr::bind_rows(
#   cpue_biomass_station %>% 
#     dplyr::filter(!species_code %in% c(69323, 69322, 68580, 68560)), 
#   cpue_biomass_station %>% 
#     dplyr::filter(species_code %in% c(69323, 69322, 68580, 68560))
# )


# Include crab data
cpue_biomass_station <- dplyr::bind_rows(
  dplyr::left_join(
    x = cpue_biomass_station %>% 
      dplyr::filter(print_name %in% c("blue king crab", "red king crab", "snow crab")) %>% 
      dplyr::select(-cpue_kgha, -cpue_noha), 
    y = cpue_crab %>% 
      dplyr::mutate(print_name = dplyr::case_when(
        species_code == 69323 ~ "blue king crab", 
        species_code == 69322 ~ "red king crab", 
        species_code == 68580 ~ "snow crab", 
        # species_code == 68560 ~ "Tanner crab", 
      )) %>% 
      dplyr::select(print_name, year, hauljoin, cpue_kgha, cpue_noha), 
    by = c("print_name", "year", "hauljoin")
  ), 
  cpue_biomass_station %>% 
    dplyr::filter(!(print_name %in% c("blue king crab", "red king crab", "snow crab")) ) )


cpue_biomass_stratum <- cpue_biomass_station %>%
  ## calculates mean CPUE (weight) by year, group, stratum, and area
  dplyr::ungroup() %>%
  dplyr::group_by(year, group, species_name, species_name1, print_name, 
                  stratum, area, SRVY, taxon) %>%
  dplyr::summarise(cpue_by_group_stratum = mean(cpue_kgha, na.rm = TRUE)) %>% # TOLEDO - na.rm = T?
  ## creates column for meanCPUE per group/stratum/year*area of stratum
  dplyr::mutate(mean_cpue_times_area = (cpue_by_group_stratum * area)) %>%
  ## calculates sum of mean CPUE*area (over the 3 strata)
  dplyr::ungroup()
# we'll remove crab stuff from here soon

cpue_biomass_total <- cpue_biomass_stratum %>%
  dplyr::group_by(year, group, SRVY, species_name, species_name1, print_name, taxon) %>%
  dplyr::summarise(mean_CPUE_all_strata_times_area =
                     sum(mean_cpue_times_area, na.rm = TRUE)) %>% # TOLEDO - na.rm = T?
  
  # calculates total area by adding up the unique area values (each strata has a different value)
  dplyr::left_join(
    x = ., 
    y = cpue_biomass_station %>% 
      dplyr::ungroup() %>%
      dplyr::select(area, SRVY) %>% 
      dplyr::distinct() %>%
      dplyr::group_by(SRVY) %>% 
      dplyr::summarise(total_area = sum(area, na.rm = TRUE)), 
    by = "SRVY") %>%
  
  ## creates column with weighted CPUEs
  dplyr::mutate(weighted_CPUE = (mean_CPUE_all_strata_times_area / total_area)) %>%
  ### uses WEIGHTED CPUEs to calculate biomass
  ## includes empty shells and debris
  dplyr::group_by(year, group, SRVY, species_name, species_name1, print_name) %>%
  dplyr::mutate(biomass_mt = weighted_CPUE*(total_area*.1)) %>%
  # total biomass excluding empty shells and debris for each year
  dplyr::filter(group != 'empty shells and debris')  %>%
  # dplyr::mutate(type = ifelse(
  #   grepl(pattern = "@", x = (group), fixed = TRUE),
  #   # species_name == paste0(genus_taxon, " ", species_taxon),
  #   "ital", NA)) %>%
  # tidyr::separate(group, c("group", "species_name", "extra"), sep = "_") %>%
  # dplyr::select(-extra) %>%
  # dplyr::mutate(species_name = gsub(pattern = "@", replacement = " ",
  #                                   x = species_name, fixed = TRUE)) %>% 
  dplyr::ungroup()


# Include crab data
cpue_biomass_total <- dplyr::bind_rows(
  dplyr::left_join(
    x = cpue_biomass_total %>% 
      dplyr::filter(print_name %in% c("blue king crab", "red king crab", "snow crab")) %>% 
      dplyr::select(-weighted_CPUE, -biomass_mt, -mean_CPUE_all_strata_times_area), 
    y = biomass_tot_crab %>% 
      dplyr::mutate(print_name = dplyr::case_when(
        species_code == 69323 ~ "blue king crab", 
        species_code == 69322 ~ "red king crab", 
        species_code == 68580 ~ "snow crab", 
        # species_code == 68560 ~ "Tanner crab", 
      )) %>% 
      dplyr::rename(biomass_mt = biomass) %>% 
      dplyr::select(print_name, year, SRVY, biomass_mt), 
    by = c("print_name", "year", "SRVY")
  ), 
  cpue_biomass_total %>% 
    dplyr::filter(!(print_name %in% c("blue king crab", "red king crab", "snow crab"))) )

cpue_biomass_stratum <- cpue_biomass_stratum %>%
  # remove crab stuff because they use diff strata etc
  dplyr::filter(!(print_name %in% c("blue king crab", "red king crab", "snow crab")))


## *** Total Biomass ---------------------------------------------------------------

print("Total Biomass")

calc_cpue_bio <- function(catch_haul_cruises0){
  
  # for tech memo table: calculate biomass for fish and invert taxa in table 7
  # Created by: Rebecca Haehn
  # Contact: rebecca.haehn@noaa.gov
  # Created: 13 January 2022
  # script modifed from biomass script for stock assessments
  # Modified: 
  
  # *** *** fiter to EBS only data by innerjoin (catch and haul) --------------------
  
  ## to test this I filtered for YEAR = 2017 in the haul data, row count matches prebiocatch table in Oracle (after running legacy ebs_plusnw script) **do not run with filter to get match
  ## 
  ## the filter removes empty banacles, empty bivalve/gastropod shell, invert egg unid, unsorted catch and debris, Polychaete tubes, and unsorted shab 
  
  # *** *** create zeros table for CPUE calculation ---------------------------------
  # zeros table so every haul/vessel/year combination includes a row for every species caught (combine)
  
  temp1 <- catch_haul_cruises0 #%>% 
  # dplyr::group_by(year, SRVY, cruisejoin, hauljoin, stationid, stratum, haul, cruise, 
  #                 species_code, distance_fished, net_width) %>% 
  # dplyr::summarise(weight = sum(weight, na.rm = TRUE), 
  #                  number_fish = sum(number_fish, na.rm = TRUE))
  
  if (is.numeric(catch_haul_cruises0$species_code)) {
    temp1 <- temp1 %>%
      dplyr::filter(species_code < 99991)
  }
  
  z <-  temp1 %>% 
    tidyr::complete(species_code, 
                    nesting(SRVY, cruise, haul, #vessel, 
                            year, hauljoin, stratum, stationid, 
                            distance_fished, net_width)) %>%
    dplyr::select(SRVY, cruise, hauljoin, haul, #vessel, 
                  year, species_code, weight, number_fish, stratum, 
                  stationid, distance_fished, net_width) %>%
    tidyr::replace_na(list(weight = 0, number_fish = 0))
  
  
  catch_with_zeros <- 
    dplyr::full_join(x = temp1, 
                     y = z, 
                     by = c("SRVY", "cruise", "hauljoin", "haul", 
                            "year", "species_code", "stratum", "stationid", 
                            "distance_fished", "net_width")) %>%
    dplyr::select(-weight.y, -number_fish.y, -gear_depth, 
                  -duration, -net_height) %>%
    dplyr::arrange(year, haul, species_code) %>%
    dplyr::rename(weight_kg = weight.x, number_fish = number_fish.x) %>%
    tidyr::replace_na(list(weight_kg = 0, number_fish = 0))
  
  # *** *** calculate CPUE (mean CPUE by strata) -------------------------------
  
  cpue_by_stratum <- catch_with_zeros %>%
    dplyr::select(SRVY, species_code, year, stratum, stationid,
                  distance_fished, net_width, weight_kg) %>%
    dplyr::mutate(
      effort = distance_fished * net_width/10,
      cpue_kgha = weight_kg/effort) %>% 
    dplyr::left_join(x = .,
                     y = stratum_info %>%
                       dplyr::select(stratum, area, SRVY),
                     by = c("SRVY", "stratum")) %>%
    dplyr::arrange(stratum, species_code) %>%
    dplyr::group_by(SRVY, species_code, year, stratum, area) %>%
    dplyr::summarise( 
      cpue_kgha_strat = mean(cpue_kgha, na.rm = TRUE), #weight_kg/effort, 
      cpue_kgha_var = ifelse(n() <= 1, 0, var(cpue_kgha)/n()),
      num_hauls = n(),     # num_hauls = ifelse(num == 1, 1, (num-1)),
      total_area = sum(unique(area))) %>%
    dplyr::mutate(strata = dplyr::case_when(
      (stratum == 31 | stratum == 32) ~ 30,
      (stratum == 41 | stratum == 42) | stratum == 43 ~ 40,
      (stratum == 61 | stratum == 62) ~ 60, 
      TRUE ~ as.numeric(stratum)))
  
  
  # *** biomass -----------------------------------------------------------------
  
  # ## CANNOT use biomass_*** tables bc they don't contain the info for all species (ie: no poachers, blennies, lumpsuckers, eelpouts, etc.)
  
  biomass_by_stratum <- biomass_cpue_by_stratum <- cpue_by_stratum %>%
    dplyr::mutate(
      biomass_mt = cpue_kgha_strat * (area * 0.1), 
      bio_var = (area^2 * cpue_kgha_var/100), 
      fi = area * (area - num_hauls)/num_hauls,
      ci = qt(p = 0.025, df = num_hauls - 1, lower.tail = F) * sqrt(bio_var), 
      up_ci_bio = biomass_mt + ci,
      low_ci_bio = ifelse(biomass_mt - ci <0, 0, biomass_mt - ci) )
  
  
  total_biomass <- biomass_by_stratum %>%
    dplyr::filter((species_code >= 40000 &
                     species_code < 99991) |
                    (species_code > 1 & 
                       species_code < 35000)) %>% 
    ungroup() %>%
    dplyr::group_by(SRVY, year) %>% 
    dplyr::summarise(total = sum(biomass_mt, na.rm = TRUE))
  
  return(list("biomass_cpue_by_stratum" = biomass_cpue_by_stratum, 
              "total_biomass" = total_biomass))
  
}

a <- calc_cpue_bio(catch_haul_cruises0 = catch_haul_cruises_maxyr)

biomass_cpue_by_stratum <- cpue_by_stratum <- biomass_by_stratum <- 
  a$biomass_cpue_by_stratum %>%  # remove crab totals, as they use different stratum
  dplyr::filter(!(species_code %in% c(69323, 69322, 68580, 68560)))

# subtract our-calculated crab totals so we can add the right total from SAP
cc <- a$biomass_cpue_by_stratum %>% 
  dplyr::filter((species_code %in% c(69323, 69322, 68580, 68560))) %>%
  ungroup() %>%
  dplyr::group_by(SRVY, year) %>%
  dplyr::summarise(total_crab_wrong = sum(biomass_mt, na.rm = TRUE))

total_biomass <- 
  dplyr::left_join(x = a$total_biomass, 
                   y = cc) %>% 
  dplyr::left_join(x = ., 
                   y = biomass_tot_crab %>% 
                     dplyr::filter(stratum == 999) %>%
                     ungroup() %>%
                     dplyr::group_by(SRVY, year) %>% 
                     dplyr::summarise(total_crab_correct = sum(biomass, na.rm = TRUE))) %>% 
  dplyr::mutate(total = total - total_crab_wrong + total_crab_correct) %>% 
  dplyr::select(-total_crab_wrong, -total_crab_correct)


biomass_abundance_stratum_total <- dplyr::full_join(total_biomass, biomass_cpue_by_stratum)
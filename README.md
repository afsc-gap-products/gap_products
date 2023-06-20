<!-- README.md is generated from README.Rmd. Please edit that file -->

# [AFSC RACE Groundfish Design-Based Data Products](https://github.com/afsc-gap-products/gap_products/) <img src="https://avatars.githubusercontent.com/u/91760178?s=96&amp;v=4" alt="Logo." align="right" width="139" height="139"/>

[![](https://img.shields.io/github/last-commit/afsc-gap-products/gap_public_data.svg)](https://github.com/afsc-gap-products/gap_public_data/commits/main)

## This code is primarally maintained by:

**Zack Oyafuso** (Zack.Oyafuso AT noaa.gov;
[@zoyafuso-NOAA](https://github.com/zoyafuso-NOAA))

**Emily Markowitz** (Emily.Markowitz AT noaa.gov;
[@EmilyMarkowitz-NOAA](https://github.com/EmilyMarkowitz-NOAA))

Alaska Fisheries Science Center (AFSC) National Oceanic and Atmospheric
Administration (NOAA)  
Resource Assessment and Conservation Engineering Division (RACE)  
Groundfish Assessment Program (GAP) 7600 Sand Point Way, N.E. bldg. 4  
Seattle, WA 98115 USA

> The code in this repository is regularly being updated and improved.
> Please refer to
> [releases](https://github.com/afsc-gap-products/gap_products//releases)
> for finalized products and project milestones.

## Table of contents

> - [*Access the data*](#access-the-data)
>   - [*Bottom trawl surveys and
>     regions*](#bottom-trawl-surveys-and-regions)
> - [*Metadata*](#metadata)
>   - [*Data Description*](#data-description)
>   - [*Catch-per-unit-effort*](#catch-per-unit-effort)
>   - [*Biomass*](#biomass)
>   - [*Size Composition*](#size-composition)
>   - [*Age Composition*](#age-composition)
>   - [*Column Metadata*](#column-metadata)
>   - [*User Resources:*](#user-resources:)
>   - [*Access Constraints:*](#access-constraints:)
> - [*Suggestions and comments*](#suggestions-and-comments)
> - [*R Version Metadata*](#r-version-metadata)

# Access the data

Here are a few resources made by our scientists in house and keen
contributors:

- [General
  information](https://github.com/afsc-gap-products/gap_products//index.html)
- [Access public data via the AFSC Oracle Database (AFSC only) using SQL
  and
  R](https://github.com/afsc-gap-products/gap_products//access-afsc-oracle-sql-r.html)
- Access data via the [Interactive FOSS
  Platform](https://afsc-gap-products.github.io/gap_public_data/access-foss.html)
  and
  [documentation](https://afsc-gap-products.github.io/gap_public_data/)

## Bottom trawl surveys and regions

![](C:/Users/emily.markowitz/Work/projects/gap_products/img/survey_plot.png)

- **Aleutian Islands (AI)** (Von Szalay and Raring, 2020)
  - Triennial (1990s)/Biennial since 2000 in even years
  - Modified Index-Stratified Random of Successful Stations Survey
    Design
- **Eastern Bering Sea Slope (BSS)** (Hoff, 2016)
  - Intermittent (funding dependent)
  - Modified Index-Stratified Random of Successful Stations Survey
    Design
- **Eastern Bering Sea Shelf (EBS)** (Markowitz et al., 2023)
  - Annual
  - Fixed stations at center of 20 x 20 nm grid
- **Gulf of Alaska (GOA)** (Von Szalay and Raring, 2018)
  - Triennial (1990s)/Biennial since 2001 in odd years
  - Stratified Random Survey Design
- **Northern Bering Sea (NBS)** (Markowitz et al., 2023)
  - Biennial/Annual
  - Fixed stations at center of 20 x 20 nm grid

# Metadata

<div id="refs" class="references csl-bib-body hanging-indent"
line-spacing="2">

<div id="ref-RN979" class="csl-entry">

Hoff, G. R. (2016). *Results of the 2016 eastern Bering Sea upper
continental slope survey of groundfishes and invertebrate resources*
(NOAA Tech. Memo. NOAA-AFSC-339). U.S. Dep. Commer.
<https://doi.org/10.7289/V5/TM-AFSC-339>

</div>

<div id="ref-2022NEBS2023" class="csl-entry">

Markowitz, E. H., Dawson, E. J., Anderson, A. B., Rohan, S. K.,
Charriere, N. E., Prohaska, B. K., and Stevenson, D. E. (2023). *Results
of the 2022 eastern and northern Bering Sea continental shelf bottom
trawl survey of groundfish and invertebrate fauna* (NOAA Tech. Memo.
NMFS-AFSC-469; p. 213). U.S. Dep. Commer.

</div>

<div id="ref-GOA2018" class="csl-entry">

Von Szalay, P. G., and Raring, N. W. (2018). *Data report: 2017 <span
class="nocase">Gulf of Alaska</span> bottom trawl survey* (NOAA Tech.
Memo. NMFS-AFSC-374). U.S. Dep. Commer.
<https://doi.org/10.7289/V5/TM-AFSC-374>

</div>

<div id="ref-AI2018" class="csl-entry">

Von Szalay, P. G., and Raring, N. W. (2020). *Data report: 2018 Aleutian
Islands bottom trawl survey* (NOAA Tech. Memo. NMFS-AFSC-409). U.S. Dep.
Commer. <https://doi.org/10.25923/qe5v-fz70>

</div>

</div>

## Data Description

The Resource Assessment and Conservation Engineering Division (RACE)
Groundfish Assessment Program (GAP) of the Alaska Fisheries Science
Center (AFSC) conducts fisheries-independent bottom trawl surveys to
monitor the condition of the demersal fish and crab stocks of Alaska.
These data are developed to describe the temporal distribution and
abundance of commercially and ecologically important groundfish species,
examine the changes in the species composition of the fauna over time
and space, and describe the physical environment of the groundfish
habitat.

Users must read and fully comprehend the metadata prior to use. Data
should not be used beyond the limits of the source scale.
Acknowledgement of NOAA, as the source from which these data were
obtained, in any publications and/or other representations of these
data, is suggested. These data are compiled and approved annually after
each summer survey season. The data from previous years are unlikely to
change substantially once published. Some survey data are excluded, such
as non-standard stations, surveys completed in earlier years using
different/non-standard gear, and special tows and non-standard data
collections.

The data calculated in this repo include:

## Catch-per-unit-effort

Zero-filled haul-level catch per unit effort (units in kg/km2).

## Biomass

Stratum/subarea/management area/region-level mean/variance CPUE (weight
and numbers), total biomass (with variance), total abundance (with
variance). The “AREA_ID” field replaces the “STRATUM” field name to
generalize the description to include different types of areas (strata,
subareas, regulatory areas, regions, etc.). Use the GAP_PRODUCTS.AREA
table to look up the values of AREA_ID for your particular region.

Note confidence intervals are currently not supported in the
GAP_PRODUCTS version of the biomass/abundance tables. The associated
variance of estimates will suffice as the metric of variability to use.

## Size Composition

Stratum/subarea/management area/region-level abundance by sex/length
bin. Sex-specific columns (i.e., MALES, FEMALES, UNSEXED), previously
formatted in historical versions of this table, are melted into a single
column (called “SEX”) similar to the AGECOMP tables with values 1/2/3
for M/F/U. The “AREA_ID” field replaces the “STRATUM” field name to
generalize the description to include different types of areas (strata,
subareas, regulatory areas, regions, etc.). Use the GAP_PRODUCTS.AREA
table to look up the values of AREA_ID for your particular region.

## Age Composition

Region-level abundance by sex/age.

## Column Metadata

These tables provide the column metadata for all GAP oracle tables. The
GitHub repository for the scripts that created this code can be found at
<https://github.com/afsc-gap-products/gap_products/>. These reference
tables were last updated on May 25, 2023’. Find these tables
[here](https://github.com/afsc-gap-products/gap_products/tree/main/metadata).

Here are stock metadata that users can use to document their table
columns. Find the `GAP_PRODUCTS.METADATA_COLUMN` and
`GAP_PRODUCTS.METADATA_TABLE` in oracle for the tables above.

## User Resources:

- [Groundfish Assessment Program Bottom Trawl
  Surveys](https://www.fisheries.noaa.gov/alaska/science-data/groundfish-assessment-program-bottom-trawl-surveys)
- [AFSC’s Resource Assessment and Conservation Engineering
  Division](https://www.fisheries.noaa.gov/about/resource-assessment-and-conservation-engineering-division).
- For more information about codes used in the tables, please refer to
  the [survey code
  books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).
- Find [past
  reports](http://apps-afsc.fisheries.noaa.gov/RACE/surveys/cruise_results.htm)
  about these surveys.
- [GitHub
  repository](https://github.com/afsc-gap-products/gap_products/).
- Fisheries One Stop Shop (FOSS): <https://www.fisheries.noaa.gov/foss>
- Learn more about other [Research Surveys conducted at
  AFSC](https://www.fisheries.noaa.gov/alaska/ecosystems/alaska-fish-research-surveys).

## Access Constraints:

There are no legal restrictions on access to the data. They reside in
public domain and can be freely distributed.

**User Constraints:** Users must read and fully comprehend the metadata
prior to use. Data should not be used beyond the limits of the source
scale. Acknowledgement of AFSC Groundfish Assessment Program, as the
source from which these data were obtained, in any publications and/or
other representations of these data, is suggested.

**General questions and more specific data requests** can be sent to
<afsc.gap.metadata@noaa.gov> or submitted as an [issue on our GitHub
Organization](https://github.com/afsc-gap-products/data-requests). The
version of this data used for stock assessments can be found through the
Alaska Fisheries Information Network (AKFIN). For questions about the
eastern Bering Sea surveys, contact Duane Stevenson
(<Duane.Stevenson@noaa.gov>). For questions about the Gulf of Alaska or
Aleutian Islands surveys, contact Ned Laman (<Ned.Laman@noaa.gov>). For
questions specifically about crab data in any region, contact Mike
Litzow (<Mike.Litzow@noaa.gov>), the Shellfish Assessment Program lead.

For questions, comments, and concerns specifically about the [Fisheries
One Stop Shop (FOSS)](https://www.fisheries.noaa.gov/foss) platform,
please contact us using the Comments page on the
[FOSS](https://www.fisheries.noaa.gov/foss) webpage.

# Suggestions and comments

If the data or metadata can be improved, please create a pull request,
[submit an issue to the GitHub
organization](https://github.com/afsc-gap-products/data-requests/issues)
or [submit an issue to the code’s
repository](https://github.com/afsc-gap-products/gap_products//issues).

# R Version Metadata

``` r
sessionInfo()
```

    ## R version 4.3.0 (2023-04-21 ucrt)
    ## Platform: x86_64-w64-mingw32/x64 (64-bit)
    ## Running under: Windows 10 x64 (build 19045)
    ## 
    ## Matrix products: default
    ## 
    ## 
    ## locale:
    ## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
    ## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
    ## 
    ## time zone: America/Los_Angeles
    ## tzcode source: internal
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] akgfmaps_3.0.0    terra_1.7-29      stars_0.6-1       abind_1.4-5       sf_1.0-12         gstat_2.1-1      
    ##  [7] classInt_0.4-9    viridis_0.6.3     viridisLite_0.4.2 knitr_1.42        badger_0.2.3      RODBC_1.3-20     
    ## [13] ggplot2_3.4.2     stringr_1.5.0     here_1.0.1        janitor_2.2.0     readxl_1.4.2      tidyr_1.3.0      
    ## [19] readr_2.1.4       magrittr_2.0.3    googledrive_2.1.0 dplyr_1.1.2       plyr_1.8.8        devtools_2.4.5   
    ## [25] usethis_2.1.6    
    ## 
    ## loaded via a namespace (and not attached):
    ##   [1] RColorBrewer_1.1-3      sys_3.4.1               rstudioapi_0.14         dlstats_0.1.6          
    ##   [5] jsonlite_1.8.4          farver_2.1.1            rmarkdown_2.21          fs_1.6.2               
    ##   [9] ragg_1.2.5              vctrs_0.6.2             memoise_2.0.1           askpass_1.1            
    ##  [13] gh_1.4.0                htmltools_0.5.5         curl_5.0.0              cellranger_1.1.0       
    ##  [17] sass_0.4.6              KernSmooth_2.23-21      bslib_0.4.2             htmlwidgets_1.6.2      
    ##  [21] httr2_0.2.2             zoo_1.8-12              lubridate_1.9.2         cachem_1.0.8           
    ##  [25] uuid_1.1-0              mime_0.12               lifecycle_1.0.3         pkgconfig_2.0.3        
    ##  [29] R6_2.5.1                fastmap_1.1.1           shiny_1.7.4             snakecase_0.11.0       
    ##  [33] digest_0.6.31           colorspace_2.1-0        ps_1.7.5                rprojroot_2.0.3        
    ##  [37] pkgload_1.3.2           textshaping_0.3.6       lwgeom_0.2-11           labeling_0.4.2         
    ##  [41] fansi_1.0.4             timechange_0.2.0        httr_1.4.5              compiler_4.3.0         
    ##  [45] intervals_0.15.3        proxy_0.4-27            gargle_1.4.0            remotes_2.4.2          
    ##  [49] bit64_4.0.5             fontquiver_0.2.1        withr_2.5.0             DBI_1.1.3              
    ##  [53] pkgbuild_1.4.0          highr_0.10              openssl_2.0.6           rappdirs_0.3.3         
    ##  [57] sessioninfo_1.2.2       gfonts_0.2.0            units_0.8-2             tools_4.3.0            
    ##  [61] zip_2.3.0               httpuv_1.6.9            glue_1.6.2              callr_3.7.3            
    ##  [65] promises_1.2.0.1        grid_4.3.0              generics_0.1.3          gtable_0.3.3           
    ##  [69] tzdb_0.3.0              class_7.3-22            data.table_1.14.8       hms_1.1.3              
    ##  [73] sp_1.6-0                xml2_1.3.4              utf8_1.2.3              pillar_1.9.0           
    ##  [77] yulab.utils_0.0.6       vroom_1.6.3             later_1.3.1             lattice_0.21-8         
    ##  [81] FNN_1.1.3.2             bit_4.0.5               tidyselect_1.2.0        rvcheck_0.2.1          
    ##  [85] fontLiberation_0.1.0    miniUI_0.1.1.1          fontBitstreamVera_0.1.1 gitcreds_0.1.2         
    ##  [89] gridExtra_2.3           crul_1.3                xfun_0.39               credentials_1.3.2      
    ##  [93] stringi_1.7.12          yaml_2.3.7              codetools_0.2-19        evaluate_0.20          
    ##  [97] httpcode_0.3.0          officer_0.6.2           gdtools_0.3.3           tibble_3.2.1           
    ## [101] BiocManager_1.30.20     cli_3.6.1               xtable_1.8-4            systemfonts_1.0.4      
    ## [105] munsell_0.5.0           processx_3.8.1          jquerylib_0.1.4         spacetime_1.3-0        
    ## [109] Rcpp_1.0.10             gert_1.9.2              readtext_0.82           parallel_4.3.0         
    ## [113] ellipsis_0.3.2          prettyunits_1.1.1       profvis_0.3.8           urlchecker_1.0.1       
    ## [117] xts_0.13.1              e1071_1.7-13            scales_1.2.1            purrr_1.0.1            
    ## [121] crayon_1.5.2            flextable_0.9.1         rlang_1.1.1

## NOAA README

This repository is a scientific product and is not official
communication of the National Oceanic and Atmospheric Administration, or
the United States Department of Commerce. All NOAA GitHub project code
is provided on an ‘as is’ basis and the user assumes responsibility for
its use. Any claims against the Department of Commerce or Department of
Commerce bureaus stemming from the use of this GitHub project will be
governed by all applicable Federal law. Any reference to specific
commercial products, processes, or services by service mark, trademark,
manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation or favoring by the Department of Commerce.
The Department of Commerce seal and logo, or the seal and logo of a DOC
bureau, shall not be used in any manner to imply endorsement of any
commercial product or activity by DOC or the United States Government.

## NOAA License

Software code created by U.S. Government employees is not subject to
copyright in the United States (17 U.S.C. §105). The United
States/Department of Commerce reserve all rights to seek and obtain
copyright protection in countries other than the United States for
Software authored in its entirety by the Department of Commerce. To this
end, the Department of Commerce hereby grants to Recipient a
royalty-free, nonexclusive license to use, copy, and create derivative
works of the Software outside of the United States.

<img src="https://raw.githubusercontent.com/nmfs-general-modeling-tools/nmfspalette/main/man/figures/noaa-fisheries-rgb-2line-horizontal-small.png" alt="NOAA Fisheries" height="75"/>

[U.S. Department of Commerce](https://www.commerce.gov/) \| [National
Oceanographic and Atmospheric Administration](https://www.noaa.gov) \|
[NOAA Fisheries](https://www.fisheries.noaa.gov/)

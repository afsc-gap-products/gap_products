<!-- README.md is generated from README.Rmd. Please edit that file -->

# [AFSC RACE Groundfish and Shellfish Assessment Program Design-Based Production Data](https://github.com/afsc-gap-products/gap_products) <img src="https://avatars.githubusercontent.com/u/91760178?s=96&amp;v=4" alt="Logo." align="right" width="139" height="139"/>

[![](https://img.shields.io/github/last-commit/afsc-gap-products/gap_products.svg)](https://github.com/afsc-gap-products/gap_products/commits/main)

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
> [releases](https://github.com/afsc-gap-products/gap_products/releases)
> for finalized products and project milestones.

## Table of contents

> - [*User Resources*](#user-resources)
> - [*Cite this data*](#cite-this-data)
>   - [*Bottom trawl surveys and
>     regions*](#bottom-trawl-surveys-and-regions)
>   - [*Access Constraints*](#access-constraints)
> - [*Suggestions and comments*](#suggestions-and-comments)
> - [*R Version Metadata*](#r-version-metadata)

## User Resources

- [GitHub
  repository](https://github.com/afsc-gap-products/gap_products).

- [Access Tips and Documentation for All Production
  Data](https://afsc-gap-products.github.io/gap_products/)

- [Fisheries One Stop Shop (FOSS)](https://www.fisheries.noaa.gov/foss)

- [Groundfish Assessment Program Bottom Trawl
  Surveys](https://www.fisheries.noaa.gov/alaska/science-data/groundfish-assessment-program-bottom-trawl-surveys)

- [AFSC’s Resource Assessment and Conservation Engineering
  Division](https://www.fisheries.noaa.gov/about/resource-assessment-and-conservation-engineering-division)

- [Survey code
  books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual)

- [Publications and Data Reports](https://repository.library.noaa.gov/)

- [Research Surveys conducted at
  AFSC](https://www.fisheries.noaa.gov/alaska/ecosystems/alaska-fish-research-surveys)

# Cite this data

Use the below [bibtext
citations](https://github.com/afsc-gap-products/gap_products/blob/main/CITATION.bib),
as cited in our group’s [citation
repository](https://github.com/afsc-gap-products/citations/blob/main/cite/bibliography.bib)
for citing the data created and maintained in this repo. Add “note =
{Accessed: mm/dd/yyyy}” to append the day this data was accessed.
Included here are AFSC RACE Groundfish and Shellfish Assessment
Program’s:

- Design-Based Production Data (NOAA Fisheries Alaska Fisheries Science
  Center, Goundfish Assessment Program, 2023).  
- Public Data hosted on the Fisheries One Stop Shop (FOSS) Data Platform
  (NOAA Fisheries Alaska Fisheries Science Center, 2023).

<!-- -->

    ## 
    ## @misc{GAPProducts,
    ##   author = {{NOAA Fisheries Alaska Fisheries Science Center, Goundfish Assessment Program}},
    ##   year = {2023}, 
    ##   title = {AFSC Goundfish Assessment Program Design-Based Production Data},
    ##   howpublished = {https://www.fisheries.noaa.gov/alaska/science-data/groundfish-assessment-program-bottom-trawl-surveys},
    ##   publisher = {{U.S. Dep. Commer.}},
    ##   copyright = {Public Domain} 
    ## }
    ## 
    ## @misc{FOSSAFSCData,
    ##   author = {{NOAA Fisheries Alaska Fisheries Science Center}},
    ##   year = {2023}, 
    ##   title = {Fisheries One Stop Shop Public Data: RACE Division Bottom Trawl Survey Data Query},
    ##   howpublished = {https://www.fisheries.noaa.gov/foss},
    ##   publisher = {{U.S. Dep. Commer.}},
    ##   copyright = {Public Domain} 
    ## }

Or cite our latest data reports for survey-specific data and other
findings:

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

<div id="ref-FOSSAFSCData" class="csl-entry">

NOAA Fisheries Alaska Fisheries Science Center. (2023). *Fisheries one
stop shop public data: RACE division bottom trawl survey data query*.
https://www.fisheries.noaa.gov/foss; U.S. Dep. Commer.

</div>

<div id="ref-GAPProducts" class="csl-entry">

NOAA Fisheries Alaska Fisheries Science Center, Goundfish Assessment
Program. (2023). *AFSC goundfish assessment program design-based
production data*.
https://www.fisheries.noaa.gov/alaska/science-data/groundfish-assessment-program-bottom-trawl-surveys;
U.S. Dep. Commer.

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

## Bottom trawl surveys and regions

<img src="../img/survey_plot.png" width="2100" />

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

## Access Constraints

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
repository](https://github.com/afsc-gap-products/gap_products/issues).

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
    ##  [1] akgfmaps_3.0.0        terra_1.7-29          stars_0.6-1           abind_1.4-5           sf_1.0-12            
    ##  [6] gstat_2.1-1           classInt_0.4-9        viridis_0.6.3         viridisLite_0.4.2     ggplot2_3.4.2        
    ## [11] knitr_1.43            badger_0.2.3          kableExtra_1.3.4.9000 RODBC_1.3-20          stringr_1.5.0        
    ## [16] here_1.0.1            janitor_2.2.0         readxl_1.4.2          tidyr_1.3.0           readr_2.1.4          
    ## [21] magrittr_2.0.3        googledrive_2.1.1     dplyr_1.1.2           gapindex_0.0.0.9000   distill_1.5          
    ## [26] devtools_2.4.5        usethis_2.1.6        
    ## 
    ## loaded via a namespace (and not attached):
    ##   [1] RColorBrewer_1.1-3  sys_3.4.2           rstudioapi_0.14     dlstats_0.1.6       jsonlite_1.8.4      farver_2.1.1       
    ##   [7] rmarkdown_2.22      ragg_1.2.5          fs_1.6.2            vctrs_0.6.2         memoise_2.0.1       askpass_1.1        
    ##  [13] gh_1.4.0            webshot_0.5.4       htmltools_0.5.5     curl_5.0.0          cellranger_1.1.0    KernSmooth_2.23-21 
    ##  [19] htmlwidgets_1.6.2   httr2_0.2.2         zoo_1.8-12          lubridate_1.9.2     cachem_1.0.8        mime_0.12          
    ##  [25] lifecycle_1.0.3     pkgconfig_2.0.3     R6_2.5.1            fastmap_1.1.1       shiny_1.7.4         snakecase_0.11.0   
    ##  [31] digest_0.6.31       colorspace_2.1-0    ps_1.7.5            rprojroot_2.0.3     pkgload_1.3.2       textshaping_0.3.6  
    ##  [37] lwgeom_0.2-11       fansi_1.0.4         timechange_0.2.0    httr_1.4.6          compiler_4.3.0      gargle_1.5.1       
    ##  [43] proxy_0.4-27        intervals_0.15.3    remotes_2.4.2       bit64_4.0.5         withr_2.5.0         DBI_1.1.3          
    ##  [49] pkgbuild_1.4.0      highr_0.10          openssl_2.0.6       rappdirs_0.3.3      sessioninfo_1.2.2   units_0.8-2        
    ##  [55] tools_4.3.0         httpuv_1.6.9        glue_1.6.2          callr_3.7.3         promises_1.2.0.1    grid_4.3.0         
    ##  [61] generics_0.1.3      gtable_0.3.3        tzdb_0.3.0          class_7.3-22        data.table_1.14.8   hms_1.1.3          
    ##  [67] sp_1.6-0            xml2_1.3.4          utf8_1.2.3          pillar_1.9.0        yulab.utils_0.0.6   vroom_1.6.3        
    ##  [73] later_1.3.1         lattice_0.21-8      FNN_1.1.3.2         bit_4.0.5           tidyselect_1.2.0    rvcheck_0.2.1      
    ##  [79] miniUI_0.1.1.1      downlit_0.4.2       gitcreds_0.1.2      gridExtra_2.3       svglite_2.1.1       xfun_0.39          
    ##  [85] credentials_1.3.2   stringi_1.7.12      yaml_2.3.7          codetools_0.2-19    evaluate_0.21       tibble_3.2.1       
    ##  [91] BiocManager_1.30.20 cli_3.6.1           xtable_1.8-4        systemfonts_1.0.4   munsell_0.5.0       processx_3.8.1     
    ##  [97] spacetime_1.3-0     Rcpp_1.0.10         gert_1.9.2          png_0.1-8           readtext_0.82       parallel_4.3.0     
    ## [103] ellipsis_0.3.2      prettyunits_1.1.1   profvis_0.3.8       urlchecker_1.0.1    scales_1.2.1        xts_0.13.1         
    ## [109] e1071_1.7-13        purrr_1.0.1         crayon_1.5.2        rlang_1.1.1         rvest_1.0.3

[U.S. Department of Commerce](https://www.commerce.gov/) \| [National
Oceanographic and Atmospheric Administration](https://www.noaa.gov) \|
[NOAA Fisheries](https://www.fisheries.noaa.gov/)

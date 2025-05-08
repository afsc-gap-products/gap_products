# [Basic Design-Based GAP Data Products](https://github.com/afsc-gap-products/gap_products) <img src="https://avatars.githubusercontent.com/u/91760178?s=96&amp;v=4" alt="Logo." align="right" width="139" height="139"/>

The scripts therein reproducibly produce our typical data products.

<!-- README.md is generated from README.Rmd. Please edit that file -->

> This code is always in development. Find code used for various reports
> in the code
> [releases](https://github.com/afsc-gap-products/gap_products/releases).

## This code is primarily maintained by:

**Emily Markowitz** (Emily.Markowitz AT noaa.gov;
[@EmilyMarkowitz-NOAA](https://github.com/EmilyMarkowitz-NOAA))

**Zack Oyafuso** (Zack.Oyafuso AT noaa.gov;
[@zoyafuso-NOAA](https://github.com/zoyafuso-NOAA))

Alaska Fisheries Science Center,

National Marine Fisheries Service,

National Oceanic and Atmospheric Administration,

Seattle, WA 98195

## Table of contents

>   - [*User Resources*](#user-resources)
> - [*Cite this data*](#cite-this-data)
>   - [*Access Constraints*](#access-constraints)
> - [*Relevant publications*](#relevant-publications)
> - [*Suggestions and Comments*](#suggestions-and-comments)
>   - [*R Version Metadata*](#r-version-metadata)
>   - [*NOAA README*](#noaa-readme)
>   - [*NOAA License*](#noaa-license)

## User Resources

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
  Center, Goundfish Assessment Program, 2024).  
- Public Data hosted on the Fisheries One Stop Shop (FOSS) Data Platform
  (NOAA Fisheries Alaska Fisheries Science Center, 2024).

## Access Constraints

There are no legal restrictions on access to the data. They reside in
public domain and can be freely distributed.

**User Constraints:** Users must read and fully comprehend the metadata
prior to use. Data should not be used beyond the limits of the source
scale. Acknowledgement of AFSC Groundfish Assessment Program, as the
source from which these data were obtained, in any publications and/or
other representations of these data, is suggested.

**General questions and more specific data requests** can be sent to
<nmfs.afsc.gap.metadata@noaa.gov> or submitted as an [issue on our
GitHub
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

# Relevant publications

``` r
source("https://raw.githubusercontent.com/afsc-gap-products/citations/main/cite/current_data_tm.r") # srvy_cite 
```

**Learn more about these surveys** ([Hoff, 2016](#ref-RN979); [Markowitz
et al., 2024](#ref-2023NEBS), [2024](#ref-2023NEBS); [Siple et al.,
2024](#ref-GOA2023); [Von Szalay et al., 2023](#ref-AI2022); [Zacher et
al., 2024](#ref-SAPcrab2024)).

<div id="refs" class="references csl-bib-body hanging-indent"
entry-spacing="0" line-spacing="2">

<div id="ref-RN979" class="csl-entry">

Hoff, G. R. (2016). *Results of the 2016 eastern Bering Sea upper
continental slope survey of groundfishes and invertebrate resources*
(NOAA Tech. Memo. NOAA-AFSC-339). U.S. Dep. Commer.
<https://doi.org/10.7289/V5/TM-AFSC-339>

</div>

<div id="ref-2023NEBS" class="csl-entry">

Markowitz, E. H., Dawson, E. J., Wassermann, S., Anderson, C. B., Rohan,
S. K., Charriere, B. K., and Stevenson, D. E. (2024). *Results of the
2023 eastern and northern Bering Sea continental shelf bottom trawl
survey of groundfish and invertebrate fauna* (NOAA Tech. Memo.
NMFS-AFSC-487; p. 242). U.S. Dep. Commer.
<https://doi.org/10.25923/2mry-yx09>

</div>

<div id="ref-GOA2023" class="csl-entry">

Siple, M. C., Szalay, P. G. von, Raring, N. W., Dowlin, A. N., and
Riggle, B. C. (2024). *Data report: 2023 gulf of alaska bottom trawl
survey* (NOAA Tech. Memo. AFSC processed report; 2024-09). U.S. Dep.
Commer. <https://doi.org/10.25923/gbb1-x748>

</div>

<div id="ref-AI2022" class="csl-entry">

Von Szalay, P. G., Raring, N. W., Siple, M. C., Dowlin, A. N., Riggle,
B. C., and Laman, E. A. and. (2023). *Data report: 2022 Aleutian Islands
bottom trawl survey* (AFSC Processed Rep. 2023-07; p. 230). U.S. Dep.
Commer. <https://doi.org/10.25923/85cy-g225>

</div>

<div id="ref-SAPcrab2024" class="csl-entry">

Zacher, L. S., Richar, J. I., Fedewa, E. J., Ryznar, E. R., and Litzow,
M. A. (2024). *The 2024 eastern Bering Sea continental shelf trawl
survey: Results for commercial crab species DRAFT* \[NOAA Tech. Memo.\].
<https://www.fisheries.noaa.gov/resource/document/draft-2024-eastern-bering-sea-crab-technical-memorandum>

</div>

</div>

# Suggestions and Comments

If you see that the data, product, or metadata can be improved, you are
invited to create a [pull
request](https://github.com/afsc-gap-products/gap_products/pulls),
[submit an issue to the GitHub
organization](https://github.com/afsc-gap-products/data-requests/issues),
or [submit an issue to the code’s
repository](https://github.com/afsc-gap-products/gap_products/issues).

## R Version Metadata

``` r
sessionInfo()
```

    ## R version 4.4.3 (2025-02-28 ucrt)
    ## Platform: x86_64-w64-mingw32/x64
    ## Running under: Windows 10 x64 (build 19045)
    ## 
    ## Matrix products: default
    ## 
    ## 
    ## locale:
    ## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8 LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
    ## 
    ## time zone: America/Los_Angeles
    ## tzcode source: internal
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] flextable_0.9.7 akgfmaps_4.0.3  terra_1.8-15    stars_0.6-8     abind_1.4-8     sf_1.0-19       ggplot2_3.5.1   dplyr_1.1.4     jsonlite_1.9.0  httr_1.4.7     
    ## 
    ## loaded via a namespace (and not attached):
    ##   [1] DBI_1.2.3               gridExtra_2.3           remotes_2.5.0           rlang_1.1.5             magrittr_2.0.3          snakecase_0.11.1        ggridges_0.5.6          e1071_1.7-16            compiler_4.4.3          maps_3.4.2.1            systemfonts_1.2.1       vctrs_0.6.5            
    ##  [13] ftExtra_0.6.4           RODBC_1.3-26            stringr_1.5.1           profvis_0.4.0           pkgconfig_2.0.3         fastmap_1.2.0           ellipsis_0.3.2          labeling_0.4.3          promises_1.3.2          rmarkdown_2.29          sessioninfo_1.2.3       ragg_1.3.3             
    ##  [25] purrr_1.0.2             bit_4.5.0.1             xfun_0.50               cachem_1.1.0            blob_1.2.4              later_1.4.1             uuid_1.2-1              parallel_4.4.3          R6_2.6.1                RColorBrewer_1.1-3      stringi_1.8.4           pkgload_1.4.0          
    ##  [37] lubridate_1.9.4         Rcpp_1.0.14             assertthat_0.2.1        knitr_1.49              usethis_3.1.0           zoo_1.8-12              readtext_0.91           FNN_1.1.4.1             httpuv_1.6.15           timechange_0.3.0        tidyselect_1.2.1        viridis_0.6.5          
    ##  [49] rstudioapi_0.17.1       yaml_2.3.10             codetools_0.2-20        miniUI_0.1.1.1          curl_6.2.1              pkgbuild_1.4.6          lattice_0.22-6          tibble_3.2.1            intervals_0.15.5        withr_3.0.2             shiny_1.10.0            askpass_1.2.1          
    ##  [61] evaluate_1.0.3          units_0.8-5             proxy_0.4-27            urlchecker_1.0.1        zip_2.3.1               xts_0.14.1              xml2_1.3.6              pillar_1.10.1           KernSmooth_2.23-26      generics_0.1.3          rprojroot_2.0.4         sp_2.1-4               
    ##  [73] spacetime_1.3-3         hms_1.1.3               munsell_0.5.1           scales_1.3.0            xtable_1.8-4            gapindex_3.0.2          class_7.3-23            glue_1.8.0              odbc_1.6.0              janitor_2.2.1           gdtools_0.4.1           tools_4.4.3            
    ##  [85] data.table_1.16.4       fs_1.6.5                grid_4.4.3              devtools_2.4.5          colorspace_2.1-1        googledrive_2.1.1       cli_3.6.3               gstat_2.1-2             kableExtra_1.4.0        textshaping_1.0.0       officer_0.6.7           fontBitstreamVera_0.1.1
    ##  [97] gargle_1.5.2            viridisLite_0.4.2       svglite_2.1.3           keyring_1.3.2           gtable_0.3.6            digest_0.6.37           fontquiver_0.2.1        classInt_0.4-11         farver_2.1.2            htmlwidgets_1.6.4       memoise_2.0.1           htmltools_0.5.8.1      
    ## [109] lifecycle_1.0.4         here_1.0.1              mime_0.12               fontLiberation_0.1.0    openssl_2.3.1           bit64_4.6.0-1

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

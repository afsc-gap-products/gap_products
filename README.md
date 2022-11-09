<!-- README.md is generated from README.Rmd. Please edit that file -->

# [Basic Design-Based GAP Data Products](https://github.com/EmilyMarkowitz-NOAA/gap_bs_data_report) <img src="https://avatars.githubusercontent.com/u/91760178?s=96&amp;v=4" alt="Logo." align="right" width="139" height="139"/>

The scripts therein reproducibly produce our typical data products.

## This code is primarally maintained by:

**Emily Markowitz** (Emily.Markowitz AT noaa.gov;
[@EmilyMarkowitz-NOAA](https://github.com/EmilyMarkowitz-NOAA))

Alaska Fisheries Science Center,

National Marine Fisheries Service,

National Oceanic and Atmospheric Administration,

Seattle, WA 98195

> This code is always in development. Find code used for various reports
> in the code
> [releases](https://github.com/EmilyMarkowitz-NOAA/gap_bs_data_report/releases).

## This code and the associated releases were used to develop the following reports, outreach documents, and presentations:

<!-- Use .bib file to cite reports in subsection titles -->

**Documentation** **(Other documentation coming soon!)** (Markowitz et
al., In review)

<div id="refs" class="references csl-bib-body hanging-indent"
line-spacing="2">

<div id="ref-2022NEBS2022" class="csl-entry">

Markowitz, E. H., Dawson, E. J., Charriere, N., Prohaska, B., Rohan, S.,
Stevenson, D. E., and Britt, L. L. (In review). *Results of the 2022
eastern and northern Bering Sea continental shelf bottom trawl survey of
groundfish and invertebrate fauna* \[NOAA Tech. Memo.\].

</div>

</div>

## Suggestions and Comments

If you see that the data, product, or metadata can be improved, you are
invited to create a [pull
request](https://github.com/EmilyMarkowitz-NOAA/gap_bs_data_report/pulls),
[submit an issue to the GitHub
organization](https://github.com/afsc-gap-products/data-requests/issues),
or [submit an issue to the code’s
repository](https://github.com/EmilyMarkowitz-NOAA/gap_bs_data_report/issues).

# R Version Metadata

``` r
sessionInfo()
```

    ## R version 4.2.0 (2022-04-22 ucrt)
    ## Platform: x86_64-w64-mingw32/x64 (64-bit)
    ## Running under: Windows 10 x64 (build 19044)
    ## 
    ## Matrix products: default
    ## 
    ## locale:
    ## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8 LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
    ## 
    ## attached base packages:
    ## [1] grid      stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] flextable_0.8.2        officer_0.4.4          reshape_0.8.9          labeling_0.4.2         callr_3.7.2            backports_1.4.1        ps_1.7.2               ggsn_0.5.0             digest_0.6.30         
    ## [10] rosm_0.2.6             rgdal_1.5-32           prettymapr_0.2.4       jsonlite_1.8.3         rlist_0.4.6.2          akgfmaps_2.2.1         stars_0.5-6            abind_1.4-5            shadowtext_0.1.2      
    ## [19] sf_1.0-8               raster_3.6-3           sp_1.5-0               gstat_2.1-0            ggspatial_1.1.6        classInt_0.4-8         readtext_0.81          stringr_1.4.1          tidyr_1.2.1           
    ## [28] readr_2.1.3            magrittr_2.0.3         googledrive_2.0.0      dplyr_1.0.10           plyr_1.8.7             viridis_0.6.2          viridisLite_0.4.1      nmfspalette_0.0.0.9000 png_0.1-7             
    ## [37] ggplot2_3.3.6          devtools_2.4.5         usethis_2.1.6          rmarkdown_2.17         knitr_1.40             RODBC_1.3-19          
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] colorspace_2.0-3    rjson_0.2.21        ellipsis_0.3.2      class_7.3-20        ggridges_0.5.4      snakecase_0.11.0    base64enc_0.1-3     fs_1.5.2            rstudioapi_0.14     proxy_0.4-27       
    ## [11] remotes_2.4.2       bit64_4.0.5         fansi_1.0.3         lubridate_1.8.0     xml2_1.3.3          codetools_0.2-18    cachem_1.0.6        pkgload_1.3.1       NMFSReports_0.0.1.3 shiny_1.7.3        
    ## [21] compiler_4.2.0      httr_1.4.4          assertthat_0.2.1    fastmap_1.1.0       gargle_1.2.1        cli_3.4.1           later_1.3.0         htmltools_0.5.3     prettyunits_1.1.1   tools_4.2.0        
    ## [31] ggmap_3.0.0         gtable_0.3.1        glue_1.6.2          Rcpp_1.0.9          vctrs_0.5.0         lwgeom_0.2-9        xfun_0.34           mime_0.12           miniUI_0.1.1.1      lifecycle_1.0.3    
    ## [41] terra_1.6-17        zoo_1.8-11          scales_1.2.1        vroom_1.6.0         hms_1.1.2           promises_1.2.0.1    parallel_4.2.0      yaml_2.3.6          memoise_2.0.1       gridExtra_2.3      
    ## [51] gdtools_0.2.4       stringi_1.7.8       maptools_1.1-5      e1071_1.7-12        pkgbuild_1.3.1      zip_2.2.2           systemfonts_1.0.4   intervals_0.15.2    RgoogleMaps_1.4.5.3 rlang_1.0.6        
    ## [61] pkgconfig_2.0.3     bitops_1.0-7        evaluate_0.17       lattice_0.20-45     purrr_0.3.5         htmlwidgets_1.5.4   bit_4.0.4           tidyselect_1.2.0    processx_3.8.0      R6_2.5.1           
    ## [71] generics_0.1.3      profvis_0.3.7       DBI_1.1.3           pillar_1.8.1        foreign_0.8-83      withr_2.5.0         xts_0.12.2          units_0.8-0         spacetime_1.2-8     tibble_3.1.8       
    ## [81] janitor_2.1.0       crayon_1.5.2        uuid_1.1-0          KernSmooth_2.23-20  utf8_1.2.2          tzdb_0.3.0          urlchecker_1.0.1    jpeg_0.1-9          data.table_1.14.4   FNN_1.1.3.1        
    ## [91] xtable_1.8-4        httpuv_1.6.6        munsell_0.5.0       sessioninfo_1.2.2

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

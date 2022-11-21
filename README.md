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

**Documentation** **(Other documentation coming soon!)**

<div id="refs">

</div>

# Access data via Oracle (AFSC-only)

If you have access to the AFSC Oracle data base, you can pull the data
directly from the Oracle schema these data are pulled from for FOSS.

You will need to install the `RODBC` R package and have OFIS (IT)
connect R to Oracle. Once connected, you can use the following code in R
to connect to Oracle.

``` r
library("RODBC")

channel<-odbcConnect(dsn = "AFSC",
                     uid = "USERS_USERNAME", # change
                     pwd = "USERS_PASSWORD", # change
                     believeNRows = FALSE)

odbcGetInfo(channel)
```

Then, you can pull and save (if you need) the table into your R
environment.

``` r
# pull table from oracle into R environment
a <- RODBC::sqlQuery(channel, "SELECT * FROM FAP_PRODUCTS.FOSS_CPUE_ZEROFILLED")
# Save table to local directory
write.csv(x = a, 
          file = "RACEBASE_FOSS-FOSS_CPUE_ZEROFILLED.csv")
```

This is presence and absence data. This is a huge file and has all of
the bells and whistles. For reference:

    ## RACEBASE_FOSS.FOSS_CPUE_ZEROFILLED: 
    ##   rows: 36440900
    ##   cols: 37
    ##   4.513 GB

If you only want to pull a small subset of the data (especially since
files like `RACEBASE_FOSS.FOSS_CPUE_ZEROFILLED` are so big), you can use
a variation of the following code. Here, we are pulling EBS Pacific cod
from 2010 - 2021:

``` r
# Pull data
a <- RODBC::sqlQuery(channel, "SELECT * FROM RACEBASE_FOSS.FOSS_CPUE_ZEROFILLED 
WHERE SRVY = 'EBS' 
AND COMMON_NAME = 'Pacific cod' 
AND YEAR >= 2010 
AND YEAR < 2021")

# Save table to local directory
write.csv(x = a, 
          file = "RACEBASE_FOSS-FOSS_CPUE_ZEROFILLED-ebs_pcod_2010-2020.csv")
```

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

    ## R version 4.2.1 (2022-06-23 ucrt)
    ## Platform: x86_64-w64-mingw32/x64 (64-bit)
    ## Running under: Windows 10 x64 (build 19044)
    ## 
    ## Matrix products: default
    ## 
    ## locale:
    ## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8
    ## [4] LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ## [1] RODBC_1.3-19   stringr_1.4.1  tidyr_1.2.1    readr_2.1.2    magrittr_2.0.3 dplyr_1.0.10   plyr_1.8.7     devtools_2.4.4 usethis_2.1.6 
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] Rcpp_1.0.9        lubridate_1.8.0   here_1.0.1        prettyunits_1.1.1 ps_1.7.1          assertthat_0.2.1  rprojroot_2.0.3   digest_0.6.29    
    ##  [9] utf8_1.2.2        mime_0.12         cellranger_1.1.0  R6_2.5.1          evaluate_0.16     pillar_1.8.1      rlang_1.0.6       readxl_1.4.1     
    ## [17] rstudioapi_0.14   miniUI_0.1.1.1    callr_3.7.2       urlchecker_1.0.1  rmarkdown_2.16    htmlwidgets_1.5.4 bit_4.0.4         shiny_1.7.2      
    ## [25] compiler_4.2.1    httpuv_1.6.6      janitor_2.1.0     xfun_0.33         pkgconfig_2.0.3   pkgbuild_1.3.1    htmltools_0.5.3   tidyselect_1.1.2 
    ## [33] tibble_3.1.8      fansi_1.0.3       withr_2.5.0       crayon_1.5.1      tzdb_0.3.0        later_1.3.0       xtable_1.8-4      lifecycle_1.0.2  
    ## [41] DBI_1.1.3         cli_3.4.1         stringi_1.7.8     vroom_1.5.7       cachem_1.0.6      fs_1.5.2          promises_1.2.0.1  remotes_2.4.2    
    ## [49] snakecase_0.11.0  ellipsis_0.3.2    generics_0.1.3    vctrs_0.4.1       tools_4.2.1       bit64_4.0.5       glue_1.6.2        purrr_0.3.4      
    ## [57] hms_1.1.2         processx_3.7.0    pkgload_1.3.0     parallel_4.2.1    fastmap_1.1.0     yaml_2.3.5        sessioninfo_1.2.2 memoise_2.0.1    
    ## [65] knitr_1.40        profvis_0.3.7

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

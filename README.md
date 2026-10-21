# [Basic Design-Based GAP Data Products](https://github.com/afsc-gap-products/gap_products) <img src="https://avatars.githubusercontent.com/u/91760178?s=96&amp;v=4" alt="Logo." align="right" width="139" height="139"/>

The scripts therein reproducibly produce our typical data products.

<!-- README.md is generated from README.Rmd. Please edit that file -->

> This code is always in development. Find code used for various reports
> in the code
> [releases](https://github.com/afsc-gap-products/gap_products/releases).

*This code is primarily maintained by:*

**Emily Markowitz** (Emily.Markowitz AT noaa.gov;
[@EmilyMarkowitz-NOAA](https://github.com/EmilyMarkowitz-NOAA))

**Zack Oyafuso** (Zack.Oyafuso AT noaa.gov;
[@zoyafuso-NOAA](https://github.com/zoyafuso-NOAA))

Alaska Fisheries Science Center,

National Marine Fisheries Service,

National Oceanic and Atmospheric Administration,

Seattle, WA 98195

## Table of contents

> - [*Cite this data*](#cite-this-data)
>   - [*Access Constraints*](#access-constraints)
> - [*Relevant publications*](#relevant-publications)
> - [*Suggestions and Comments*](#suggestions-and-comments)
>   - [*Run notes*](#run-notes)
>   - [*R Version Metadata*](#r-version-metadata)
>   - [*NOAA README*](#noaa-readme)
>   - [*NOAA License*](#noaa-license)

## User Resources

- [GitHub repository](https://github.com/afsc-gap-products/gap_products)

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
repository](https://github.com/afsc-gap-products/gap_products/blob/main/content/references.bib)
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
source(here::here("content/references_current_tm.R")) # srvy_cite 
```

**Learn more about these surveys** ([Dowlin et al., 2026](#ref-AI2024);
[Hoff, 2016](#ref-BSS2016); [Markowitz et al., 2026](#ref-EBS2025),
[2026](#ref-EBS2025); [Siple et al., 2026](#ref-GOA2025); [Zacher et
al., In review](#ref-SAPcrab2026)).

<div id="refs" class="references csl-bib-body hanging-indent"
entry-spacing="0" line-spacing="2">

<div id="ref-AI2024" class="csl-entry">

Dowlin, A. N., Siple, M. C., and Szalay, P. G. von. (2026). *Data
report: 2024 Aleutian Islands bottom trawl survey* (AFSC Processed Rep.
2026-03; p. 190). NOAA Alaska Fisheries Science Center; U.S. Dep.
Commer. <https://doi.org/10.25923/090j-8132>

</div>

<div id="ref-BSS2016" class="csl-entry">

Hoff, G. R. (2016). *Results of the 2016 eastern Bering Sea upper
continental slope survey of groundfishes and invertebrate resources*
(NOAA Tech. Memo. NOAA-AFSC-339; p. 288). NOAA Alaska Fisheries Science
Center; U.S. Dep. Commer. <https://doi.org/10.7289/V5/TM-AFSC-339>

</div>

<div id="ref-EBS2025" class="csl-entry">

Markowitz, E. H., Charriere, N. E., Wassermann, S. N., Rohan, S. K., and
Stevenson, D. E. (2026). *Results of the 2025 eastern and northern
Bering Sea continental shelf bottom trawl survey of groundfish and
invertebrate fauna* (NOAA Tech. Memo. NMFS-AFSC-517; p. 203). NOAA
Alaska Fisheries Science Center; U.S. Dep. Commer.
<https://doi.org/10.25923/eam4-gp93>

</div>

<div id="ref-GOA2025" class="csl-entry">

Siple, M. C., Oyafuso, Z. O., and Dowlin, A. N. (2026). *Data report:
2025 <span class="nocase">Gulf of Alaska</span> bottom trawl survey*
(NOAA Tech. Memo. NMFS-AFSC-519). NOAA Alaska Fisheries Science Center;
U.S. Dep. Commer. <https://doi.org/10.25923/z4ta-p697>

</div>

<div id="ref-SAPcrab2026" class="csl-entry">

Zacher, L. S., Hennessey, J. I., Richar, J. I., Fedewa, E. J., and
Ryznar, E. R. (In review). *The 2026 eastern and northern Bering Sea
continental shelf trawl surveys: Results for commercial crab species*
\[NOAA Tech. Memo.\]. NOAA Alaska Fisheries Science Center; U.S. Dep.
Commer.
<https://meetings.npfmc.org/CommentReview/DownloadFile?p=499f3d7e-daf1-40a4-b5b0-94e8d44d5f03.pdf&fileName=2026%20EBS%20Crab%20Tech%20Memo%20DRAFT.pdf>

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

## Run notes

Will need to install [miktex](https://miktex.org/) and run the following
code in the console.

``` r
 # https://yihui.org/tinytex/r/#debugging
update.packages(ask = FALSE, checkBuilt = TRUE)
tinytex::tlmgr_update()
tinytex::reinstall_tinytex()
options(tinytex.verbose = TRUE)
```

``` r
install.packages("tinytex")   
require("tinytex")
install_tinytex(force = TRUE)
tlmgr_install('montserrat') 
xelatex('Report.tex')
```

## R Version Metadata

``` r
sessionInfo()
```

    FALSE R version 4.6.1 (2026-06-24 ucrt)
    FALSE Platform: x86_64-w64-mingw32/x64
    FALSE Running under: Windows 11 x64 (build 26100)
    FALSE 
    FALSE Matrix products: default
    FALSE   LAPACK version 3.12.1
    FALSE 
    FALSE locale:
    FALSE [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8    LC_MONETARY=English_United States.utf8 LC_NUMERIC=C                           LC_TIME=English_United States.utf8    
    FALSE 
    FALSE time zone: America/Los_Angeles
    FALSE tzcode source: internal
    FALSE 
    FALSE attached base packages:
    FALSE [1] stats     graphics  grDevices utils     datasets  methods   base     
    FALSE 
    FALSE other attached packages:
    FALSE  [1] RefManageR_1.4.0     knitr_1.52           knitcitations_1.0.12 RCurl_1.98-1.20      odbc_1.7.2           DBI_1.3.0            RODBC_1.3-26.3       ftExtra_0.6.5        scales_1.4.0         stringr_1.6.0       
    FALSE [11] flextable_0.10.3     kableExtra_1.4.1     janitor_2.2.1        readxl_1.6.0         readr_2.2.0          googledrive_2.1.2    akfingapdata_0.1.0   akgfmaps_4.2.2       terra_1.9-50         stars_0.7-3         
    FALSE [21] abind_1.4-8          sf_1.1-3             ggplot2_4.0.3.9000   gapindex_3.1.0       devtools_2.5.2       usethis_3.2.2        here_1.0.2           dplyr_1.2.1          tidyr_1.3.2         
    FALSE 
    FALSE loaded via a namespace (and not attached):
    FALSE  [1] bitops_1.1-0            rlang_1.3.0             magrittr_2.0.5          snakecase_0.11.1        otel_0.2.0              e1071_1.7-17            compiler_4.6.1          systemfonts_1.3.2       vctrs_0.7.3            
    FALSE [10] pkgconfig_2.0.3         fastmap_1.2.0           ellipsis_0.3.3          rmarkdown_2.32          sessioninfo_1.2.4       tzdb_0.5.0              ragg_1.5.2              purrr_1.2.2             bit_4.6.0              
    FALSE [19] xfun_0.61               cachem_1.1.0            litedown_0.11           jsonlite_2.0.0          pak_0.11.1              blob_1.3.0              uuid_1.2-2              parallel_4.6.1          R6_2.6.1               
    FALSE [28] stringi_1.8.9           RColorBrewer_1.1-3      pkgload_1.5.3           lubridate_1.9.5         cellranger_1.1.0        Rcpp_1.1.2              zoo_1.9-1               readtext_0.92.1         FNN_1.1.4.1            
    FALSE [37] timechange_0.4.0        tidyselect_1.2.1        yaml_2.3.12             rstudioapi_0.19.0       codetools_0.2-20        curl_8.1.0              pkgbuild_1.4.8          plyr_1.8.9              lattice_0.23-1         
    FALSE [46] tibble_3.3.1            intervals_0.15.5        withr_3.0.3             S7_0.2.2                askpass_1.2.1           evaluate_1.0.5          units_1.0-1             proxy_0.4-29            zip_3.0.2              
    FALSE [55] xts_0.14.3              xml2_1.6.0              lpSolve_5.6.23          pillar_1.11.1           KernSmooth_2.23-27      generics_0.1.4          rprojroot_2.1.1         sp_2.2-4                spacetime_1.3-4        
    FALSE [64] hms_1.1.4               commonmark_2.0.0        sampling_2.11           class_7.3-24            glue_1.8.1              gdtools_0.5.2           tools_4.6.1             data.table_1.18.6.1     fs_2.1.0               
    FALSE [73] grid_4.6.1              bibtex_0.5.3            cli_3.6.6               gstat_2.1-6             textshaping_1.0.5       officer_0.7.7           fontBitstreamVera_0.1.1 gargle_1.6.1            viridisLite_0.4.3      
    FALSE [82] svglite_2.2.2           gtable_0.3.6            digest_0.6.39           fontquiver_0.2.1        classInt_0.4-11         farver_2.1.2            memoise_2.0.1           htmltools_0.5.9         lifecycle_1.0.5        
    FALSE [91] httr_1.4.9              mime_0.13               fontLiberation_0.1.0    openssl_2.4.2           bit64_4.8.6             MASS_7.3-66

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

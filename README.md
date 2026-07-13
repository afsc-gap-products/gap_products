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
et al., 2026](#ref-2025NEBS), [2026](#ref-2025NEBS); [Siple et al.,
2024](#ref-GOA2023); [Von Szalay et al., 2026](#ref-AI2024); [Zacher et
al., 2026](#ref-SAPcrab2025)).

<div id="refs" class="references csl-bib-body hanging-indent"
entry-spacing="0" line-spacing="2">

<div id="ref-RN979" class="csl-entry">

Hoff, G. R. (2016). *Results of the 2016 eastern Bering Sea upper
continental slope survey of groundfishes and invertebrate resources*
(NOAA Tech. Memo. NOAA-AFSC-339). U.S. Dep. Commer.
<https://doi.org/10.7289/V5/TM-AFSC-339>

</div>

<div id="ref-2025NEBS" class="csl-entry">

Markowitz, E. H., Charriere, N. E., Wassermann, S. N., Rohan, S. K., and
Stevenson, D. E. (2026). *Results of the 2025 eastern and northern
Bering Sea continental shelf bottom trawl survey of groundfish and
invertebrate fauna* (NOAA Tech. Memo. NMFS-AFSC-517; p. 203). U.S. Dep.
Commer. <https://doi.org/10.25923/eam4-gp93>

</div>

<div id="ref-GOA2023" class="csl-entry">

Siple, M. C., Szalay, P. G. von, Raring, N. W., Dowlin, A. N., and
Riggle, B. C. (2024). *Data report: 2023 gulf of alaska bottom trawl
survey* (NOAA Tech. Memo. AFSC processed report; 2024-09). U.S. Dep.
Commer. <https://doi.org/10.25923/gbb1-x748>

</div>

<div id="ref-AI2024" class="csl-entry">

Von Szalay, P. G., Raring, N. W., Siple, M. C., Dowlin, A. N., Riggle,
B. C., and Laman, E. A. and. (2026). *Data report: 2024 Aleutian Islands
bottom trawl survey* (AFSC Processed Rep. 2026-03; p. 190). U.S. Dep.
Commer. <https://doi.org/10.25923/090j-8132>

</div>

<div id="ref-SAPcrab2025" class="csl-entry">

Zacher, L. S., Hennessey, J. I., Richar, J. I., Fedewa, E. J., Ryznar,
E. R., and Litzow, M. A. (2026). *The 2025 eastern and northern Bering
Sea continental shelf trawl surveys: Results for commercial crab
species* \[NOAA Tech. Memo.\]. (NMFS-AFSC-513), 299.
<https://doi.org/10.25923/a99f-9g50>

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

    ## R version 4.5.3 (2026-03-11 ucrt)
    ## Platform: x86_64-w64-mingw32/x64
    ## Running under: Windows 11 x64 (build 22631)
    ## 
    ## Matrix products: default
    ##   LAPACK version 3.12.1
    ## 
    ## locale:
    ## [1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8   
    ## [3] LC_MONETARY=English_United States.utf8 LC_NUMERIC=C                          
    ## [5] LC_TIME=English_United States.utf8    
    ## 
    ## time zone: America/Los_Angeles
    ## tzcode source: internal
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] digest_0.6.39     R6_2.6.1          fastmap_1.2.0     xfun_0.57         glue_1.8.1        knitr_1.51       
    ##  [7] htmltools_0.5.9   rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.6         readtext_0.92.1   vctrs_0.7.3      
    ## [13] data.table_1.18.4 compiler_4.5.3    httr_1.4.8        rprojroot_2.1.1   here_1.0.2        rstudioapi_0.19.0
    ## [19] tools_4.5.3       pillar_1.11.1     evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        rlang_1.2.0      
    ## [25] stringi_1.8.7

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

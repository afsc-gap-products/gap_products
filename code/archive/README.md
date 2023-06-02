<!-- README.md is generated from README.Rmd. Please edit that file -->

# [Basic Design-Based GAP Data Products](https://github.com/EmilyMarkowitz-NOAA/gap_bs_data_report) <img src="https://avatars.githubusercontent.com/u/91760178?s=96&amp;v=4" alt="Logo." align="right" width="139" height="139"/>

The scripts therein reproducibly produce our typical data products.

<!-- README.md is generated from README.Rmd. Please edit that file -->

[![](https://img.shields.io/github/last-commit/afsc-gap-products/gap_public_data.svg)](https://github.com/afsc-gap-products/gap_public_data/commits/main)

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

## This code is primarily maintained by:

**Emily Markowitz** (Emily.Markowitz AT noaa.gov;
[@EmilyMarkowitz-NOAA](https://github.com/EmilyMarkowitz-NOAA))  
Research Fisheries Biologist  
Bering Sea Survey Team Alaska Fisheries Science Center,  
National Marine Fisheries Service,  
National Oceanic and Atmospheric Administration,  
Seattle, WA 98195

# Cite this Data

**NOAA Fisheries Alaska Fisheries Science Center. RACE Division Bottom
Trawl Survey Data, Accessed mm/dd/yyyy**

*These data were last ran and pushed to the AFSC oracle on November 21,
2022*. This is not the date that these data were pulled into FOSS and
the FOSS dataset may be behind.

# Metadata

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

There are no legal restrictions on access to the data. They reside in
the public domain and can be freely distributed. Users must read and
fully comprehend the metadata prior to use. Data should not be used
beyond the limits of the source scale. Acknowledgement of NOAA, as the
source from which these data were obtained, in any publications and/or
other representations of these data, is suggested. These data are
compiled and approved annually after each summer survey season. The data
from previous years are unlikely to change substantially once published.
Some survey data are excluded, such as non-standard stations, surveys
completed in earlier years using different/non-standard gear, and
special tows and non-standard data collections.

The data calculated in this repo include:

1)  all (presence and absence; a.k.a. “zero-filled”) observations from
    surveys conducted on fishing vessels. These surveys monitor trends
    in distribution and abundance of groundfish, crab, and
    bottom-dwelling species in Alaska’s marine ecosystems. These data
    include estimates of catch-per-unit-effort (CPUE) for most
    identified species at a standard set of stations.

2)  Stratum- and total-level biomass and abundance estimates. \[**More
    description coming soon**\]

3)  Stratum- and total-level length and age comp estimates. \[**More
    description coming soon**\]: using length and otoliths (fish ear
    bones to learn about age).

## Bottom Trawl Surveys and Regions

<img src="img/_grid_bs.png" alt="Eastern and Northern Bering Sea Shelf" align="right" width="250"/>
<img src="img/_grid_ai.png" alt="Aleutian Islands" align="right" width="300"/>

-   **Eastern Bering Sea Shelf (EBS)**
-   Annual
-   Fixed stations at center of 20 x 20 nm grid
-   **Northern Bering Sea (NBS)**
-   Biennial/Annual
-   Fixed stations at center of 20 x 20 nm grid
-   **Eastern Bering Sea Slope (BSS)**
-   Intermittent (funding dependent)
-   Modified Index-Stratified Random of Successful Stations Survey
    Design
-   **Aleutian Islands (AI)**
-   Triennial (1990s)/Biennial since 2000 in even years
-   Modified Index-Stratified Random of Successful Stations Survey
    Design
-   **Gulf of Alaska (GOA)**
-   Triennial (1990s)/Biennial since 2001 in odd years
-   Stratified Random Survey Design

## User Resources:

-   [AFSC’s Resource Assessment and Conservation Engineering
    Division](https://www.fisheries.noaa.gov/about/resource-assessment-and-conservation-engineering-division).
-   For more information about codes used in the tables, please refer to
    the [survey code
    books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).
-   Find [past
    reports](http://apps-afsc.fisheries.noaa.gov/RACE/surveys/cruise_results.htm)
    about these surveys.
-   [GitHub
    repository](https://github.com/EmilyMarkowitz-NOAA/gap_bs_data_report).
-   Fisheries One Stop Shop (FOSS):
    <https://www.fisheries.noaa.gov/foss/f?p=215:200:13045102793007:Mail:NO>:::
-   Learn more about other [Research Surveys conducted at
    AFSC](https://www.fisheries.noaa.gov/alaska/ecosystems/alaska-fish-research-surveys).

## Access Constraints:

There are no legal restrictions on access to the data. They reside in
public domain and can be freely distributed.

**User Constraints:** Users must read and fully comprehend the metadata
prior to use. Data should not be used beyond the limits of the source
scale. Acknowledgement of AFSC Groundfish Assessment Program, as the
source from which these data were obtained, in any publications and/or
other representations of these data, is suggested.

**Address:** Alaska Fisheries Science Center (AFSC) National Oceanic and
Atmospheric Administration (NOAA)  
Resource Assessment and Conservation Engineering Division (RACE)  
Groundfish Assessment Program (GAP) 7600 Sand Point Way, N.E. bldg. 4  
Seattle, WA 98115 USA

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
One Stop Shop
(FOSS)](https://www.fisheries.noaa.gov/foss/f?p=215:200:13045102793007:Mail:NO:::)
platform, please contact us using the Comments page on the
[FOSS](https://www.fisheries.noaa.gov/foss/f?p=215:200:13045102793007:Mail:NO:::)
webpage.

## Table short metadata

### Station-level CPUE data (zero filled)

This dataset includes zero-filled (presence and absence) observations
and catch-per-unit-effort (CPUE) estimates for most identified species
at a standard set of stations in the Northern Bering Sea (NBS), Eastern
Bering Sea (EBS), Bering Sea Slope (BSS), Gulf of Alaska (GOA), and
Aleutian Islands (AI) Surveys conducted by the esource Assessment and
Conservation Engineering Division (RACE) Groundfish Assessment Program
(GAP) of the Alaska Fisheries Science Center (AFSC). There are no legal
restrictions on access to the data. The data from this dataset are
shared on the Fisheries One Stop Stop (FOSS) platform
(<https://www.fisheries.noaa.gov/foss/f?p=215:200:13045102793007:Mail:NO>:::).
The GitHub repository for the scripts that created this code can be
found at <https://github.com/EmilyMarkowitz-NOAA/gap_bs_data_report>
These data were last updated 2022-11-21 15:51:33.

## Column-level metadata

| Column name from data | Descriptive Column Name                                  | Units                                           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|:----------------------|:---------------------------------------------------------|:------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| year                  | Year                                                     | numeric                                         | Year the survey was conducted in.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| srvy                  | Survey                                                   | Abbreviated text                                | Abbreviated survey names. The column ‘srvy’ is associated with the ‘survey’ and ‘survey_id’ columns. Northern Bering Sea (NBS), Southeastern Bering Sea (EBS), Bering Sea Slope (BSS), Gulf of Alaska (GOA), Aleutian Islands (AI).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| survey                | Survey Name                                              | text                                            | Name and description of survey. The column ‘survey’ is associated with the ‘srvy’ and ‘survey_id’ columns.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| survey_id             | Survey ID                                                | ID code                                         | This number uniquely identifies a survey. Name and description of survey. The column ‘survey_id’ is associated with the ‘srvy’ and ‘survey’ columns. For a complete list of surveys, review the [code books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| cruise                | Cruise ID                                                | ID code                                         | This is a six-digit number identifying the cruise number of the form: YYYY99 (where YYYY = year of the cruise; 99 = 2-digit number and is sequential; 01 denotes the first cruise that vessel made in this year, 02 is the second, etc.).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| haul                  | Haul Number                                              | ID code                                         | This number uniquely identifies a sampling event (haul) within a cruise. It is a sequential number, in chronological order of occurrence.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| hauljoin              | hauljoin                                                 | ID Code                                         | This is a unique numeric identifier assigned to each (vessel, cruise, and haul) combination.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| stratum               | Stratum ID                                               | ID Code                                         | RACE database statistical area for analyzing data. Strata were designed using bathymetry and other geographic and habitat-related elements. The strata are unique to each survey series. Stratum of value 0 indicates experimental tows.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| station               | Station ID                                               | ID code                                         | Alpha-numeric designation for the station established in the design of a survey.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| vessel_name           | Vessel Name                                              | text                                            | Name of the vessel used to collect data for that haul. The column ‘vessel_name’ is associated with the ‘vessel_id’ column. Note that it is possible for a vessel to have a new name but the same vessel id number. For a complete list of vessel ID codes, review the [code books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| vessel_id             | Vessel ID                                                | ID Code                                         | ID number of the vessel used to collect data for that haul. The column ‘vessel_id’ is associated with the ‘vessel_name’ column. Note that it is possible for a vessel to have a new name but the same vessel id number. For a complete list of vessel ID codes, review the [code books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| date_time             | Date and Time of Haul                                    | MM/DD/YYYY HH::MM                               | The date (MM/DD/YYYY) and time (HH:MM) of the beginning of the haul.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| latitude_dd_start     | Start Latitude (decimal degrees)                         | decimal degrees, 1e-05 resolution               | Latitude (one hundred thousandth of a decimal degree) of the start of the haul.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| longitude_dd_start    | Start Longitude (decimal degrees)                        | decimal degrees, 1e-05 resolution               | Longitude (one hundred thousandth of a decimal degree) of the start of the haul.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| latitude_dd_end       | End Latitude (decimal degrees)                           | decimal degrees, 1e-05 resolution               | Latitude (one hundred thousandth of a decimal degree) of the end of the haul.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| longitude_dd_end      | End Longitude (decimal degrees)                          | decimal degrees, 1e-05 resolution               | Longitude (one hundred thousandth of a decimal degree) of the end of the haul.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| species_code          | Taxon Code                                               | ID code                                         | The species code of the organism associated with the ‘common_name’ and ‘scientific_name’ columns. For a complete species list, review the [code books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| itis                  | ITIS Taxonomic Serial Number                             | ID code                                         | Species code as identified in the Integrated Taxonomic Information System (<https://itis.gov/>). Codes were last updated 2022-11-21 14:36:19.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| worms                 | World Register of Marine Species Taxonomic Serial Number | ID code                                         | Species code as identified in the World Register of Marine Species (WoRMS) (<https://www.marinespecies.org/>). Codes were last updated 2022-11-21 14:36:19.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| common_name           | Taxon Common Name                                        | text                                            | The common name of the marine organism associated with the ‘scientific_name’ and ‘species_code’ columns. For a complete species list, review the [code books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| scientific_name       | Taxon Scientific Name                                    | text                                            | The scientific name of the organism associated with the ‘common_name’ and ‘species_code’ columns. For a complete taxon list, review the [code books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| taxon_confidence      | Taxon Confidence Rating                                  | rating                                          | Confidence in the ability of the survey team to correctly identify the taxon to the specified level, based solely on identification skill (e.g., not likelihood of a taxon being caught at that station on a location-by-location basis). Quality codes follow: **‘High’**: High confidence and consistency. Taxonomy is stable and reliable at this level, and field identification characteristics are well known and reliable. **‘Moderate’**: Moderate confidence. Taxonomy may be questionable at this level, or field identification characteristics may be variable and difficult to assess consistently. **‘Low’**: Low confidence. Taxonomy is incompletely known, or reliable field identification characteristics are unknown. Documentation: [Species identification confidence in the eastern Bering Sea shelf survey (1982-2008)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2009-04.pdf), [Species identification confidence in the eastern Bering Sea slope survey (1976-2010)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2014-05.pdf), and [Species identification confidence in the Gulf of Alaska and Aleutian Islands surveys (1980-2011)](http://apps-afsc.fisheries.noaa.gov/Publications/ProcRpt/PR2014-01.pdf). |
| cpue_kgha             | Weight CPUE (kg/ha)                                      | kilograms/hectare                               | Relative Density. Catch weight (kilograms) divided by area (hectares) swept by the net.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| cpue_kgkm2            | Weight CPUE (kg/km<sup>2</sup>)                          | kilograms/kilometers<sup>2</sup>                | Relative Density. Catch weight (kilograms) divided by area (squared kilometers) swept by the net.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| cpue_noha             | Number CPUE (no./ha)                                     | count/hectare                                   | Relative Abundance. Catch number (in number of organisms) per area (hectares) swept by the net.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| cpue_nokm2            | Number CPUE (no./km<sup>2</sup>)                         | count/kilometers<sup>2</sup>                    | Relative Abundance. Catch number (in number of organisms) per area (squared kilometers) swept by the net.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| weight_kg             | Taxon Weight (kg)                                        | kilograms, thousandth resolution                | Weight (thousandths of a kilogram) of individuals in a haul by taxon.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| count                 | Taxon Count                                              | count, whole number resolution                  | Total number of individuals caught in haul by taxon, represented in whole numbers.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| bottom_temperature_c  | Bottom Temperature (Degrees Celsius)                     | degrees Celsius, tenths of a degree resolution  | Bottom temperature (tenths of a degree Celsius); NA indicates removed or missing values.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| surface_temperature_c | Surface Temperature (Degrees Celsius)                    | degrees Celsius, tenths of a degree resolution  | Surface temperature (tenths of a degree Celsius); NA indicates removed or missing values.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| depth_m               | Depth (m)                                                | meters, tenths of a meter resolution            | Bottom depth (tenths of a meter).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| distance_fished_km    | Distance Fished (km)                                     | kilometers, thousandths of kilometer resolution | Distance the net fished (thousandths of kilometers).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| net_width_m           | Net Width (m)                                            | meters                                          | Measured or estimated distance (meters) between wingtips of the trawl.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| net_height_m          | Net Height (m)                                           | meters                                          | Measured or estimated distance (meters) between footrope and headrope of the trawl.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| area_swept_ha         | Area Swept (ha)                                          | hectares                                        | The area the net covered while the net was fishing (hectares), defined as the distance fished times the net width.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| duration_hr           | Tow Duration (decimal hr)                                | decimal hours                                   | This is the elapsed time between start and end of a haul (decimal hours).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| performance           | Haul Performance Code (rating)                           | rating                                          | This denotes what, if any, issues arose during the haul. For more information, review the [code books](https://www.fisheries.noaa.gov/resource/document/groundfish-survey-species-code-manual-and-data-codes-manual).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

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
    ##  [1] knitr_1.40     badger_0.2.1   RODBC_1.3-19   stringr_1.4.1  tidyr_1.2.1    readr_2.1.2    magrittr_2.0.3 dplyr_1.0.10   plyr_1.8.7    
    ## [10] devtools_2.4.4 usethis_2.1.6 
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] fs_1.5.2            lubridate_1.8.0     bit64_4.0.5         RColorBrewer_1.1-3  httr_1.4.4          rprojroot_2.0.3     gh_1.3.1           
    ##  [8] tools_4.2.1         profvis_0.3.7       utf8_1.2.2          R6_2.5.1            DBI_1.1.3           colorspace_2.0-3    urlchecker_1.0.1   
    ## [15] withr_2.5.0         tidyselect_1.1.2    prettyunits_1.1.1   processx_3.7.0      bit_4.0.4           curl_4.3.2          compiler_4.2.1     
    ## [22] cli_3.4.1           scales_1.2.1        callr_3.7.2         askpass_1.1         digest_0.6.29       yulab.utils_0.0.5   rmarkdown_2.16     
    ## [29] pkgconfig_2.0.3     htmltools_0.5.3     sessioninfo_1.2.2   highr_0.9           fastmap_1.1.0       htmlwidgets_1.5.4   rlang_1.0.6        
    ## [36] readxl_1.4.1        rstudioapi_0.14     shiny_1.7.2         generics_0.1.3      jsonlite_1.8.0      vroom_1.5.7         credentials_1.3.2  
    ## [43] Rcpp_1.0.9          munsell_0.5.0       fansi_1.0.3         lifecycle_1.0.2     stringi_1.7.8       yaml_2.3.5          snakecase_0.11.0   
    ## [50] pkgbuild_1.3.1      grid_4.2.1          parallel_4.2.1      promises_1.2.0.1    crayon_1.5.1        miniUI_0.1.1.1      hms_1.1.2          
    ## [57] sys_3.4             ps_1.7.1            pillar_1.8.1        pkgload_1.3.0       glue_1.6.2          evaluate_0.16       remotes_2.4.2      
    ## [64] BiocManager_1.30.18 vctrs_0.4.1         tzdb_0.3.0          httpuv_1.6.6        cellranger_1.1.0    gtable_0.3.1        openssl_2.0.3      
    ## [71] purrr_0.3.4         assertthat_0.2.1    cachem_1.0.6        ggplot2_3.3.6       xfun_0.33           mime_0.12           janitor_2.1.0      
    ## [78] xtable_1.8-4        gitcreds_0.1.2      later_1.3.0         dlstats_0.1.5       gert_1.9.0          tibble_3.1.8        rvcheck_0.2.1      
    ## [85] memoise_2.0.1       ellipsis_0.3.2      here_1.0.1

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

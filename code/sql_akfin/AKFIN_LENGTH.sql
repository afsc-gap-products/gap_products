-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_LENGTH
--
-- Created by querying records from RACEBASE.LENGTH but only using hauls 
-- with ABUNDANCE_HAUL = 'Y' from the five survey areas w/ survey_definition_id:
-- "AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_LENGTH AS
SELECT 
a.hauljoin,
species_code, 
sex, 
frequency, 
length as length_mm, 
length_type, 
sample_type 
--select count(*)
from racebase.length a, race_data.cruises b, race_data.surveys c, 
race_data.survey_definitions d, racebase.haul f
where abs(a.cruisejoin) = b.cruise_id
and a.hauljoin = f.hauljoin
and c.survey_id =  b.survey_id 
and c.survey_definition_id = d.SURVEY_DEFINITION_ID 
and d.survey_definition_id in (143, 98, 47, 52, 78)
and f.abundance_haul = 'Y'


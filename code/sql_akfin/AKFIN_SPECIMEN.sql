-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_SPECIMEN
--
-- Created by querying records from RACEBASE.SPECIMEN but only using hauls 
-- with ABUNDANCE_HAUL = 'Y' from the five survey areas w/ survey_definition_id:
-- "AI" = 52, "GOA" = 47, "EBS" = 98, "BSS" = 78, "NBS" = 143
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_SPECIMEN AS 
select 
-- a.cruisejoin, 
a.hauljoin, 
-- a.region, 
-- b.vessel_id, 
a.specimenid as specimen_id, 
-- a.biostratum stratum, 
a.species_code, 
a.length as length_mm, 
a.sex, 
a.weight as weight_g, 
a.age, 
a.maturity, 
-- a.maturity_table, 
a.gonad_wt as gonad_g, 
a.specimen_subsample_method, 
a.specimen_sample_type, 
a.age_determination_method 
--select count(*)
from racebase.specimen a, 
race_data.cruises b, 
race_data.surveys c, 
race_data.survey_definitions d, 
racebase.haul f
where abs(a.cruisejoin) = b.cruise_id
and a.hauljoin = f.hauljoin
and c.survey_id =  b.survey_id 
and c.survey_definition_id = d.SURVEY_DEFINITION_ID 
and d.survey_definition_id in (143, 98, 47, 52, 78)
and f.abundance_haul = 'Y';

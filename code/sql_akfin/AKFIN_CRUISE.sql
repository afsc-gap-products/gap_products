-- SQL Command to Create Materilized View GAP_PRODUCTS.AKFIN_CRUISE
--
-- Contributors: Ned Laman (ned.laman@noaa.gov), 
--               Zack Oyafuso (zack.oyafuso@noaa.gov), 
--               Emily Markowitz (emily.markowitz@noaa.gov)
--

CREATE MATERIALIZED VIEW GAP_PRODUCTS.AKFIN_CRUISE AS

select distinct 
a.cruisejoin, 
b.cruise, 
floor(b.cruise/100) year, 
d.survey_definition_id, 
d.survey_name, 
b.vessel_id, 
e.name vessel_name,
f.acronym sponsor_acronym, 
c.start_date date_start, 
c.END_DATE date_end
from racebase.haul a, 
race_data.cruises b, 
race_data.surveys c, 
race_data.survey_definitions d, 
race_data.vessels e, 
race_data.organizations f
where a.vessel = b.vessel_id
and b.vessel_id = e.vessel_id
and a.cruise = b.cruise 
and c.survey_id =  b.survey_id 
and c.survey_definition_id = d.survey_definition_id 
and d.survey_definition_id in (143,98,47,52,78)
and a.abundance_haul = 'Y'
and f.organization_id = c.sponsor_organization_id

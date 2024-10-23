/* THIS SCRIPT CALCULATES AVERAGE BOTTOM AND SURFACE TEMPERATURE, WEIGHTED BY */
/* STRATA AREA, FOR THE NBS */

REM modified 9/22/2023 update haulname to include current survey year

/*  THIS SECTION GETS THE PROPER HAUL TABLE */
REM ***THIS GRABS THE MOST UP-TO-DATE CRUISEJOINS***

REM  ****MAKE SURE YOU INCLUDE THE MOST RECENT YEAR IN THE HAULNAME SELECT****
drop  table haulname; 
create table haulname as 
SELECT  
	to_number(to_char(a.start_time,'yyyy')) year,
	A.*
FROM 
	RACEBASE.HAUL A
JOIN 
	RACE_DATA.V_CRUISES B
ON 
	(B.CRUISEJOIN = A.CRUISEJOIN)
WHERE 
	A.PERFORMANCE >= 0
	AND A.HAUL_TYPE = 3
	AND A.STATIONID IS NOT NULL
	AND B.SURVEY_DEFINITION_ID = 143
	AND B.YEAR in (2010,2017,2019,2021,2022,2023);

drop table totarea;
drop view totarea;
create table totarea as 
select sum(area) totareas from 
racebase.stratum where 
region='BS' and year=2019 
and stratum in (70,71,81);

drop table stratwgt;
drop view stratwgt;
create table stratwgt as 
select stratum, (area/totareas) ratio 
from racebase.stratum r, totarea f 
where region='BS' and year=2019 
and stratum in (70,71,81);

drop table pretemptab;
drop view pretemptab;
create table pretemptab as 
select to_char(start_time,'YYYY') year, haul, r.stratum,(gear_temperature*ratio) pregtemp, 
(surface_temperature*ratio) prestemp from haulname r, stratwgt f 
where f.stratum=r.stratum ;

drop table geartemp_subarea;
drop view geartemp_subarea;
create table geartemp_subarea as 
select year, stratum, avg(pregtemp) gtempwgt, avg(prestemp) stempwgt from pretemptab 
group by year, stratum;

drop table bttemp_nbs;
drop view bttemp_nbs;
create table bttemp_nbs as
select year, sum(gtempwgt) avgbsbt, sum(stempwgt) avgbsst from geartemp_subarea 
group by year;

grant select on bttemp_nbs to public;
commit;

select * from bttemp_nbs order by year;
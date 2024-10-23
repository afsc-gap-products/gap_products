REM CPUE VERSION UPDATE 8/4/2015 BY NICHOL
REM THIS SCRIPT CALULATES THE CPUE_KGHA AND CPUE_NOHA BY HAUL/STATION FOR ALL SPECIES IDENTIFIED FOR MULIPLE YEARS.
REM STATION/HAULS WITH ZERO WEIGHTS AND NULL NUMBERS ARE INCLUDED.
REM  FISHING POWER CORRECTIONS ARE NOT APPLIED HERE.
REM INCLUDES STATIONS IN THE NBS SURVEY STRATA.

REM modified 9/22/2023 insert current year in haulname table 


/*  THIS SECTION GETS THE PROPER HAUL TABLE */
REM ***THIS GRABS THE MOST UP-TO-DATE CRUISEJOINS***

drop table haulname;
drio view haulname;
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

delete from haulname where stationid='AA-10';


rem /*table 'species_catch' joins haul data with catch data, field name stratum 
rem is changed to substrata */

drop table species_catch;
drop view species_catch;
create table species_catch as 
select a.species_code, b.year, b.cruise, b.vessel, b.stratum, b.hauljoin, b.stationid, b.haul,
 a.weight, a.number_fish, a.subsample_code, a.voucher, a.auditjoin
from racebase.catch a, haulname b 
where a.hauljoin = b.hauljoin ;

REM FIRST SET UP A ZEROS TABLE  
drop table temp1;
create table temp1 as select
year,vessel,stratum,hauljoin,haul, stationid, start_latitude latitude, start_longitude longitude,
DISTANCE_FISHED*NET_WIDTH/10 area_fished from haulname;
drop table temp2;
create table temp2 as select species_code from species_catch group by species_code order by species_code;
drop table cpue_zeros;
create table cpue_zeros as select species_code, year, vessel,stratum, hauljoin, haul, stationid, latitude, longitude,
 0 wgtcpue_zero, 0 numcpue_zero, area_fished 
from temp1, temp2 
order by species_code, year, stratum ;

REM NOW CALC THE WGTCPUE & NUMCPUE WHERE THE SPECIES IS PRESENT IN A HAUL
drop table cpue_present;
create table cpue_present as
select species_code,h.year,h.vessel,h.stratum,h.hauljoin, h.haul, h.stationid, h.start_latitude latitude, h.start_longitude longitude,
(weight/((distance_fished*net_width)/10)) wgtcpue_present,
((number_fish)/((distance_fished*net_width)/10)) numcpue_present,
DISTANCE_FISHED*NET_WIDTH/10 area_fished
from species_catch c, haulname h
where c.hauljoin=h.hauljoin ;

REM NOW COMBINE THE CPUES ZEROS AND THOSE WHERE THE SPECIES WAS PRESENT
drop table temp_cpue;
drop view temp_cpue;
create table temp_cpue as select
z.species_code, z.year,z.vessel,z.stratum, z.hauljoin, z.haul, z.stationid, z.latitude, z.longitude,
(wgtcpue_zero+wgtcpue_present) cpue_kgha, (numcpue_zero+numcpue_present) cpue_noha, z.area_fished area_fished_ha 
from cpue_zeros z, cpue_present p 
where z.species_code=p.species_code(+) and z.year=p.year(+) and z.stratum=p.stratum(+) and z.hauljoin=p.hauljoin(+);

REM NOW CHANGE NULLS TO ZEROS FOR THE HAULS IN WHICH THE SPECIES WAS NOT PRESENT
REM  ***NEED TO BE CAREFUL HERE BECAUSE THERE MIGHT BE ACTUAL NULLS -E.G. WHERE THERE ARE WGTS BUT NO NUMBERS ***

update temp_cpue set cpue_noha=999999 where cpue_kgha is not null and cpue_noha is null;
commit;
update temp_cpue set cpue_kgha=0 where cpue_kgha is null;
commit;
update temp_cpue set cpue_noha=0 where cpue_noha is null;
commit;
update temp_cpue set cpue_noha=null where cpue_noha=999999;
commit;

REM NEED TO DELETE ROCK SOLE CASES FOR YEARS IN WHICH THE SPECIES CODE WAS NOT USED
delete from temp_cpue where species_code=10261 and year<=1995;
delete from temp_cpue where species_code=10262 and year<=1995;
delete from temp_cpue where species_code=10260 and year>=1996;

drop table cpue_nbs;
create table cpue_nbs 
(
    "SPECIES_CODE"   CHAR(5 BYTE),
    "SPECIES_NAME"   VARCHAR2(80),
    "COMMON_NAME"    VARCHAR2(40),
    "YEAR"           NUMBER(5),
    "VESSEL"         NUMBER(4),
    "STRATUM"        NUMBER(6,0),
    "HAULJOIN"       NUMBER(12),
    "HAUL"           NUMBER(4),
    "STATIONID"      VARCHAR2(10),
    "LATITUDE"       NUMBER(7,5),
    "LONGITUDE"      NUMBER(8,5),
    "CPUE_KGHA"      NUMBER,
    "CPUE_NOHA"      NUMBER,
    "AREA_FISHED_HA" NUMBER
  );

insert into cpue_nbs select a.species_code, b.species_name, b.common_name, 
a.year, a.vessel, a.stratum, a.hauljoin, a.haul, stationid, latitude, longitude, 
round(cpue_kgha,4) cpuekgha, round(cpue_noha,4) cpue_noha,
area_fished_ha from temp_cpue a, racebase.species b where a.species_code=b.species_code;


select * from cpue_nbs order by species_code, year, vessel, haul;

drop table temp_cpue;

grant select on cpue_nbs to public;
commit;

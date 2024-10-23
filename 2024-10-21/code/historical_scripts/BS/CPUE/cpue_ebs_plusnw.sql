REM CPUE VERSION UPDATE 8/4/2015 BY NICHOL
REM THIS SCRIPT CALULATES THE CPUE_KGHA AND CPUE_NOHA BY HAUL/STATION FOR MULTIPLE SPECIES FOR MULIPLE YEARS.
REM STATION/HAULS WITH ZERO WEIGHTS AND NULL NUMBERS ARE INCLUDED.
REM  FISHING POWER CORRECTIONS ARE NOT APPLIED HERE.
REM INCLUDES STATIONS IN THE STANDARD + PLUSNW SURVEY STRATA.

REM ADDED NEW TABLE WITH CPUE IN KG/KM2 AND NO/KM2 -- STEVENSD 11/02/2022


/*  THIS SECTION GETS THE PROPER HAUL TABLE */
REM ***THIS GRABS THE MOST UP-TO-DATE CRUISEJOINS***

drop  table haulname; 
drop  view haulname; 
create table haulname as 
SELECT  to_number(to_char(a.start_time,'yyyy')) year,A.*
FROM RACEBASE.HAUL A
JOIN RACE_DATA.V_CRUISES B
ON (B.CRUISEJOIN = A.CRUISEJOIN)
WHERE A.PERFORMANCE >= 0
AND A.HAUL_TYPE = 3
AND A.STATIONID IS NOT NULL
AND A.STRATUM IN (10,20,31,32,41,42,43,50,61,62,82,90)
AND B.SURVEY_DEFINITION_ID = 98;


rem /*table 'species_catch' joins haul data with catch data, field name stratum 
rem is changed to substrata */

drop table species_catch;
drop view species_catch;
create table species_catch as 
select a.species_code, b.year, b.cruise, b.vessel, b.stratum, b.hauljoin, b.stationid, b.haul,
 a.weight, a.number_fish, a.subsample_code, a.voucher, a.auditjoin
from racebase.catch a, haulname b 
where a.species_code in 
(232,310,320,
420,435,440,455,471,472,
480,490,495,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
21420,21371,21370,21368,21347,
21314,21315,21316,21329,21333,21340,21341,21346,21348,21352,21353,21354,21355,21356,21388,21390,21397,21405,21406,21438,21441,
21720,21740,
30050,30051,30052,30060,30150,30152,30420,30535,
78010,78012,78020,78403,78454,78455,
79020,79210)
and a.hauljoin = b.hauljoin ;

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

drop table cpue_ebs_plusnw;
create table cpue_ebs_plusnw 
(
    "SPECIES_CODE"   CHAR(5 BYTE),
    "SPECIES_NAME"   VARCHAR2(40),
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

insert into cpue_ebs_plusnw select a.species_code, b.species_name, b.common_name, 
a.year, a.vessel, a.stratum, a.hauljoin, a.haul, stationid, latitude, longitude, 
round(cpue_kgha,4) cpuekgha, round(cpue_noha,4) cpue_noha,
area_fished_ha from temp_cpue a, racebase.species b where a.species_code=b.species_code;

select * from cpue_ebs_plusnw order by species_code, year, vessel, haul;

REM CREATE SAME TABLE WITH CPUE IN KG/KM2 AND NO/KM2 -- STEVENSD 11/02/2022

drop table cpue_ebs_km2;
create table cpue_ebs_km2 
(
    "SPECIES_CODE"   CHAR(5 BYTE),
    "SPECIES_NAME"   VARCHAR2(40),
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
    "CPUE_KGKM"      NUMBER,
    "CPUE_NOKM"      NUMBER,
    "AREA_FISHED_HA" NUMBER
  );

insert into cpue_ebs_km2 select a.species_code, b.species_name, b.common_name, 
a.year, a.vessel, a.stratum, a.hauljoin, a.haul, stationid, latitude, longitude, 
round(cpue_kgha,4) cpuekgha, round(cpue_noha,4) cpue_noha,
(cpue_kgha * 100) cpue_kgkm, (cpue_noha * 100) cpue_nokm,
area_fished_ha from temp_cpue a, racebase.species b where a.species_code=b.species_code;


drop table temp_cpue;

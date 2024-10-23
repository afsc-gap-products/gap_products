REM CPUE VERSION UPDATE 8/4/2015 BY NICHOL
REM THIS SCRIPT CALULATES THE CPUE_KGHA AND CPUE_NOHA BY HAUL/STATION FOR MULTIPLE SPECIES FOR MULIPLE YEARS.
REM STATION/HAULS WITH ZERO WEIGHTS AND NULL NUMBERS ARE INCLUDED.
REM  FISHING POWER CORRECTIONS ARE NOT APPLIED HERE.
REM INCLUDES STATIONS IN THE STANDARD + PLUSNW SURVEY STRATA.


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

/* THIS CHANGES THE SPECIES TO BE GROUPED TO THEIR RESPECTIVE */
/* NEW CODES */
drop view group_species; 
drop  table group_species;
create table group_species as
 select resultcode species_code, h.year, c.cruise, c.vessel, h.stratum, c.hauljoin, h.stationid, c.haul,
 c.weight, c.number_fish from racebase.catch c, haulname h, species_group g 
 where c.hauljoin = h.hauljoin and  c.species_code >= g.fromcode and c.species_code<=g.tocode;


/*  THIS VIEW SUMS UP WITHIN A HAUL THE WEIGHTS AND NUMBERS FOR */
/*  DUPLICATE SPECIES CODES. NOTE THAT ORACLE WILL SUM NULLS JUST */
/*  LIKE NUMBERS HERE.  MAYBE NOT WHAT YOU EXPECT */

drop table group_species_catch;
drop view group_species_catch;
create table group_species_catch as
select species_code, year, cruise, vessel, stratum, hauljoin, stationid, haul, sum(weight) weight, sum(number_fish) number_fish
 from group_species 
group by species_code, year, cruise, vessel, stratum, hauljoin, stationid, haul;


REM FIRST SET UP A ZEROS TABLE  
drop table temp1;
create table temp1 as select
year,vessel,stratum,hauljoin,haul, stationid, start_latitude latitude, start_longitude longitude,
DISTANCE_FISHED*NET_WIDTH/10 area_fished from haulname;
drop table temp2;
create table temp2 as select species_code from group_species_catch group by species_code order by species_code;
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
from group_species_catch c, haulname h
where c.hauljoin=h.hauljoin ;

REM NOW COMBINE THE CPUES ZEROS AND THOSE WHERE THE SPECIES WAS PRESENT
drop table temp_group_cpue;
drop view temp_group_cpue;
create table temp_group_cpue as select
z.species_code, z.year,z.vessel,z.stratum, z.hauljoin, z.haul, z.stationid, z.latitude, z.longitude,
(wgtcpue_zero+wgtcpue_present) cpue_kgha, (numcpue_zero+numcpue_present) cpue_noha, z.area_fished area_fished_ha 
from cpue_zeros z, cpue_present p 
where z.species_code=p.species_code(+) and z.year=p.year(+) and z.stratum=p.stratum(+) and z.hauljoin=p.hauljoin(+);

REM NOW CHANGE NULLS TO ZEROS FOR THE HAULS IN WHICH THE SPECIES WAS NOT PRESENT
REM  ***NEED TO BE CAREFUL HERE BECAUSE THERE MIGHT BE ACTUAL NULLS -E.G. WHERE THERE ARE WGTS BUT NO NUMBERS ***

update temp_group_cpue set cpue_noha=999999 where cpue_kgha is not null and cpue_noha is null;
commit;
update temp_group_cpue set cpue_kgha=0 where cpue_kgha is null;
commit;
update temp_group_cpue set cpue_noha=0 where cpue_noha is null;
commit;
update temp_group_cpue set cpue_noha=null where cpue_noha=999999;
commit;

drop table cpue_ebs_plusnw_grouped;
create table cpue_ebs_plusnw_grouped 
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

insert into cpue_ebs_plusnw_grouped select a.species_code, b.species_name, b.common_name, 
a.year, a.vessel, a.stratum, a.hauljoin, a.haul, stationid, latitude, longitude, 
round(cpue_kgha,4) cpuekgha, round(cpue_noha,4) cpue_noha,
area_fished_ha from temp_group_cpue a, species_group b where a.species_code=b.resultcode;


select * from cpue_ebs_plusnw_grouped order by species_code, year, vessel, haul;

drop table temp_group_cpue;


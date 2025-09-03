REM For this script, the list of years needs to be updated in a few places for each new survey year

drop table HAUL_nbs;
drop view HAUL_nbs;
create table HAUL_nbs as
SELECT  
  to_number(to_char(a.start_time,'yyyy')) year,
  'NBS' survey,
  a.CRUISEJOIN,
  a.hauljoin,
  a.vessel,
  a.cruise,
  a.HAUL,
  a.HAUL_TYPE,
  a.PERFORMANCE,
  START_TIME,
  DURATION,
  DISTANCE_FISHED,
  NET_WIDTH,
  NET_MEASURED,
  NET_HEIGHT,
  a.STRATUM,
  START_LATITUDE,
  END_LATITUDE,
  START_LONGITUDE,
  END_LONGITUDE,
  STATIONID,
  GEAR_DEPTH,
  BOTTOM_DEPTH,
  BOTTOM_TYPE,
  SURFACE_TEMPERATURE,
  GEAR_TEMPERATURE,
  WIRE_LENGTH,
  GEAR,
  ACCESSORIES,
  SUBSAMPLE,
  AUDITJOIN
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
delete from HAUL_nbs where stationid='AA-10';

drop table surveys_nbs;
create table surveys_nbs as
select distinct c.CRUISEJOIN,
'NBS' survey,
c.VESSEL,
c.CRUISE,
c.START_DATE,
c.END_DATE,
c.MIN_LATITUDE,
c.MAX_LATITUDE,
c.MIN_LONGITUDE,
c.MAX_LONGITUDE,
c.AGENCY_NAME,
c.SURVEY_NAME,
to_number(to_char(start_date,'yyyy')) year
from racebase.cruise c, HAUL_nbs h
where c.cruisejoin=h.cruisejoin
and c.vessel=h.vessel
and c.cruise=h.cruise
and to_number(to_char(start_date,'yyyy'))=h.year
order by year;


drop table CATCH_nbs;
create table CATCH_nbs as
select YEAR,
'NBS' survey,
c.CRUISEJOIN,
c.HAULJOIN,
CATCHJOIN,
c.VESSEL,
c.CRUISE,
c.HAUL,
SPECIES_CODE,
WEIGHT,
NUMBER_FISH,
SUBSAMPLE_CODE,
VOUCHER,
c.AUDITJOIN
from racebase.catch c, HAUL_nbs h
where h.hauljoin=c.hauljoin;

drop table LENGTH_nbs;
create table LENGTH_nbs as
select 'NBS' survey,
C.CRUISEJOIN,
C.HAULJOIN,
C.CATCHJOIN,
C.VESSEL,
C.CRUISE,
C.HAUL,
SPECIES_CODE,
LENGTH,
FREQUENCY,
SEX,
SAMPLE_TYPE,
LENGTH_TYPE,
C.AUDITJOIN
from racebase.LENGTH c, HAUL_nbs h
where h.hauljoin=c.hauljoin;

drop table SPECIMEN_nbs;
create table SPECIMEN_nbs as
select 'NBS' survey,
C.CRUISEJOIN,
C.HAULJOIN,
C.VESSEL,
C.CRUISE,
C.HAUL,
SPECIES_CODE,
SPECIMENID,
BIOSTRATUM,
LENGTH,
SEX,
WEIGHT,
AGE,
MATURITY,
MATURITY_TABLE,
GONAD_WT,
C.AUDITJOIN,
SPECIMEN_SUBSAMPLE_METHOD,
SPECIMEN_SAMPLE_TYPE,
AGE_DETERMINATION_METHOD
from racebase.SPECIMEN c, HAUL_nbs h
where h.hauljoin=c.hauljoin;



drop table nbs_CPUE;
drop view nbs_CPUE;
create table nbs_CPUE as
select       'NBS' survey,
             a.year,
             b.catchjoin,
             a.hauljoin,
             a.vessel,
             a.cruise,
             a.haul,
             a.stratum,
             a.stationid,
             a.distance_fished,
             a.net_width,
             a.species_code,
             nvl(b.weight,0) weight,
             nvl(b.number_fish,0) number_fish,
             ((a.distance_fished*a.net_width)/1000) effort,
             nvl(b.weight,0)/((a.distance_fished*a.net_width)/1000) wgtcpue,
             nvl(b.number_fish,0)/((a.distance_fished*a.net_width)/1000) numcpue
from       (select distinct c.year,
                            c.hauljoin,
                            c.vessel,
                            c.cruise,
                            c.haul,
                            c.stratum,
                            c.stationid,
                            c.distance_fished,
                            c.net_width,
                            a.species_code
          from CATCH_nbs a, HAUL_nbs c, racebase.species b
                       where a.year=c.year
                            and a.species_code=b.species_code
             ) a, 
             CATCH_nbs b
where     a.hauljoin = b.hauljoin(+) and
          a.species_code=b.species_code(+);


drop table CPUE_nbs_POS;
create table CPUE_nbs_POS as
select
	a.year,
  a.vessel,
  a.haul,
  a.species_code,
  c.species_name,
  c.common_name,
	b.start_latitude latitude,
	b.start_longitude longitude,
	b.surface_temperature sst_c,
	b.gear_temperature btemp_c,
	b.bottom_depth depth_m,
	a.wgtcpue,
	a.numcpue
from 
  nbs_CPUE a, 
  HAUL_nbs b,
  racebase.species c
where
	a.hauljoin=b.hauljoin
  and a.species_code=c.species_code
  and a.year in (2010, 2017, 2019, 2021, 2022, 2023)
order by
  a.year,
  a.vessel,
  a.haul,
  a.species_code;

REM DONT NEED TO DO THIS ONE AGAIN  
REM drop table species_codes;
REM create table species_codes as
REM select * from racebase.species;


REM THE FOLLOWING INCLUDES BIOMASS FOR ALL SPECIES IDENTIFIED DURING THE SURVEYS
Drop table nbs_biomass;
create table nbs_biomass as
select  'NBS' survey,
        year,
        species_code,
        species_name,
        common_name,
        STRATUM,
        HAULCOUNT haul_count,
        CATCOUNT catch_count,
        NUMCOUNT number_count,
        LENCOUNT length_count,
        MEANWGTCPUE*100 MEAN_WGT_CPUE,
        VARMNWGTCPUE*10000 VAR_WGT_CPUE,
        MEANNUMCPUE*100 MEAN_NUM_CPUE,
        VARMNNUMCPUE*10000 VAR_NUM_CPUE,
        biomass STRATUM_BIOMASS,
        VARBIO BIOMASS_VAR,
        LOWERB MIN_BIOMASS,
        UPPERB MAX_BIOMASS,
        DEGREEFwgt degreef_biomass,
        POPULATION STRATUM_POP,
        VARPOP POP_VAR,
        LOWERP MIN_POP,
        UPPERP MAX_POP,
        DEGREEFNUM degreef_pop
from haehnr.biomass_nbs_safe
where species_code not in(400,10111,10260,10129,79000,78010); 


REM NO GROUPED TABLES ARE NECESSARY FOR THE NBS


Drop table nbs_sizecomp;
create table nbs_sizecomp as
select  'NBS' survey,
        year,
        species_code,
        species_name,
        common_name,
        stratum,
        LENGTH,
        MALES,
        FEMALES,
        UNSEXED,
        TOTAL
from haehnr.sizecomp_nbs_stratum 
where 
  species_code not in(400,10111,10260,10129,79000,78010)
order by year,
        species_code,
        stratum,
        LENGTH;


REM  AGAIN, THE GROUPED TABLE NOT NECESSARY FOR NBS



REM BE AWARE HERE THAT THERE IS A SEX=9 (COMBINED SEXES) IN ADDITION TO SEX = 1,2,&3
Drop table nbs_agecomp;
create table nbs_agecomp as
select 
  'NBS' survey,
  year,
  species_code,
  STRATUM,
  sex,
  age,
  agepop,
  meanlen MEAN_LENGTH,
  sdev STANDARD_DEVIATION
from haehnr.agecomp_nbs_stratum;



REM *************************************************************************************************
REM NOT SURE WHAT BOB WANTED BELOW, BUT SUBAREA 9999999 DOES NOT EXIST - SO THIS SELECT NEVER WORKED
REM drop table nbs_agecomp;
REM create table nbs_agecomp as
REM select 
REM 'NBS' survey,
REM year SURVEY_YEAR, 
REM SPECIES_CODE,
REM subarea STRATUM,
REM sex,
REM age,
REM agepop,
REM meanlen MEAN_LENGTH,
REM SDEV STANDARD_DEVIATION
REM from agecomp
REM where subarea<>9999999
REM union
REM select 
REM 'NBS' survey,
REM year SURVEY_YEAR, 
REM SPECIES_CODE,
REM 999 STRATUM,
REM sex,
REM age,
REM agepop,
REM meanlen MEAN_LENGTH,
REM SDEV STANDARD_DEVIATION
REM from agecomp
REM where subarea=9999999
REM order by SPECIES_CODE,SURVEY_YEAR,stratum,sex,age;
REM ************************************************************************************************




REM ********************************************************************************************************************************************************
REM NEED TO CREATE TABLE STRATUM BEFORE THE NEXT STEP
drop table nbs_strata;
create table nbs_strata as
select 'NBS' survey,
       2021 year,
       stratum,
       area
from racebase.stratum 
where stratum in(70,71,81) and year=2022
ORDER BY STRATUM;

alter table nbs_strata
add description VARchar(80);

alter table nbs_strata
add domain char(40);

alter table nbs_strata
add DENSITY char(40);

UPDATE nbs_strata b
set description =
(select description
          from racebase.stratum a
          where year=2022
                and region='BS'
                and a.stratum=b.stratum);

update nbs_strata
set year = 2022;

alter table ebsshelf_strata
drop column DOMAIN;

alter table ebsshelf_strata
drop column DENSITY;
                
select * from nbs_strata;

REM ********************************************************************************************************************************************************


















REM *********************************************************************************************
REM ALL CODE BEYOND HERE SEEMS LIKE IT IT JUST FOR TESTING TO SEE IF THE DATA ARE CORRECT - WOULD HAVE TO ASK BOB.

                
select 'select distinct year from '||table_name||' order by year;' 
from user_tables 
where table_name
like '%';   

select distinct year from CATCH_nbs order by year;                                                                                                                   
select distinct year from CPUE_nbs_POS order by year;                                                                                                                
select distinct year from nbs_AGECOMP order by year;                                                                                                 
select distinct year from nbs_BIOMASS order by year;                                                                                                   
select distinct year from nbs_CPUE order by year;                                                                                                                    
select distinct year from nbs_SIZECOMP order by year;                                                                                                         
                                                                                                   
select distinct year from HAUL_nbs order by year;                                                                                                                    
select distinct year from LENGTH_nbs order by year;                                                                                                                  
select distinct year from SPECIES_CODES order by year;                                                                                                                    
select distinct year from SPECIMEN_nbs order by year;                                                                                                                
select distinct year from SURVEYS_nbs order by year;  

select year,stratum,avg(wgtcpue)
from nbs_cpue
where species_code=21740
group by year,stratum
order by year,stratum;

select year,stratum,stratum_biomass
from nbs_biomass
where stratum in(999)
and species_code=21720
order by year,stratum;

select year,species_code, count(*)
from nbs_cpue
where species_code In(21725,21720)
group by year,species_code
order by year;
REM *********************************************************************************************



REM  NOT SURE IF THIS IS USED???????????
drop table Performance_codes;
create table performance_codes as
select 
  HAUL_PERFORMANCE_CODE,SATISFACTORY_PERFORMANCE,b.HAUL_PERFORMANCE_NOTE_ID,note
from
  race_data.HAUL_PERFORMANCE_CODES a, race_data.HAUL_PERFORMANCE_NOTES b
where
  a.HAUL_PERFORMANCE_NOTE_ID=b.HAUL_PERFORMANCE_NOTE_ID
order by 
  HAUL_PERFORMANCE_CODE;
  
DROP TABLE CPUE_nbs_POS;



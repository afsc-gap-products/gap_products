REM  MAKE SURE ALL THE PLUSNW AND STANDARD AREA BIOMASS, SIZECOMP, AND AGECOMP SCRIPTS
REM   HAVE BEEN RUN ON YOUR USERCODE FIRST, SO THE APPROPRIATE TABLES ARE CREATED AND AVAILABLE
REM   ON YOUR USERCODE.

REM modified 9/16/2022 updated racebase.stratum YEAR = 2022 (areas), HAEHNR
REM modified 9/16/2022 removed dependency of LAUTHB.DATARPT_STRATANW table by creating new table framework, HAEHNR (see notes in code)
REM modified 9/16/2022 added in subarea and depth region area values, DES (see notes in code) 

set heading off
select 'drop table '||table_name||';' 
from user_tables 
where table_name
like '%';


drop table HAUL_ebsshelf;
drop view HAUL_ebsshelf;
create table HAUL_ebsshelf as
SELECT  
  to_number(to_char(a.start_time,'yyyy')) year,
  'EBS_SHELF' survey,
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
  AND A.STRATUM IN(10,20,31,32,41,42,43,50,61,62,82,90)
  AND B.SURVEY_DEFINITION_ID = 98;

drop table surveys_ebsshelf;
create table surveys_ebsshelf as
select distinct c.CRUISEJOIN,
'EBS_SHELF' survey,
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
from racebase.cruise c, HAUL_ebsshelf h
where c.cruisejoin=h.cruisejoin
and c.vessel=h.vessel
and c.cruise=h.cruise
and to_number(to_char(start_date,'yyyy'))=h.year
order by year;


drop table CATCH_ebsshelf;
create table CATCH_ebsshelf as
select YEAR,
'EBS_SHELF' survey,
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
from racebase.catch c, HAUL_ebsshelf h
where h.hauljoin=c.hauljoin;

drop table LENGTH_ebsshelf;
create table LENGTH_ebsshelf as
select 'EBS_SHELF' survey,
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
from racebase.LENGTH c, HAUL_ebsshelf h
where h.hauljoin=c.hauljoin;

drop table SPECIMEN_ebsshelf;
create table SPECIMEN_ebsshelf as
select 'EBS_SHELF' survey,
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
from racebase.SPECIMEN c, HAUL_ebsshelf h
where h.hauljoin=c.hauljoin;



drop table EBSSHELF_CPUE;
drop table EBSSHELF_CPUE;
create table EBSSHELF_CPUE as
select       'EBS_SHELF' survey,
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
          from CATCH_ebsshelf a, HAUL_ebsshelf c, racebase.species b
                       where a.year=c.year
                            and a.species_code=b.species_code
             ) a, 
             CATCH_ebsshelf b
where     a.hauljoin = b.hauljoin(+) and
          a.species_code=b.species_code(+);


drop table CPUE_EBSSHELF_POS;
create table CPUE_EBSSHELF_POS as
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
  EBSSHELF_CPUE a, 
  HAUL_ebsshelf b,
  racebase.species c
where
	a.hauljoin=b.hauljoin
  and a.species_code=c.species_code
order by
	a.year,
  a.vessel,
  a.haul,
  a.species_code;
  
  
drop table species_codes;
create table species_codes as
select * from racebase.species;

drop table ebsshelf_biomass_plusnw;
create table ebsshelf_biomass_plusnw as
select  'EBS_SHELF' survey,
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
from haehnr.biomass_ebs_plusnw
where species_code not in(400,10111,10260,10129,79000,78010); 

drop table ebsshelf_biomass_plusnw_groupd;
create table ebsshelf_biomass_plusnw_groupd as
select  'EBS_SHELF' survey,
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
from haehnr.biomass_ebs_plusnw_grouped;



drop table ebsshelf_biomass_standard;
create table ebsshelf_biomass_standard as
select  'EBS_SHELF' survey,
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
from haehnr.biomass_ebs_standard
where species_code not in(400,10111,10260,10129,79000,78010);

drop table ebsshelf_biomass_stand_grouped;
create table ebsshelf_biomass_stand_grouped as
select  'EBS_SHELF' survey,
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
from haehnr.biomass_ebs_standard_grouped;


drop table ebsshelf_sizecomp_plusnw;
create table ebsshelf_sizecomp_plusnw as
select  'EBS_SHELF' survey,
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
from haehnr.sizecomp_ebs_plusnw_stratum 
where 
  species_code not in(400,10111,10260,10129,79000,78010)
  and stratum<>999999
union
select  'EBS_SHELF' survey,
        year,
        species_code,
        species_name,
        common_name,
        999 STRATUM,
        LENGTH,
        MALES,
        FEMALES,
        UNSEXED,
        TOTAL
from haehnr.sizecomp_ebs_plusnw_stratum
where species_code not in(400,10111,10260,10129,79000,78010)
and stratum=999999
order by year,
        species_code,
        stratum,
        LENGTH;


drop table ebsshelf_sizecomp_plusnw_grp;
create table ebsshelf_sizecomp_plusnw_grp as
select  'EBS_SHELF' survey,
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
from haehnr.sizecomp_ebs_plusnw_stratum_grouped
where stratum<>999999
union
select  'EBS_SHELF' survey,
        year,
        species_code,
        species_name,
        common_name,
        999 STRATUM,
        LENGTH,
        MALES,
        FEMALES,
        UNSEXED,
        TOTAL
from haehnr.sizecomp_ebs_plusnw_stratum_grouped
where stratum=999999
order by year,
        species_code,
        stratum,
        LENGTH;

drop table ebsshelf_sizecomp_standard;
create table ebsshelf_sizecomp_standard as
select  'EBS_SHELF' survey,
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
from haehnr.sizecomp_ebs_standard_stratum
where stratum<>999999 and species_code not in(400,10111,10260,10129,79000,78010)
union
select  'EBS_SHELF' survey,
        year,
        species_code,
        species_name,
        common_name,
        999 STRATUM,
        LENGTH,
        MALES,
        FEMALES,
        UNSEXED,
        TOTAL
from haehnr.sizecomp_ebs_standard_stratum
where stratum=999999 and species_code not in(400,10111,10260,10129,79000,78010)
order by year,
        species_code,
        stratum,
        LENGTH;


drop table ebsshelf_sizecomp_stand_grp;
create table ebsshelf_sizecomp_stand_grp as
select  'EBS_SHELF' survey,
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
from haehnr.sizecomp_ebs_standard_stratum_grouped
where stratum<>999999
union
select  'EBS_SHELF' survey,
        year,
        species_code,
        species_name,
        common_name,
        999 STRATUM,
        LENGTH,
        MALES,
        FEMALES,
        UNSEXED,
        TOTAL
from haehnr.sizecomp_ebs_standard_stratum_grouped
where stratum=999999
order by year,
        species_code,
        stratum,
        LENGTH;
        




drop table ebsshelf_agecmp_plusnw;
create table ebsshelf_agecmp_plusnw as
select 
  species_code,
  year,'EBS_SHELF' survey,
  STRATUM,
  sex,
  age,
  agepop,
  meanlen,sdev 
from haehnr.agecomp_ebs_plusnw_stratum;

drop table ebsshelf_agecomp_plusnw;
create table ebsshelf_agecomp_plusnw as
select 
'EBS_SHELF' survey,
year SURVEY_YEAR, 
SPECIES_CODE,
STRATUM,
sex,
age,
agepop,
meanlen MEAN_LENGTH,
SDEV STANDARD_DEVIATION
from haehnr.agecomp_ebs_plusnw_stratum
where stratum<>9999999
union
select 
'EBS_SHELF' survey,
year SURVEY_YEAR, 
SPECIES_CODE,
999 STRATUM,
sex,
age,
agepop,
meanlen MEAN_LENGTH,
SDEV STANDARD_DEVIATION
from haehnr.agecomp_ebs_plusnw_stratum
where stratum=9999999
order by SPECIES_CODE,SURVEY_YEAR,stratum,sex,age;


drop table ebsshelf_agecomp_standard;
create table ebsshelf_agecomp_standard as
select 
'EBS_SHELF' survey,
year SURVEY_YEAR, 
SPECIES_CODE,
STRATUM,
sex,
age,
agepop,
meanlen MEAN_LENGTH,
SDEV STANDARD_DEVIATION
from haehnr.agecomp_ebs_standard_stratum
where stratum<>9999999
union
select 
'EBS_SHELF' survey,
year SURVEY_YEAR, 
SPECIES_CODE,
999 STRATUM,
sex,
age,
agepop,
meanlen MEAN_LENGTH,
SDEV STANDARD_DEVIATION
from haehnr.agecomp_ebs_standard_stratum
where stratum=9999999
order by SPECIES_CODE,SURVEY_YEAR,stratum,sex,age;


/*/////////////////*/
rem new code 9/16/22, HAEHNR

drop table ebsshelf_strata;
create table ebsshelf_strata as select * from racebase.stratum where 1=2;
 
alter table ebsshelf_strata modify area number(15,8); REM NEED TO INCREASE THE NUMBER OF DIGITS FOR "AREA" TO ACCOMODATE THE SUMMED AREA

insert into ebsshelf_strata select * from racebase.stratum 
   where region='BS' and year=2022 and stratum in (10,20,31,32,41,42,43,50,61,62,82,90);

insert into ebsshelf_strata 
   select 
    region, year, '999' stratum, null portion, 
    sum(area) area, 'Sum of strata 10,20,31,32,41,42,43,50,61,62,82,90' description, null auditjoin 
  from ebsshelf_strata group by region, year;
  
insert into ebsshelf_strata
    select
    region, year, 1, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;
    
insert into ebsshelf_strata
    select
    region, year, 2, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;

insert into ebsshelf_strata
    select
    region, year, 3, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;

insert into ebsshelf_strata
    select
    region, year, 4, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;
    
insert into ebsshelf_strata
    select
    region, year, 5, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;

insert into ebsshelf_strata
    select
    region, year, 6, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;
    
insert into ebsshelf_strata
    select
    region, year, 8, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;
    
insert into ebsshelf_strata
    select
    region, year, 9, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;
    
insert into ebsshelf_strata
    select
    region, year, 100, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;
    
insert into ebsshelf_strata
    select
    region, year, 200, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;

insert into ebsshelf_strata
    select
    region, year, 300, null portion, null area, null description, null audtijoin 
    from ebsshelf_strata group by region, year;
        

/*///////////////*/

alter table ebsshelf_strata
add domain char(40);

alter table ebsshelf_strata
add DENSITY char(40);
            
select * from ebsshelf_strata;

/*//////////////////*/
rem new code DES (Sept 2022)

update ebsshelf_strata
set year = 2022;
UPDATE ebsshelf_strata
set description = '=stratum 10'
          where year=2022
                and stratum=1;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 10)
where stratum = 1;

UPDATE ebsshelf_strata
set description = '=stratum 20'
          where year=2022
                and stratum=2;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 20)
where stratum = 2;

UPDATE ebsshelf_strata
set description = '=strata 31, 32 combined'
          where year=2022
                and stratum=3;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 31) + 
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 32)
where stratum = 3;          

UPDATE ebsshelf_strata
set description = '=strata 41, 42, 43 combined'
          where year=2022
                and stratum=4;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 41) + 
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 42) + 
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 43)
where stratum = 4;         

UPDATE ebsshelf_strata
set description = '=stratum 50'
          where year=2022
                and stratum=5;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 50)
where stratum = 5;

UPDATE ebsshelf_strata
set description = '=strata 61, 62 combined'
          where year=2022
                and stratum=6;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 61) + 
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 62)
where stratum = 6;

UPDATE ebsshelf_strata
set description = '=stratum 82'
          where year=2022
                and stratum=8;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 82)
where stratum = 8;

UPDATE ebsshelf_strata
set description = '=stratum 90'
          where year=2022
                and stratum=9;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 90)
where stratum = 9; 

UPDATE ebsshelf_strata
set description = 'Depth zone<50 m, i.e., all inner domain strata combined'
          where year=2022
                and stratum=100;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 10) + 
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 20)
where stratum = 100;   

UPDATE ebsshelf_strata
set description = 'Depth zone 50-100 m, i.e., all middle domain strata combined'
          where year=2022
                and stratum=200;
UPDATE ebsshelf_strata
set description = 'Depth zone 50-100 m, i.e., all middle domain strata combined'
          where year=2022
                and stratum=200;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 31) + 
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 32) +
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 41) +
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 42) +
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 43) +
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 82)
where stratum = 200;               

             
UPDATE ebsshelf_strata
set description = 'Depth zone 100-200 m, i.e., all outer domain strata combined'
          where year=2022
                and stratum=300;
UPDATE ebsshelf_strata
set area = (SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 50) + 
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 61) +
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 62) +
(SELECT area from racebase.stratum
where year = 2022
and region = 'BS'
and stratum = 90)
where stratum = 300;  

alter table ebsshelf_strata
drop column AUDITJOIN;

alter table ebsshelf_strata
drop column PORTION;

select * from ebsshelf_strata;

/*/////////////////////////////////*/

                
-------------------------------------------------------------------------------------------------------------------
REM I ASSUME BOB HAS USED THE FOLLOWING SELECT COMMANDS TO JUST MAKE SURE ALL THE TABLES WERE POPULATED FULLY WITH ALL YEARS
select distinct year from CATCH_EBSSHELF order by year;                                                                                                                   
select distinct year from CPUE_EBSSHELF_POS order by year;                                                                                                                
select distinct survey_year from EBSSHELF_AGECOMP_PLUSNW order by survey_year;                                                                                                           
select distinct survey_year from EBSSHELF_AGECOMP_PLUSNW order by survey_year;                                                                                                          
select distinct survey_year from EBSSHELF_AGECOMP_STANDARD order by survey_year;                                                                                                        
select distinct year from EBSSHELF_BIOMASS_PLUSNW order by year;                                                                                                          
select distinct year from EBSSHELF_BIOMASS_PLUSNW_GROUPD order by year;                                                                                                   
select distinct year from EBSSHELF_BIOMASS_STANDARD order by year;                                                                                                        
select distinct year from EBSSHELF_BIOMASS_STAND_GROUPED order by year;                                                                                                   
select distinct year from EBSSHELF_CPUE order by year;                                                                                                                    
select distinct year from EBSSHELF_SIZECOMP_PLUSNW order by year;                                                                                                         
select distinct year from EBSSHELF_SIZECOMP_PLUSNW_GRP order by year;                                                                                                     
select distinct year from EBSSHELF_SIZECOMP_STANDARD order by year;                                                                                                       
select distinct year from EBSSHELF_SIZECOMP_STAND_GRP order by year;                                                                                                      
select distinct year from HAUL_EBSSHELF order by year;                                                                                                                    
select distinct year from LENGTH_EBSSHELF order by year;                                                                                                                  
select distinct year from SPECIES_CODES order by year;                                                                                                                    
select distinct year from SPECIMEN_EBSSHELF order by year;                                                                                                                
select distinct year from SURVEYS_EBSSHELF order by year;  

select year,stratum,avg(wgtcpue)
from ebsshelf_cpue
where species_code=21740
group by year,stratum
order by year,stratum;

select year,stratum,stratum_biomass
from biomass_ebsshelf
where stratum in(999)
and species_code=21740
order by year,stratum;

select year,species_code, count(*)
from ebsshelf_cpue
where species_code In(21725,21720)
group by year,species_code
order by year;
-------------------------------------------------------------------------------------------------------------------



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
  
dROP TABLE CPUE_EBSSHELF_POS;





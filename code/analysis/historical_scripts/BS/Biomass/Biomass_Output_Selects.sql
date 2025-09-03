REM  MY ROUTINE WOULD BE TO INDIVIDUALLY RUN THESE BIOMASS SELECT STATEMENTS IN SQL-DEVELOPER, AND  EXPORT THEM INDIVIDUALLY AS
REM  FLAT FILES THAT CAN BE POSTED ON THE AKC-PUBLIC DRIVE.  IT WILL LIKELY EASIER TO EXPORT USING R WHERE ONE SCRIPT 
REM  COULD BE RUN TO EXPORT ALL OF THESE AT ONCE.  IT WOULD MAKE SENSE THEN TO ALSO MAKE INDIVIDUAL SPECIES FILES FOR THE FLATFISH INSTEAD
REM  OF MAKING ONE FILE FOR THE 10 SPECIES.


REM FOR ALL THE MAJOR FLATFISH SPECIES, EXPORT AS FLAT FILE: flatfish_biomass_ebs_plusnw.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(10110,10112,10115,10120,10130,10140,10210,10260,10261,10285)
order by a.species_code,a.year,stratum ;

REM FOR ALL THE MAJOR FLATFISH SPECIES, EXPORT AS FLAT FILE: flatfish_biomass_ebs_standard.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(10110,10112,10115,10120,10130,10140,10210,10260,10261,10285)
order by a.species_code, a.year,stratum ;

REM FOR ALL THE "OTHER FLATFISH" SPECIES, EXPORT AS FLAT FILE: otherflatfish_biomass_ebs_plusnw.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(10180,10200,10211,10212,10220,10262,10270)
order by a.species_code,a.year,stratum ;

REM FOR THE GROUPED FLATFISH PLUSNW AREA, A TABLE IS CREATED TO ADD IN THE COMMON NAMES. EXPORT AS: flatfish_biomass_ebs_pluswnw_grouped.xls
drop table flatfish_biomass_plusnw_group;
create table flatfish_biomass_plusnw_group as
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw_grouped a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(10111,10129)
order by a.species_code, a.year,stratum ;
update flatfish_biomass_plusnw_group set common_name='Arrowtooth flounder + Kamchatka flounder' 
where species_code=10111;
update flatfish_biomass_plusnw_group set common_name='Flathead sole + Bering flounder' 
where species_code=10129;
select * from flatfish_biomass_plusnw_group order by species_code, year, stratum;

REM FOR THE GROUPED FLATFISH, STANDARD AREA. EXPORT AS: flatfish_biomass_ebs_standard_grouped.xls
drop table flatfish_biomass_standard_group;
create table flatfish_biomass_standard_group as
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard_grouped a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(10111,10129)
order by a.species_code, a.year,stratum ;
update flatfish_biomass_standard_group set common_name='Arrowtooth flounder + Kamchatka flounder' 
where species_code=10111;
update flatfish_biomass_standard_group set common_name='Flathead sole + Bering flounder' 
where species_code=10129;
select * from flatfish_biomass_standard_group order by species_code, year, stratum;


REM EXPORT AS: foragefish_biomass_ebs_plusnw
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and
a.species_code in (20202,20203,20204,21110,21592,23000,23010,23020,23030,23041,23055,23060,23061,23071)
order by a.species_code, a.year,stratum ;

REM EXPORT AS: foragefish_biomass_ebs_standard
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and
a.species_code in (20202,20203,20204,21110,21592,23000,23010,23020,23030,23041,23055,23060,23061,23071)
order by a.species_code, a.year,stratum ;


REM  EXPORT AS: halibut_biomass_ebs_plusnw.xls 
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code=10120
order by a.year,stratum ;

REM  EXPORT AS: halibut_biomass_ebs_standard.xls 
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code=10120
order by a.year,stratum ;

REM  EXPORT AS: pcod_biomass_ebs_plusnw.xls 
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code=21720
order by a.year,stratum ;

REM  EXPORT AS: pcod_biomass_ebs_standard.xls 
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code=21720
order by a.year,stratum ;


REM  EXPORT AS: pollock_biomass_ebs_plusnw.xls 
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code=21740
order by a.year,stratum ;

REM  EXPORT AS: pollock_biomass_ebs_standard.xls 
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code=21740
order by a.year,stratum ;

REM  EXPORT AS: octopus_biomass_ebs_plusnw.xls  (OLAV DOES NOT NEED "GROUPED" OCTOPUS, SQUID, or SKATE TABLES)
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb, round(UPPERB,2) upperb, DEGREEFWGT, 
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT 
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(78010,78012,78020,78403,78454,78455) and stratum=999 
order by a.species_code, a.year;

REM  EXPORT AS: octopus_biomass_ebs_standard.xls (OLAV DOES NOT NEED "GROUPED" OCTOPUS, SQUID, or SKATE TABLES)
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb, round(UPPERB,2) upperb, DEGREEFWGT, 
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT 
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(78010,78012,78020,78403,78454,78455) and stratum=999 
order by a.species_code, a.year;

REM  EXPORT AS: squids_biomass_ebs_plusnw.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb, round(UPPERB,2) upperb, DEGREEFWGT, 
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT 
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(79020, 79210) and stratum=999 
order by a.species_code, a.year ;

REM  EXPORT AS: squids_biomass_ebs_standard.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb, round(UPPERB,2) upperb, DEGREEFWGT, 
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT 
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(79020, 79210) and stratum=999 
order by a.species_code, a.year ;


REM EXPORT AS: sculpins_biomass_ebs_plusnw.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(21420,21371,21370,21368,21347) 
order by a.species_code,a.year,stratum ;

REM EXPORT AS: sculpins_biomass_ebs_standard.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(21420,21371,21370,21368,21347) 
order by a.species_code,a.year,stratum ;


REM EXPORT AS: othersculpins_biomass_ebs_plusnw.xls
REM  FOR OTHER_SCULPINS JUST PROVIDE TOTAL SURVEY VALUES (STRATUM=999)
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT 
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code >= 21300 and a.species_code <=21447 and 
a.species_code not in (21420,21371,21370,21368,21347,21340)
 and stratum=999 
order by a.year ;


REM EXPORT AS: skates_biomass_ebs_plusnw.xls (OLAV DOES NOT NEED "GROUPED" OCTOPUS, SQUID, or SKATE TABLES)
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(420,435,440,455,471,472,480,490,495) 
order by a.species_code,a.year,stratum ;

REM EXPORT AS: skates_biomass_ebs_standard.xls (OLAV DOES NOT NEED "GROUPED" OCTOPUS, SQUID, or SKATE TABLES)
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_standard a, racebase.species b
where a.species_code=b.species_code and a.species_code in 
(420,435,440,455,471,472,480,490,495) 
order by a.species_code,a.year,stratum ;



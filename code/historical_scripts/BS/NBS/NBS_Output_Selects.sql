REM  EXPORT THESE SELECT STATEMENTS AS FLAT FILES AND THEN PLACE ON THE AKC-PUBLIC DRIVE ...HAEHN\NBS_SURVEY_ESTIMATES_2020\

REM modified 9/14/2022 updated sizecomp table name, HAEHNR


REM FIRST SELECT BIOMASS FOR ALL NBS SPECIES (BIOMASS BY STRATUM 70,71,81 & COMBINED STRATA 999 AND YEAR-2010,2017,2019,2020, ...)
REM  EXPORT TO FLATFILE: biomass_nbs.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_nbs_safe a, racebase.species b
where a.species_code=b.species_code 
order by a.species_code,a.year,stratum ;

REM  FOR NBS PCOD, EXPORT TO FLATFILE: biomass_nbs_pcod.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_nbs_safe a, racebase.species b
where a.species_code=b.species_code and a.species_code=21720 
order by a.species_code,a.year,stratum ;


REM  FOR NBS HALIBUT, EXPORT TO FLATFILE: biomass_nbs_halibut.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_nbs_safe a, racebase.species b
where a.species_code=b.species_code and a.species_code=10120 
order by a.species_code,a.year,stratum ;



REM NEED TO RUN BIOMASS FOR NBS "SCULPINS" FOR INGRID
REM  EXPORT TO FLATFILE: biomass_nbs_sculpins.xls
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_nbs_safe a, racebase.species b
where a.species_code=b.species_code and a.species_code in (21420,21371,21370,21368,21347)
order by a.species_code,a.year,stratum ;


REM NEED TO RUN BIOMASS FOR NBS "OTHER SCULPINS" FOR INGRID
REM  EXPORT TO FLATFILE: biomass_nbs_othersculpins.xls
REM  FOR OTHER_SCULPINS JUST PROVIDE TOTAL SURVEY VALUES (STRATUM=999)
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_nbs_safe a, racebase.species b
where a.species_code=b.species_code and a.species_code >= 21300 and a.species_code <=21447 and 
a.species_code not in (21420,21371,21370,21368,21347)
 and stratum=999 
order by a.species_code,a.year,stratum ;


REM SELECT NBS SIZECOMPS (DO FOR ALL SPECIES WITH LENGTHS BY STRATUM 70,71,81 & COMBINED STRATA 999999 AND YEAR-2010,2017,2019,2020, ...)
REM  EXPORT TO FLATFILE: sizecomp_nbs.xls
select * from sizecomp_nbs_stratum order by species_code, year, stratum, length;

REM NOW FOR PCOD AND HALIBUT FOR GRANT THOMPSON AND IPHC (EXPORT TO: sizecomp_nbs_pcod.xls; sizecomp_nbs_halibut.xls)
select * from sizecomp_nbs_stratum where species_code=21720 order by year, stratum, length;
select * from sizecomp_nbs_stratum where species_code=10120 order by year, stratum, length;



REM SELECT CPUES BY STATION for NBS (DO FOR ALL SPECIES)
REM  EXPORT TO FLATFILE: cpue_nbs.xls
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_nbs 
order by species_code, year, vessel, haul;


REM NOW FOR PCOD AND HALIBUT FOR GRANT THOMPSON AND IPHC (EXPORT TO: cpue_nbs_pcod.xls; cpue_nbs_halibut.xls)
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_nbs where species_code=21720 
order by year, vessel, haul;

select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha  
from cpue_nbs where species_code=10120 
order by year, vessel, haul;


REM SELECT AGECOMPS FOR NBS
REM  EXPORT TO FLATFILE: agecomp_nbs.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_nbs_stratum order by species_code, year, stratum, sex, age;



REM SELECT SAMPLESIZE FOR NBS
REM  EXPORT TO FLATFILE: samplesize_nbs.xls
select species_code, year, total_hauls, hauls_w_length, num_lengths, hauls_w_otoliths, 
hauls_w_ages, num_otoliths, num_ages
 from samplesize_nbs order by species_code, year;

REM SELECT TEMPERATURE DATA FOR NBS
REM  EXPORT TO FLATFILE: bttemp_nbs.xls
select * from bttemp_nbs order by year;








REM OUPUT FLATFISH CPUE
REM  IF DOWNLOADING THE FLATFISH_CPUE USING SQL DEVELOPER, DOWNLOAD FILE AS A CSV (NOT XLS). THE XLS OPTION IS LIMITED TO 60,000 ROWS
REM    AND BECAUSE THIS FILE IS LARGE, ALL THE DATA WILL NOT DOWNLOAD
REM  EXPORT AS FLAT FILE: flatfish_cpue_ebs_plusnw.csv
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw
where species_code in 
(10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10262,10270,10285)
order by species_code, year, vessel, haul;

REM OUTPUT RS + NRS CPUE
REM  EXPORT AS FLAT FILE: nrs_cpue_ebs_plusnw.xls
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw 
where species_code in (10260, 10261)
order by species_code, year, vessel, haul;

REM OUTPUT HALIBUT
REM  EXPORT AS FLAT FILE: halibut_cpue_ebs_plusnw.xls
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw 
where species_code =10120
order by species_code, year, vessel, haul;

REM OUTPUT SKATE CPUE
REM  ***DOWNLOAD AS CSV INSTEAD OF XLS DUE TO THE LINE LIMIT***
REM  EXPORT AS FLAT FILE: skates_cpue_ebs_plusnw.csv
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw 
where species_code in (420,435,440,455,471,472,480,490,495)
order by species_code, year, vessel, haul;

REM OUTPUT SCULPIN CPUE
REM  ***DOWNLOAD AS CSV INSTEAD OF XLS DUE TO THE LINE LIMIT***
REM  EXPORT AS FLAT FILE: sculpins_cpue_ebs_plusnw.csv
select a.species_code, b.common_name, b.species_name, 
a.year, a.vessel,a.haul,stratum,stationid,latitude,longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw a, racebase.species b 
where a.species_code=b.species_code and a.species_code in 
(21420,21371,21370,21368,21347) 
order by a.species_code, year, vessel, haul;

REM OUTPUT GROUPED ATF-KAMCHATKA CPUE
REM  EXPORT AS FLAT FILE: atfkam_cpue_ebs_plusnw_grouped.xls
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw_grouped 
where species_code =10111 
order by species_code, year, vessel, haul;

REM OUTPUT GROUPED FHS-BERING FLOUNDER CPUE
REM  EXPORT AS FLAT FILE: fhsberingfl_cpue_ebs_plusnw_grouped.xls
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw_grouped 
where species_code =10129 
order by species_code, year, vessel, haul;

REM OLAV DOES NOT WANT CPUE DATA FOR GROUPED SPECIES
REM OUTPUT OCTOPUS AND SQUIDS BY INDIVIDUAL SPECIES CPUE (NOT GROUPED)
REM  ***DOWNLOAD AS CSV INSTEAD OF XLS DUE TO THE LINE LIMIT***
REM  EXPORT AS FLAT FILE: cephalapods_cpue_ebs_plusnw.csv
select species_code, common_name, species_name, 
year, vessel,haul,stratum,stationid,latitude,longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw 
where species_code >=78000 and species_code<80000 
order by species_code, year, vessel, haul;

REM OUTPUT PCOD CPUE
REM  EXPORT AS FLAT FILE: pcod_cpue_ebs_plusnw.xls
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw 
where species_code =21720
order by species_code, year, vessel, haul;

REM OUTPUT POLLOCK CPUE
REM  EXPORT AS FLAT FILE: pollock_cpue_ebs_plusnw.xls
select species_code, species_name, common_name, 
year, vessel, haul, stratum, stationid, latitude, longitude,
cpue_kgha,cpue_noha, area_fished_ha 
from cpue_ebs_plusnw 
where species_code =21740
order by species_code, year, vessel, haul;

REM OUTPUT YFS AVERAGE CPUE BY YEAR FOR PLUSNW AREA - FOR INGRID
REM  RUN  avg_annual_cpue_for_yfs_plusnw_FOR_INGRID.sql
REM    USE THE FINAL SELECT IN THE ABOVE SCRIPT TO EXPORT AS FLAT FILE: yfs_avg_cpue_by_year_plusnw.xls

REM OUTPUT YFS AVERAGE CPUE BY YEAR FOR STANDARD AREA - FOR INGRID
REM  RUN  avg_annual_cpue_for_yfs_standard_FOR_INGRID.sql
REM    USE THE FINAL SELECT IN THE ABOVE SCRIPT TO EXPORT AS FLAT FILE: yfs_avg_cpue_by_year_standard.xls


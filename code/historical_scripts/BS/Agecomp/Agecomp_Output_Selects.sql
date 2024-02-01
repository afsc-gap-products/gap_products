REM DO FOR ALL SPECIES - PLUSNW AREA
REM  EXPORT TO FLATFILE: agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum order by species_code, year, stratum, sex, age;


REM DO FOR ALL SPECIES - STANDARD AREA
REM  EXPORT TO FLATFILE: agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum order by species_code, year, stratum, sex, age;


 REM  NOW DO FOR INDIVIDUAL SPECIES

REM EXPORT TO FLATFILE: akplaice_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=10285 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: akplaice_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=10285 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: akskate_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=471 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: akskate_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=471 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: atf_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=10110 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: atf_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=10110 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: beringfl_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=10140 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: beringfl_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=10140 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: bigmouth_sculpin_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=21420 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: bigmouth_sculpin_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=21420 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: fhs_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=10130 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: fhs_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=10130 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: great_sculpin_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=21370 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: great_sculpin_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=21370 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: gtr_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=10115 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: gtr_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=10115 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: kam_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=10112 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: kam_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=10112 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: nrs_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code in (10260, 10261) 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: nrs_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code in (10260, 10261) 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: plain_sculpin_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=21371 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: plain_sculpin_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=21371 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: warty_sculpin_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=21368 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: warty_sculpin_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=21368 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: yfs_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=10210 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: yfs_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=10210 
order by species_code, year, stratum, sex, age;


REM EXPORT TO FLATFILE: yil_agecomp_plusnw.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_plusnw_stratum 
  where species_code=21347 
order by species_code, year, stratum, sex, age;

REM EXPORT TO FLATFILE: yil_agecomp_standard.xls
select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum 
  where species_code=21347 
order by species_code, year, stratum, sex, age;


REM 1) NOTE THAT CAITLIN AND STAN WILL LIKELY BE RUNNING THE AGECOMPS FOR WALLEYE POLLOCK AND WILL BE RUNNING A DIFFERENT SCHEME FOR
REM     AN AGE-LENGTH KEY THAN WHAT IS RUN IN THE STANDARD AGECOMP SCRIPTS RUN HERE.

REM 2) YOU WILL BE RUNNING A SEPARATE AGECOMP SCRIPT FOR P.COD BECAUSE GRANT ALSO WANTS A SPECIFIC AGE-LENGTH KEY SCHEME.
REM VERSION 11/09/2015
/* THIS VERSION UPDATES SPECIMEN RECORDS THAT WERE TAKEN IN MM INTERVALS */
/* TO THE NEAREST 10MM TO MATCH THE SIZECOMP LENGTHS */

REM ***NEED TO RUN SIZECOMP_STANDARD_YR_STRATUM.SQL BEFORE RUNNING THIS SCRIPT***

REM  THIS SECTION GETS THE PROPER HAUL TABLE
REM ***THIS GRABS THE MOST UP-TO-DATE CRUISEJOINS***
REM  THIS DOES ALLOW FOR THE INCLUSION OF OTOLITHS COLLECTED AT STATIONS 
REM   WHERE THE PERFORMANCE WAS NEGATIVE BUT WAS AT A STANDARD + NW STATIONS

REM  OUTPUT CODES:
REM   SEX=9 ALL SEXES COMBINED
REM   AGE=-9 INDICATES UNAGED LENGTHS FOR A PARTUCULAR SEX (I.E., NO OTOLITH COLLECTED FOR THAT SEX/LENGTH)
REM   AGE=-99 INDICATES A CASE WHERE NO LENGTHS WERE COLLECTED WITHIN A STRATUM FOR A SPECIES/YEAR EVEN THOUGH CATCH 
REM      NUMBERS EXISTED. THESE UNASSIGNED POPULATION NUMBERS ARE HENCE ASSIGNED TO AGE=-99.

drop  table haulname; 
drop  view haulname; 
create table haulname as 
SELECT  to_number(to_char(a.start_time,'yyyy')) year,A.*
FROM RACEBASE.HAUL A
JOIN RACE_DATA.V_CRUISES B
ON (B.CRUISEJOIN = A.CRUISEJOIN)
WHERE A.HAUL_TYPE = 3
AND A.STATIONID IS NOT NULL
AND A.STRATUM IN (10,20,31,32,41,42,43,50,61,62)
AND B.SURVEY_DEFINITION_ID = 98;

REM ***NOW GRAB THE SPECIMEN DATA

drop table tempspec;
drop view tempspec;
create table tempspec as 
select s.species_code, h.year, 
s.cruisejoin, s.hauljoin, s.region, s.vessel, s.cruise, s.haul, s.specimenid, s.length, s.sex, s.weight, s.age 
from racebase.specimen s, haulname h 
where s.hauljoin=h.hauljoin and s.age>=0;

update tempspec set length=round(length/10,0)*10;


REM ***THIS SECTION MAKES A TABLE OF ALL LENGTHS IN THE SIZECOMP, BUT LIMITED TO THE SPECIES AND YEARS***
REM ***IN WHICH AGES WERE COLLECTED***

drop table lenlist;
drop view lenlist;
create table lenlist as
select distinct species_code, year, length from sizecomp_ebs_standard_stratum ;

REM THIS MAKES A LIST OF THE SPECIES AND YEARS IN WHICH AGES WERE COLLECTED
drop table speclist;
drop view speclist;
create table speclist as select distinct s.species_code, year from racebase.specimen s, haulname h where 
s.hauljoin=h.hauljoin and s.age>=0;

drop table lenlist2;
drop view lenlist2;
create table lenlist2 as
select l.species_code, l.year, length from lenlist l, speclist s where l.species_code=s.species_code and 
l.year=s.year ;


/*  THESE VIEWS COUNTS THE RECORDS BY SEX FROM THE SPECIMEN TABLE */

drop table totm;
drop view totm;
create table totm as
select species_code, year,
length, sex, age, count(*) num from tempspec where sex=1
group by species_code, year, length, sex, age;

drop table totf;
drop view totf;
create table totf as
select species_code, year,
length, sex, age, count(*) num from tempspec where sex=2
group by species_code, year, length, sex, age;

drop table totu;
drop view totu;
create table totu as
select species_code, year,
length, 3 sex, age, count(*) num from tempspec where sex in (1,2,3) 
group by species_code, year, length, sex, age;


/* THE UNSEXED FISH ARE AGED FROM ALL AVAILABLE AGE DATA SO THIS */
/* VIEW COMPILES THAT DATA */

drop table totu2;
drop view totu2;
create table totu2 as
select species_code, year, length, sex, age, sum(num) num from totu 
group by species_code, year, length, sex, age;


/* THESE TABLES ADD A SPECIMEN RECORD OF AGE -9 FOR ALL MALES */
/* OF LENGTHS IN THE SIZECOMP BUT NOT IN THE SPECIMEN TABLE */

drop table fillupm;
drop view fillupm;
create table fillupm as
select l.species_code, l.year, l.length, 1 sex, -9  age, 1 num from lenlist2 l, totm s
where l.species_code=s.species_code(+) and l.year=s.year(+) and l.length=s.length(+) and
s.length is null
union
select s.species_code, s.year, s.length, s.sex, s.age, num
from lenlist2 l, totm s
where l.species_code=s.species_code and l.year=s.year and l.length=s.length
and s.sex=1;


/* SAME FOR FEMALES */

drop table fillupf;
drop view fillupf;
create table fillupf as
select l.species_code, l.year, l.length, 2 sex, -9  age, 1 num from lenlist2 l, totf s
where l.species_code=s.species_code(+) and l.year=s.year(+) and l.length=s.length(+) and
s.length is null
union
select s.species_code, s.year, s.length, s.sex, s.age, num
from lenlist2 l, totf s
where l.species_code=s.species_code and l.year=s.year and l.length=s.length
and s.sex=2;

/* SAME FOR UNSEXED */

drop table fillupu;
drop view fillupu;
create table fillupu as
select l.species_code, l.year, l.length, 3 sex, -9  age, 1 num from lenlist2 l,totu2 s
where l.species_code=s.species_code(+) and l.year=s.year(+) and l.length=s.length(+) and
s.length is null
union
select s.species_code, s.year, s.length, s.sex, s.age, num
from lenlist2 l, totu2 s
where l.species_code=s.species_code and l.year=s.year and l.length=s.length
and s.sex=3;


/* NOW SUM UP THE AGE BY LENGTH RECORDS FOR EACH SEX */

drop table totmcount;
drop view totmcount;
create table totmcount as
select species_code, year, length, sex, sum(num) totlen from fillupm group by species_code, year, length, sex;

drop table totfcount;
drop view totfcount;
create table totfcount as
select species_code, year, length,sex,sum(num) totlen from fillupf group by species_code, year, length, sex;

drop table totucount;
drop view totucount;
create table totucount as
select species_code, year, length,sex,sum(num) totlen from fillupu group by species_code, year, length,sex;

/* NOW FIND THE RATIO OF NUMBER AT AGE VERSUS THE TOTAL NUMBER */

drop table ratioma;
drop view ratioma;
create table ratioma as
select f.species_code, f.year, f.length, f.sex, f.age, (num/decode(totlen,0,1,totlen)) ratm 
from fillupm f, totmcount t where f.species_code=t.species_code and f.year=t.year and f.length=t.length and f.sex=t.sex;

drop table ratiofe;
drop view ratiofe;
create table ratiofe as
select f.species_code, f.year, f.length, f.sex, f.age, (num/decode(totlen,0,1,totlen)) ratf 
from fillupf f, totfcount t where f.species_code=t.species_code and f.year=t.year and f.length=t.length and f.sex=t.sex;

drop table ratioun;
drop view ratioun;
create table ratioun as
select f.species_code, f.year, f.length, f.sex, f.age, (num/decode(totlen,0,1,totlen)) ratu 
from fillupu f, totucount t where f.species_code=t.species_code and f.year=t.year and f.length=t.length and f.sex=t.sex;





/*  NOW CALCULATE POPULATION AT AGE AND MEANLENGTH AND SDEV OF */
/*  MEAN LENGTH */

drop table agemale;
drop view agemale;
create table agemale as 
select sz.species_code, sz.year, stratum, sex, age, sum(ratm*males) agepop,
((sum(sz.length*ratm*males))/(decode(sum(ratm*males),0,1, 
sum(ratm*males)))) meanlen,
sqrt(trunc(((sum((ratm*males)*power(sz.length,2)))-(power(sum(ratm*males*sz.length),2))/
(decode(sum(ratm*males),0,1,sum(ratm*males))))/(decode(sum(ratm*males)-1,0,1,sum(ratm*males)-1)),8)) sdev
 from sizecomp_ebs_standard_stratum sz, ratioma r
where sz.species_code=r.species_code and sz.year=r.year and sz.length=r.length 
group by sz.species_code, sz.year, stratum, age, sex;

drop table agefemale;
drop view agefemale;
create table agefemale as 
select sz.species_code, sz.year, stratum, sex, age, sum(ratf*females) agepop,
((sum(sz.length*ratf*females))/(decode(sum(ratf*females),0,1, 
sum(ratf*females)))) meanlen,
sqrt(trunc(((sum((ratf*females)*power(sz.length,2)))-(power(sum(ratf*females*sz.length),2))/
(decode(sum(ratf*females),0,1,sum(ratf*females))))/(decode(sum(ratf*females)-1,0,1,sum(ratf*females)-1)),8)) sdev
 from sizecomp_ebs_standard_stratum sz, ratiofe r
where sz.species_code=r.species_code and sz.year=r.year and sz.length=r.length 
group by sz.species_code, sz.year, stratum, age, sex;

drop table ageunsex;
drop view ageunsex;
create table ageunsex as
select sz.species_code, sz.year, stratum, sex, age, sum(ratu*unsexed)unsexagepop,
((sum(sz.length*ratu*unsexed))/(decode(sum(ratu*unsexed),0,1,
sum(ratu*unsexed)))) meanlen,
sqrt(trunc((((sum((ratu*unsexed)*power(sz.length,2)))) -((power(sum(ratu*unsexed*sz.length),2))/
(decode(sum(ratu*unsexed),0,1,sum(ratu*unsexed)))))/((decode(sum(ratu*unsexed)-1,0,1,sum(ratu*unsexed))-1)),8)) sdev
 from sizecomp_ebs_standard_stratum sz, ratioun r
where sz.species_code=r.species_code and sz.year=r.year and sz.length=r.length 
group by sz.species_code, sz.year, stratum,age,sex;


/* NOW PREPARE FOR THE TOTAL OF ALL SEXES.  FIRST CALCULATE */
/* POPULATION AT LENGTH AND AGE FOR EACH SEX AND year, stratum */
drop table matest;
drop view matest;
create table matest as
select s.species_code, s.year, stratum, r.length, r.age, ratm*males pops 
 from ratioma r, sizecomp_ebs_standard_stratum s where s.species_code=r.species_code and s.year=r.year and r.length=s.length ;

drop table fetest;
drop view fetest;
create view fetest as
select s.species_code, s.year, stratum, r.length,r.age, ratf*females pops from
ratiofe r, sizecomp_ebs_standard_stratum s where s.species_code=r.species_code and s.year=r.year and r.length=s.length ;

drop table untest;
drop view untest;
create table untest as
select s.species_code, s.year, stratum, r.length,r.age, ratu*unsexed pops from
ratioun r, sizecomp_ebs_standard_stratum s where s.species_code=r.species_code and s.year=r.year and r.length=s.length ;

/* NOW COMBINE ALL THESE INTO ONE TABLE */
drop table alltest;
create table alltest as
select * from matest;

insert into alltest
select * from fetest;

insert into alltest
select * from untest;


/* NOW DO TOTAL POPULATION, MEAN LENGTH AND SDEV FOR ALL SEXES COMBINED */
drop table agetot;
drop view agetot;
create table agetot as
select species_code, year, stratum, 9 sex, age, sum(pops) totpop,
((sum(length*pops))/(decode(sum(pops),0,1,sum(pops)))) meanlen, 
sqrt(trunc((((sum((pops)*power(length,2)))) -((power(sum(pops*length),2))/(decode(sum(pops),0,1,
sum(pops)))))/((decode(sum(pops)-1,0,1,sum(pops))-1)),8)) sdev
 from alltest
group by species_code, year, stratum, age;


rem /* NOW COMBINE ALL SEXES AND ALL SEXES COMBINED INTO ONE TABLE */


drop table agecomp_ebs_standard_stratum;
create table agecomp_ebs_standard_stratum as
select * from agemale;

insert into agecomp_ebs_standard_stratum
select * from agefemale;

insert into agecomp_ebs_standard_stratum
select * from ageunsex;

insert into agecomp_ebs_standard_stratum
select * from agetot;

REM NEED TO SET MEAN LENGTH AND STANDARD DEVIATION TO NULL (INSTEAD OF ZERO) WHERE APPROPRIATE
update agecomp_ebs_standard_stratum set sdev=null where meanlen=0;
update agecomp_ebs_standard_stratum set meanlen=null where meanlen=0;


REM ********************************************************************************************************************************
REM  NOW ADD IN THE POPULATION NUMBERS THAT ARE UNACCOUNTED FOR DUE TO SPECIES/YEAR/STRATA WHERE THERE WERE NO LENGTHS TAKEN WITHIN 
REM   STRATA, YET THERE WERE CATCH NUMBERS. THESE ARE THE -9 LENGTHS IN THE SIZECOMP AND WILL BE DESIGNATED AS -99 AGES HERE.

drop table missing_age_pop;
create table missing_age_pop as 
select species_code, year, stratum, 9 sex, -99 age, total agepop, 0 meanlen, 0 sdev 
from sizecomp_ebs_standard_stratum where length=-9 order by 
species_code, year, stratum;
update missing_age_pop set meanlen=null;
update missing_age_pop set sdev=null;
insert into agecomp_ebs_standard_stratum select * from missing_age_pop;
REM ********************************************************************************************************************************


grant select on agecomp_ebs_standard_stratum to public;

select species_code, year, stratum, sex, age, round(agepop) agepop, 
round(meanlen,2) meanlen, round(sdev,2) sdev 
from agecomp_ebs_standard_stratum order by species_code, year, stratum, sex, age;

REM SCRIPT UPDATED BY NICHOL 11/09/2015 TO RUN FOR MULTIPLE SPECIES AND YEARS (1987-PRESENT)
REM  DURING WHICH THE SPECIES WAS MEASURED (E.G., ALASKA SKATE: YEARS >=2000).
REM THIS SCRIPT PRODUCES POPULATION NUMBERS AT LENGTH BY SPECIES_CODE, YEAR, STRATUM (10,20,31,32,41,42,43,50,61,62).
REM INCLUDES THE STANDARD + NW STRATA. ALSO UPDATED 2/12/2020 TO ASSEMBLE BY STRATUM INSTEAD OF SUBAREA

REM MODIFIED 9/9/2022 UPDATED RACEBASE.STRATUM YEAR = 2022 FOR STRATUM AREAS, HAEHN

REM ***NO FISHING POWER CORRECTIONS ARE APPLIED HERE***

REM  SEE SPECIES CODES LISTED IN BIOCATCH AND LENVIEW BELOW FOR THE SPECIES INCLUDED.


REM THE OUTPUT INCLUDES THE FOLLOWING COLUMNS:
REM   SPECIES_NAME
REM   SPECIES_CODE
REM   YEAR
REM   STRATUM
REM   LENGTH (length, mm)
REM   MALES (population number, males)
REM   FEMALES (population number, females)
REM   UNSEXED (population number, unsexed)
REM   TOTAL (population number, total)

REM  STRATUM 999999 DESIGNATES POPULATION AT LENGTH FOR ALL STRATA COMBINED FOR A SPECIES/YEAR.


/*  THIS SECTION GETS THE PROPER HAUL TABLE - USES UP-TO-DATE CRUISJOINS*/

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
AND A.STRATUM IN (10,20,31,32,41,42,43,50,61,62)
AND B.SURVEY_DEFINITION_ID = 98;


/*  FIRST WE GATHER THE CATCH AND LENGTH DATA TO MATCH */
/*  THE HAUL DATA */

drop view biocatch;
drop table biocatch;
create table biocatch as
select c.species_code, h.year, h.stratum, c.hauljoin, c.haul, c.weight, c.number_fish  
from racebase.catch c, haulname h
where c.region='BS' and c.hauljoin = h.hauljoin and c.species_code in 
(420, 435,471,472,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
21420,21371,21370,21368,21347,
21720,21740);


drop table lenview;
drop view lenview;
create table lenview as
select l.species_code, h.year, h.stratum, l.hauljoin, l.haul, sex, length, frequency 
from racebase.length l, haulname h 
where l.region='BS' and l.hauljoin=h.hauljoin and 
l.species_code in 
(420,435,471,472,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
21420,21371,21370,21368,21347,
21720,21740);

/* THIS SECTION CALCULATES CPUE'S.  THE FIRST PART GATHERS HAULS */
/* WHERE THE SPECIES WAS NOT CAUGHT AND GIVES THEM A CPUE OF ZERO */
/* THEN THE SECOND SECTION CALCULATES CPUES WHERE THE SPECIES WAS */
/* CAUGHT AND THEN ZEROS AND CPUES ARE COMBINED */

REM FIRST SET UP A ZEROS TABLE  
drop table temp1;
create table temp1 as select
year,stratum,hauljoin,haul from haulname;
drop table temp2;
create table temp2 as select species_code from biocatch group by species_code order by species_code;
drop table wholelistbio_zeros;
create table wholelistbio_zeros as select species_code, year, stratum, hauljoin, haul, 0 wgtcpue_zero, 0 numcpue_zero from temp1, temp2 
order by species_code, year, stratum ;

REM NOW CALC THE WGTCPUE & NUMCPUE WHERE THE SPECIES IS PRESENT IN A HAUL
drop table wholelistbio_present;
create table wholelistbio_present as
select species_code,h.year,h.stratum,h.hauljoin, h.haul,
(weight/((distance_fished*net_width)/10)) wgtcpue_present,
((number_fish)/((distance_fished*net_width)/10)) numcpue_present
from biocatch c, haulname h
where c.hauljoin=h.hauljoin;

REM NOW COMBINE THE CPUES ZEROS AND THOSE WHERE THE SPECIES WAS PRESENT
drop table wholelistbio;
drop view wholelistbio;
create table wholelistbio as select
z.species_code, z.year,z.stratum, z.hauljoin, z.haul, 
(wgtcpue_zero+wgtcpue_present) wgtcpue, (numcpue_zero+numcpue_present) numcpue 
from wholelistbio_zeros z, wholelistbio_present p 
where z.species_code=p.species_code(+) and z.year=p.year(+) and z.stratum=p.stratum(+) and z.hauljoin=p.hauljoin(+);

REM NOW CHANGE NULLS TO ZEROS FOR THE HAULS IN WHICH THE SPECIES WAS NOT PRESENT
REM  ***NEED TO BE CAREFUL HERE BECAUSE THERE MIGHT BE ACTUAL NULLS -E.G. WHERE THERE ARE WGTS BUT NO NUMBERS ***

update wholelistbio set numcpue=999999 where wgtcpue is not null and numcpue is null;
commit;
update wholelistbio set wgtcpue=0 where wgtcpue is null;
commit;
update wholelistbio set numcpue=0 where numcpue is null;
commit;
update wholelistbio set numcpue=null where numcpue=999999;
commit;


/* NOW WE NEED TO SEE HOW MUCH OF AN IMPACT EACH HAUL HAD BY CPUE AND */
/* THEREFORE HOW MUCH IT SHOULD HAVE ON SIZECOMP */

/* FIRST, THIS SECTION MAKES A LIST OF HAULS WHERE THE SPECIES */
/* OCCURS AT IN THE LENGTH VIEW, I.E. WHERE WAS IT MEASURED */

drop table lenlist;
drop view lenlist;
create table lenlist as 
select species_code, year, hauljoin from lenview group by species_code, year, hauljoin;


/* NOW, THIS SECTION CALCULATES THE SUM OF THE CPUE'S */
/* IN A STRATUM FOR HAULS WITH LF */

drop table strattot;
drop view strattot;
create table strattot as
select w.species_code, w.year, w.stratum, sum(numcpue) sumcpue from wholelistbio w, lenlist l
where w.species_code=l.species_code and w.year=l.year and w.hauljoin=l.hauljoin
group by w.species_code, w.year, w.stratum ;


/* THIS SECTION THEN CALCULATES THE RATIO OF EACH HAUL CPUE TO THE */
/* TOTAL STRATUM CPUE. THE HIGHER THE CPUE, THE HIGHER THE RATIO AND */
/* THE MORE EFFECT IT WILL HAVE ON THE OUTPUT SIZECOMP */

drop table cpueratio;
drop view cpueratio;
create table cpueratio as
select w.species_code, w.year, w.stratum, w.hauljoin, numcpue, numcpue/sumcpue cprat from
wholelistbio w, strattot s where 
w.species_code=s.species_code and w.year=s.year and w.stratum = s.stratum;




/*  -----------------THAT ENDS THIS SECTION TILL THE LAST ---------*/

/*  NOW WE START A NEW SECTION TO SEE WHAT PART EACH LENGTH BY SEX HAS */
/*  TO PLAY ON THE SIZECOMP */


/* FIRST, THIS SECTION SUMS THE LENGTHS TAKEN BY HAUL AND PUTS IT IN */
/* A VIEW CALLED TOT */

drop table tot;
drop view tot;
create table tot as
select species_code, year,l.hauljoin,
sum(frequency) totbyhaul
from lenview l 
group by species_code, year,l.hauljoin;


/*  NOW, THIS SECTION PUTS THE LENGTH DATA AND TOT VIEW TOGETHER */
/*  TO GET A RATIO OF FREQ TO TOTBYHAUL FOR EACH MALE LENGTH. */

drop table ratiomale;
drop view ratiomale;
create table ratiomale as
select l.species_code, l.year, t.hauljoin,
l.length, sex, frequency/totbyhaul ratiom from tot t, lenview l 
where t.species_code=l.species_code and t.year=l.year and 
sex=1 and t.hauljoin=l.hauljoin;

/* NOW FEMALES */
drop table ratiofemale;
drop view ratiofemale;
create table ratiofemale as
select l.species_code, l.year, t.hauljoin,
l.length, sex, frequency/totbyhaul ratiof from tot t, lenview l 
where t.species_code=l.species_code and t.year=l.year and 
sex=2 and t.hauljoin=l.hauljoin;

/* NOW UNSEXED */
drop table ratiounsex;
drop view ratiounsex;
create table ratiounsex as
select l.species_code, l.year, t.hauljoin,
l.length, sex, frequency/totbyhaul ratiou from tot t, lenview l 
where t.species_code=l.species_code and t.year=l.year and 
sex=3 and t.hauljoin=l.hauljoin;


/*  NEXT, WE MAKE A MASTER LIST OF EVERY HAUL, LENGTH PRESENT IN THE */
/*  LENGTH DATA */
drop table masterlen;
drop view masterlen;
create table masterlen as
select species_code, year, hauljoin, length from lenview
 group by species_code, year, hauljoin, length;




/*  NOW WE EXPAND THE RATIO DATA OUT TO INCLUDE THOSE HAULS, LENGTHS */
/*  WHERE THEY DIDN'T OCCUR - JUST LIKE CPUE DATA WE PICK UP THE ZEROES */

/*  START WITH MALES */
drop table addstratm;
drop view addstratm;
create table addstratm as
select l.species_code, l.year, l.hauljoin, l.length, 0.0 ratiom
from ratiomale m, masterlen l
where m.species_code(+)=l.species_code and m.year(+)=l.year and m.hauljoin(+)=l.hauljoin and
m.length(+) = l.length and m.hauljoin is NULL
union
select l.species_code, l.year, l.hauljoin, l.length, ratiom
from ratiomale m, masterlen l
where 
m.species_code=l.species_code and m.year=l.year and m.hauljoin=l.hauljoin and
m.length=l.length;

/*  NOW FEMALES */
drop table addstratf;
drop view addstratf;
create table addstratf as
select l.species_code, l.year, l.hauljoin, l.length, 0.0 ratiof
from ratiofemale f, masterlen l
where f.species_code(+)=l.species_code and f.year(+)=l.year and f.hauljoin(+)=l.hauljoin and
f.length(+)=l.length and f.hauljoin is NULL
union
select l.species_code, l.year, l.hauljoin, l.length, ratiof
from ratiofemale f, masterlen l
where 
f.species_code=l.species_code and f.year=l.year and f.hauljoin=l.hauljoin and
f.length=l.length;

/* THEN UNSEXED */
drop table addstratu;
drop view addstratu;
create table addstratu as
select l.species_code, l.year, l.hauljoin, l.length, 0.0 ratiou
from ratiounsex u, masterlen l
where u.species_code(+)=l.species_code and u.year(+)=l.year and u.hauljoin(+)=l.hauljoin and
u.length(+)=l.length and u.hauljoin is NULL
union
select l.species_code, l.year, l.hauljoin, l.length, ratiou
from ratiounsex u, masterlen l
where 
u.species_code=l.species_code and u.year=l.year and u.hauljoin=l.hauljoin and
u.length=l.length;


/*  NOW WE PUT ALL THE DATA FOR EACE SEX TOGETHER IN ONE BIG TABLE */

drop table totallen;
drop view totallen;
create table totallen as 
select l.species_code, l.year, l.hauljoin, l.length, ratiom, ratiof, ratiou, stratum 
from masterlen l, addstratm m, addstratf f, addstratu u,
haulname h where 
l.species_code=m.species_code and l.species_code=f.species_code and l.species_code=u.species_code and
l.year=m.year and l.year=f.year and l.year=u.year and 
l.hauljoin=m.hauljoin and l.hauljoin=f.hauljoin and l.hauljoin=u.hauljoin and l.hauljoin=h.hauljoin and
l.length=f.length and l.length=m.length and l.length=u.length;


/*  -----------THAT ENDS THE LENGTH PORTION TILL THE END -----*/

/*  NOW WE ESTIMATE THE POPULATION THAT WE WILL DISTRIBUTE INTO A */
/*  SIZE COMPOSTION BY STRATUM */
/*  AND TO A TOTAL */

/* FIRST, THIS SECTION CALCULATES THE MEAN CPUE IN A STRATUM USING */
/* ALL HAULS */


REM  ****THERE ARE NULL NUMCPUE, SO THIS NEXT SCRIPTS RUNS WITH A WARNING****
drop table stratavg;
drop view stratavg;
create table stratavg as
select species_code, year, stratum, avg(numcpue) avgcpue from wholelistbio group by species_code, year, 
stratum;



/* THEN, THIS SECTION CALCULATES THE POPULATION IN A STRATUM */
drop table poplist;
drop view poplist;
create table poplist as
select species_code,s.year,s.stratum, (avgcpue * area * 100) population
 from stratavg s, racebase.stratum a where 
s.stratum = a.stratum and a.region = 'BS' and a.year=2022;


/* FINALLY, WE HAVE ALL THE PIECES NECESSARY. */
/* THIS SECTION MULTIPLIES RATIO OF CPUES TIMES RATIO OF LENGTHS */
/* TIMES POPULATION AND SUMS OVER STRATUM FOR EACH LENGTH */

drop table temp_sizecomp;
drop view temp_sizecomp;
create table temp_sizecomp as
select r.species_code, r.year, p.stratum, r.length,
sum(cprat * ratiom * population) males,
sum(cprat * ratiof * population) females,
sum(cprat * ratiou * population) unsexed,
((sum(cprat*ratiom*population))+(sum(cprat*ratiof*population))+(sum(cprat*ratiou*population))) total
from totallen r, cpueratio c, poplist p where 
r.species_code=c.species_code and r.species_code=p.species_code and c.species_code=p.species_code and 
r.year=c.year and r.year=p.year and c.year=p.year and
r.hauljoin=c.hauljoin and r.stratum=p.stratum 
group by r.species_code, r.year, p.stratum, length;

REM ADD IN STRATUM 999999 WHICH SUMS POPULATION ACROSS STRATA
insert into  temp_sizecomp
select r.species_code, r.year, 999999 "STRATUM", r.length,
sum(cprat * ratiom * population) males,
sum(cprat * ratiof * population) females,
sum(cprat * ratiou * population) unsexed,
((sum(cprat*ratiom*population))+(sum(cprat*ratiof*population))+(sum(cprat*ratiou*population))) total
from totallen r, cpueratio c, poplist p where
r.species_code=c.species_code and r.species_code=p.species_code and c.species_code=p.species_code and 
r.year=c.year and r.year=p.year and c.year=p.year and  
r.hauljoin=c.hauljoin and r.stratum=p.stratum
group by r.species_code, r.year, length;

REM **********************************************************************************************************************************
REM THIS SECTION FINDS THE CASES (~105) IN WHICH CATCH NUMBERS EXISTED IN A STRATUM BUT NO LENGTHS WERE MEASURED,
REM  FOR SPECIES IN WHICH LENGTHS ARE COMMONLY MEASURED.
REM   WE NEED TO FIND THESE CASES BECAUSE THEY ACCOUNT FOR MISSING BIOMASS AND POPULATION NUMBERS IN THE SIZECOMP OUTPUTS
REM   AND THEY SHOULD BE ACCOUNTED FOR (AT LEAST AS -9 LENGTHS) WITHIN THE STRATA.

drop table temp_catch;
drop view temp_catch;
create table temp_catch as 
select c.species_code, h.year, h.stratum, sum(number_fish) num_fish from haulname h, racebase.catch c
where 
h.hauljoin=c.hauljoin and number_fish>0  and 
species_code in (420, 435,471,472,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
21420,21371,21370,21368,21347,
21720,21740)
group by c.species_code, h.year, h.stratum;

REM NEED TO DELETE THE CASES FOR YEARS IN WHICH A SPECIES WAS NOT MEASURED AT ALL
delete from temp_catch where species_code in (471, 21368, 21370, 21371, 21420) and year<2000;
delete from temp_catch where species_code=21347 and year<2003;
delete from temp_catch where species_code=10211 and year in (1984, 1994, 1995, 1996);
commit;

drop table temp_length;
drop view temp_length;
create table temp_length as select l.species_code, h.year, h.stratum, sum(frequency) num_lengths from haulname h, racebase.length l 
where h.hauljoin=l.hauljoin and frequency>0 
and species_code in (420, 435,471,472,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
21420,21371,21370,21368,21347,
21720,21740)
group by l.species_code, h.year, h.stratum;

drop table temp_catlen;
drop view temp_catlen;
create table temp_catlen as select 
c.species_code, c.year, c.stratum, num_fish, num_lengths from temp_catch c, temp_length l where 
c.species_code=l.species_code(+) and c.year=l.year(+) and c.stratum=l.stratum(+);

REM NOW SUM THE MISSING POPULATION NUMBERS BY SPECIES_CODE, YEAR, STRATUM
drop table missing_pop;
drop view missing_pop;
create table missing_pop as
select t.species_code, t.year, t.stratum, -9 length, 0 males, 0 females, 0 unsexed, sum(b.population) total 
 from biomass_ebs_standard b, temp_catlen t 
where b.species_code=t.species_code and b.year=t.year and b.stratum=t.stratum and num_lengths is null 
group by t.species_code, t.year, t.stratum
order by t.species_code, t.year, stratum;
drop table temp_catch;
drop table temp_length;
drop table temp_catlen;

REM NOW INSERT THE CASES ABOVE WHERE CATCH NUMBERS EXIST IN A STRATUM BUT NO LENGTHS WERE TAKEN FOR THAT YEAR/STRATUM/SPECIES: -9 LENGTHS
REM  FIRST FOR EACH STRATUM, THEN FOR COMBINED STRATUM (999999)
insert into temp_sizecomp select * from missing_pop;
REM NOW COMBINE MISSING POPS BY YEAR TO THE 999999 STRATUM
drop table missing_pop_combine;
create table missing_pop_combine as select species_code, year, sum(males) males, sum(females) females, sum(unsexed) unsexed, 
sum(total) total from missing_pop group by species_code, year;
insert into temp_sizecomp select species_code, year, 999999 STRATUM, -9 length, males, females, unsexed, 
total from missing_pop_combine order by species_code, year;
drop table missing_pop_combine;
REM ************************************************************************************************************************************

drop table sizecomp_ebs_standard_stratum;
create table sizecomp_ebs_standard_stratum as 
select a.species_code, b.species_name, common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from temp_sizecomp a, racebase.species b
where a.species_code=b.species_code order by b.species_code, year, stratum, length;


drop table temp_sizecomp;

grant select on sizecomp_ebs_standard_stratum to public;

select * from sizecomp_ebs_standard_stratum order by species_code, year, stratum, length;
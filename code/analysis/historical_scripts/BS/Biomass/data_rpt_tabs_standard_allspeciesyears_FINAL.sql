REM MODIFIED 11/10/2015 TO RUN FOR MULIPLES SPECIES AND MULTIPLE YEARS FOR STANDARD STRATA, NICHOL
REM MODIFIED 09/09/2022 UPDATED RACEBASE.STRATUM CALLS TO AREAS CALCULATED IN 2022, HAEHN

REM THINGS TO UPDATE:  
REM                    1) IF SPECIES ARE TO BE CHANGED, MAKE SURE ALL SPECIES LISTED ARE
REM                       THE SAME IN THE 3 LOCATIONS IN WHICH THEY OCCUR IN THIS SCRIPT

REM CALCULATES BIOMASS & POPULATION NUMBERS, CI'S, AND HAUL COUNTS BY STRATA(10,20,31,32,41,42,43,50,61,62),
REM  SUBAREA(1,2,3,4,5,6), DEPTH ZONE (100=<50M; 200=50-100; 300=100-200M), AND TOTAL SURVEY (999).
REM IF STRATA ARE NOT LISTED FOR A SPECIES/YEAR, THIS INDICATES THAT NO STATIONS WERE CONDUCTED IN THAT YEAR/STRATUM.

REM  BIOMASS AND POPULATION NUMBERS ARE CALCULATED HERE WITHOUT FISHING POWER CORRECTIONS (FPCs)

REM THE FOLLOWING COLUMNS OF DATA ARE CREATED
REM   SPECIES_CODE
REM   SPECIES_NAME
REM   COMMON_NAME
REM   YEAR
REM   STRATUM
REM   MEANWGTCPUE (kg/hectare)
REM   VARMNWGTCPUE
REM   BIOMASS (metric tons)
REM   VARBIO 
REM   LOWERB 
REM   UPPERB
REM   DEGREEFWGT
REM   MEANNUMCPUE
REM   VARMNNUMCPUE
REM   POPULATION (numbers)
REM   VARPOP
REM   LOWERP
REM   UPPERP
REM   DEGREEFNUM
REM   HAULCOUNT (no. hauls conducted in stratum)
REM   CATCOUNT (no. hauls with catch weights for the species)
REM   NUMCOUNT (no. hauls with catch numbers for the species)
REM   LENCOUNT (no. hauls with lengths for the species)




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
AND A.STRATUM IN (10,20,31,32,41,42,43,50,61,62)
AND B.SURVEY_DEFINITION_ID = 98;


/*  THIS SECTION GETS THE PROPER CATCH RECORDS FOR THE HAUL */
/*  TABLE */

drop view biocatch;
drop table biocatch;
create table biocatch as
select c.species_code,h.year, h.stratum,c.hauljoin,c.haul, c.weight,c.number_fish  
from racebase.catch c, haulname h
where c.region='BS' and c.hauljoin = h.hauljoin and species_code in 
(232,310,320,
420,435,440,455,471,472,
480,490,495,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
20202,20203,20204,21110,21592,23000,23010,23020,23030,23041,23055,23060,23061,23071,
21420,21371,21370,21368,21347,
21314,21315,21316,21329,21333,21340,21341,21346,21348,21352,21353,21354,21355,21356,21388,21390,21397,21405,21406,21438,21441,
21720,21725,21735,21740,
30050,30051,30052,30060,30150,30152,30420,30535,
78010,78012,78020,78403,78454,78455,
79020,79210,81742);




 /*   THIS TABLE GETS THE APPROPRIATE LENGTH RECORDS */
drop table biolength;
drop view biolength;
create table biolength as
select c.species_code,h.year, h.stratum,c.hauljoin,c.haul, sum(c.frequency) frequency
from racebase.length c,haulname h 
where c.hauljoin = h.hauljoin
and species_code in (232,310,320,
420,435,440,455,471,472,
480,490,495,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
20202,20203,20204,21110,21592,23000,23010,23020,23030,23041,23055,23060,23061,23071,
21420,21371,21370,21368,21347,
21314,21315,21316,21329,21333,21340,21341,21346,21348,21352,21353,21354,21355,21356,21388,21390,21397,21405,21406,21438,21441,
21720,21725,21735,21740,
30050,30051,30052,30060,30150,30152,30420,30535,
78010,78012,78020,78403,78454,78455,
79020,79210,81742) 
group by c.species_code,h.year,h.stratum,c.hauljoin,c.haul;

   
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

REM  THIS SECTION CREATES A TABLE OF THE MEAN CPUE FOR EACH STRATUM
REM  AND OF VARIANCE OF THE MEAN CPUE */

drop view stratlist;
drop table stratlist;
create table stratlist as
select species_code, year, stratum, avg(wgtcpue) meanwgtcpue, avg(numcpue) meannumcpue,
(variance(wgtcpue)/count(wgtcpue))varmnwgtcpue,
(variance(numcpue)/count(numcpue)) varmnnumcpue 
from wholelistbio 
group by species_code, year, stratum;


/* THIS SECTION CREATES A STRATA AREA FILE BASED ON RACEBASE.STRATUM WHERE YEAR=2010 AND */
/* SUMS THE AREAS FOR EACH                                                               */
/* 1) STRATUM (10,20,31,32,41,42,43,50,61,62,                                            */
/* 2) SUBAREA (1,2,3,4,5,6),                                                             */
/* 3) TOTAL AREA FOR THE STANDARD AREA (999 = sum of strata )                            */
/* 4) DEPTH ZONE 100 (< 50M), 200 (50-100M), AND 300 (100-200M)                          */

REM **FIRST CREATE A TABLE THAT COUNTS THE NUMBER OF STATIONS IN A STRATUM**
drop table stations;
create table stations as
select year, stratum, count(*) num_stations from haulname group by year, stratum order by year, stratum;


REM **NOW WE GET THE STRATA + STRATA AREAS THAT WERE EFFECTIVELY SAMPLED EACH YEAR (I.E., > 2 STATIONS PER STRATUM)**
/*STRATUM*/
drop table strata_standard_1;
drop view strata_standard_1;
create table strata_standard_1 as select  t.year, s.stratum, s.area from racebase.stratum s, stations t where 
s.region='BS' and s.year=2022 and s.stratum in (10,20,31,32,41,42,43,50,61,62)
and s.stratum=t.stratum and t.num_stations > 2 order by t.year, s.stratum;

/*SUBAREA*/
drop table strata_standard_2;
drop view strata_standard_2;
create table strata_standard_2 as select t.year, decode(s.stratum,10,1,20,2,31,3,32,3,
41,4,42,4,43,4,50,5,61,6,62,6,-9) stratum, 
sum(s.area) area from racebase.stratum s, stations t where s.region='BS' and s.year=2022
and s.stratum=t.stratum and t.num_stations > 2  
group by t.year, decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9)  
order by t.year, decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9);

/*TOTAL AREA*/
drop table strata_standard_3;
drop view strata_standard_3;
create table strata_standard_3 as select t.year, 
decode(s.stratum, 10,999,20,999,31,999,32,999,41,999,42,999,43,999,50,999,61,999,62,999,-9) stratum, 
sum(s.area) area from racebase.stratum s, stations t where s.region='BS' and s.year=2022 
and s.stratum=t.stratum and t.num_stations > 2 
group by t.year, decode(s.stratum,10,999,20,999,31,999,32,999,41,999,42,999,43,999,50,999,61,999,62,999,-9)
order by t.year, decode(s.stratum,10,999,20,999,31,999,32,999,41,999,42,999,43,999,50,999,61,999,62,999,-9);

/*DEPTH ZONE*/
drop table strata_standard_4;
drop view strata_standard_4;
create table strata_standard_4 as select t.year, decode(s.stratum, 10,100,20,100,31,200,32,200,
41,200,42,200,43,200,50,300,61,300,62,300,-9) stratum, 
sum(s.area) area from racebase.stratum s, stations t where s.region='BS' and s.year=2022 
 and s.stratum=t.stratum and t.num_stations > 2 
group by t.year, decode(s.stratum,10,100,20,100,31,200,32,200,41,200,42,200,43,200,50,300,61,300,62,300,-9)
order by t.year, decode(s.stratum,10,100,20,100,31,200,32,200,41,200,42,200,43,200,50,300,61,300,62,300,-9);

drop table strata_standard;
drop view strata_standard;
create table strata_standard as select year, stratum, area from racebase.stratum where 1=2;
alter table strata_standard modify area number (15,8);
insert into strata_standard select * from strata_standard_1;
insert into strata_standard select * from strata_standard_2;
insert into strata_standard select * from strata_standard_3;
insert into strata_standard select * from strata_standard_4;
delete from strata_standard where stratum=-9;
drop table strata_standard_1;
drop table strata_standard_2;
drop table strata_standard_3;
drop table strata_standard_4;


/* THIS SECTION COMBINES THE STRATUM NUMBERS WITH AREA AND */
/*  TOTAL AREA FOR A SUBAREA TO BE USED IN THE NEXT SCRIPT */

drop view totarea;
drop table totarea;
create table totarea as select year, stratum subarea, area totareas from strata_standard where stratum in 
(1,2,3,4,5,6);


drop view areamix;
drop table areamix;
create table areamix as
select r.year,stratum,area,totareas
 from strata_standard r,totarea t
 where r.year=t.year and subarea=decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
 50,5,61,6,62,6,-9)
order by r.year, stratum;


/* THIS SECTION DOES THE FIRST CALCULATION TO WEIGHTING THE */
/* VARIANCES BY AREA AND COMBINING INTO SUBAREAS */

drop view wtdvar;
drop table wtdvar;
create table wtdvar as
select s.species_code, s.year, s.stratum,  
(power(area/totareas,2)*varmnwgtcpue) vprodw,
(power(area/totareas,2)*varmnnumcpue) vprodn
from stratlist s, areamix a where
s.year=a.year and s.stratum=a.stratum
order by s.species_code, s.year, s.stratum;


/* THIS SECTION SUMS UP THE WEIGHTED VALUES FROM ABOVE INTO */
/* TOTALS BY SUBAREA */

drop view wtdvar2;
drop table wtdvar2;
create table wtdvar2 as
select species_code, year,
decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9) subarea, 
sum(vprodw) wtvarmnwgtcpue,
sum(vprodn) wtvarmnnumcpue from wtdvar
group by species_code, year, 
decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9)
order by species_code, year, decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9);


/* THIS SECTION CALCULATES THE VARIANCE OF BIOMASS AND POPULATION */
/* FOR EACH SUBAREA---DIVIDING BY 100 AND MULT. BY 10000 ARE DUE */
/* TO KM2 AND HA AND ALSO GETTING TO MT.*/

drop table biovar;
drop view biovar;
create table biovar as
select species_code, w.year,
w.subarea,(power(totareas,2)*wtvarmnwgtcpue/100) varbio,
(power(totareas,2)*wtvarmnnumcpue*10000) varpop from
wtdvar2 w, totarea t where w.year=t.year and w.subarea=t.subarea;

insert into biovar
select species_code, year, 
999999 "SUBAREA",sum(varbio) varbio,sum(varpop) varpop
from biovar group by species_code, year ;


/* THIS SECTION CREATES A TABLE TO WEIGHT THE CPUE ESTIMATE */
/* BY STRATUM AREA */
 
drop view prodlist;
drop table prodlist;
create table prodlist as
select s.species_code, s.year, s.stratum,
decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9) subarea,
(meanwgtcpue*area) prodw,
(meannumcpue * area) prodn, area
from stratlist s, racebase.stratum a
where s.stratum = a.stratum and a.region = 'BS' and a.year = 2022
order by s.species_code, s.year,  decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9) ;

drop table sumlist;
create table sumlist as select 
species_code, year,  
subarea "STRATUM", 
sum(prodw)/sum(area) meanwgtcpue,sum(prodn)/sum(area) meannumcpue
from prodlist
group by species_code, year, subarea
order by species_code, year, subarea;

insert into sumlist
select species_code, year, 
100 "STRATUM", 
sum(prodw)/sum(area) meanwgtcpue,sum(prodn)/sum(area) meannumcpue
from prodlist
where subarea in (1,2) group by species_code, year;

insert into sumlist
select species_code, year,
200 "STRATUM", 
sum(prodw)/sum(area) meanwgtcpue,sum(prodn)/sum(area) meannumcpue
from prodlist
where subarea in (3,4) group by species_code, year;

insert into sumlist
select species_code, year,
300 "STRATUM", 
sum(prodw)/sum(area) meanwgtcpue,sum(prodn)/sum(area) meannumcpue
from prodlist
where subarea in (5,6) group by species_code, year;

insert into sumlist
select species_code, year,
999 "STRATUM",sum(prodw)/sum(area) meanwgtcpue,
sum(prodn)/sum(area) meannumcpue
from prodlist group by species_code, year;

drop table sumlist2;
create table sumlist2 as
select species_code, year,
subarea "STRATUM",wtvarmnwgtcpue "VARMNWGTCPUE",wtvarmnnumcpue "VARMNNUMCPUE"
from wtdvar2;

alter table biovar add stratum number(3);
alter table biovar add area number(15,8);
update biovar set stratum=999 where subarea=999999;
update biovar set stratum=100 where subarea in (1,2);
update biovar set stratum=200 where subarea in (3,4);
update biovar set stratum=300 where subarea in (5,6);
update biovar b set b.area=(select s.area from strata_standard s where b.year=s.year and b.stratum=s.stratum);

drop view biovar2;
drop table biovar2;
create table biovar2 as select species_code, year, 
stratum, area, sum(varbio) varbio, 
sum(varpop) varpop from biovar group by species_code, year, stratum, area;

REM THIS ADDS IN THE DEPTH STRATA
insert into sumlist2
select species_code, year,
stratum,((varbio*100)/(power(area,2))) varmnwgtcpue, 
(varpop/(10000*(power(area,2)))) varmnnumcpue
from biovar2;

REM THIS ADDS IN MEANCPUE AND VARCPUE FOR SUBAREA (1,2,3,..6) AND GROUPED AREAS (100,200, ...999) 
REM  TO TABLE WITH STANDARD STRATA (10,20,31 ...62)
insert into stratlist
select a.species_code, a.year,
a.stratum, meanwgtcpue, meannumcpue,
varmnwgtcpue, varmnnumcpue
from sumlist a,sumlist2 b
where a.species_code=b.species_code and a.year=b.year and a.stratum=b.stratum;


/* THIS SECTION MAKES A LIST OF STRATUM, HAULCOUNT FOR EACH YEAR */

drop table hcount;
drop view hcount;
create table hcount as
select year, stratum, count(*) haulcount from haulname
group by year, stratum;

drop table hcountot;
drop view hcountot;
create table hcountot as
select year, (decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,-9)) stratum, count(*) haulcount 
from haulname group by year, stratum;

insert into hcount
select year, stratum, sum(haulcount) haulcount
from hcountot group by year,stratum;

insert into hcount
select year, 999 "STRATUM", sum(haulcount) haulcount
from hcountot group by year;

insert into hcount
select year, 100 "STRATUM", sum(haulcount) haulcount
from hcountot where stratum in (1,2) group by year;

insert into hcount
select year, 200 "STRATUM", sum(haulcount) haulcount
from hcountot where stratum in (3,4) group by year;

insert into hcount
select year, 300 "STRATUM", sum(haulcount) haulcount
from hcountot where stratum in (5,6) group by year;



/* THIS SECTION IS THE START OF CALCULATING THE EFFECTIVE DEGREES */
/* OF FREEDOM. */

drop table tot_towarea_bystrat;
create table tot_towarea_bystrat as 
select year, stratum, 
sum(((distance_fished*net_width)/10)) towarea_bystrat, count(hauljoin) counthj
from haulname
group by year, stratum; 

drop view fi;
drop table fi;
create table fi as
select a.year, a.stratum, 
((counthj*area/towarea_bystrat)*((counthj*area/towarea_bystrat)-counthj))/counthj fi
from areamix a, tot_towarea_bystrat b
where a.year=b.year and a.stratum=b.stratum;



REM VARBAREWGT AND VARBARENUM ARE SAMPLE VARIANCES
drop view varstrat;
drop table varstrat;
create table varstrat as
select species_code, year, stratum, decode(variance(wgtcpue),0,1,variance(wgtcpue))
 varbarewgt,decode(variance(numcpue),0,1,variance(numcpue))
  varbarenum from wholelistbio group by species_code, year, stratum;

REM *****NEED TO ADD THE NEXT LINE FOR THE CASE WHERE THE HAULCOUNT=1
REM *****THIS NEEDS TO BE DONE TO AVOID A ZERO DENOMINATOR.
UPDATE HCOUNT SET HAULCOUNT=2 WHERE HAULCOUNT=1;


drop table degree;
drop view degree;
create table degree as
select v.species_code, v.year, 
(decode(v.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,-9)) stratum,
((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum 
from fi f, hcount h, varstrat v 
where f.stratum=h.stratum and v.stratum=f.stratum and h.stratum=f.stratum and 
f.year=h.year and v.year=f.year and h.year=f.year 
group by v.species_code, v.year,
decode(v.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,-9);


REM THIS INSERTS STRATUM (1,31,32,...62) rows
insert into degree
select v.species_code, v.year, v.stratum,
((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum from
fi f, hcount h,varstrat v where f.stratum=h.stratum and 
v.stratum=f.stratum and f.year=h.year and v.year=f.year group by v.species_code, v.year, v.stratum;

insert into degree
select v.species_code, v.year, 100 "STRATUM",((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum from
fi f, hcount h,varstrat v where v.stratum in (10,20) and f.stratum=h.stratum and
v.stratum=f.stratum and f.year=h.year and v.year=f.year group by v.species_code, v.year;

insert into degree
select v.species_code, v.year, 200 "STRATUM",((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum from
fi f, hcount h,varstrat v where v.stratum in (31,32,41,42,43) and f.stratum=h.stratum and
v.stratum=f.stratum and f.year=h.year and v.year=f.year group by v.species_code, v.year;

insert into degree
select v.species_code, v.year, 300 "STRATUM",((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum from
fi f, hcount h,varstrat v where v.stratum in (50,61,62) and f.stratum=h.stratum and
v.stratum=f.stratum and f.year=h.year and v.year=f.year group by v.species_code, v.year;

insert into degree
select v.species_code, v.year, 999 "STRATUM",((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum from
fi f, hcount h, varstrat v where f.stratum=h.stratum and
v.stratum=f.stratum and f.year=h.year and v.year=f.year group by v.species_code, v.year;




REM   THIS CREATES A MASTER HAUL COUNT TABLE WITH ALL THE SPECIES AND STRATA SO ZEROS CAN BE INCLUDED
drop table temp;
create table temp as select species_code from racebase.species where 
species_code in 
(232,310,320,
420,435,440,455,471,472,
480,490,495,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,
20202,20203,20204,21110,21592,23000,23010,23020,23030,23041,23055,23060,23061,23071,
21420,21371,21370,21368,21347,
21314,21315,21316,21329,21333,21340,21341,21346,21348,21352,21353,21354,21355,21356,21388,21390,21397,21405,21406,21438,21441,
21720,21725,21735,21740,
30050,30051,30052,30060,30150,30152,30420,30535,
78010,78012,78020,78403,78454,78455,
79020,79210,81742);
drop table hcount_zeros;
create table hcount_zeros as
select species_code, year, stratum from hcount h, temp 
group by species_code, year, stratum
order by species_code, year, stratum;
alter table hcount_zeros add haulcount number; update hcount_zeros set haulcount=0;
alter table hcount_zeros add catcount number; update hcount_zeros set catcount=0;
alter table hcount_zeros add numcount number; update hcount_zeros set numcount=0;
alter table hcount_zeros add lencount number; update hcount_zeros set lencount=0;



/* THIS SECTION COUNTS HAULS, HAULS W/CATCH, HAULS W/LENGTH */
/* FOR A DATA SUMMARY */

REM CALCS THE NUMBER OF HAULS WHERE CATCH WEIGHTS EXIST - ZEROS INCLUDED
drop table ccount;
drop view ccount;
create table ccount as
select species_code, a.year, a.stratum, count(*) catcount 
from haulname a, biocatch b
where a.hauljoin=b.hauljoin and a.year=b.year 
group by species_code, a.year, a.stratum;

drop table ccountot;
drop view ccountot;
create table ccountot as
select species_code, a.year, (decode(a.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,-9)) stratum, count(*) catcount 
from haulname a, biocatch b
where weight >0 and a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;


REM INSERTS SUBAREA COUNTS
insert into ccount
select species_code, year, stratum, sum(catcount) catcount
from ccountot
group by species_code, year, stratum;

insert into ccount
select species_code, year, 999 "STRATUM", sum(catcount) catcount
from ccountot group by species_code, year;

insert into ccount
select species_code, year, 100 "STRATUM", sum(catcount) catcount
from ccountot
where stratum in (1,2) group by species_code, year;

insert into ccount
select species_code, year, 200 "STRATUM", sum(catcount) catcount
from ccountot
where stratum in (3,4) group by species_code, year;

insert into ccount
select species_code, year, 300 "STRATUM", sum(catcount) catcount
from ccountot
where stratum in (5,6) group by species_code, year;

drop table ccount2;
create table ccount2 as
select h.species_code, h.year, h.stratum, c.catcount+h.catcount catcount from ccount c, hcount_zeros h 
where c.species_code(+)=h.species_code and c.year(+)=h.year and c.stratum(+)=h.stratum; 
update ccount2 set catcount=0 where catcount is null;



REM CALCS THE NUMBER OF HAULS WHERE CATCH NUMBERS - ZEROS INCLUDED
drop table ncount;
drop view ncount;
create table ncount as
select species_code, a.year, a.stratum, count(*) numcount 
from haulname a, biocatch b
where number_fish >0
and a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

drop table ncountot;
drop view ncountot;
create table ncountot as
select species_code, a.year, (decode(a.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,-9))stratum, count(*)numcount 
from haulname a, biocatch b
where number_fish >0 and
a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

insert into ncount
select species_code, year, stratum, sum(numcount) numcount
from ncountot
group by species_code, year, stratum;

insert into ncount
select species_code, year, 999 "STRATUM", sum(numcount) numcount
from ncountot 
group by species_code, year;

insert into ncount
select species_code, year, 100 "STRATUM", sum(numcount) numcount
from ncountot
where stratum in (1,2)
group by species_code, year;

insert into ncount
select species_code, year, 200 "STRATUM", sum(numcount) numcount
from ncountot
where stratum in (3,4)
group by species_code, year;

insert into ncount
select species_code, year, 300 "STRATUM", sum(numcount) numcount
from ncountot
where stratum in (5,6)
group by species_code, year;

drop table ncount2;
create table ncount2 as
select h.species_code, h.year, h.stratum, n.numcount+h.numcount numcount from ncount n, hcount_zeros h 
where n.species_code(+)=h.species_code and n.year(+)=h.year and n.stratum(+)=h.stratum; 
update ncount2 set numcount=0 where numcount is null;




REM CALCS THE NUMBER OF HAULS WITH LENGTH - ZEROS INCLUDED


REM CALCS THE NUMBER OF HAULS WHERE LENGTH NUMBERS EXIST - ZEROS INCLUDED
drop table lcount;
drop view lcount;
create table lcount as
select species_code, a.year, a.stratum, count(*) lencount 
from haulname a, biolength b
where frequency >0
and a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

drop table lcountot;
drop view lcountot;
create table lcountot as
select species_code, a.year, (decode(a.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,-9))stratum, count(*) lencount 
from haulname a, biolength b
where frequency >0 and
a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

insert into lcount
select species_code, year, stratum, sum(lencount) lencount
from lcountot
group by species_code, year, stratum;

insert into lcount
select species_code, year, 999 "STRATUM", sum(lencount) lencount
from lcountot 
group by species_code, year;

insert into lcount
select species_code, year, 100 "STRATUM", sum(lencount) lencount
from lcountot
where stratum in (1,2)
group by species_code, year;

insert into lcount
select species_code, year, 200 "STRATUM", sum(lencount) lencount
from lcountot
where stratum in (3,4)
group by species_code, year;

insert into lcount
select species_code, year, 300 "STRATUM", sum(lencount) lencount
from lcountot
where stratum in (5,6)
group by species_code, year;

drop table lcount2;
create table lcount2 as
select h.species_code, h.year, h.stratum, l.lencount+h.lencount lencount from lcount l, hcount_zeros h 
where l.species_code(+)=h.species_code and l.year(+)=h.year and l.stratum(+)=h.stratum; 
update lcount2 set lencount=0 where lencount is null;


REM ASSEMBLES COUNTS INTO ONE TABLE
drop table counts;
create table counts as
select c.species_code, a.year, a.stratum, haulcount, catcount, numcount, lencount
from hcount a, ccount2 b, ncount2 c, lcount2 d
where a.stratum=b.stratum and b.stratum=c.stratum and c.stratum=d.stratum and 
a.stratum=c.stratum and a.stratum=d.stratum and b.stratum=d.stratum
and a.year=b.year and b.year=c.year and c.year=d.year and a.year=c.year and a.year=d.year and b.year=d.year 
and b.species_code=c.species_code and c.species_code=d.species_code and b.species_code=d.species_code
order by c.species_code, a.year, a.stratum;


REM MAKE SURE DEGREEFWGT IS ROUNDED CONSISTANTLY; OTHER SCRIPTS MAY NOT COME UP WITH THE
REM EXACT SAME LOWER AND UPPER BOUNDS DUE TO ROUNDING ERROR & SUBSEQUENT T-VALUE SELECTION.
REM  USE ROUND(DEGREEFWGT) & ROUND(DEGREEFNUM).

drop table biomasstab;
create table biomasstab as
select a.species_code, a.year,
a.stratum,(meanwgtcpue * (area* 0.1)) biomass,(power(area,2)*varmnwgtcpue/100) varbio, round(newgt) degreefwgt,
(meannumcpue * (area* 100))population, (power(area,2)*varmnnumcpue*10000) varpop, round(nenum) degreefnum 
from stratlist a, strata_standard b, degree c 
where a.stratum=b.stratum and b.stratum=c.stratum and a.stratum=c.stratum 
and a.species_code=c.species_code 
and a.year=c.year and a.year=b.year and c.year=b.year;

drop table prefinaltable;
drop view prefinaltable;
create table prefinaltable as
select a.species_code, a.year,
a.stratum, meanwgtcpue, varmnwgtcpue,biomass,varbio,degreefwgt, meannumcpue, 
varmnnumcpue,population, varpop, degreefnum, 
haulcount,catcount,numcount,lencount
 from stratlist a,counts b, biomasstab c
where a.stratum=b.stratum and b.stratum=c.stratum and a.stratum=c.stratum 
and a.year=b.year and b.year=c.year and a.year=c.year
and a.species_code=b.species_code and b.species_code=c.species_code and a.species_code=c.species_code;


drop table confint;
create table confint as
select species_code, year,
stratum,
decode(sign(biomass-(ninety_five*sqrt(varbio))),-1,0,0,0,1,(biomass-(ninety_five*sqrt(varbio)))) lowerb,
(biomass +(ninety_five*sqrt(varbio)))upperb,
decode(sign(population-(ninety_five*sqrt(varpop))),-1,0,0,0,1,(population-(ninety_five*sqrt(varpop)))) lowerp,
(population +(ninety_five*sqrt(varpop)))upperp
from prefinaltable, racebase.gwttable 
where (degreefwgt >=degreef_from and degreefwgt < degreef_to) ;

REM THIS CREATES TABLE biomass_zeros SETTING UP A ZEROS TABLE FOR THE BIOMASS OUTPUT
drop table biomass_zeros;
drop view biomass_zeros;
create table biomass_zeros as select * from hcount_zeros;
alter table biomass_zeros add meanwgtcpue number; update biomass_zeros set meanwgtcpue=0;
alter table biomass_zeros add varmnwgtcpue number; update biomass_zeros set varmnwgtcpue=0;
alter table biomass_zeros add biomass number; update biomass_zeros set biomass=0;
alter table biomass_zeros add varbio number; update biomass_zeros set varbio=0;
alter table biomass_zeros add lowerb number; update biomass_zeros set lowerb=0;
alter table biomass_zeros add upperb number; update biomass_zeros set upperb=0;
alter table biomass_zeros add degreefwgt number; update biomass_zeros set degreefwgt=0;
alter table biomass_zeros add meannumcpue number; update biomass_zeros set meannumcpue=0;
alter table biomass_zeros add varmnnumcpue number; update biomass_zeros set varmnnumcpue=0;
alter table biomass_zeros add population number; update biomass_zeros set population=0;
alter table biomass_zeros add varpop number; update biomass_zeros set varpop=0;
alter table biomass_zeros add lowerp number; update biomass_zeros set lowerp=0;
alter table biomass_zeros add upperp number; update biomass_zeros set upperp=0;
alter table biomass_zeros add degreefnum number; update biomass_zeros set degreefnum=0;

REM select * from biomass_zeros order by species_code, year, stratum;



REM NOW FILL THE ZEROS INTO THE BIOMASS TABLE
drop table fillzeros;
drop view fillzeros;
create table fillzeros as
select species_code, year, stratum, meanwgtcpue, varmnwgtcpue,biomass,varbio,lowerb, upperb,degreefwgt, 
meannumcpue, varmnnumcpue,population, varpop,lowerp,upperp,degreefnum,
haulcount,catcount,numcount,lencount
from biomass_zeros 
union
select a.species_code, a.year, a.stratum, meanwgtcpue, varmnwgtcpue,biomass,varbio,lowerb, upperb,degreefwgt, 
meannumcpue, varmnnumcpue,population, varpop,lowerp,upperp,degreefnum,
haulcount,catcount,numcount,lencount
from prefinaltable a, confint b
where a.species_code=b.species_code and a.year=b.year and a.stratum=b.stratum;


drop table temp_biomass;
drop view temp_biomass;
create table temp_biomass as
select species_code, year, stratum, sum(meanwgtcpue) meanwgtcpue, sum(varmnwgtcpue) varmnwgtcpue,sum(biomass) biomass,
sum(varbio) varbio,sum(lowerb) lowerb, sum(upperb) upperb,sum(degreefwgt) degreefwgt, 
sum(meannumcpue) meannumcpue, sum(varmnnumcpue) varmnnumcpue,sum(population) population, sum(varpop) varpop,
sum(lowerp) lowerp,sum(upperp) upperp,sum(degreefnum) degreefnum,
sum(haulcount) haulcount, sum(catcount) catcount, sum(numcount) numcount, sum(lencount) lencount
from fillzeros 
group by species_code, year, stratum;

delete from temp_biomass where species_code=10260 and year>=1996;
delete from temp_biomass where species_code=10261 and year<=1995;
delete from temp_biomass where species_code=10262 and year<=1995;


drop table biomass_ebs_standard ;
create table biomass_ebs_standard 

(
    "SPECIES_CODE" CHAR(5 BYTE),
    "SPECIES_NAME" VARCHAR2(40),
    "COMMON_NAME" VARCHAR2(40),
    "YEAR"         NUMBER,
    "STRATUM"      NUMBER(6,0),
    "MEANWGTCPUE"  NUMBER,
    "VARMNWGTCPUE" NUMBER,
    "BIOMASS"      NUMBER,
    "VARBIO"       NUMBER,
    "LOWERB"       NUMBER,
    "UPPERB"       NUMBER,
    "DEGREEFWGT"   NUMBER,
    "MEANNUMCPUE"  NUMBER,
    "VARMNNUMCPUE" NUMBER,
    "POPULATION"   NUMBER,
    "VARPOP"       NUMBER,
    "LOWERP"       NUMBER,
    "UPPERP"       NUMBER,
    "DEGREEFNUM"   NUMBER,
    "HAULCOUNT"    NUMBER,
    "CATCOUNT"     NUMBER,
    "NUMCOUNT"     NUMBER,
    "LENCOUNT"     NUMBER
  );


insert into biomass_ebs_standard 
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from temp_biomass a, racebase.species b
where a.species_code=b.species_code 
order by a.species_code, a.year,stratum ;

drop table temp_biomass;

grant select on biomass_ebs_standard to public;
commit;

select * from biomass_ebs_standard order by species_code, year, stratum;






















REM MODIFIED 11/10/2015 TO RUN FOR MULIPLES SPECIES AND MULTIPLE YEARS FOR STANDARD+NW STRATA, NICHOL
REM MODIFIED 09/09/2022 UPDATE RACEBASE.STRATUM YEAR = 2022 (UPDATED STRATUM AREAS), HAEHN

REM TABLES NEEDED:  
REM                        nichold.species_group: TABLE THAT IDENTIFIES THE SPECIES GROUPINGS
REM                          FROMCODE     NOT NULL NUMBER(5)    
REM                          TOCODE       NOT NULL NUMBER(5)    
REM                          RESULTCODE   NOT NULL NUMBER(5)    
REM                          SPECIES_NAME          VARCHAR2(72) 
REM                          COMMON_NAME           VARCHAR2(72)

REM TABLE: nichold.species_group
REM   FROMCODE          TOCODE            RESULTCODE        SPECIES_NAME              COMMON_NAME                   
REM   ----------------- ----------------- ----------------- -------------------       -------------------------------
REM     400               495               400             Rajidae                   Skate unident.
REM   10110             10112             10111             Atheresthes sp.           Arrowtooth + Kamchatka flounder
REM   10130             10140             10129             Hippoglossoides sp.       Flathead sole + Bering flounder
REM   10260             10262             10260             Lepidopsetta sp.          rock sole unid. 
REM   78010             78455             78010             Octopididae        
REM   79000             79513             79000             Decapodiformes            Squid unid.      

REM ***NOTE THAT SKATE EGG CASES NEED TO BE EXCLUDED FROM THE SKATE GROUP***


REM CALCULATES BIOMASS & POPULATION NUMBERS, CI'S, AND HAUL COUNTS BY STRATA(10,20,31,32,41,42,43,50,61,62,82,90),
REM  SUBAREA(1,2,3,4,5,6,8,9), DEPTH ZONE (100=<50M; 200=50-100; 300=100-200M), AND TOTAL SURVEY (999).
REM FOR THE STANDARD + NW (82,90) AREA. NOTE FOR YEARS PRIOR TO 1987, THAT THE NW STATIONS WERE NOT ALWAYS 
REM  SAMPLED SO PAY ATTENTION TO HAUL COUNTS (HAULCOUNT) WITHIN EACH OF THESE STRATA. 
REM IF STRATA ARE NOT LISTED FOR A SPECIES/YEAR, THIS INDICATES THAT NO STATIONS WERE CONDUCTED IN THAT YEAR/STRATUM.

REM  BIOMASS AND POPULATION NUMBERS ARE CALCULATED HERE WITHOUT FISHING POWER CORRECTIONS (FPCs)

REM THE FOLLOWING COLUMNS OF DATA ARE CREATED
REM   SPECIES_CODE
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
AND A.STRATUM IN (10,20,31,32,41,42,43,50,61,62,82,90)
AND B.SURVEY_DEFINITION_ID = 98;

/* THIS CHANGES THE SPECIES TO BE GROUPED TO THEIR RESPECTIVE NEW CODES */
REM ***NEED TO EXCLUDE SKATE EGG CASES***

drop view group_species; 
drop  table group_species;
create table group_species as
 select resultcode species_code, h.year, c.cruise, c.vessel, h.stratum, c.hauljoin, h.stationid, c.haul,
 c.weight, c.number_fish from racebase.catch c, haulname h, nichold.species_group g 
 where c.hauljoin = h.hauljoin and  c.species_code >= g.fromcode and c.species_code<=g.tocode
and c.species_code not in (402,403,411,421,436,441,446,456,461,473,474,476,478,481,484,486);

/*  THIS VIEW SUMS UP WITHIN A HAUL THE WEIGHTS AND NUMBERS FOR */
/*  DUPLICATE SPECIES CODES. NOTE THAT ORACLE WILL SUM NULLS JUST */
/*  LIKE NUMBERS HERE.  MAYBE NOT WHAT YOU EXPECT */

drop table group_species_catch;
drop view group_species_catch;
create table group_species_catch as
select species_code, year, cruise, vessel, stratum, hauljoin, stationid, haul, sum(weight) weight, sum(number_fish) number_fish
 from group_species 
group by species_code, year, cruise, vessel, stratum, hauljoin, stationid, haul;


 /*   THIS TABLE GETS THE APPROPRIATE LENGTH RECORDS AND THEN SUMS THE LENGTH FREQUENCIES*/
drop table group_biolength_raw;
drop view group_biolength_raw;
create table group_biolength_raw as
select resultcode species_code,h.year, h.stratum,l.hauljoin,l.haul, frequency
from racebase.length l, haulname h, nichold.species_group g 
where l.hauljoin = h.hauljoin and l.species_code >= g.fromcode and l.species_code<=g.tocode;

drop table group_biolength;
drop view group_biolength;
create table group_biolength as
select species_code, year, stratum, hauljoin, haul, sum(frequency) frequency
 from group_biolength_raw 
group by species_code, year,  stratum, hauljoin,  haul;


   
/* THIS SECTION CALCULATES CPUE'S.  THE FIRST PART GATHERS HAULS */
/* WHERE THE SPECIES WAS NOT CAUGHT AND GIVES THEM A CPUE OF ZERO */
/* THEN THE SECOND SECTION CALCULATES CPUES WHERE THE SPECIES WAS */
/* CAUGHT AND THEN ZEROS AND CPUES ARE COMBINED */

REM FIRST SET UP A ZEROS TABLE  
drop table temp1;
create table temp1 as select
year,stratum,hauljoin,haul from haulname;
drop table temp2;
create table temp2 as select species_code from group_species_catch group by species_code order by species_code;
drop table wholelistbio_zeros;
create table wholelistbio_zeros as select species_code, year, stratum, hauljoin, haul, 0 wgtcpue_zero, 0 numcpue_zero from temp1, temp2 
order by species_code, year, stratum ;

REM NOW CALC THE WGTCPUE & NUMCPUE WHERE THE SPECIES IS PRESENT IN A HAUL
drop table wholelistbio_present;
create table wholelistbio_present as
select species_code,h.year,h.stratum,h.hauljoin, h.haul,
(weight/((distance_fished*net_width)/10)) wgtcpue_present,
((number_fish)/((distance_fished*net_width)/10)) numcpue_present
from group_species_catch c, haulname h
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


/* THIS SECTION CREATES A STRATA AREA FILE BASED ON RACEBASE.STRATUM WHERE YEAR=2022 AND */
/* SUMS THE AREAS FOR EACH                                                               */
/* 1) STRATUM (10,20,31,32,41,42,43,50,61,62,82,90,                                      */
/* 2) SUBAREA (1,2,3,4,5,6,8,9),                                                         */
/* 3) TOTAL AREA FOR THE STANDARD PLUS_NW AREA (999 = sum of strata )                    */
/* 4) DEPTH ZONE 100 (< 50M), 200 (50-100M), AND 300 (100-200M), and                     */

REM **FIRST CREATE A TABLE THAT COUNTS THE NUMBER OF STATIONS IN A STRATUM**
drop table stations;
create table stations as
select year, stratum, count(*) num_stations from haulname group by year, stratum order by year, stratum;


REM **NOW WE GET THE STRATA + STRATA AREAS THAT WERE EFFECTIVELY SAMPLED EACH YEAR (I.E., > 2 STATIONS PER STRATUM)**
/*STRATUM*/
drop table strata_plusnw_1;
drop view strata_plusnw_1;
create table strata_plusnw_1 as select  t.year, s.stratum, s.area from racebase.stratum s, stations t where 
s.region='BS' and s.year=2022 and s.stratum in (10,20,31,32,41,42,43,50,61,62,82,90)
and s.stratum=t.stratum and t.num_stations > 2 order by t.year, s.stratum;

/*SUBAREA*/
drop table strata_plusnw_2;
drop view strata_plusnw_2;
create table strata_plusnw_2 as select t.year, decode(s.stratum,10,1,20,2,31,3,32,3,
41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9) stratum, 
sum(s.area) area from racebase.stratum s, stations t where s.region='BS' and s.year=2022
and s.stratum=t.stratum and t.num_stations > 2  
group by t.year, decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9)  
order by t.year, decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9);

/*TOTAL AREA*/
drop table strata_plusnw_3;
drop view strata_plusnw_3;
create table strata_plusnw_3 as select t.year, 
decode(s.stratum, 10,999,20,999,31,999,32,999,41,999,42,999,43,999,50,999,61,999,62,999,82,999,90,999,-9) stratum, 
sum(s.area) area from racebase.stratum s, stations t where s.region='BS' and s.year=2022 
and s.stratum=t.stratum and t.num_stations > 2 
group by t.year, decode(s.stratum,10,999,20,999,31,999,32,999,41,999,42,999,43,999,50,999,61,999,62,999,82,999,90,999,-9)
order by t.year, decode(s.stratum,10,999,20,999,31,999,32,999,41,999,42,999,43,999,50,999,61,999,62,999,82,999,90,999,-9);

/*DEPTH ZONE*/
drop table strata_plusnw_4;
drop view strata_plusnw_4;
create table strata_plusnw_4 as select t.year, decode(s.stratum, 10,100,20,100,31,200,32,200,
41,200,42,200,43,200,50,300,61,300,62,300,82,200,90,300,-9) stratum, 
sum(s.area) area from racebase.stratum s, stations t where s.region='BS' and s.year=2022 
 and s.stratum=t.stratum and t.num_stations > 2 
group by t.year, decode(s.stratum,10,100,20,100,31,200,32,200,41,200,42,200,43,200,50,300,61,300,62,300,82,200,90,300,-9)
order by t.year, decode(s.stratum,10,100,20,100,31,200,32,200,41,200,42,200,43,200,50,300,61,300,62,300,82,200,90,300,-9);

drop table strata_plusnw;
drop view strata_plusnw;
create table strata_plusnw as select year, stratum, area from racebase.stratum where 1=2;
alter table strata_plusnw modify area number (15,8);
insert into strata_plusnw select * from strata_plusnw_1;
insert into strata_plusnw select * from strata_plusnw_2;
insert into strata_plusnw select * from strata_plusnw_3;
insert into strata_plusnw select * from strata_plusnw_4;
delete from strata_plusnw where stratum=-9;
drop table strata_plusnw_1;
drop table strata_plusnw_2;
drop table strata_plusnw_3;
drop table strata_plusnw_4;


/* THIS SECTION COMBINES THE STRATUM NUMBERS WITH AREA AND */
/*  TOTAL AREA FOR A SUBAREA TO BE USED IN THE NEXT SCRIPT */

drop view totarea;
drop table totarea;
create table totarea as select year, stratum subarea, area totareas from strata_plusnw where stratum in 
(1,2,3,4,5,6,8,9);

drop view areamix;
drop table areamix;
create table areamix as
select r.year,stratum,area,totareas
 from strata_plusnw r,totarea t
 where r.year=t.year and subarea=decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
 50,5,61,6,62,6,82,8,90,9,-9)
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
decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9) subarea, 
sum(vprodw) wtvarmnwgtcpue,
sum(vprodn) wtvarmnnumcpue from wtdvar
group by species_code, year, 
decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9)
order by species_code, year, decode(stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9);


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
decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9) subarea,
(meanwgtcpue*area) prodw,
(meannumcpue * area) prodn, area
from stratlist s, racebase.stratum a
where s.stratum = a.stratum and a.region = 'BS' and a.year = 2022
order by s.species_code, s.year,  decode(s.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9) ;

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
where subarea in (3,4,8) group by species_code, year;

insert into sumlist
select species_code, year,
300 "STRATUM", 
sum(prodw)/sum(area) meanwgtcpue,sum(prodn)/sum(area) meannumcpue
from prodlist
where subarea in (5,6,9) group by species_code, year;

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
update biovar set stratum=200 where subarea in (3,4,8);
update biovar set stratum=300 where subarea in (5,6,9);
update biovar b set b.area=(select s.area from strata_plusnw s where b.year=s.year and b.stratum=s.stratum);

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

REM THIS ADDS IN MEANCPUE AND VARCPUE FOR SUBAREA (1,2,3,..9) AND GROUPED AREAS (100,200, ...999) 
REM  TO TABLE WITH STANDARD STRATA (10,20,31 ...90)
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
50,5,61,6,62,6,82,8,90,9,-9)) stratum, count(*) haulcount 
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
from hcountot where stratum in (3,4,8) group by year;

insert into hcount
select year, 300 "STRATUM", sum(haulcount) haulcount
from hcountot where stratum in (5,6,9) group by year;



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
REM *****AS FOR IN 1985 WHERE THERE WAS ONLY ONE HAUL IN STRATUM 82.
REM *****THIS NEEDS TO BE DONE TO AVOID A ZERO DENOMINATOR.
UPDATE HCOUNT SET HAULCOUNT=2 WHERE HAULCOUNT=1;


drop table degree;
drop view degree;
create table degree as
select v.species_code, v.year, 
(decode(v.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,82,8,90,9,-9)) stratum,
((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum 
from fi f, hcount h, varstrat v 
where f.stratum=h.stratum and v.stratum=f.stratum and h.stratum=f.stratum and 
f.year=h.year and v.year=f.year and h.year=f.year 
group by v.species_code, v.year,
decode(v.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,50,5,61,6,62,6,82,8,90,9,-9);


REM THIS INSERTS STRATUM (1,31,32,...90) rows
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
fi f, hcount h,varstrat v where v.stratum in (31,32,41,42,43,82) and f.stratum=h.stratum and
v.stratum=f.stratum and f.year=h.year and v.year=f.year group by v.species_code, v.year;

insert into degree
select v.species_code, v.year, 300 "STRATUM",((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) newgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) nenum from
fi f, hcount h,varstrat v where v.stratum in (50,61,62,90) and f.stratum=h.stratum and
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
create table temp as select resultcode species_code from nichold.species_group; 
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
from haulname a, group_species_catch b
where a.hauljoin=b.hauljoin and a.year=b.year 
group by species_code, a.year, a.stratum;

drop table ccountot;
drop view ccountot;
create table ccountot as
select species_code, a.year, (decode(a.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,82,8,90,9,-9)) stratum, count(*) catcount 
from haulname a, group_species_catch b
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
where stratum in (3,4,8) group by species_code, year;

insert into ccount
select species_code, year, 300 "STRATUM", sum(catcount) catcount
from ccountot
where stratum in (5,6,9) group by species_code, year;

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
from haulname a, group_species_catch b
where number_fish >0
and a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

drop table ncountot;
drop view ncountot;
create table ncountot as
select species_code, a.year, (decode(a.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,82,8,90,9,-9))stratum, count(*)numcount 
from haulname a, group_species_catch b
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
where stratum in (3,4,8)
group by species_code, year;

insert into ncount
select species_code, year, 300 "STRATUM", sum(numcount) numcount
from ncountot
where stratum in (5,6,9)
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
from haulname a, group_biolength b
where frequency >0
and a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

drop table lcountot;
drop view lcountot;
create table lcountot as
select species_code, a.year, (decode(a.stratum,10,1,20,2,31,3,32,3,41,4,42,4,43,4,
50,5,61,6,62,6,82,8,90,9,-9))stratum, count(*) lencount 
from haulname a, group_biolength b
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
where stratum in (3,4,8)
group by species_code, year;

insert into lcount
select species_code, year, 300 "STRATUM", sum(lencount) lencount
from lcountot
where stratum in (5,6,9)
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
from stratlist a, strata_plusnw b, degree c 
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


drop table temp_biomass_grouped;
drop view temp_biomass_grouped;
create table temp_biomass_grouped as
select species_code, year, stratum, sum(meanwgtcpue) meanwgtcpue, sum(varmnwgtcpue) varmnwgtcpue,sum(biomass) biomass,
sum(varbio) varbio,sum(lowerb) lowerb, sum(upperb) upperb,sum(degreefwgt) degreefwgt, 
sum(meannumcpue) meannumcpue, sum(varmnnumcpue) varmnnumcpue,sum(population) population, sum(varpop) varpop,
sum(lowerp) lowerp,sum(upperp) upperp,sum(degreefnum) degreefnum,
sum(haulcount) haulcount, sum(catcount) catcount, sum(numcount) numcount, sum(lencount) lencount
from fillzeros
group by species_code, year, stratum; 

drop table biomass_ebs_plusnw_grouped ;
create table biomass_ebs_plusnw_grouped

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


insert into biomass_ebs_plusnw_grouped
select a.SPECIES_CODE, b.SPECIES_NAME, b.COMMON_NAME,
a.YEAR, a.STRATUM, round(MEANWGTCPUE,4) meanwgtcpue, round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(BIOMASS,2) biomass, round(VARBIO,4) varbio, round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, DEGREEFWGT, round(MEANNUMCPUE,4) meannumcpue, round(VARMNNUMCPUE,10) varmnnumcpue,
round(POPULATION) population, round(VARPOP,4) varpop, round(LOWERP) lowerp, round(UPPERP) upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from temp_biomass_grouped a, nichold.species_group b 
where a.species_code=b.resultcode  
order by a.species_code, a.year, stratum ;

REM NEED TO DELETE YEARS 1982-1986 FOR THE PLUSNW BECAUSE ESSENTIALLY NO SAMPLING OCCURRED IN STRATA 82 & 90 DURING THESE YEARS
delete from biomass_ebs_plusnw_grouped where year <=1986;

drop table temp_biomass_grouped;

grant select on biomass_ebs_plusnw_grouped to public;
commit;

select SPECIES_CODE, SPECIES_NAME, COMMON_NAME,YEAR, STRATUM, meanwgtcpue, varmnwgtcpue, biomass, varbio, lowerb,
upperb, DEGREEFWGT,  meannumcpue, varmnnumcpue,population,  varpop,  lowerp,  upperp, 
DEGREEFNUM,HAULCOUNT,CATCOUNT,NUMCOUNT,LENCOUNT  
from biomass_ebs_plusnw_grouped order by species_code, year, stratum;


REM MODIFIED BY NICHOL 10/18/2019. REMOVES SUMMATION RESULTS FOR SUBAREA AND DEPTH ZONES

REM ***REPLACED NICHOLD.STRATUM WITH RACEBASE.STRATUM AFTER HEATHER & NANCY UPDATED RACEBACE.STRATUM WITH THE NEW AREA FOR STRATUM 71 (2019 VERSION) 
REM     AND RECLASSIFIES STATION 'AA-10' TO HAUL_TYPE=0 AND ABUNDANCE_HAUL='N' (DONE FOR 2010 & 2017)****

REM modified 9/15/22 updated haultable to current survey year and updated racebase.stratum year = 2022 area, HAEHNR
REM modified 9/22/23 updated haultable to current survey year STEVENSD


/*  THIS SECTION GETS THE PROPER HAUL TABLE */
drop  table haulname; 
create table haulname as 
SELECT  
	to_number(to_char(a.start_time,'yyyy')) year,
	A.*
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

REM -THIS LINE NOT NEEDED NOW THAT HAUL_TYPE FOR STATION AA-10 HAS BEEN CHAGED TO ZERO:   delete from haulname where stationid='AA-10';


REM CREATE A STRATUM TABLE WITH THE APPROPRIATE AREAS (70,71,81) AND SUMMED AREA (999)
 drop table nbs_stratum;
 drop view nbs_stratum;
 create table nbs_stratum as select * from racebase.stratum where 1=2;
 alter table nbs_stratum modify area number(15,8); REM NEED TO INCREASE THE NUMBER OF DIGITS FOR "AREA" TO ACCOMODATE THE SUMMED AREA
 insert into nbs_stratum select * from racebase.stratum 
   where region='BS' and year=2022 and stratum in (70,71,81);
  insert into nbs_stratum 
   select 
    region, year, '999' stratum, null portion, sum(area) area, 'Sum of strata 70, 71, 81' description, null auditjoin 
  from nbs_stratum group by region, year;


/*  THIS SECTION GETS THE PROPER CATCH RECORDS FOR THE HAUL */
/*  TABLE */

drop table prebiocatch;
drop view prebiocatch;
create table prebiocatch as
select year,c3.hauljoin,stratum,c3.species_code,
c3.weight,c3.number_fish  
from racebase.catch c3, haulname h3
where c3.region='BS' and c3.hauljoin = h3.hauljoin;



drop table biocatch;
create table biocatch as
select 
  year,
  hauljoin,
  stratum,
  species_code,
  weight,
  number_fish
from 
  prebiocatch ;


drop table spectab;
create table spectab as
select distinct 
  h.year,
  h.hauljoin,
  h.stratum,
  s.species_code 
from
  haulname h,
  biocatch s;


   
/* THIS SECTION CALCULATES CPUE'S.  THE FIRST PART GATHERS HAULS */
/* WHERE THE SPECIES WAS NOT CAUGHT AND GIVES THEM A CPUE OF ZERO */
/* THEN THE SECOND SECTION CALCULATES CPUES WHERE THE SPECIES WAS */
/* CAUGHT AND THEN THE UNION COMBINES THEM */

drop view wholelistbio;
drop table wholelistbio;
create table wholelistbio as
select
  s.year,
  s.hauljoin,
  s.stratum,
  s.species_code,
  0.0 weight,
  0 number_fish
from biocatch f, spectab s
where  f.hauljoin(+)=s.hauljoin
and f.species_code(+)=s.species_code
and f.hauljoin is NULL 
union
select 
  f.year,
  f.hauljoin,
  f.stratum,
  f.species_code,
  weight,
  number_fish
from biocatch f,  spectab s
where f.hauljoin=s.hauljoin and 
f.species_code = s.species_code;

drop table spectab;


/* THIS SECTION CREATES A TABLE OF THE MEAN CPUE FOR EACH STRATUM */
/* AND OF VARIANCE OF THE MEAN CPUE */
drop table cpuelist;
drop view cpuelist;
create table cpuelist as
select 
  a.species_code,
  a.year,
  a.hauljoin,
  b.stratum, 
  (weight/((distance_fished * net_width)/10)) wgtcpue,
  (number_fish/((distance_fished * net_width)/10)) numcpue
from wholelistbio a, haulname b
where a.hauljoin=b.hauljoin;

drop view stratlist;
drop table stratlist;
create table stratlist as
select 
  species_code, 
  year,
  stratum, 
  avg(wgtcpue) meanwgtcpue,
  variance(wgtcpue)/count(*) varmnwgtcpue,
  avg(numcpue) meannumcpue,
  variance(numcpue)/count(*) varmnnumcpue
from cpuelist 
group by species_code, year,stratum;



REM  ***********************************************************************************************************************************
REM CREATE TOTAL SURVEY AREA (STRATUM 999) VALUES FOR MEANWGTCPUE, MEANNUMCPUE, VARMNWGTCPUE, AND VARMNNUMCPUE THEN ADD INTO STRATLIST 

REM  FIRST, ADD IN STRATA AREAS AND STRATA TOTAL AREA
alter table stratlist add area number(15,8);
update stratlist a set a.area= (select b.area from nbs_stratum b where a.stratum=b.stratum);
alter table stratlist add totarea number(15,8);
update stratlist a set a.totarea= (select b.area from nbs_stratum b where b.stratum=999);

REM FOR STRATA 999 (TOTAL SURVEY AREA) WE TAKE A WEIGHTED AVERAGE OF MEANWGTCPUE AND MEANNUMCPUE WITH STRATA AREA AS THE WEIGHTING VALUE
drop table stratlist_add_1;
drop view stratlist_add_1;
create table stratlist_add_1 as
select 
  species_code,
  year,
  999 stratum,
  sum(meanwgtcpue*area)/sum(area) meanwgtcpue,
  sum(meannumcpue*area)/sum(area) meannumcpue,
  sum(area) area,
  avg(totarea) totarea
from stratlist 
group by species_code, year;


REM NOW DO THE SAME FOR THE VARIANCE ESTIMATES BUT USE EQUATION (6) ON PAGE 27 OF WAKABAYASHI ET AL (INPFC BULLETIN NUMBER 44)
drop table stratlist_add_2;
drop view stratlist_add_2;
create table stratlist_add_2 as
select 
  species_code,
  year,
  999 stratum,
  sum(power((area/totarea),2)*varmnwgtcpue) varmnwgtcpue,
  sum(power((area/totarea),2)*varmnnumcpue) varmnnumcpue,
  sum(area) area,
  avg(totarea) totarea 
from stratlist
group by species_code, year;

insert into stratlist 
select
  a.species_code,
  a.year,
  999 stratum,
  a.meanwgtcpue,
  b.varmnwgtcpue,
  a.meannumcpue,
  b.varmnnumcpue,
  a.area,
  a.totarea
from stratlist_add_1 a, stratlist_add_2 b 
where a.species_code=b.species_code and a.year=b.year;
REM  ************************************************************************************************************************************


/* THIS SECTION CALCULATES THE VARIANCE OF BIOMASS AND POPULATION FOR EACH STRATUM */
/---DIVIDING BY 100 AND MULTIPLYING BY 10000 ARE ENABLE CONVERSION FROM KM2 TO HA AND ALSO GETTING TO MT.*/

drop table biovar;
create table biovar as
select 
  species_code,
  year, 
  stratum,  
  area,
  (power(area,2)*varmnwgtcpue/100) varbio,
  (power(area,2)*varmnnumcpue*10000) varpop
from
  stratlist ;


REM ADDS IN THE COUNTS **********************************************************************************************************************
/* THIS SECTION MAKES A LIST OF STRATUM,HAULCOUNTs, CATCHCOUNTS (WTS & NUMBERS), AND LENGTHCOUNTS --BY STRATA AND STRATA TOTAL*/

drop table hcount;
drop view hcount;
create table hcount as
select 
  year,
  stratum, 
  count(*)haulcount 
from haulname
group by year,stratum;

insert into hcount
select 
  year,
  999 "STRATUM", 
  sum(haulcount) haulcount
from hcount
group by year;

REM select * from hcount order by year,stratum;

REM   THIS CREATES A MASTER HAUL COUNT TABLE WITH ALL POSSIBLE SPECIES AND STRATA SO ZEROS CAN BE INCLUDED
drop table temp;
create table temp as select distinct species_code from biocatch;
drop table hcount_zeros;
create table hcount_zeros as
select 
  species_code, 
  year, 
  stratum 
from hcount h, temp 
group by species_code, year, stratum
order by species_code, year, stratum;
alter table hcount_zeros add haulcount number; update hcount_zeros set haulcount=0;
alter table hcount_zeros add catcount number; update hcount_zeros set catcount=0;
alter table hcount_zeros add numcount number; update hcount_zeros set numcount=0;
alter table hcount_zeros add lencount number; update hcount_zeros set lencount=0;


REM CALCS THE NUMBER OF HAULS WHERE CATCH WEIGHTS EXIST - ZEROS INCLUDED
drop table ccount;
drop view ccount;
create table ccount as
select 
  species_code, 
  a.year, 
  a.stratum, 
  count(*) catcount 
from haulname a, biocatch b
where a.hauljoin=b.hauljoin and a.year=b.year 
group by species_code, a.year, a.stratum;

insert into ccount
select 
  species_code, 
  year, 
  999 "STRATUM", sum(catcount) catcount
from ccount group by species_code, year;

REM NOW ADD IN THE ZERO CATCHES
drop table ccount2;
create table ccount2 as
select 
  h.species_code, 
  h.year, 
  h.stratum, 
  c.catcount+h.catcount catcount 
from ccount c, hcount_zeros h 
where c.species_code(+)=h.species_code and c.year(+)=h.year and c.stratum(+)=h.stratum; 
update ccount2 set catcount=0 where catcount is null;


REM CALCS THE NUMBER OF HAULS WHERE CATCH NUMBERS - ZEROS INCLUDED
drop table ncount;
drop view ncount;
create table ncount as
select 
  species_code, 
  a.year, 
  a.stratum, 
  count(*) numcount 
from haulname a, biocatch b
where number_fish >0
and a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

insert into ncount
select 
  species_code, 
  year, 
  999 "STRATUM", sum(numcount) numcount
from ncount 
group by species_code, year;

REM NOW ADD IN THE ZERO CATCH NUMBERS
drop table ncount2;
create table ncount2 as
select 
  h.species_code, 
  h.year, 
  h.stratum, 
  n.numcount+h.numcount numcount 
from ncount n, hcount_zeros h 
where n.species_code(+)=h.species_code and n.year(+)=h.year and n.stratum(+)=h.stratum; 
update ncount2 set numcount=0 where numcount is null;


REM CALCS THE NUMBER OF HAULS WHERE LENGTH NUMBERS EXIST - ZEROS INCLUDED
drop table biolength;
drop view biolength;
create table biolength as
select 
  c.species_code, 
  h.year, 
  h.stratum, 
  c.hauljoin, 
  c.haul, 
  sum(c.frequency) frequency
from racebase.length c,haulname h 
where c.hauljoin = h.hauljoin
and species_code in (232,310,320,
420,435,440,455,471,472,
480,490,495,
10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10260,10261,10262,10270,10285,21110,
21420,21371,21370,21368,21347,
21314,21315,21316,21329,21333,21340,21341,21346,21348,21352,21353,21354,21355,21356,21388,21390,21397,21405,21406,21438,21441,
21720,21725,21735,21740,
30050,30051,30052,30060,30150,30152,30420,30535,
78010,78012,78020,78403,78454,78455,
79020,79210,81742) 
group by c.species_code,h.year,h.stratum,c.hauljoin,c.haul;

drop table lcount;
drop view lcount;
create table lcount as
select 
  species_code, 
  a.year, 
  a.stratum, 
  count(*) lencount 
from haulname a, biolength b
where frequency >0
and a.hauljoin=b.hauljoin
group by species_code, a.year, a.stratum;

insert into lcount
select 
  species_code, 
  year, 999 "STRATUM", 
  sum(lencount) lencount
from lcount
group by species_code, year;

drop table lcount2;
create table lcount2 as
select 
  h.species_code, 
  h.year, 
  h.stratum, 
  l.lencount+h.lencount lencount 
from lcount l, hcount_zeros h 
where l.species_code(+)=h.species_code and l.year(+)=h.year and l.stratum(+)=h.stratum; 
update lcount2 set lencount=0 where lencount is null;


REM ASSEMBLES COUNTS INTO ONE TABLE
drop table counts;
create table counts as
select 
  c.species_code, 
  a.year, 
  a.stratum, 
  haulcount, 
  catcount, 
  numcount, 
  lencount
from hcount a, ccount2 b, ncount2 c, lcount2 d
where a.stratum=b.stratum and b.stratum=c.stratum and c.stratum=d.stratum and 
a.stratum=c.stratum and a.stratum=d.stratum and b.stratum=d.stratum
and a.year=b.year and b.year=c.year and c.year=d.year and a.year=c.year and a.year=d.year and b.year=d.year 
and b.species_code=c.species_code and c.species_code=d.species_code and b.species_code=d.species_code
order by c.species_code, a.year, a.stratum;

REM ********************************************************************************************************************************************
/* THIS SECTION IS THE START OF CALCULATING THE EFFECTIVE DEGREES */
/* OF FREEDOM. */

drop table tot_towarea_bystrat;
create table tot_towarea_bystrat as 
select 
  year,
  stratum, 
  sum(((distance_fished*net_width)/10)) towarea_bystrat, 
  count(hauljoin) counthj
from haulname
group by year,stratum; 


drop view fi;
drop table fi;
create table fi as
select 
  b.year,
  b.stratum, 
  ((counthj*area/towarea_bystrat)*((counthj*area/towarea_bystrat)-counthj))/counthj fi
from nbs_stratum a, tot_towarea_bystrat b
where a.stratum=b.stratum;
REM ********************************************************************************************************************************************


REM ********************************************************************************************************************************************
REM ****CORRECTED BOBS AKFIN SCRIPT THAT TOOK THE VARIANCE FROM WEIGHT AND NUMBER_FISH INSTEAD OF CPUEWGT AND CPUENUM****
REM VARBAREWGT AND VARBARENUM ARE SAMPLE VARIANCES
drop view varstrat;
drop table varstrat;
create table varstrat as
select 
  species_code,
  year,
  stratum,  
  decode(variance(wgtcpue),0,1,variance(wgtcpue)) varbarewgt,
  decode(variance(numcpue),0,1,variance(numcpue)) varbarenum 
from cpuelist
group by species_code, year, stratum;
REM ********************************************************************************************************************************************


drop table degree;
create table degree as
select 
  species_code,
  v.year,
  v.stratum,
  ((power(sum(fi*varbarewgt),2))/sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) degreefwgt,
  ((power(sum(fi*varbarenum),2))/sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) degreefnum
from fi, hcount h,varstrat v 
where 
  fi.year=h.year
  and v.year=fi.year
  and fi.stratum=h.stratum 
  and v.stratum=fi.stratum
group by species_code, v.year, v.stratum;

insert into degree
select 
   v.species_code, 
   v.year, 999 "STRATUM", 
   ((power(sum(fi*varbarewgt),2))/sum(power(fi,2)*power(varbarewgt,2)/(haulcount-1))) degreefwgt,
   ((power(sum(fi*varbarenum),2))/sum(power(fi,2)*power(varbarenum,2)/(haulcount-1))) degreefnum from
   fi f, 
   hcount h, 
   varstrat v 
where f.stratum=h.stratum and
v.stratum=f.stratum and f.year=h.year and v.year=f.year group by v.species_code, v.year;


/* THESE TWO SECTIONS DEVELOP A SMALL TABLE OF STRATUM VS. BIOMASS */
/* AND POPULATION FOR USE IN OTHER SCRIPTS SUCH AS BIOMASS BY SIZE */
drop table table7;
create table table7 as
select 
  species_code, 
  year,
  stratum, 
  sum(meanwgtcpue * (area * 0.1)) biomass,
  sum(meannumcpue * (area * 100)) population
from stratlist 
group by species_code, year, stratum
order by species_code, year, stratum;


REM COMBINE MOST OF THE REQUIRED COLUMNS INTO ONE TABLE
drop table prefinaltable1;
create table prefinaltable1 as
select 
  a.species_code,
  a.year,
  a.stratum,
  d.meanwgtcpue, 
  d.varmnwgtcpue,
  d.meannumcpue, 
  d.varmnnumcpue,
  biomass,
  varbio,
  degreefwgt,
  population,
  varpop,
  degreefnum
from 
  table7 a, 
  biovar b, 
  degree c,
  stratlist d
where 
  a.year=b.year and a.year=c.year and a.year=d.year and b.year=c.year and b.year=d.year and c.year=d.year and
  a.species_code=b.species_code and a.species_code=c.species_code and a.species_code=d.species_code and 
       b.species_code=c.species_code and b.species_code=d.species_code and c.species_code=d.species_code and
  a.stratum=b.stratum and a.stratum=c.stratum and a.stratum=d.stratum and b.stratum=c.stratum and b.stratum=d.stratum and c.stratum=d.stratum
order by 
  species_code,
  year,
  stratum;

REM COMPUTE LOWER AND UPPER CONFIDENCE BOUNDS FOR BIOMASS AND POPULATION
drop table confint;
create table confint as
select 
  species_code, 
  year,
  stratum,
  decode(sign(biomass-(ninety_five*sqrt(varbio))),-1,0,0,0,1,(biomass-(ninety_five*sqrt(varbio)))) lowerb,
  (biomass +(ninety_five*sqrt(varbio))) upperb,
  decode(sign(population-(ninety_five*sqrt(varpop))),-1,0,0,0,1,(population-(ninety_five*sqrt(varpop)))) lowerp,
  (population +(ninety_five*sqrt(varpop))) upperp
from prefinaltable1, racebase.gwttable 
where (degreefwgt >=degreef_from and degreefwgt < degreef_to) ;


REM NOW ADD IN THE COUNTS AND LOWER AND UPPER 95CI
drop table prefinaltable2;
create table prefinaltable2 as select
  a.species_code,
  a.year,
  a.stratum,
  a.meanwgtcpue, 
  a.varmnwgtcpue,
  a.meannumcpue, 
  a.varmnnumcpue,
  a.biomass,
  a.varbio,
  a.degreefwgt,
  a.population,
  a.varpop,
  a.degreefnum,
  b.haulcount,
  b.catcount,
  b.numcount,
  b.lencount,
  c.lowerb,
  c.upperb,
  c.lowerp,
  c.upperp
from prefinaltable1 a, counts b, confint c 
 where a.year=b.year and a.year=c.year and b.year=c.year 
      and a.species_code=b.species_code and a.species_code=c.species_code and b.species_code=c.species_code 
      and a.stratum=b.stratum and a.stratum=c.stratum and b.stratum=c.stratum;


REM **************************************************************************************************************************************
REM NOW SET UP THE TABLE IN THE FORM TO BE SENT TO THE STOCK ASSESSEMENT (SAFE) AUTHORS
REM  ***NOTE THAT UNITS OF CPUE HERE ARE KG PER HECTARE (1 HECTARE = 0.01 KM-SQUARED)***
drop table biomass_nbs_safe ;
create table biomass_nbs_safe 

(
    "SPECIES_CODE" CHAR(5 BYTE),     
    "SPECIES_NAME" VARCHAR2(70),
    "COMMON_NAME"  VARCHAR2(40),
    "YEAR"         NUMBER, 
    "STRATUM"      NUMBER(6,0),
    "HAULCOUNT"    NUMBER,
    "CATCOUNT"     NUMBER,
    "NUMCOUNT"     NUMBER,
    "LENCOUNT"     NUMBER,
    "MEANWGTCPUE"  NUMBER,
    "VARMNWGTCPUE" NUMBER,
    "MEANNUMCPUE"  NUMBER,
    "VARMNNUMCPUE" NUMBER,
    "BIOMASS"      NUMBER,
    "VARBIO"       NUMBER,
    "LOWERB"       NUMBER,
    "UPPERB"       NUMBER,
    "DEGREEFWGT"   NUMBER,
    "POPULATION"   NUMBER,
    "VARPOP"       NUMBER,
    "LOWERP"       NUMBER,
    "UPPERP"       NUMBER,
    "DEGREEFNUM"   NUMBER
    
   );

insert into biomass_nbs_safe select 
a.SPECIES_CODE, 
b.SPECIES_NAME, 
b.COMMON_NAME,
a.YEAR, 
a.STRATUM, 
HAULCOUNT,
CATCOUNT,
NUMCOUNT,
LENCOUNT,
round(MEANWGTCPUE,4) meanwgtcpue, 
round(VARMNWGTCPUE,10) varmnwgtcpue, 
round(MEANNUMCPUE,4) meannumcpue, 
round(VARMNNUMCPUE,10) varmnnumcpue,
round(BIOMASS,2) biomass, 
round(VARBIO,4) varbio, 
round(LOWERB,2) lowerb,
round(UPPERB,2) upperb, 
round(degreefwgt) degreefwgt, 
round(POPULATION) population, 
round(VARPOP,4) varpop, 
round(LOWERP) lowerp, 
round(UPPERP) upperp, 
round(degreefnum) degreefnum
from prefinaltable2 a, racebase.species b
where a.species_code=b.species_code 
order by a.species_code, a.year,stratum ;

grant select on biomass_nbs_safe to public;
REM **************************************************************************************************************************************


REM NOW SELECT A TABLE IN THE FORM BOB HAS SENT TO AKFIN
REM  ***NOTE THAT FOR AKFIN, THE UNITS FOR MEAN CPUE AND VARIANCES OF CPUE ARE CONVERTED TO KG PER KM-SQUARED*** 
Drop table biomass_nbs_akfin;
create table biomass_nbs_akfin as
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
        degreefwgt degreef_biomass,
        POPULATION STRATUM_POP,
        VARPOP POP_VAR,
        LOWERP MIN_POP,
        UPPERP MAX_POP,
        degreefnum degreef_pop
from biomass_nbs_safe
where species_code not in (400,10111,10260,10129,79000,78010)
order by year, species_code, stratum; 

grant select on biomass_nbs_akfin to public;
commit;



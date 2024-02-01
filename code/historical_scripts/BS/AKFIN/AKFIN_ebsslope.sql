set heading off
select 'drop table '||table_name||';' 
from user_tables 
where table_name
like '%';
 
  

DROP TABLE COMB_DEPTH_STRATA;
CREATE TABLE COMB_DEPTH_STRATA AS
select 'EBS_SLOPE' survey,
       YEAR,
       decode(stratum,11,1,12,1,13,1,14,1,15,1,
       21,2,22,2,23,2,24,2,25,2,
       31,3,32,3,33,3,34,3,35,3,
       41,4,42,4,43,4,44,4,45,4,
       51,5,52,5,53,5,54,5,55,5,
       61,6,62,6,63,6,64,6,65,6,-9)STRATUM,
       AREA
from RACEBASE.STRATUM
where region = 'BS' and year=2002;

drop table strata_ebsslope;
create table strata_ebsslope as
select 'EBS_SLOPE' survey,
       year,
       stratum,
       area
from RACEBASE.STRATUM
where region = 'BS' and year=2002
union
select survey,
       YEAR,
       STRATUM,
       SUM(AREA)AREA
from COMB_DEPTH_STRATA
GROUP BY survey,
       YEAR,
       STRATUM
union
select survey,
       YEAR,
       999999 STRATUM,
       SUM(AREA)AREA
from COMB_DEPTH_STRATA
GROUP BY survey,
       YEAR;



alter table strata_ebsslope
add description VARchar(80);

alter table strata_ebsslope
add domain char(40);

alter table strata_ebsslope
add DENSITY char(40);

UPDATE strata_ebsslope b
set description =
(select description
          from racebase.stratum a
          where year=2002
                and region='BS'
                and a.stratum=b.stratum);
                
UPDATE strata_ebsslope
set description =
(select 'EBS slope subarea 1 all depths 200-1200 meters' description
          from dual)
          where stratum=1;

UPDATE strata_ebsslope
set description =
(select 'EBS slope subarea 2 all depths 200-1200 meters' description
          from dual)
          where stratum=2;
          
UPDATE strata_ebsslope
set description =
(select 'EBS slope subarea 3 all depths 200-1200 meters' description
          from dual)
          where stratum=3;

UPDATE strata_ebsslope
set description =
(select 'EBS slope subarea 4 all depths 200-1200 meters' description
          from dual)
          where stratum=4;

UPDATE strata_ebsslope
set description =
(select 'EBS slope subarea 5 all depths 200-1200 meters' description
          from dual)
          where stratum=5;
          
UPDATE strata_ebsslope
set description =
(select 'EBS slope subarea 6 all depths 200-1200 meters' description
          from dual)
          where stratum=6;
          
UPDATE strata_ebsslope
set description =
(select 'EBS slope all subareas all depths 200-1200 meters' description
          from dual)
          where stratum=999999;

drop table HAUL_ebsslope;
drop view HAUL_ebsslope;
create table HAUL_ebsslope as
SELECT  
  to_number(to_char(a.start_time,'yyyy')) year,
  'EBS_SLOPE' survey,
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
  AND B.SURVEY_DEFINITION_ID = 78
  AND b.YEAR>=2002
ORDER BY YEAR,
         A.STATIONID;


drop table CATCH_ebsslope;
create table CATCH_ebsslope as
select YEAR,
'EBS_SLOPE' survey,
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
from racebase.catch c, HAUL_ebsslope h
where h.hauljoin=c.hauljoin;

drop table LENGTH_ebsslope;
create table LENGTH_ebsslope as
SELECT YEAR,
'EBS_SLOPE' survey,
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
from racebase.LENGTH c, HAUL_ebsslope h
where h.hauljoin=c.hauljoin;

drop table SPECIMEN_ebsslope;
create table SPECIMEN_ebsslope as
select 'EBS_SLOPE' survey,
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
from racebase.SPECIMEN c, HAUL_ebsslope h
where h.hauljoin=c.hauljoin;

/* CPUE'S ARE IN KG OR NUM PER SQUAE KILOMETER */
drop table CPUE_EBSSLOPE;
create table CPUE_EBSSLOPE as
select       'EBS_SLOPE' survey,
             a.year,
             b.catchjoin,
             a.hauljoin,
             a.vessel,
             a.cruise,
             a.haul,
             a.stratum,
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
                            c.distance_fished,
                            c.net_width,
                            a.species_code
          from CATCH_ebsslope a, HAUL_ebsslope c, racebase.species b
                       where a.year=c.year
                            and a.species_code=b.species_code
             ) a, 
             CATCH_ebsslope b
where     a.hauljoin = b.hauljoin(+) and
          a.species_code=b.species_code(+);


drop table CPUE_EBSSLOPE_POS;
create table CPUE_EBSSLOPE_POS as
select
	a.year,
  a.hauljoin,
  a.stratum,
  a.species_code,
	b.start_latitude latitude,
	b.start_longitude longitude,
	b.surface_temperature sst_c,
	b.gear_temperature btemp_c,
	b.bottom_depth depth_m,
	a.wgtcpue,
	a.numcpue
from 
  CPUE_EBSSLOPE a, 
  HAUL_ebsslope b
where
	a.hauljoin=b.hauljoin
order by
	year,
  hauljoin,
  stratum,
  species_code;
	
/* BIOPOP SCRIPT */

drop view stratlist;
drop table stratlist;
create table stratlist as
select YEAR,species_code,stratum, avg(wgtcpue) meanwgtcpue, avg(numcpue) meannumcpue,
(variance(wgtcpue)/count(*))varmnwgtcpue,
(variance(numcpue)/count(*)) varmnnumcpue 
from CPUE_EBSSLOPE
group by YEAR, species_code,stratum
ORDER BY YEAR, species_code,stratum;

drop table biopopvar_stratum;
drop view biopopvar_stratum;
create table biopopvar_stratum as
select s.YEAR,species_code,s.stratum,
        (meanwgtcpue * (area/1000)) STRATUM_BIOMASS,
        (power(area,2)*varmnwgtcpue/1000000) BIO_VAR,
        (meannumcpue * (area)) STRATUM_POP, 
        (power(area,2)*varmnnumcpue) POP_VAR 
FROM
stratlist s, STRATA_EBSSLOPE a 
WHERE s.stratum=a.stratum;

select * from biopopvar_stratum where species_code=21740 and year=2002;

drop table prebiopopvar_subarea;
drop view prebiopopvar_subarea;
create table prebiopopvar_subarea as       
select YEAR,species_code,decode(stratum,11,1,12,1,13,1,14,1,15,1,
       21,2,22,2,23,2,24,2,25,2,
       31,3,32,3,33,3,34,3,35,3,
       41,4,42,4,43,4,44,4,45,4,
       51,5,52,5,53,5,54,5,55,5,
       61,6,62,6,63,6,64,6,65,6,-9)STRATUM,
       STRATUM_BIOMASS,
       BIO_VAR,
       STRATUM_POP, 
       POP_VAR 
FROM biopopvar_stratum;      

select * from prebiopopvar_subarea where species_code=21740 and year=2002;

drop table biopopvar_subarea;
drop view biopopvar_subarea;
create table biopopvar_subarea as        
select YEAR,
       species_code,
       STRATUM,
       sum(STRATUM_BIOMASS) STRATUM_BIOMASS,
       sum(BIO_VAR) BIO_VAR,
       sum(STRATUM_POP) STRATUM_POP,
       sum(POP_VAR) POP_VAR 
from prebiopopvar_subarea 
group by YEAR,
        species_code,
        STRATUM
ORDER BY YEAR, species_code,stratum;

select * from biopopvar_subarea where species_code=21740 and year=2002;

insert into stratlist
select a.YEAR,
       a.species_code,
       a.STRATUM,
       (STRATUM_BIOMASS)/(area/1000) meanwgtcpue,
       (BIO_VAR*1000000)/power(area,2) varmnwgtcpue,
       (STRATUM_POP)/area meannumcpue,
       (POP_VAR)/power(area,2) varmnnumcpue 
from biopopvar_subarea a, STRATA_EBSSLOPE b
where a.stratum=b.stratum
ORDER BY YEAR, species_code,stratum;

select * from stratlist where species_code=21740 and year=2002;

/* THIS SECTION CALCULATES THE VARIANCE OF BIOMASS AND POPULATION */
/* FOR EACH SUBAREA---DIVIDING BIOMASS BY 100O TO GET TO MT*/

drop table biopopvar;
create table biopopvar as
SELECT * from biopopvar_subarea
union
SELECT * from biopopvar_stratum;

select * from biopopvar where species_code=21740 and year=2002;


drop table hcount;
drop view hcount;
create table hcount as
select year,stratum, count(*)haulcount 
from HAUL_ebsslope
group by year,stratum
order by year,stratum;

insert into hcount
select year,999 "STRATUM", sum(haulcount)haulcount
from hcount
group by year
order by year;

drop table subarea_haulcount;
drop view subarea_haulcount;
create table subarea_haulcount as
select year,
      decode(stratum,11,1,12,1,13,1,14,1,15,1,
       21,2,22,2,23,2,24,2,25,2,
       31,3,32,3,33,3,34,3,35,3,
       41,4,42,4,43,4,44,4,45,4,
       51,5,52,5,53,5,54,5,55,5,
       61,6,62,6,63,6,64,6,65,6,-9)STRATUM,
       count(*)haulcount 
from HAUL_ebsslope
group by year,stratum
order by year,stratum;

insert into hcount
select year,STRATUM, sum(haulcount)haulcount
from subarea_haulcount
group by year,STRATUM
order by year,STRATUM;

drop table subarea_haulcount;

drop table pccountot;
drop view pccountot;
create table pccountot as
select 
      year,
      species_code,
      stratum, 
      count(*) catcount 
from CPUE_EBSSLOPE
where wgtcpue>0
GROUP BY year,species_code,stratum;

drop table allspp;
create table allspp as
select distinct species_code from CPUE_EBSSLOPE;

insert into pccountot
select distinct a.year,b.species_code,a.stratum,0 CATCOUNT 
from hcount a, allspp b
where a.stratum not in(1,2,3,4,5,6,999)
order by year,species_code,stratum;



drop table subarea_pccountot;
create table subarea_pccountot as
select 
      year,
      species_code,stratum str,
      decode(stratum,10,1,11,1,12,1,13,1,14,1,15,1,
       21,2,22,2,23,2,24,2,25,2,
       31,3,32,3,33,3,34,3,35,3,
       41,4,42,4,43,4,44,4,45,4,
       51,5,52,5,53,5,54,5,55,5,
       61,6,62,6,63,6,64,6,65,6)STRATUM,
       catcount 
from pccountot;

insert into pccountot
select year,species_code, 999 "STRATUM", sum(catcount) catcount
from pccountot
GROUP BY year,species_code 
order by year,species_code;

select distinct year,species_code,stratum from pccountot
where species_code=21740 and year=2002;

insert into pccountot
select year,species_code, stratum, sum(catcount) catcount
from subarea_pccountot
GROUP BY year,species_code, stratum
order by year,species_code, stratum;



select * from pccountot where species_code=21740 and year=2002 order by stratum;


drop table ccountot;
drop view ccountot;
create table ccountot as
select 
      year,
      species_code,
      stratum, 
      sum(catcount) catcount 
from pccountot
group by year,
      species_code,
      stratum
order by year,species_code,stratum ;

select * from ccountot where species_code=21740 and year=2002 order by stratum;

Drop table prebiomass_ebssLOPE;
create table prebiomass_ebssLOPE as
SELECT
        'EBS_SLOPE' survey,
        S.YEAR,
        s.stratum,
        s.species_code,
        HAULCOUNT haul_count,
        CATCOUNT catch_count,
        MEANWGTCPUE MEAN_WGT_CPUE,
        VARMNWGTCPUE VAR_WGT_CPUE,
        MEANNUMCPUE MEAN_NUM_CPUE,
        VARMNNUMCPUE VAR_NUM_CPUE,
        STRATUM_BIOMASS,
        BIO_VAR,
        STRATUM_POP, 
        POP_VAR
FROM 
        stratlist s, biopopvar b,HCOUNT H, ccountot C
WHERE 
        s.stratum<>999 and S.YEAR=B.YEAR AND B.YEAR=H.YEAR AND H.YEAR=C.YEAR 
        AND s.stratum=b.stratum 
        and B.STRATUM=H.STRATUM AND H.STRATUM=C.STRATUM AND
        s.species_code=b.species_code and B.SPECIES_CODE=C.SPECIES_CODE
ORDER BY
        YEAR,species_code,stratum;
        
        select * from prebiomass_ebssLOPE where species_code=21720 and year=2002;

drop view slope_totarea;
create view slope_totarea as
select area from STRATA_EBSSLOPE
where stratum=999999;

insert into prebiomass_ebssLOPE
SELECT
        survey,
        YEAR,
        999999 STRATUM,
        species_code,
        sum(haul_count) haul_count,
        sum(catch_count) catch_count,
        sum(STRATUM_BIOMASS)/(32723.493 /1000) MEAN_WGT_CPUE,
        sum(BIO_VAR*1000000)/power(32723.493 ,2) VAR_WGT_CPUE,
        sum(STRATUM_POP)/32723.493  MEAN_NUM_CPUE,
        sum(POP_VAR)/power(32723.493 ,2) VAR_NUM_CPUE,
        sum(STRATUM_BIOMASS) STRATUM_BIOMASS,
        sum(BIO_VAR) BIO_VAR,
        sum(STRATUM_POP) STRATUM_POP, 
        sum(POP_VAR) POP_VAR
FROM 
        slope_totarea, prebiomass_ebssLOPE b
WHERE 
        stratum in(1,2,3,4,5,6)
GROUP BY survey,YEAR,species_code
ORDER BY
        YEAR,species_code,stratum;
        

      
select * from prebiomass_ebssLOPE  where species_code=21740 and year=2002;
/* FOR CALCULATING 95% CI'S */

drop table tot_towarea_bystrat;
create table tot_towarea_bystrat as 
select year,stratum, 
sum(((distance_fished*net_width)/1000)) towarea_bystrat, count(hauljoin) counthj
from HAUL_ebsslope
group by year,stratum
order by year,stratum; 

drop view fi;
drop table fi;
create view fi as
select b.year, a.stratum, 
((counthj*area/towarea_bystrat)*((counthj*area/towarea_bystrat)-counthj))/counthj fi
from racebase.stratum a, tot_towarea_bystrat b
where a.stratum=b.stratum and region='BS' and a.year=2002
order by year,stratum;

drop view varstrat;
drop table varstrat;
create table varstrat as
select year,species_code,stratum, decode(variance(wgtcpue),0,1,variance(wgtcpue))
varbarewgt,decode(variance(numcpue),0,1,variance(numcpue))
varbarenum from CPUE_EBSSLOPE 
group by year,species_code,stratum
order by year,species_code,stratum;

select * from varstrat  where species_code=21740 and year=2002;


drop table degree;
drop view degree;
create table degree as
select 
v.YEAR,V.SPECIES_CODE,
v.stratum,STRATUM_BIOMASS, BIO_VAR,STRATUM_POP,POP_VAR,
round(((power(sum(fi*varbarewgt),2))/
sum(power(fi,2)*power(varbarewgt,2)/(DECODE((counthj-1),0,1,(counthj-1))))),0) dfwgt,
((power(sum(fi*varbarenum),2))/
sum(power(fi,2)*power(varbarenum,2)/(DECODE((counthj-1),0,1,(counthj-1))))) dfnum
from 
fi, varstrat v,tot_towarea_bystrat h,prebiomass_ebssLOPE c 
where 
V.SPECIES_CODE=C.SPECIES_CODE AND c.stratum<>999999 and c.stratum not in(1,2,3,4,5,6)
and v.year=fi.year and fi.year=h.year and h.year=c.year and
v.stratum=fi.stratum and fi.stratum=h.stratum and h.stratum=c.stratum
group by v.year,V.SPECIES_CODE,v.stratum,STRATUM_BIOMASS, BIO_VAR,STRATUM_POP,POP_VAR
order by year,stratum,SPECIES_CODE;

select * from degree  where species_code=21740 and year=2002;


drop table sub_degree;
create table sub_degree as
select YEAR,SPECIES_CODE,
       decode(stratum,11,1,12,1,13,1,14,1,15,1,
       21,2,22,2,23,2,24,2,25,2,
       31,3,32,3,33,3,34,3,35,3,
       41,4,42,4,43,4,44,4,45,4,
       51,5,52,5,53,5,54,5,55,5,
       61,6,62,6,63,6,64,6,65,6,-9)STRATUM,
       SUM(STRATUM_BIOMASS) STRATUM_BIOMASS, SUM(BIO_VAR)BIO_VAR,
       SUM(STRATUM_POP)STRATUM_POP,SUM(POP_VAR) POP_VAR,
       sum(DFWGT) dfwgt,
       SUM(dfnum) dfnum
from degree
GROUP BY YEAR,SPECIES_CODE, stratum;

select * from sub_degree  where species_code=21740 and year=2002;

INSERT INTO DEGREE
select YEAR,SPECIES_CODE,
stratum,SUM(STRATUM_BIOMASS) STRATUM_BIOMASS, SUM(BIO_VAR)BIO_VAR,
SUM(STRATUM_POP)STRATUM_POP,SUM(POP_VAR) POP_VAR,
sum(DFWGT) dfwgt,
SUM(dfnum) dfnum
from sub_degree
GROUP BY YEAR,SPECIES_CODE,stratum;

select * from degree  where species_code=21740 and year=2002;

INSERT INTO DEGREE
select YEAR,SPECIES_CODE,
999999 stratum,SUM(STRATUM_BIOMASS) STRATUM_BIOMASS, SUM(BIO_VAR)BIO_VAR,
SUM(STRATUM_POP)STRATUM_POP,SUM(POP_VAR) POP_VAR,
sum(DFWGT) dfwgt,
SUM(dfnum) dfnum
from degree
where stratum not in(1,2,3,4,5,6)
GROUP BY YEAR,SPECIES_CODE
order by YEAR,SPECIES_CODE;

select * from degree  where species_code=21740 and year=2002;
order by stratum;
drop table sub_degree;

drop table BIOMASS_ebssLOPE;
create table BIOMASS_ebssLOPE as
SELECT  B.YEAR,
        B.STRATUM,
        B.SPECIES_CODE,
        B.haul_count,
        B.catch_count,
        B.MEAN_WGT_CPUE,
        B.VAR_WGT_CPUE,
        B.MEAN_NUM_CPUE,
        B.VAR_NUM_CPUE,
        B.STRATUM_BIOMASS,
        B.BIO_VAR,
        decode(sign(B.STRATUM_BIOMASS-(ninety_five*sqrt(B.BIO_VAR))),-1,0,0,0,1,
        (B.STRATUM_BIOMASS-(ninety_five*sqrt(B.BIO_VAR)))) MIN_BIOMASS,
        (B.STRATUM_BIOMASS +(ninety_five*sqrt(B.BIO_VAR)))MAX_BIOMASS,
        B.STRATUM_POP,
        B.POP_VAR,
        decode(sign(B.STRATUM_POP-(ninety_five*sqrt(B.POP_VAR))),-1,0,0,0,1,
        (B.STRATUM_POP-(ninety_five*sqrt(B.POP_VAR)))) MIN_POP,
        (B.STRATUM_POP +(ninety_five*sqrt(B.POP_VAR)))MAX_POP
FROM degree A,PREbiomass_ebssLOPE B,lauthb.gwttable 
WHERE 
        A.YEAR=B.YEAR AND 
        A.STRATUM=B.STRATUM AND 
        A.SPECIES_CODE=B.SPECIES_CODE AND
        (dfwgt >=degreef_from and dfwgt < degreef_to)
order by species_code,year,stratum;

select * from BIOMASS_ebssLOPE  where species_code=21740 and year=2002;

/* EBSSLOPE_SIZECOMPS */
/* EBSSLOPE_SIZECOMPS */
/* EBSSLOPE_SIZECOMPS */
/* EBSSLOPE_SIZECOMPS */
/* EBSSLOPE_SIZECOMPS */

DROP TABLE TOT;
DROP VIEW TOT;
create table tot as
select YEAR,hauljoin,species_code,
sum(frequency) totbyhaul
from LENGTH_ebsslope
group by YEAR,hauljoin,species_code;



/*  NOW, THIS SECTION PUTS THE LENGTH DATA AND TOT VIEW TOGETHER */
/*  TO GET A RATIO OF FREQ TO TOTBYHAUL FOR MALES  */
drop table ratiomale;
create table ratiomale as
select t.YEAR,t.hauljoin,T.species_code,
length,sex,frequency/totbyhaul ratiom 
from tot,LENGTH_ebsslope t 
where t.species_code = tot.species_code and sex = 1 and
tot.hauljoin=t.hauljoin;

/* NOW FEMALES */
drop table ratiofemale;
create table ratiofemale as
select t.YEAR,t.hauljoin,T.species_code,
length,sex,frequency/totbyhaul ratiof
from tot,LENGTH_ebsslope t 
where t.species_code = tot.species_code and sex = 2 and
tot.hauljoin=t.hauljoin;

/* NOW UNSEXED */
drop table ratiounsex;
create table ratiounsex as
select t.YEAR,t.hauljoin,T.species_code,
length,sex,frequency/totbyhaul ratiou 
from tot,LENGTH_ebsslope t 
where t.species_code = tot.species_code and sex = 3 and
tot.hauljoin=t.hauljoin;




/*  NEXT, WE MAKE A MASTER LIST OF EVERY HAUL,LENGTH PRESENT IN THE */
/*  LENGTH DATA */
drop table table masterlen;
create table masterlen as
select distinct year,hauljoin,species_code,length 
from LENGTH_ebsslope
ORDER BY year,hauljoin,species_code,length;

/*  NOW WE EXPAND THE RATIO DATA OUT TO INCLUDE THOSE HAULS, LENGTHS */
/*  WHERE THEY DIDN'T OCCUR - JUST LIKE CPUE DATA WE PICK UP THE ZEROES */
/*  START WITH MALES */

drop view addstratm;
drop table addstratm;
create view addstratm as
select l.year, l.hauljoin,l.species_code,l.length,0.0 ratiom
from ratiomale m,masterlen l
where l.hauljoin = m.hauljoin(+) and
m.hauljoin is NULL and
l.species_code = m.species_code(+) and
m.species_code is NULL and
m.length(+) = l.length
union
select l.year, l.hauljoin,l.species_code,l.length,ratiom
from ratiomale m, masterlen l
where 
m.hauljoin = l.hauljoin and m.species_code=l.species_code 
and l.length = m.length;

/*  THEN FEMALES */

drop view addstratf;
drop table addstratf;
create view addstratf as
select l.year, l.hauljoin,l.species_code,l.length,0.0 ratiof
from ratiofemale m,masterlen l
where l.hauljoin = m.hauljoin(+) and
m.hauljoin is NULL and
l.species_code = m.species_code(+) and
m.species_code is NULL and
m.length(+) = l.length
union
select l.year, l.hauljoin,l.species_code,l.length,ratiof
from ratiofemale m, masterlen l
where 
m.hauljoin = l.hauljoin and m.species_code=l.species_code 
and l.length = m.length;

/* THEN UNSEXED */

drop view addstratu;
drop table addstratu;
create view addstratu as
select l.year, l.hauljoin,l.species_code,l.length,0.0 ratiou
from ratiounsex m,masterlen l
where l.hauljoin = m.hauljoin(+) and
m.hauljoin is NULL and
l.species_code = m.species_code(+) and
m.species_code is NULL and
m.length(+) = l.length 
union
select l.year, l.hauljoin,l.species_code,l.length,ratiou
from ratiounsex m, masterlen l
where 
m.hauljoin = l.hauljoin and m.species_code=l.species_code 
and l.length = m.length;

/*  NOW WE PUT ALL THE DATA FOR EACE SEX TOGETHER IN ONE BIG TABLE */
drop view totallen;
drop table totallen;
create table totallen as 
select 
  l.year, l.hauljoin,l.species_code,l.length,ratiom,ratiof,ratiou,stratum 
from 
  masterlen l,addstratm m,addstratf f,addstratu u,HAUL_ebsslope h 
where
l.year = m.year and m.year = f.year and f.year = u.year and u.year = h.year and
l.hauljoin = m.hauljoin and m.hauljoin = f.hauljoin and f.hauljoin = u.hauljoin and u.hauljoin = h.hauljoin 
and  l.species_code =m.species_code  and m.species_code = f.species_code  and f.species_code = u.species_code
and l.length = m.length and m.length = f.length and f.length = u.length;


/*  -----------THAT ENDS THE LENGTH PORTION TILL THE END -----*/

/*  NOW WE ESTIMATE THE POPULATION THAT WE WILL DISTRIBUTE INTO A */
/*  SIZE COMPOSTION BY STRATUM THAT WILL BE SUMMED UP TO  */
/*  A TOTAL */

/* THIS SECTION CALCULATES THE MEAN CPUE IN A STRATUM USING */
/* ALL HAULS */
drop table stratavg;
create table stratavg as
select 
  year,species_code,stratum, avg(numcpue) avgcpue 
from 
  CPUE_EBSSLOPE 
group by
  year,species_code,stratum;

/* NOW, THIS SECTION CALCULATES THE SUM OF THE CPUE'S */
/* IN A STRATUM FOR HAULS WITH LF */

drop table strattot;
drop view strattot;
create table strattot as
select year,species_code, stratum, sum(numcpue)sumcpue 
from CPUE_EBSSLOPE
group by  year,species_code,stratum
order by year,species_code,stratum;

/* THIS SECTION THEN CALCULATES THE RATIO OF EACH HAUL CPUE TO THE */
/* TOTAL STRATUM CPUE. THE HIGHER THE CPUE, THE HIGHER THE RATIO AND */
/* THE MORE EFFECT IT WILL HAVE ON THE OUTPUT SIZECOMP */

drop table cpueratio;
drop view cpueratio;
create table cpueratio as
select w.year, w.hauljoin,w.species_code,w.stratum,numcpue,numcpue/(decode(sumcpue,0,1,sumcpue)) cprat 
from CPUE_EBSSLOPE w,strattot s 
where w.year=s.year
and w.species_code=s.species_code
and w.stratum = s.stratum;

/* THIS SECTION CALCULATES THE POPULATION IN A STRATUM */
drop table poplist;
create table poplist as
select 
    s.year,s.species_code,s.stratum, (avgcpue * area) population,
    decode(s.stratum,11,1,12,1,13,1,14,1,15,1,21,2,22,2,23,2,
            24,2,25,2,31,3,32,3,33,3,34,3,35,3,41,4,42,4,43,4,
            44,4,45,4,51,5,52,5,53,5,54,5,55,5,61,6,62,6,63,6,64,6,65,6,-9)subarea
from 
    stratavg s, racebase.stratum a 
where 
    s.stratum = a.stratum and a.region = 'BS' and a.year=2002
order by
    s.year,s.species_code,s.stratum;
    

 


/* FINALLY, WE HAVE ALL THE PIECES NECESSARY. */
/* THIS SECTION MULTIPLIES RATIO OF CPUES TIMES RATIO OF LENGTHS */
/* TIMES POPULATION AND SUMS OVER STRATUM FOR EACH SPECIES,LENGTH */
drop table SIZECOMP_ebsslope;
create table SIZECOMP_ebsslope as
select 
  c.year,
  c.species_code,
  species_name,
  common_name,
  p.stratum,r.length,
  sum(cprat * ratiom * population)males,
  sum(cprat * ratiof * population) females,
  sum(cprat * ratiou * population) unsexed,
  ((sum(cprat*ratiom*population))+(sum(cprat*ratiof*population))+
  (sum(cprat*ratiou*population)))total
from 
  totallen r, cpueratio c, poplist p, racebase.species s 
where 
  r.year=c.year and c.year=p.year
  and r.hauljoin=c.hauljoin 
  and  r.stratum = c.stratum 
  and c.stratum=p.stratum
  and r.species_code=c.species_code 
  and c.species_code=p.species_code
  and p.species_code=s.species_code
group by 
  c.year,
  c.species_code,
  species_name,
  common_name,
  p.stratum,
  r.length
UNION
select 
  c.year, 
  c.species_code,   
  species_name,
  common_name,
  p.subarea stratum,
  r.length,
  sum(cprat * ratiom * population)males,
  sum(cprat * ratiof * population) females,
  sum(cprat * ratiou * population) unsexed,
  ((sum(cprat*ratiom*population))+(sum(cprat*ratiof*population))+
  (sum(cprat*ratiou*population)))total
from 
  totallen r, cpueratio c, poplist p, racebase.species s 
where 
  r.year=c.year 
  and c.year=p.year
  and r.hauljoin=c.hauljoin 
  and r.species_code=c.species_code 
  and c.species_code=p.species_code
  and p.species_code=s.species_code
  and  r.stratum = c.stratum 
  and c.stratum=p.stratum
group by 
  c.year,
  c.species_code,
  species_name,
  common_name,
  p.subarea,
  r.length
UNION
select 
  c.year, 
  c.species_code,   
  species_name,
  common_name, 
  p.subarea stratum,
  9999 LENGTH,
  sum(cprat * ratiom * population)males,
  sum(cprat * ratiof * population) females,
  sum(cprat * ratiou * population) unsexed,
  ((sum(cprat*ratiom*population))+(sum(cprat*ratiof*population))+
  (sum(cprat*ratiou*population)))total
from 
  totallen r, cpueratio c, poplist p, racebase.species s 
where 
  r.year=c.year 
  and c.year=p.year
  and r.hauljoin=c.hauljoin 
  and r.species_code=c.species_code 
  and c.species_code=p.species_code
  and p.species_code=s.species_code
  and  r.stratum = c.stratum 
  and c.stratum=p.stratum
group by 
  c.year,
  c.species_code,
  species_name,
  common_name,
  p.subarea
UNION
select 
  c.year, 
  c.species_code,   
  species_name,
  common_name,  
  999999 STRATUM, 
  9999 LENGTH,
  sum(cprat * ratiom * population)males,
  sum(cprat * ratiof * population) females,
  sum(cprat * ratiou * population) unsexed,
  ((sum(cprat*ratiom*population))+(sum(cprat*ratiof*population))+
  (sum(cprat*ratiou*population)))total
from 
  totallen r, cpueratio c, poplist p, racebase.species s 
where 
  P.STRATUM>9 
  AND r.year=c.year 
  and c.year=p.year
  and r.hauljoin=c.hauljoin 
  and r.species_code=c.species_code 
  and c.species_code=p.species_code
  and p.species_code=s.species_code
  and  r.stratum = c.stratum 
  and c.stratum=p.stratum
group by 
  c.year,
  c.species_code,
  species_name,
  common_name
order by  
  species_code,year,stratum,length;


drop table spplist;
create table spplist as
select distinct species_code from SIZECOMP_ebsslope;


insert into poplist
select 
    year,
    species_code,
    decode(stratum,11,1,12,1,13,1,14,1,15,1,21,2,22,2,23,2,
        24,2,25,2,31,3,32,3,33,3,34,3,35,3,41,4,42,4,43,4,44,4,
        45,4,51,5,52,5,53,5,54,5,55,5,61,6,62,6,63,6,64,6,65,6,-9) stratum, 
        sum(population) population, 9999 subarea
from 
    poplist 
group by
    year,
    species_code,
   decode(stratum,11,1,12,1,13,1,14,1,15,1,21,2,22,2,23,2,
        24,2,25,2,31,3,32,3,33,3,34,3,35,3,41,4,42,4,43,4,44,4,
        45,4,51,5,52,5,53,5,54,5,55,5,61,6,62,6,63,6,64,6,65,6,-9)
order by
    year,species_code,stratum;
    
drop table prepop_nolengths;
create table prepop_nolengths as
select 
  a.year,
  a.stratum,
  a.species_code,
  c.species_name, 
  a.total,0.0 population
from 
  SIZECOMP_ebsslope a, racebase.species c
where 
  a.species_code=c.species_code
  and a.length<>9999
UNION
select 
  a.year,
  a.stratum,
  a.species_code,
  c.species_name, 
  0.0 total,
  population
from 
   poplist a, spplist b, racebase.species c
where 
  a.species_code=b.species_code
  and b.species_code=c.species_code
order by 
  year,
  species_code,
  stratum;
  
drop table pop_nolengths;
create table pop_nolengths as
select 
  year,
  stratum,
  species_code,
  species_name, 
  sum(total) total,sum(population) population
from prepop_nolengths
group by
  year,
  stratum,
  species_code,
  species_name
order by
  year,
  species_code,
  stratum;

insert into SIZECOMP_ebsslope
select 
  year, 
  species_code,
  stratum,
  -9 length,
  0.0 males,
  0.0 females,
  0.0 unsexed,
  (population-total) total
from
  pop_nolengths
where 
  total<>population
  order by
  species_code,year,stratum;
  
insert into SIZECOMP_ebsslope
select 
  year, 
  species_code,
  999999 stratum,
  -9 length,
  0.0 males,
  0.0 females,
  0.0 unsexed,
  sum(total) total
from
  SIZECOMP_ebsslope
where 
  length=-9
  and stratum<7
group by
  year, 
  species_code
order by
  species_code,year,stratum;


select * from SIZECOMP_ebsslope
where year=2016
and species_code=320
order by species_code,year,stratum


select sum(population) totpop from poplist
where year=2016 and species_code=320 and stratum<7
order by year, species_code,stratum



drop table surveys_ebsslope;
create table surveys_ebsslope as
select distinct c.CRUISEJOIN,
'EBS_Slopw' survey,
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
from racebase.cruise c, HAUL_ebsslope h
where c.cruisejoin=h.cruisejoin
and c.vessel=h.vessel
and c.cruise=h.cruise
and to_number(to_char(start_date,'yyyy'))=h.year
order by year;


drop table HCOUNT; 
drop table MASTERLEN;                      
drop table RATIOFEMALE;                    
drop table RATIOMALE;                      
drop table RATIOUNSEX;
drop table TOT;                            
drop table TOTALLEN;                       
drop table TOT_TOWAREA_BYSTRAT;    
drop view addstratf;
drop view addstratm;
drop view addstratu;
drop view biocatch;
drop view biolength;
drop view fi;
drop view slope_totarea;
drop view CHUKCHI2012_CATCH;
drop view CHUKCHI2012_CATCH_83112;
drop view CHUKCHI2012_CATCH_pbst;
drop table allspp;
drop table stratlist;
drop table biopopvar;
DROP TABLE SUBAREA_BIOMASS;
drop table biopopvar_stratum;
drop table biopopvar_subarea;
drop table ccountot;
drop table pccountot;
drop table subarea_pccountot;
drop table prebiopopvar_subarea;
drop table pccountot2;
drop table biovar;
drop table ccount;
drop table degree;
drop table falsecnt;
drop table hcount;
drop table PREBIOMASS_EBSSLOPE;
drop table TOT_TOWAREA_BYSTRAT;
drop table varstrat;
  drop table poplist;
    drop table cpueratio;
      drop table masterlen;
        drop table tot;
          drop table stratavg;
            drop table totallen;
              drop table ratiofemale;
                drop table ratiomale;
                  drop table ratiounsex;
                    drop table strattot;
                    drop table COMB_DEPTH_STRATA;
                    drop table cpue_ebsslope_pos;
REM ****DAN--- INCORPORATE BOBS SELECT HERE TO CORRECTLY GET NONMERGED LENGTHS COLLECTED 
REM  THIS SCRIPT GRABS ALL SPECIES THAT WERE PRESENT IN THE LENGTH TABLE FOR NBS HAULS

REM modified 9/22/2023 updated masterhaul_nbsshelf table to current survey year

/*  THIS SECTION GETS THE PROPER HAUL TABLE */
REM ***THIS GRABS THE MOST UP-TO-DATE CRUISEJOINS***


drop  table masterhaul_nbsshelf; 
create table masterhaul_nbsshelf as 
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
	AND B.YEAR in (2010, 2017, 2019, 2021, 2022,2023);

REM ***LINE NOT NEEDED ANYMORE - 'AA-10 HAUL_TYPE CHANGED TO ZERO***   delete from masterhaul_nbsshelf where stationid='AA-10';


REM THIS SECTION COUNTS HAULS, HAULS W/CATCH, HAULS W/LENGTH */
REM FOR A DATA SUMMARY */

drop table total_hauls;
drop view total_hauls;
create table total_hauls as
select to_char(start_time,'YYYY') year,count(*) total_hauls from masterhaul_nbsshelf 
group by to_char(start_time,'YYYY');

drop table hauls_w_length;
drop view hauls_w_length;
create table hauls_w_length as
select species_code, trunc(l.cruise/100) year, count(distinct l.hauljoin) hauls_w_length 
from racebase.length l, masterhaul_nbsshelf h
where  l.hauljoin=h.hauljoin 
group by species_code, trunc(l.cruise/100);

REM *****************************************************************************************************
REM THIS SECTION GETS THE NUMBER OF FISH MEASURED (EXCLUDES EXPANDED NUMBERS FROM MERGED JUVENILES AND ADULTS)

REM THIS PART GETS ALL THE PRE-2005 LENGTH SUMMARIES PRIOR TO GIDES
drop table num_lengths1;
drop view num_lengths1;
create table num_lengths1 as 
select species_code, trunc(l.cruise/100) year,sum(frequency) num_lengths 
from racebase.length l, masterhaul_nbsshelf h 
where  l.hauljoin=h.hauljoin 
and h.year<2005 
group by species_code, trunc(l.cruise/100);

REM THIS GETS ALL THE >=2005 YEARS WHEN GIDES KICKED IN - AND INCLUDES RECENT YEARS WHEN JUV & ADULT MERGING OCCURRED
drop table num_lengths2;
create table num_lengths2 as
SELECT SPECIES_CODE, h.YEAR, SUM(FREQUENCY) num_lengths
FROM masterhaul_nbsshelf H, race_data.lengths L, RACE_DATA.HAULS A
WHERE  A.CRUISE_id=-H.CRUISEJOIN AND A.HAUL=H.HAUL AND A.HAUL_ID=L.HAUL_ID and 
h.year>=2005 
GROUP BY h.YEAR, SPECIES_CODE
ORDER BY h.YEAR, SPECIES_CODE;

REM NOW COMBINE THE UPPER TWO TABLES
drop table num_lengths;
create table num_lengths as select * from num_lengths1;
insert into num_lengths select * from num_lengths2;

drop table num_lengths1;
drop table num_lengths2;


REM ****************************************************************************************************

drop table hauls_w_otoliths;
drop view hauls_w_otoliths;
create table hauls_w_otoliths as 
select species_code, trunc(s.cruise/100) year, count(distinct s.hauljoin) hauls_w_otoliths 
from racebase.specimen s, masterhaul_nbsshelf h 
where  s.hauljoin=h.hauljoin and specimen_sample_type<>8
group by species_code,trunc(s.cruise/100);

drop table hauls_w_ages;
drop view hauls_w_ages;
create table hauls_w_ages as 
select species_code, trunc(s.cruise/100) year, count(distinct s.hauljoin) hauls_w_ages 
from racebase.specimen s, masterhaul_nbsshelf h 
where s.hauljoin=h.hauljoin and age >=0 
group by species_code, trunc(s.cruise/100);

drop table num_otoliths;
drop view num_otoliths;
create table num_otoliths as 
select species_code, trunc(s.cruise/100) year, count(specimenid) num_otoliths 
from racebase.specimen s, masterhaul_nbsshelf h 
where  s.hauljoin=h.hauljoin  and specimen_sample_type<>8
group by species_code, trunc(s.cruise/100);


drop table num_ages;
drop view num_ages;
create table num_ages as 
select species_code, trunc(s.cruise/100) year, count(age) num_ages 
from racebase.specimen s, masterhaul_nbsshelf h 
where  s.hauljoin=h.hauljoin and age >=0 
group by species_code, trunc(s.cruise/100);

drop table samplesize_nbs;
create table samplesize_nbs as select * from hauls_w_length;
alter table samplesize_nbs add total_hauls number;
alter table samplesize_nbs add num_lengths number;
alter table samplesize_nbs add hauls_w_otoliths number;
alter table samplesize_nbs add hauls_w_ages number;
alter table samplesize_nbs add num_otoliths number;
alter table samplesize_nbs add num_ages number;


update samplesize_nbs a set a.total_hauls=(select b.total_hauls from total_hauls b where a.year=b.year(+));
update samplesize_nbs a set hauls_w_length=(select hauls_w_length from hauls_w_length b where a.species_code=b.species_code(+) 
and a.year=b.year(+));
update samplesize_nbs a set num_lengths=(select num_lengths from num_lengths b where a.species_code=b.species_code(+) 
and a.year=b.year(+));
update samplesize_nbs a set hauls_w_otoliths=(select hauls_w_otoliths from hauls_w_otoliths b where a.species_code=b.species_code(+) 
and a.year=b.year(+));
update samplesize_nbs a set hauls_w_ages=(select hauls_w_ages from hauls_w_ages b where a.species_code=b.species_code(+) 
and a.year=b.year(+));
update samplesize_nbs a set num_otoliths=(select num_otoliths from num_otoliths b where a.species_code=b.species_code(+) 
and a.year=b.year(+));
update samplesize_nbs a set num_ages=(select num_ages from num_ages b where a.species_code=b.species_code(+) 
and a.year=b.year(+));


select a.species_code, species_name, common_name, year, total_hauls, hauls_w_length, num_lengths, hauls_w_otoliths, hauls_w_ages, num_otoliths, num_ages
 from samplesize_nbs a, racebase.species b where a.species_code=b.species_code order by a.species_code, year;
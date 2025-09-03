
REM SPOOLS ALL FLATFISH SIZECOMPS FOR PLUSNW - MUST EXPORT TO CSV - NOT ALL ROWS TRANSFERRED WITH XLS.
REM  EXPORT AS FLAT FILE: flatfish_sizecomp_ebs_plusnw.xls
select a.species_code,b.species_name, b.common_name,  year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10262,10270,10285)
order by b.species_code, year, stratum, length;

REM SPOOLS ALL FLATFISH SIZECOMPS FOR STANDARD - MUST EXPORT TO CSV - NOT ALL ROWS TRANSFERRED WITH XLS.
REM  EXPORT AS FLAT FILE: flatfish_sizecomp_ebs_standard.xls
select a.species_code,b.species_name, b.common_name,  year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_standard_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (10110,10112,10115,10120,10130,10140,10180,10200,10210,10211,10212,10220,10262,10270,10285)
order by b.species_code, year, stratum, length;

REM SPOOLS RS + NRS SIZECOMPS FOR PLUSNW 
REM  EXPORT AS FLAT FILE: nrs_sizecomp_ebs_plusnw.xls
select a.species_code,b.species_name, b.common_name,  year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (10260,10261)
order by b.species_code, year, stratum, length;

REM SPOOLS RS + NRS SIZECOMPS FOR STANDARD AREA
REM  EXPORT AS FLAT FILE: nrs_sizecomp_ebs_standard.xls
select a.species_code,b.species_name, b.common_name,  year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_standard_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (10260,10261)
order by b.species_code, year, stratum, length;


REM SPOOLS PCOD SIZECOMPS FOR PLUSNW AREA FOR GRANT
REM  EXPORT AS FLAT FILE: pcod_sizecomp_ebs_plusnw.xls
select a.species_code,b.species_name, b.common_name,  year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (21720)
order by b.species_code, year, stratum, length;

REM SPOOLS PCOD SIZECOMPS FOR STANDARD AREA FOR GRANT
REM  EXPORT AS FLAT FILE: pcod_sizecomp_ebs_standard.xls
select a.species_code,b.species_name, b.common_name,  year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_standard_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (21720)
order by b.species_code, year, stratum, length;


REM SPOOLS HALIBUT SIZECOMPS FOR PLUSNW
REM  EXPORT AS FLAT FILE: halibut_sizecomp_ebs_plusnw.xls
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =10120 
order by b.species_code, year, stratum, length;

REM SPOOLS HALIBUT SIZECOMPS FOR STANDARD AREA
REM  EXPORT AS FLAT FILE: halibut_sizecomp_ebs_standard.xls
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_standard_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =10120 
order by b.species_code, year, stratum, length;

REM SPOOLS SKATE SIZECOMPS FOR PLUSNW 
REM  EXPORT AS FLAT FILE: skates_sizecomp_ebs_plusnw.xls
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (420,435,471,472)
order by b.species_code, year, stratum, length;

REM SPOOLS GROUPED ATF + KAM FOR PLUSNW AREA
REM  EXPORT AS FLAT FILE: atfkam_sizecomp_ebs_plusnw_grouped.xls
drop table temp;
create table temp as
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum_grouped a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =10111 
order by b.species_code, year, stratum, length;
update temp set common_name='Arrowtooth flounder + Kamchatka flounder';
select * from temp order by species_code, year, stratum, length;

REM SPOOLS GROUPED ATF + KAM FOR STANDARD AREA
REM  EXPORT AS FLAT FILE: atfkam_sizecomp_ebs_standard_grouped.xls 
drop table temp;
create table temp as
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_standard_stratum_grouped a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =10111 
order by b.species_code, year, stratum, length;
update temp set common_name='Arrowtooth flounder + Kamchatka flounder';
select * from temp order by species_code, year, stratum, length;

REM SPOOLS GROUPED FHS + BERING FLOUNDER FOR PLUSNW AREA
REM  EXPORT AS FLAT FILE: fhsberingfl_sizecomp_ebs_plusnw_grouped.xls 
drop table temp;
create table temp as
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum_grouped a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =10129 
order by b.species_code, year, stratum, length;
update temp set common_name='Flathead sole + Bering flounder';
select * from temp order by species_code, year, stratum, length;

REM SPOOLS GROUPED FHS + BERING FLOUNDER FOR STANDARD AREA
REM  EXPORT AS FLAT FILE: fhsberingfl_sizecomp_ebs_standard_grouped.xls 
drop table temp;
create table temp as
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_standard_stratum_grouped a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =10129 
order by b.species_code, year, stratum, length;
update temp set common_name='Flathead sole + Bering flounder';
select * from temp order by species_code, year, stratum, length;

REM SPOOLS SCULPIN SIZECOMPS FOR PLUSNW AREA (SS AUTHORS HAVE NOT WANTED STANDARD AREA FOR SCULPINS)
REM  EXPORT AS FLAT FILE: sculpins_sizecomp_ebs_plusnw.xls
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code in (21420,21371,21370,21368,21347)
order by b.species_code, year, stratum, length;

REM SPOOLS PCOD SIZECOMPS FOR PLUSNW AREA
REM  EXPORT AS FLAT FILE: pcod_sizecomp_ebs_plusnw.xls
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =21720 
order by b.species_code, year, stratum, length;

REM SPOOLS PCOD SIZECOMPS FOR STANDARD AREA
REM  EXPORT AS FLAT FILE: pcod_sizecomp_ebs_standard.xls
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_standard_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =21720 
order by b.species_code, year, stratum, length;

REM SPOOLS POLLOCK SIZECOMPS FOR PLUSNW AREA  (STANDARD AREA NOT USED BY SS AUTHORS FOR POLLOCK)
REM  EXPORT AS FLAT FILE: pollock_sizecomp_ebs_plusnw.xls
select a.species_code, b.species_name, b.common_name, year, stratum, length,
round(males) males, round(females) females, round(unsexed) unsexed, round(total) total  
from sizecomp_ebs_plusnw_stratum a, racebase.species b
where a.species_code=b.species_code 
and a.species_code =21740 
order by b.species_code, year, stratum, length;

















********************************************************************************
* 03 - GTI Construction Excluding 9/11 (Robustness)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Constructs a variant of the GTI that excludes the September 11, 2001 attacks for robustness checks (Table 2, column 2).
*
* Input:   GTD event-level data (1970-2016)
*
* Output:  Terror origin without 1109.dta, Terror dest without 1109.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

cls 
clear all 
set more off, permanently
set scrollbufsize 500000 
set maxvar 120000
set matsize 11000
capture log close 

*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\" 
cd "D:\Dropbox\PhD Killian\Paper I\"

*cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

use "Data/GTD/Old/Dta/1970-1994_stataversion.dta", clear

append using "Data/GTD/Old/Dta/1993_stataversion.dta", force
append using "Data/GTD/Old/Dta/1995-2012_stataversion.dta", force
append using "Data/GTD/Old/Dta/2013-2016_stataversion.dta", force

order iyear country_txt country imonth iday
sort iyear country_txt imonth iday

drop eventid approxdate location summary attacktype2 attacktype2_txt attacktype3 attacktype3_txt corp1 target1 corp2 target2 targtype3 targtype3_txt targsubtype3 targsubtype3_txt corp3 target3 natlty3 natlty3_txt gname gsubname gname2 gsubname2 gname3 gsubname3 motive guncertain1 guncertain2 guncertain3 individual nperpcap claimmode claimmode_txt claim2 claimmode2 claimmode2_txt claim3 claimmode3 claimmode3_txt compclaim weapsubtype1 weapsubtype1_txt weapsubtype2 weapsubtype2_txt weapsubtype3 weapsubtype3_txt weapsubtype4 weapsubtype4_txt weapdetail nkillter nwoundte propcomment nhostkidus nhours ndays divert kidhijcountry ransomamt ransomamtus ransompaid ransompaidus ransomnote hostkidoutcome hostkidoutcome_txt nreleased addnotes scite1 scite2 scite3 dbsource related

* Consider 11/09/2001 as an outlier
drop if country_txt=="United States" & iyear==2001 & imonth==9 & iday==11

replace nhostkid=. if nhostkid==-99
replace INT_LOG=. if INT_LOG==-9
replace INT_IDEO=. if INT_IDEO==-9
replace INT_MISC=. if INT_MISC==-9
replace INT_ANY=. if INT_ANY==-9

*** Prepare propvalue to be used for GTI index

replace propvalue=0 if propvalue==-99
gen propvalue1= 1 if propextent==3
replace propvalue1=0 if propvalue1==.
gen propvalue2= 2 if propextent==2 
replace propvalue2=0 if propvalue2==.
gen propvalue3= 3 if propextent==1
replace propvalue3=0 if propvalue3==.

*** Construct raw variables of interest 1.0

gen propvaluetotal=propvalue1+propvalue2+propvalue3
drop propvalue propvalue1 propvalue2 propvalue3

gen NationalTarget=1 if natlty1==country
replace NationalTarget=0 if NationalTarget==.

gen type1=1 if attacktype1==3
replace type1=0 if type1==.

gen type2=1 if targtype1==15
replace type2=0 if type2==.

gen type3=1 if targtype1==22
replace type3=0 if type3==.

gen type4=1 if weaptype1==6
replace type4=0 if type4==.

*** Change countries names

replace country_txt="Bosnia and Herzegovina" if country_txt=="Bosnia-Herzegovina"
replace country_txt="Republic of Congo" if country_txt=="Republic of the Congo"
replace country_txt="Timor-Leste" if country_txt=="East Timor"
replace country_txt="Côte d'Ivoire" if country_txt=="Ivory Coast"
replace country_txt="Guyana" if country_txt=="French Guiana"
replace country_txt="Saint Lucia" if country_txt=="St. Lucia"
replace country_txt="Macao" if country_txt=="Macau"
replace country_txt="Democratic Republic of the Congo" if country_txt=="People's Republic of the Congo"
replace country_txt="Saint Kitts and Nevis" if country_txt=="St. Kitts and Nevis"
replace country_txt="Palestina" if country_txt=="West Bank and Gaza Strip"

rename country_txt origin
replace origin="Germany" if origin=="East Germany (GDR)"
replace origin="Germany" if origin=="West Germany (FRG)"
replace origin="Slovakia" if origin=="Slovak Republic"
replace origin="USSR Soviet Union" if origin=="Soviet Union"

merge m:1 origin using "Data/iso3/Clean/Dta/iso3clean origin.dta"
drop if _merge==2
drop _merge

replace iso3o="CSK" if origin=="Czechoslovakia"
replace iso3o="DEU" if origin=="Germany"
* WARNING: For these two, we can think that the effect of one attack in the FRG might not have the same impact on the GDR than on the FRG before 1990, and even maybe after. Should I exclude Germany in a robustness check to avoid that bias? 
replace iso3o="SCG" if origin=="Serbia-Montenegro"
replace iso3o="SYE" if origin=="South Yemen"
replace iso3o="NYE" if origin=="North Yemen"
* I made that up to try keeping the observations for South/North Yemen
replace iso3o="USR" if origin=="USSR Soviet Union"
replace iso3o="YUG" if origin=="Yugoslavia"

drop if origin=="International"
drop if iso3o==""

drop imonth provstate city latitude longitude

*** Construct raw variables of interest 2.0

egen BombingPCPY= sum(type1), by(iyear origin)
* This command gives the number of attacks type "bombing/explosion" per YEAR per COUNTRY

egen TargReligPCPY= sum(type2), by(iyear origin)
* This command gives the number of attacks targetting "religious figures and institutions" per YEAR per COUNTRY

egen TargViolPolPCPY= sum(type3), by(iyear origin)
* This command gives the number of attacks targetting "violent political parties" per YEAR per COUNTRY

egen WeapBombPCPY= sum(type4), by(iyear origin)
* This command gives the number of attacks with explosives/Bombs/Dynamite per YEAR per COUNTRY

egen NationalTargPCPY= sum(NationalTarget), by(iyear origin)
* This command gives the number of attacks targetting national people per YEAR per COUNTRY

egen VictimsPCPY= sum(nkill), by(iyear origin)
* This command gives the number of victims per YEAR per COUNTRY

egen WoundedPCPY= sum(nwound), by(iyear origin)
* This command gives the number of wounded per YEAR per COUNTRY

gen var1=1
egen AttacksPCPY= sum(var1), by(iyear origin)
drop var1
* This command gives the number of attacks per YEAR per COUNTRY

egen propvaluePCPY= sum(propvaluetotal), by(iyear origin)
* This command gives the value of property damage per YEAR per COUNTRY

keep iyear iso3o origin VictimsPCPY WoundedPCPY AttacksPCPY NationalTargPCPY BombingPCPY TargViolPolPCPY propvaluePCPY TargReligPCPY

*** Keep unique values per country year
duplicates drop
// (167,279 observations deleted)

rename iyear year

*** Cumulative attacks
// First, need to create a full matrix to keep all the information when lagging variables

egen o = group(origin)
egen t = group(year)

tsset o t
tsfill, full

bysort t: carryforward year, gen(yearn)
bysort o: carryforward origin iso3o, gen(originn iso3oo)
drop year origin iso3o

gsort o - t

bysort t: carryforward yearn, gen(yearnn)
bysort o: carryforward originn iso3oo, gen(originnn iso3ooo)
drop yearn originn iso3oo

gsort o - t

bysort t: carryforward yearnn, gen(yearnnn)
bysort o: carryforward originnn iso3ooo, gen(originnnn iso3oooo)
drop yearnn originnn iso3ooo

gsort o - t

bysort t: carryforward yearnnn, gen(yearnnnn)
bysort o: carryforward originnnn iso3oooo, gen(originnnnn iso3ooooo)
drop yearnnn originnnn iso3oooo

gsort o - t

bysort t: carryforward yearnnnn, gen(yearnnnnn)
bysort o: carryforward originnnnn iso3ooooo, gen(originnnnnn iso3oooooo)
drop yearnnnn originnnnn iso3ooooo

rename yearnnnnn year
rename originnnnnn origin
rename iso3oooooo iso3o
order origin year
sort origin year

replace VictimsPCPY=0 if VictimsPCPY==.
replace WoundedPCPY=0 if WoundedPCPY==.
replace AttacksPCPY=0 if AttacksPCPY==.
replace NationalTargPCPY=0 if NationalTargPCPY==.
replace BombingPCPY=0 if BombingPCPY==.
replace TargViolPolPCPY=0 if TargViolPolPCPY==.
replace propvaluePCPY=0 if propvaluePCPY==.
replace TargReligPCPY=0 if TargReligPCPY==.
gen AttackOccurrencePCPY=1 if AttacksPCPY>0
replace AttackOccurrencePCPY=0 if AttackOccurrencePCPY==.

*** Total GTI raw score
gen GTIPCPY=AttacksPCPY+3*VictimsPCPY+0.5*WoundedPCPY+2*propvaluePCPY

*** Total number of victims (fatalities + wounded)
rename VictimsPCPY FatalitiesPCPY
gen VictimsPCPY=FatalitiesPCPY+WoundedPCPY

sort o t

*** Lag variables up to 4 years before

forval i = 1/4 {  
gen GTIPCPYL`i'=L`i'.GTIPCPY
gen AttackOccurrencePCPYL`i'=L`i'.AttackOccurrencePCPY
gen AttacksPCPYL`i'=L`i'.AttacksPCPY
gen VictimsPCPYL`i'=L`i'.VictimsPCPY
gen BombingPCPYL`i'=L`i'.BombingPCPY
gen NationalTargPCPYL`i'=L`i'.NationalTargPCPY
gen TargViolPolPCPYL`i'=L`i'.TargViolPolPCPY
gen TargReligPCPYL`i'=L`i'.TargReligPCPY
}

gen AttackOccurrence=1 if AttackOccurrencePCPY==1 | AttackOccurrencePCPYL1==1 | AttackOccurrencePCPYL2==1 | AttackOccurrencePCPYL3==1 | AttackOccurrencePCPYL4==1
replace AttackOccurrence=0 if AttackOccurrence==.

*** Time weighting of historical scores

foreach k in GTIPCPY AttacksPCPY VictimsPCPY BombingPCPY NationalTargPCPY TargViolPolPCPY TargReligPCPY {
gen `k'RawScoreA = 16*`k' + 8*`k'L1 + 4*`k'L2 + 2*`k'L3 + 1*`k'L4
}

drop o-t 
drop GTIPCPYL1-TargReligPCPYL4

*** Over 5 years before migration flows

/*
sum GTIPCPYRawScoreA

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
GTIPCPYRaw~A |      8,428     5572.82    38349.78          0    1365103

LOGARITHMIC BANDING SCORES TO OBTAIN VARIABLES ON A SCALE OF 1-10 

1. Define the Minimum GTI Score across all countries as
having a banded score of 0.

2. Define the Maximum GTI Score across all countries as
having a banded score 10.

3. Subtract the Minimum from the Maximum GTI scores
and calculate 'r' by:
a. root = 2 X (Highest GTI Banded Score
– Lowest GTI Banded Score) = 2 X (10–0)=20
b. Range = 1 X (Highest Recorded GTI Raw Score
– Lowest Recorded GTI Raw Score)
c. r = root V range
4. The mapped band cut-off value for bin n is
calculated by r^n.

Formula to find scores cleaned: 
* Scores fine = 1/2 * [log(...RawScoreA/log(r)]
(see computation on the pictures in the Paper II file)
*/

/* GTI
root=2*(10-0)=20
range=(1365103-0)
r=20 V 1365103 = 2.0265544223787
*/

gen GTIA1= log(GTIPCPYRawScoreA)/log(2.0265544223787)
gen GTI= 0.5* GTIA1
replace GTI=0 if GTI==.
drop GTIA1 GTIPCPYRawScoreA

/* Attacks
sum AttacksPCPYRawScoreA
root=2*(10-0)=20
range=(98487-0)
r=20 V 98487 = 1.7769243774029
*/

gen AttacksIndexA1= log(AttacksPCPYRawScoreA)/log(1.7769243774029)
gen AttacksIndex= 0.5* AttacksIndexA1
replace AttacksIndex=0 if AttacksIndex==.
drop AttacksIndexA1 AttacksPCPYRawScoreA

/* Victims
sum VictimsPCPYRawScoreA
root=2*(10-0)=20
range=(775469-0)
r=20 V 775469 = 1.9700544152633
*/

gen VictimsIndexA1= log(VictimsPCPYRawScoreA)/log(1.9700544152633)
gen VictimsIndex= 0.5* VictimsIndexA1
replace VictimsIndex=0 if VictimsIndex==.
drop VictimsIndexA1 VictimsPCPYRawScoreA

/* Bombing
sum BombingPCPYRawScoreA
root=2*(10-0)=20
range=(78564-0)
r=20 V 78564 = 1.7569571889439
*/

gen BombingIndexA1= log(BombingPCPYRawScoreA)/log(1.7569571889439)
gen BombingIndex= 0.5* BombingIndexA1
replace BombingIndex=0 if BombingIndex==.
drop BombingIndexA1 BombingPCPYRawScoreA

/* NationalTarg
sum NationalTargPCPYRawScoreA
root=2*(10-0)=20
range=(98085-0)
r=20 V 98085 = 1.7765610237418
*/

gen NationalTargIndexA1= log(NationalTargPCPYRawScoreA)/log(1.7765610237418)
gen NationalTargIndex= 0.5* NationalTargIndexA1
replace NationalTargIndex=0 if NationalTargIndex==.
drop NationalTargIndexA1 NationalTargPCPYRawScoreA

/* TargViolPol
sum TargViolPolPCPYRawScoreA
root=2*(10-0)=20
range=(2163-0)
r=20 V 2163 = 1.4680904919316
*/

gen TargViolPolIndexA1= log(TargViolPolPCPYRawScoreA)/log(1.4680904919316)
gen TargViolPolIndex= 0.5* TargViolPolIndexA1
replace TargViolPolIndex=0 if TargViolPolIndex==.
drop TargViolPolIndexA1 TargViolPolPCPYRawScoreA

/* TargRelig
sum TargReligPCPYRawScoreA
root=2*(10-0)=20
range=(2557-0)
r=20 V 2557 = 1.4804254293966
*/

gen TargReligIndexA1= log(TargReligPCPYRawScoreA)/log(1.4804254293966)
gen TargReligIndex= 0.5* TargReligIndexA1
replace TargReligIndex=0 if TargReligIndexA==.
drop TargReligIndexA1 TargReligPCPYRawScoreA

*** 1 year before the migration flow

* Attack occurrence
rename AttackOccurrencePCPY AttackOccurrence_1

/* GTI
sum GTIPCPY	 
root=2*(10-0)=20
range=(54260.5-0)
r=20 V 54260.5 = 1.7247422000238
*/

gen GTIA1= log(GTIPCPY)/log(1.7247422000238)
gen GTI_1= 0.5* GTIA1
replace GTI_1=0 if GTI_1==.
drop GTIA1 GTIPCPY

/* Attacks
sum AttacksPCPY
root=2*(10-0)=20
range=(3926-0)
r=20 V 3926 = 1.5125074230944
*/

gen AttacksA1= log(AttacksPCPY)/log(1.5125074230944)
gen Attacks_1= 0.5* AttacksA1
replace Attacks_1=0 if Attacks_1==.
drop AttacksA1 AttacksPCPY

/* Victims
sum VictimsPCPY
root=2*(10-0)=20
range=(29874-0)
r=20 V 29874 = 1.6740355205246
*/

gen VictimsA1= log(VictimsPCPY)/log(1.6740355205246)
gen Victims_1= 0.5* VictimsA1
replace Victims_1=0 if Victims_1==.
drop VictimsA1 VictimsPCPY

/* Bombing
sum BombingPCPY
root=2*(10-0)=20
range=(2866-0)
r=20 V 2866 = 1.4888941011984
*/

gen BombingA1= log(BombingPCPY)/log(1.4888941011984)
gen Bombing_1= 0.5* BombingA1
replace Bombing_1=0 if Bombing_1==.
drop BombingA1 BombingPCPY

/* NationalTarg
sum NationalTargPCPY
root=2*(10-0)=20
range=(3914-0)
r=20 V 3914 = 1.5122759343918
*/

gen NationalTargA1= log(NationalTargPCPY)/log(1.5122759343918)
gen NationalTarg_1= 0.5* NationalTargA1
replace NationalTarg_1=0 if NationalTarg_1==.
drop NationalTargA1 NationalTargPCPY

/* TargViolPol
sum TargViolPolPCPY
root=2*(10-0)=20
range=(100-0)
r=20 V 100 = 1.2589254117942
*/

gen TargViolPolA1= log(TargViolPolPCPY)/log(1.2589254117942)
gen TargViolPol_1= 0.5* TargViolPolA1
replace TargViolPol_1=0 if TargViolPol_1==.
drop TargViolPolA1 TargViolPolPCPY

/* TargRelig
sum TargReligPCPY
root=2*(10-0)=20
range=(116-0)
r=20 V 116 = 1.2683026488017
*/

gen TargReligA1= log(TargReligPCPY)/log(1.2683026488017)
gen TargRelig_1= 0.5* TargReligA1
replace TargRelig_1=0 if TargRelig_1==.
drop TargReligA1 TargReligPCPY

sort origin iso3o year
order origin iso3o year

replace year=year+1
drop if year<1975
* GTD starts in 1970, thus first complete index for 1970-1974 -> 1975

// In that way, terrorism matched with 2000 migration flow will correspond to index of terror computed using 1999-1995 data

drop origin
rename * *_o
rename iso3o_o iso3o
rename year_o year

drop FatalitiesPCPY_o WoundedPCPY_o propvaluePCPY_o

*** GTI spatial lag
preserve
keep year iso3o
duplicates drop
tab iso3o
bysort iso3o: tab year
* As we can see, most of the origin have 43 years corresponding. If we want to balance, we need to drop countries with less than 43y
bysort iso3o : gen N = _N
list if N < 43
drop if N < 43
drop N
save "Data/Merge/Dta/Clean/spmat_raw.dta", replace
drop year
duplicates drop
rename iso3o GID_0
merge m:1 GID_0 using "Maps/worlddata.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                            72
        from master                         6  (_merge==1)
        from using                         66  (_merge==2)

    matched                               190  (_merge==3)
    -----------------------------------------
*/

tab GID_0 if _merge==1
/*
      GID_0 |      Freq.     Percent        Cum.
------------+-----------------------------------
        CSK |          1       16.67       16.67
        NYE |          1       16.67       33.33
        SCG |          1       16.67       50.00
        SYE |          1       16.67       66.67
        USR |          1       16.67       83.33
        YUG |          1       16.67      100.00
------------+-----------------------------------
      Total |          6      100.00
*/

keep if _merge==3
drop _merge
spmat contiguity spatial_matrix using "Maps/worldcoor.dta", id(id) replace
spmat save spatial_matrix using spmat_contig.spmat, replace
spmat use NAME_0 using spmat_contig.spmat // Why do you call the spatial weight matrix here NAME_0 and then below spatial_matrix?
spmat export NAME_0 using weight_contig.txt, replace
spmat summarize NAME_0, links
restore

*preserve // won't work as we preserve in the loop to create the spatial lag
save "Data/Merge/spmat work/Datasettobemergedwithspatiallag.dta", replace // added
keep GTI_o year iso3o
duplicates drop
tab iso3o
bysort iso3o: tab year
* As we can see, most of the origin have 37 years corresponding. If we want to balance, we need to drop countries with less than 43y
bysort iso3o : gen N = _N
list if N < 43
drop if N<43

drop if iso3o=="CSK" |  iso3o=="NYE" | iso3o=="SCG" | iso3o=="SYE" | iso3o=="USR" | iso3o=="YUG" // added

*spmat use spatial_matrix using spmat_contig.spmat // got error message that this spatial_matrix was already constructed
forval i = 1975(1)2017 { // Updated
preserve
keep if year==`i'
spmat lag double GTI_o_lag spatial_matrix GTI_o
save "Data/Merge/spmat work/spatial lag_`i'.dta", replace
restore
}

*** Merge everything
use "Data/Merge/spmat work/spatial lag_1975.dta", clear
forval i = 1976(1)2017 { // Updated
append using "Data/Merge/spmat work/spatial lag_`i'.dta"
}
keep iso3o year GTI_o_lag
save "Data/Merge/spmat work/Spatially lagged GTI_o.dta", replace

*** Then go back to original dataset
use "Data/Merge/spmat work/Datasettobemergedwithspatiallag.dta", clear
merge m:1 iso3o year using "Data/Merge/spmat work/Spatially lagged GTI_o.dta"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           258
        from master                       258  (_merge==1)
        from using                          0  (_merge==2)

    matched                             8,170  (_merge==3)
    -----------------------------------------
*/

tab iso3o if _merge==1

/*
      GID_0 |      Freq.     Percent        Cum.
------------+-----------------------------------
        CSK |         43       16.67       16.67
        NYE |         43       16.67       33.33
        SCG |         43       16.67       50.00
        SYE |         43       16.67       66.67
        USR |         43       16.67       83.33
        YUG |         43       16.67      100.00
------------+-----------------------------------
      Total |        258      100.00
*/

drop _merge

keep iso3o year GTI_o
rename GTI_o GTI_o_1109

save "Data/GTD/Clean/Dta/Terror origin without 1109", replace

rename iso3o iso3d
rename GTI_o_1109 GTI_d_1109

save "Data/GTD/Clean/Dta/Terror dest without 1109", replace

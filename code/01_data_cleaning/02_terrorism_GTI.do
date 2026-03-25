********************************************************************************
* 02 - Global Terrorism Index Construction
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Constructs the Global Terrorism Index (GTI) and alternative terrorism indicators from the Global Terrorism Database (GTD). Implements time-weighting, logarithmic banding, and spatial lag computation using a contiguity matrix.
*
* Input:   GTD event-level data (1970-2016), GADM shapefiles
*
* Output:  Terror origin.dta, Terror dest.dta (country-year terrorism indices)
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
*cd "D:\Dropbox\PhD Killian\Paper I\"

cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

use "Data/GTD/Old/Dta/1970-1994_stataversion.dta", clear

append using "Data/GTD/Old/Dta/1993_stataversion.dta", force
append using "Data/GTD/Old/Dta/1995-2012_stataversion.dta", force
append using "Data/GTD/Old/Dta/2013-2016_stataversion.dta", force

order iyear country_txt country imonth iday
sort iyear country_txt imonth iday

drop eventid approxdate location summary attacktype2 attacktype2_txt attacktype3 attacktype3_txt corp1 target1 corp2 target2 targtype3 targtype3_txt targsubtype3 targsubtype3_txt corp3 target3 natlty3 natlty3_txt gname gsubname gname2 gsubname2 gname3 gsubname3 motive guncertain1 guncertain2 guncertain3 individual nperpcap claimmode claimmode_txt claim2 claimmode2 claimmode2_txt claim3 claimmode3 claimmode3_txt compclaim weapsubtype1 weapsubtype1_txt weapsubtype2 weapsubtype2_txt weapsubtype3 weapsubtype3_txt weapsubtype4 weapsubtype4_txt weapdetail nkillter nwoundte propcomment nhostkidus nhours ndays divert kidhijcountry ransomamt ransomamtus ransompaid ransompaidus ransomnote hostkidoutcome hostkidoutcome_txt nreleased addnotes scite1 scite2 scite3 dbsource related

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

merge m:1 iso3o year using "Data/WDI/Clean/Dta/WDI origin - JEBO revision.dta"
/* UPDATED AS OF OCTOBER 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                         2,483
        from master                       748  (_merge==1)
        from using                      1,735  (_merge==2)

    matched                             8,464  (_merge==3)
    -----------------------------------------
*/

/* ORIGINAL
merge m:1 iso3o year using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\WDI origin.dta"

    Result                           # of obs.
    -----------------------------------------
    not matched                         3,169
        from master                     1,568  (_merge==1)
        from using                      1,601  (_merge==2)

    matched                             7,644  (_merge==3)
    -----------------------------------------
*/

drop if _merge == 2
drop _merge

*** Total GTI raw score
gen GTIPCPY=AttacksPCPY+3*VictimsPCPY+0.5*WoundedPCPY+2*propvaluePCPY

*** Total number of victims (fatalities + wounded)
rename VictimsPCPY FatalitiesPCPY
gen VictimsPCPY=FatalitiesPCPY+WoundedPCPY

*******************
*** Alternatives created for JEBO revision
*** GTI pc (population in millions)
gen PopTotal_mil_o = PopTotal_or/1000000
gen GTIPCPYpc=(AttacksPCPY+3*VictimsPCPY+0.5*WoundedPCPY+2*propvaluePCPY)/PopTotal_mil_o

*** GTI without weights
gen GTIPCPYnoweight=AttacksPCPY+VictimsPCPY+WoundedPCPY+propvaluePCPY

*** Other terrorism indicators per capita // Added November 2023
gen VictimsPCPYpc=(FatalitiesPCPY+WoundedPCPY)/PopTotal_mil_o 
gen BombingPCPYpc=BombingPCPY/PopTotal_mil_o 
gen AttacksPCPYpc=AttacksPCPY/PopTotal_mil_o 
*******************

sort o t

gen GTI_score2= log(GTIPCPY)/log(1.7247422000238) // Ilse: what are these lines???
gen GTI_score= 0.5*GTI_score2
replace GTI_score=0 if GTI_score==.
drop GTI_score2

*** Lag variables up to 4 years before

forval i = 1/4 {  
gen GTIPCPYL`i'=L`i'.GTIPCPY
gen GTI_score_lag`i'=L`i'.GTI_score
gen AttackOccurrencePCPYL`i'=L`i'.AttackOccurrencePCPY
gen AttacksPCPYL`i'=L`i'.AttacksPCPY
gen VictimsPCPYL`i'=L`i'.VictimsPCPY
gen BombingPCPYL`i'=L`i'.BombingPCPY
gen NationalTargPCPYL`i'=L`i'.NationalTargPCPY
gen TargViolPolPCPYL`i'=L`i'.TargViolPolPCPY
gen TargReligPCPYL`i'=L`i'.TargReligPCPY
gen GTIPCPYpcL`i'=L`i'.GTIPCPYpc
gen GTIPCPYnoweightL`i'=L`i'.GTIPCPYnoweight
gen AttacksPCPYpcL`i'=L`i'.AttacksPCPYpc
gen VictimsPCPYpcL`i'=L`i'.VictimsPCPYpc
gen BombingPCPYpcL`i'=L`i'.BombingPCPYpc
}


gen AttackOccurrence=1 if AttackOccurrencePCPY==1 | AttackOccurrencePCPYL1==1 | AttackOccurrencePCPYL2==1 | AttackOccurrencePCPYL3==1 | AttackOccurrencePCPYL4==1
replace AttackOccurrence=0 if AttackOccurrence==.

*** Time weighting of historical scores
foreach k in GTIPCPY AttacksPCPY VictimsPCPY BombingPCPY NationalTargPCPY TargViolPolPCPY TargReligPCPY GTIPCPYpc GTIPCPYnoweight AttacksPCPYpc VictimsPCPYpc BombingPCPYpc {
gen `k'RawScoreA = 16*`k' + 8*`k'L1 + 4*`k'L2 + 2*`k'L3 + 1*`k'L4
}

drop o-t 

*** Over 5 years before migration flows

/*
sum GTIPCPYRawScoreA

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
GTIPCPYRaw~A |      8,428    5633.301    38488.31          0    1365103

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
** Test if this was obtained through the formula:
gen r = 1365103 ^ (1/20) // Yes, confirmed!!
*/

gen GTIA1= log(GTIPCPYRawScoreA)/log(2.0265544223787)
gen GTI= 0.5* GTIA1
replace GTI=0 if GTI==.
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
         GTI |      9,212    2.409821    2.499591          0         10
*/

/* Attacks
sum AttacksPCPYRawScoreA
root=2*(10-0)=20
range=(98487-0)
r=20 V 98487 = 1.7769243774029
*/

gen AttacksIndexA1= log(AttacksPCPYRawScoreA)/log(1.7769243774029)
gen AttacksIndex= 0.5* AttacksIndexA1
replace AttacksIndex=0 if AttacksIndex==.
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
AttacksIndex |      9,212    2.172387    2.361619          0         10
*/

/* Victims
sum VictimsPCPYRawScoreA
root=2*(10-0)=20
range=(775469-0)
r=20 V 775469 = 1.9700544152633
*/

gen VictimsIndexA1= log(VictimsPCPYRawScoreA)/log(1.9700544152633)
gen VictimsIndex= 0.5* VictimsIndexA1
replace VictimsIndex=0 if VictimsIndex==.
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
VictimsIndex |      9,212    2.037253    2.445905          0         10
*/

/* Bombing
sum BombingPCPYRawScoreA
root=2*(10-0)=20
range=(78564-0)
r=20 V 78564 = 1.7569571889439
*/

gen BombingIndexA1= log(BombingPCPYRawScoreA)/log(1.7569571889439)
gen BombingIndex= 0.5* BombingIndexA1
replace BombingIndex=0 if BombingIndex==.
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
BombingIndex |      9,212    1.596841    2.166793          0         10
*/

/* NationalTarg
sum NationalTargPCPYRawScoreA
root=2*(10-0)=20
range=(98085-0)
r=20 V 98085 = 1.7765610237418
*/

gen NationalTargIndexA1= log(NationalTargPCPYRawScoreA)/log(1.7765610237418)
gen NationalTargIndex= 0.5* NationalTargIndexA1
replace NationalTargIndex=0 if NationalTargIndex==.
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
NationalTa~x |      9,212    1.904436    2.293006          0         10
*/

/* TargViolPol
sum TargViolPolPCPYRawScoreA
root=2*(10-0)=20
range=(2163-0)
r=20 V 2163 = 1.4680904919316
*/

gen TargViolPolIndexA1= log(TargViolPolPCPYRawScoreA)/log(1.4680904919316)
gen TargViolPolIndex= 0.5* TargViolPolIndexA1
replace TargViolPolIndex=0 if TargViolPolIndex==.
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
TargViolPo~x |      9,212    .2918001    1.163105          0         10
*/
/* TargRelig
sum TargReligPCPYRawScoreA
root=2*(10-0)=20
range=(2557-0)
r=20 V 2557 = 1.4804254293966
*/

gen TargReligIndexA1= log(TargReligPCPYRawScoreA)/log(1.4804254293966)
gen TargReligIndex= 0.5* TargReligIndexA1
replace TargReligIndex=0 if TargReligIndexA==.
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
TargReligI~x |      9,212    .7573138    1.725506          0         10
*/


/* GTIpc
root=2*(10-0)=20 
sum GTIPCPYpcRawScoreA // But has values between 0 and 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
GTIPCPYpcR~A |      7,708    636.8732    3549.763          0   82693.36

*** This gives negative logs and prevents the minimum bandth width being set to zero (remains negative)
*** SO add one to the rawscore before taking logs. The range stays the same
gen range= 82693.36 - 0 // equivalent to 82694.36 (max) - 1 (min) when 1 would be added
*/
cap drop r
gen r = 82693.36^ (1/20)
di r // 1.7614732
gen GTIpcA1= log(GTIPCPYpcRawScoreA+1)/log(1.7614732) // I added one first to the rawscore
gen GTIpc= 0.5* GTIpcA1
replace GTIpc=0 if GTIpc==.
sum GTIpc // Good enough!
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTIpc |      9,212     2.10864    2.399394          0   9.999908
*/


/* GTInoweight 
root=2*(10-0)=20
sum GTIPCPYnoweightRawScoreA
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
GTIPCPYnow~A |      8,428    5454.728    39448.12          0    1335678
range=1335678 - 0
*/
cap drop r
gen r = 1335678 ^(1/20) // 2.0243475
di r
gen GTInoweightA1= log(GTIPCPYnoweightRawScoreA)/log(2.0243475)
gen GTInoweight= 0.5* GTInoweightA1
replace GTInoweight=0 if GTInoweight==.
/*
sum GTInoweight
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
 GTInoweight |      9,212     2.40746    2.502487          0         10
*/


/* AttacksIndexpc // Same technique as GTIpc
root=2*(10-0)=20
sum AttacksPCPYpcRawScoreA
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
A~cRawScoreA |      7,895    296.0436    1528.262          0   48180.78
range=48180.78 - 0
*/
cap drop r
gen r = 48180.78 ^(1/20) // 1.7145245
di r
gen AttacksIndexpcA1= log(AttacksPCPYpcRawScoreA+1)/log(1.7145245)
gen AttacksIndexpc= 0.5* AttacksIndexpcA1
replace AttacksIndexpc=0 if AttacksIndexpc==.
sum AttacksIndexpc
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
AttacksInd~c |      9,212    1.245995    1.594193          0    7.68796
*/



/* VictimsIndexpc // Same technique as GTIpc
root=2*(10-0)=20
sum VictimsPCPYpcRawScoreA
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
V~cRawScoreA |      7,895    1521.303    10488.33          0   365880.5
range=48180.78 - 0
*/
cap drop r
gen r = 365880.5 ^(1/20) // 1.8974352
di r
gen VictimsIndexpcA1= log(VictimsPCPYpcRawScoreA+1)/log(1.8974352)
gen VictimsIndexpc= 0.5* VictimsIndexpcA1
replace VictimsIndexpc=0 if VictimsIndexpc==.
sum VictimsIndexpc
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
VictimsInd~c |      9,212     1.26355    1.721944          0   7.942519
*/


/* BombingIndexpc // Same technique as GTIpc
root=2*(10-0)=20
sum BombingPCPYpcRawScoreA
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
B~cRawScoreA |      7,895     141.717    934.7353          0   35589.14
*/
cap drop r
gen r = 35589.14 ^(1/20) // 1.6887519
di r
gen BombingIndexpcA1= log(BombingPCPYpcRawScoreA+1)/log(1.6887519)
gen BombingIndexpc= 0.5* BombingIndexpcA1
replace BombingIndexpc=0 if BombingIndexpc==.
sum BombingIndexpc
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
BombingInd~c |      9,212    .8284035    1.361095          0   7.313854
*/


rename GTIPCPYL4 GTIPCPYL4_keep
rename GTIPCPYL3 GTIPCPYL3_keep
rename GTIPCPYL2 GTIPCPYL2_keep
rename GTIPCPYL1 GTIPCPYL1_keep
rename GTIPCPY GTIPCPY_keep
rename GTIPCPYpcL4 GTIPCPYpcL4_keep
rename GTIPCPYpcL3 GTIPCPYpcL3_keep
rename GTIPCPYpcL2 GTIPCPYpcL2_keep
rename GTIPCPYpcL1 GTIPCPYpcL1_keep
rename GTIPCPYpc GTIPCPYpc_keep

drop *A1 *RawScoreA  *L1 *L2 *L3 *L4 ///
 VictimsPCPY PopTotal_mil_o  GTIPCPYnoweight VictimsPCPYpc BombingPCPYpc AttacksPCPYpc

rename GTIPCPYL4_keep GTIPCPYL4
rename GTIPCPYL3_keep GTIPCPYL3
rename GTIPCPYL2_keep GTIPCPYL2 
rename GTIPCPYL1_keep GTIPCPYL1 
rename GTIPCPY_keep GTIPCPY 
rename  GTIPCPYpcL4_keep GTIPCPYpcL4
rename  GTIPCPYpcL3_keep GTIPCPYpcL3
rename  GTIPCPYpcL2_keep GTIPCPYpcL2
rename  GTIPCPYpcL1_keep GTIPCPYpcL1
rename  GTIPCPYpc_keep GTIPCPYpc

/*** 1 year before the migration flow

* Attack occurrence
rename AttackOccurrencePCPY AttackOccurrence_1

/* GTI
sum GTIPCPY	 
root=2*(10-0)=20
range=(54260.5-0)
r=20 V 54260.5 = 1.7247422000238
*/

gen GTIA1= log(GTI_L1)/log(1.7247422000238)
gen GTI_1= 0.5* GTIA1
replace GTI_1=0 if GTI_1==.
drop GTIA1

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

*/

sort origin iso3o year
order origin iso3o year

rename GTI_score_lag4 GTI_score_lag5
rename GTI_score_lag3 GTI_score_lag4
rename GTI_score_lag2 GTI_score_lag3
rename GTI_score_lag1 GTI_score_lag2 
rename GTI_score GTI_score_lag1


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

rename GTIPCPYL4_o GTIPCPYL5_o
rename GTIPCPYL3_o GTIPCPYL4_o
rename GTIPCPYL2_o GTIPCPYL3_o
rename GTIPCPYL1_o GTIPCPYL2_o
rename GTIPCPY_o GTIPCPYL1_o

rename GTIPCPYpcL4_o GTIPCPYpcL5_o
rename GTIPCPYpcL3_o GTIPCPYpcL4_o
rename GTIPCPYpcL2_o GTIPCPYpcL3_o
rename GTIPCPYpcL1_o GTIPCPYpcL2_o
rename GTIPCPYpc_o GTIPCPYpcL1_o

save "Data/GTD/Clean/Dta/Terror origin - JEBO revision.dta", replace

rename iso3o iso3d
rename GTI_o_lag GTI_d_lag
rename *_o *_d

save "Data/GTD/Clean/Dta/Terror dest - JEBO revision.dta", replace

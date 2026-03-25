********************************************************************************
* 10 - Ethnic and Religious Fractionalization
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Constructs ethnic and religious fractionalization indices (Herfindahl-based) from group-level population share data.
*
* Input:   EthnicGroupsLong_v1.02.csv, ReligiousGroupsLong_v1.02.csv
*
* Output:  FRAC_o.dta, FRAC_d.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

* Creation fractionalization index
* FRACTj=1-sum_i(s²_ij) with j=country & i=share of group. s_ij share of group i in country j.

*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data"
cd "D:\Dropbox\PhD Killian\Paper I\Data"

clear all
import delimited "Ethnic religious frac/ReligiousGroupsLong_v1.02.csv"
keep country year groupname groupestimate
duplicates drop
replace groupestimate=groupestimate/100
gen grpsquared=groupestimate^2
egen oy = group(country year)
sort oy
by oy: egen sumsquared=sum(grpsquared)
gen FRACT_relig=1-sumsquared
keep country year FRACT_relig
duplicates drop
rename country origin

replace origin="Bosnia and Herzegovina" if origin=="Bosnia-Herzegovina"
replace origin="Republic of Congo" if origin=="Congo"
replace origin="Côte d'Ivoire" if origin=="Cote d'Ivoire"
drop if origin=="Czechoslovakia"
replace origin="Democratic Republic of the Congo" if origin=="Democratic Republic of Congo"
drop if origin=="Democratic Republic of Vietnam"
replace origin="Timor-Leste" if origin=="East Timor"
drop if origin=="German Democratic Republic"
drop if origin=="German Federal Republic"
replace origin="Kyrgyzstan" if origin=="Kyrgyz Republic"
replace origin="South Korea" if origin=="Republic of Korea"
replace origin="Romania" if origin=="Rumania"
replace origin="United States" if origin=="United States of America"

merge m:1 origin using "iso3/Clean/Dta/iso3clean origin.dta"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           376
        from master                       276  (_merge==1)
        from using                        100  (_merge==2)

    matched                            10,764  (_merge==3)
    -----------------------------------------
*/

replace iso3o="USR" if origin=="USSR"
drop if _merge!=3 & iso3o!="USR"
drop _merge
drop origin

rename FRACT_relig FRACT_relig_o

save "Ethnic religious frac/relig_frac_o.dta", replace

rename FRACT_relig_o FRACT_relig_d
rename iso3o iso3d

save "Ethnic religious frac/relig_frac_d.dta", replace


********************************************************************************
********************************************************************************
********************************************************************************

* Creation fractionalization index
* FRACTj=1-sum_i(s²_ij) with j=country & i=share of group. s_ij share of group i in country j.

*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data"
cd "D:\Dropbox\PhD Killian\Paper I\Data"

clear all
import delimited "Ethnic religious frac/EthnicGroupsLong_v1.02.csv"
keep country year groupname groupestimate
duplicates drop
replace groupestimate=groupestimate/100
gen grpsquared=groupestimate^2
egen oy = group(country year)
sort oy
by oy: egen sumsquared=sum(grpsquared)
gen FRACT_ethnic=1-sumsquared
keep country year FRACT_ethnic
duplicates drop
rename country origin

replace origin="Bosnia and Herzegovina" if origin=="Bosnia-Herzegovina"
replace origin="Republic of Congo" if origin=="Congo"
replace origin="Côte d'Ivoire" if origin=="Cote d'Ivoire"
drop if origin=="Czechoslovakia"
replace origin="Democratic Republic of the Congo" if origin=="Democratic Republic of Congo"
drop if origin=="Democratic Republic of Vietnam"
replace origin="Timor-Leste" if origin=="East Timor"
drop if origin=="German Democratic Republic"
drop if origin=="German Federal Republic"
replace origin="Kyrgyzstan" if origin=="Kyrgyz Republic"
replace origin="South Korea" if origin=="Republic of Korea"
replace origin="Romania" if origin=="Rumania"
replace origin="United States" if origin=="United States of America"
replace origin="North Korea" if origin=="Democratic People's Republic of Korea"

merge m:1 origin using "iso3/Clean/Dta/iso3clean origin.dta"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           448
        from master                       345  (_merge==1)
        from using                        103  (_merge==2)

    matched                            10,557  (_merge==3)
    -----------------------------------------
*/

replace iso3o="USR" if origin=="USSR"
drop if _merge!=3 & iso3o!="USR"
drop _merge
drop origin

rename FRACT_ethnic FRACT_ethnic_o

save "Ethnic religious frac/ethnic_frac_o.dta", replace

rename FRACT_ethnic_o FRACT_ethnic_d
rename iso3o iso3d

save "Ethnic religious frac/ethnic_frac_d.dta", replace


********************************************************************************
********************************************************************************
********************************************************************************

clear all
*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data"
cd "D:\Dropbox\PhD Killian\Paper I\Data"

use "Ethnic religious frac/relig_frac_o.dta"

merge 1:1 iso3o year using "Ethnic religious frac/ethnic_frac_o.dta"
drop _merge
sort iso3o year
order iso3o year

replace year=year+1

save "Ethnic religious frac/FRAC_o.dta", replace

rename iso3o iso3d
rename FRACT_relig_o FRACT_relig_d
rename FRACT_ethnic_o FRACT_ethnic_d

save "Ethnic religious frac/FRAC_d.dta", replace


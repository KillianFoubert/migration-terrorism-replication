********************************************************************************
* 11 - Quality of Institutions (WGI)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans the Worldwide Governance Indicators and constructs an institutional quality index averaging voice, government effectiveness, regulatory quality, rule of law, and control of corruption (excluding political stability to avoid correlation with GTI).
*
* Input:   wgidataset-fixed.dta (WGI)
*
* Output:  Instits origin.dta, Instits dest.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

* https://info.worldbank.org/governance/wgi/Home/Documents#wgiDataCrossCtry

cls 
clear all 
set more off, permanently
set scrollbufsize 500000 
set maxvar 120000
set matsize 11000
capture log close 

cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\" 
*cd "D:\Dropbox\PhD Killian\Paper I\"
*cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

use "Data/Quality of institutions/wgidataset-fixed.dta", clear

keep countryname year vae vas pve pvs gee ges rqe rqs rle rls cce ccs
egen instit = rmean(vae gee rqe rle cce)
* I do not include pve to avoid correlation with GTI
/* sum instit
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      instit |      4,394    .0101875    .9418296  -2.283145   2.050642
*/

rename countryname origin

replace origin="Bahamas" if origin=="Bahamas, The"
replace origin="Brunei" if origin=="Brunei Darussalam"
replace origin="Democratic Republic of the Congo" if origin=="Congo, Dem. Rep."
replace origin="Republic of Congo" if origin=="Congo, Rep."
replace origin="Egypt" if origin=="Egypt, Arab Rep."
replace origin="Gambia" if origin=="Gambia, The"
replace origin="Hong Kong" if origin=="Hong Kong SAR, China"
replace origin="Iran" if origin=="Iran, Islamic Rep."
replace origin="Jersey" if origin=="Jersey, Channel Islands"
replace origin="North Korea" if origin=="Korea, Dem. Rep."
replace origin="South Korea" if origin=="Korea, Rep."
replace origin="Kyrgyzstan" if origin=="Kyrgyz Republic"
replace origin="Laos" if origin=="Lao PDR"
replace origin="Macao" if origin=="Macao SAR, China"
replace origin="Micronesia" if origin=="Micronesia, Fed. Sts."
replace origin="Russia" if origin=="Russian Federation"
replace origin="Reunion" if origin=="Réunion"
replace origin="Slovakia" if origin=="Slovak Republic"
replace origin="Saint Kitts and Nevis" if origin=="St. Kitts and Nevis"
replace origin="Saint Lucia" if origin=="St. Lucia"
replace origin="Saint Vincent and the Grenadines" if origin=="St. Vincent and the Grenadines"
replace origin="Syria" if origin=="Syrian Arab Republic"
replace origin="Taiwan" if origin=="Taiwan, China"
replace origin="Venezuela" if origin=="Venezuela, RB"
replace origin="Virgin Islands, U.S." if origin=="Virgin Islands (U.S.)"
replace origin="Palestina" if origin=="West Bank and Gaza"
replace origin="Yemen" if origin=="Yemen, Rep."

merge m:1 origin using "Data/iso3/Clean/Dta/iso3clean origin.dta"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           108
        from master                        63  (_merge==1)
        from using                         45  (_merge==2)

    matched                             4,431  (_merge==3)
    -----------------------------------------
*/

drop if _merge!=3
drop _merge
rename * *_o
drop origin_o
rename year_o year
rename iso3o_o iso3o

order iso3o year instit_o
sort iso3o year

save "Data/Quality of institutions/Instits origin", replace

rename *o *d
save "Data/Quality of institutions/Instits dest", replace



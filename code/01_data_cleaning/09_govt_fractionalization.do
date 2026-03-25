********************************************************************************
* 09 - Government Fractionalization (DPI 2020)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans government fractionalization from the Database of Political Institutions (2020 update). Used as an instrumental variable for terrorism in the IV regressions.
*
* Input:   DPI2020.dta
*
* Output:  frac_o2020.dta, frac_d2020.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

* source: https://datacatalog.worldbank.org/dataset/wps2283-database-political-institutions#

cls 
clear all 
set more off 
set scrollbufsize 500000 
set maxvar 10000
graph drop _all 
capture log close 

*cd "D:\Dropbox\PhD Killian\Paper I\"
*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\"
cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

//use "Data/Government fractionalization/dpi2012.dta"
use "Data/Government fractionalization/DPI2020.dta"

keep countryname year frac govfrac polariz
*frac: total fractionalization (the proba that two random draws would produce legislators from different parties)
*govfrac: government fractionalization (the proba that two random draws would produce legislators from different parties)
*polariz: maximum difference of orientation among government parties (0-2)

rename countryname origin

replace origin="Bosnia and Herzegovina" if origin=="Bosnia-Herz"
replace origin="Cape Verde" if origin=="C. Verde Is."
replace origin="Central African Republic" if origin=="Cent. Af. Rep."
replace origin="Comoros" if origin=="Comoro Is."
replace origin="Republic of Congo" if origin=="Congo"
replace origin="Democratic Republic of the Congo" if origin=="Congo (DRC)"
replace origin="Côte d'Ivoire" if origin=="Cote d'Ivoire"
replace origin="Czech Republic" if origin=="Czech Rep."
replace origin="Dominican Republic" if origin=="Dom. Rep."
replace origin="Equatorial Guinea" if origin=="Eq. Guinea"
replace origin="Papua New Guinea" if origin=="P. N. Guinea"
replace origin="China" if origin=="PRC"
replace origin="North Korea" if origin=="PRK"
replace origin="South Korea" if origin=="ROK"
replace origin="South Africa" if origin=="S. Africa"
replace origin="Solomon Islands" if origin=="Solomon Is."
replace origin="Saint Lucia" if origin=="St. Lucia"
replace origin="Trinidad and Tobago" if origin=="Trinidad-Tobago"
replace origin="Northern Cyprus" if origin=="Turk Cyprus"
replace origin="United Arab Emirates" if origin=="UAE"
replace origin="United Kingdom" if origin=="UK"
replace origin="United States" if origin=="USA"
replace origin="Yemen North" if origin=="Yemen (AR)"
replace origin="Yemen South" if origin=="Yemen (PDR)"
replace origin="Yugoslavia, former" if origin=="Yugoslavia"

merge m:1 origin using "Data/iso3/Clean/Dta/iso3clean origin.dta"

/*
      Result                           # of obs.
    -----------------------------------------
    not matched                           300
        from master                       219  (_merge==1)
        from using                         81  (_merge==2)

    matched                             7,981  (_merge==3)
    -----------------------------------------
*/

replace iso3o="NYE" if origin=="Yemen North"
replace iso3o="SYE" if origin=="Yemen South"
replace iso3o="YUG" if origin=="Yugoslavia, former"

drop if iso3o==""

drop _merge origin
order iso3o year
sort iso3o year

gen frac2 = frac if frac>=0
drop frac
rename frac2 frac2020_o
// I do it like this to replace the NA obs by missings because the replace command is not working due to syntax issue with the obs

gen govfrac2 = govfrac if govfrac>=0
drop govfrac
rename govfrac2 govfrac2020_o

gen polariz2 = polariz if polariz>=0
drop polariz
rename polariz2 polariz2020_o

replace year=year+1
drop if year==.

save "Data/Government fractionalization/frac_o2020.dta", replace

rename *o *d
save "Data/Government fractionalization/frac_d2020.dta", replace

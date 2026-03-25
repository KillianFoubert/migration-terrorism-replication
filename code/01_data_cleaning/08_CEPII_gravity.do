********************************************************************************
* 08 - Gravity Variables (CEPII)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans the CEPII GeoDist database and harmonizes country names. Provides bilateral distance, contiguity, and common language variables for the gravity model.
*
* Input:   CEPII_compatibleGWP_raw.dta
*
* Output:  CEPII_compatibleGWP.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

cls 
clear all 
set more off 
set scrollbufsize 500000 
set maxvar 10000
graph drop _all 
capture log close 

*cd "D:\Dropbox\PhD Killian\Paper I\"
cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\"

*cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

use "Data/CEPII/Clean/Dta/CEPII_compatibleGWP_raw.dta"

*** Israel -> Israel and PSE

expand 2 if origin=="Israel"
expand 2 if destination=="Israel"

gen z=_n

replace origin="Palestine" if origin=="Israel" & z>=51077 & z<= 51302
replace destination="Palestine" if destination=="Israel" & z>=51303 & z<=51527

drop z

*** Serbia and Montenegro -> Serbia AND Montenegro

expand 2 if origin=="Serbia and Montenegro"
expand 2 if destination=="Serbia and Montenegro"

gen z=_n

replace origin="Serbia" if origin=="Serbia and Montenegro" & z>=39325 & z<= 39550
replace origin="Montenegro" if origin=="Serbia and Montenegro" & z>=51528 & z<= 51754

replace destination="Serbia" if destination=="Serbia and Montenegro" & z>=51755 & z<=51980
drop z

sort destination
gen z=_n

replace destination="Montenegro" if destination=="Serbia and Montenegro" & z>=40178 & z<=40403
drop z

sort origin destination
expand 2 if origin=="Serbia"
expand 2 if destination=="Serbia"

gen z=_n

replace origin="Serbia-Montenegro" if origin=="Serbia" & z>=51981 & z<= 52206
replace destination="Serbia-Montenegro" if destination=="Serbia" & z>=52207 & z<= 52432

drop iso3o iso3d

replace origin="Brunei" if origin=="Brunei Darussalam"
replace origin="Cocos Islands" if origin=="Cocos (Keeling) Islands"
replace origin="Republic of Congo" if origin=="Congo Brazzaville"
replace origin="Democratic Republic of the Congo" if origin=="Congo Kinshasa"
replace origin="Timor-Leste" if origin=="East Timor"
replace origin="Côte d'Ivoire" if origin=="Ivory Coast"
replace origin="Macao" if origin=="Macau (Aomen)"
replace origin="Palestina" if origin=="Palestine"
replace origin="Pitcairn Islands" if origin=="Pitcairn"
replace origin="São Tomé and Príncipe" if origin=="Sao Tome & Principe"
replace origin="Saint Kitts and Nevis" if origin=="St. Kitts & Nevis"
replace origin="Saint Pierre and Miquelon" if origin=="St. Pierre and Miquelon"
replace origin="Saint Vincent and the Grenadines" if origin=="St. Vincent and Grenadines"
replace origin="Gambia" if origin=="The Gambia"

merge m:1 origin using "Data/iso3/Clean/Dta/iso3clean origin.dta"
drop _merge

replace iso3o="CSK" if origin=="Czechoslovakia"
replace iso3o="ANT" if origin=="Netherland Antilles"
replace origin="Yugoslavia" if origin=="Serbia and Montenegro"
replace iso3o="YUG" if origin=="Yugoslavia"
replace origin="Serbia and Montenegro" if origin=="Serbia-Montenegro"
replace iso3o="SCG" if origin=="Serbia and Montenegro"

replace iso3o="USR" if origin=="USSR"
replace iso3o="CSK" if origin=="Czechoslovakia"
replace iso3o="YUG" if origin=="Socialist Federal Republic of Yugoslavia"

replace destination="Brunei" if destination=="Brunei Darussalam"
replace destination="Cocos Islands" if destination=="Cocos (Keeling) Islands"
replace destination="Republic of Congo" if destination=="Congo Brazzaville"
replace destination="Democratic Republic of the Congo" if destination=="Congo Kinshasa"
replace destination="Timor-Leste" if destination=="East Timor"
replace destination="Côte d'Ivoire" if destination=="Ivory Coast"
replace destination="Macao" if destination=="Macau (Aomen)"
replace destination="Palestina" if destination=="Palestine"
replace destination="Pitcairn Islands" if destination=="Pitcairn"
replace destination="São Tomé and Príncipe" if destination=="Sao Tome & Principe"
replace destination="Saint Kitts and Nevis" if destination=="St. Kitts & Nevis"
replace destination="Saint Pierre and Miquelon" if destination=="St. Pierre and Miquelon"
replace destination="Saint Vincent and the Grenadines" if destination=="St. Vincent and Grenadines"
replace destination="Gambia" if destination=="The Gambia"

merge m:1 destination using "Data/iso3/Clean/Dta/iso3clean dest.dta"
drop _merge

replace iso3d="CSK" if destination=="Czechoslovakia"
replace iso3d="ANT" if destination=="Netherland Antilles"
replace destination="Yugoslavia" if destination=="Serbia and Montenegro"
replace iso3d="YUG" if destination=="Yugoslavia"
replace destination="Serbia and Montenegro" if destination=="Serbia-Montenegro"
replace iso3d="SCG" if destination=="Serbia and Montenegro"
replace iso3d="USR" if destination=="USSR"

replace iso3d="USR" if destination=="USSR"
replace iso3d="CSK" if destination=="Czechoslovakia"
replace iso3d="YUG" if destination=="Socialist Federal Republic of Yugoslavia"

keep iso3o iso3d contig comlang_ethno colony dist
drop if iso3o==""
drop if iso3d==""
sort iso3o iso3d
order iso3o iso3d

save "Data/iso3/Clean/Dta/CEPII_compatibleGWP.dta", replace

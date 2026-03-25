********************************************************************************
* 01 - Bilateral Migration Data (Dependent Variable + Network)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans the Annual Bilateral Migration Database (ABMD, Standaert & Rayp 2022). Constructs bilateral migration flows, migrant network stocks, and handles negative flows.
*
* Input:   migration_imputed_March2020.dta (ABMD)
*
* Output:  Glenn migration and network.dta (bilateral flows, stocks, network)
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

/* Glenn email:
Il n’y pas encore de document technique de la base de données.  Au fait elle est encore en plein développement.  Les estimations des flux annuels qu’elle contient ne sont qu’une première ébauche, utilisant uniquement les données de stock des migrants. Les séries _fl sont bien un premier essai d’interpolation des données quinnenal ou décennal (provenant de l’ONU, OCDE ou Banque Mondiale) basé sur les stock ainsi que les flux, mais qui n’a pas encore vérifié et qui n’est donc pas assez fiable pour utiliser.  Tu peux ignorer ces séries.  Seules Stock et Flow, obtenus en interpolant les données de stock des sources mentionnées, sont pertinents.  

La méthode d’interpolation est non-linéaire et tient compte (certes de façon élémentaire) de la dynamique démographique de la population (le taux de survie).  Cet article de Samuel donne plus de détails techniques: https://lib.ugent.be/en/catalog/pug01:8538414?ac=pug01%3A23A09002-F0EE-11E1-A9DE-61C894A0A6B4%3Aauthor&i=4&q=%22Samuel+Standaert%22&search_field=author
*/

cls 
clear all 
set more off 
set scrollbufsize 500000 
set maxvar 10000
graph drop _all 
capture log close 

set matsize 11000

cd "D:\Dropbox\PhD Killian\Paper I\" // Fix PC
*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\" // Killian laptop

use "Data\Migration and network\Network\Dta\migration_imputed_March2020.dta"

drop Stock_fl Flow_fl
* This line could be dropped in case they finish the database

* Changing the iso3 so we make sure to always use the same (iso3 from the GADM database) 
replace origin="Bahamas" if origin=="Bahamas; The"
replace origin="Bonaire, Sint Eustatius and Saba" if origin=="Bonaire; Sint Eustatius and Saba"
replace origin="Brunei" if origin=="Brunei Darussalam"
replace origin="Cape Verde" if origin=="Cabo Verde"
replace origin="Central African Republic" if origin=="Central African Rep."
replace origin="Democratic Republic of the Congo" if origin=="Congo; Dem. Rep."
replace origin="Republic of Congo" if origin=="Congo; Rep."
replace origin="Côte d'Ivoire" if origin=="Cote d'Ivoire"
replace origin="Curaçao" if origin=="Curacao"
replace origin="Czech Republic" if origin=="Czech Rep."
*replace origin="" if origin=="Czechoslovakia"
replace origin="Dominican Republic" if origin=="Dominican Rep."
*replace origin="" if origin=="East and West Pakistan"
replace origin="Egypt" if origin=="Egypt; Arab Rep."
replace origin="Gambia" if origin=="Gambia; The"
*replace origin="" if origin=="Holy See"
replace origin="Hong Kong" if origin=="Hong Kong; SAR China"
replace origin="Iran" if origin=="Iran; Islamic Rep."
replace origin="North Korea" if origin=="Korea; Dem. People's Rep."
replace origin="South Korea" if origin=="Korea; Rep."
replace origin="Kyrgyzstan" if origin=="Kyrgyz Rep."
replace origin="Laos" if origin=="Lao People's Dem. Rep."
replace origin="Macao" if origin=="Macao SAR; China"
replace origin="Micronesia" if origin=="Micronesia; Fed. Sts."
*replace origin="" if origin=="Netherlands Antilles"
replace origin="Netherlands" if origin=="Netherlands; The"
replace origin="Macedonia" if origin=="North Macedonia"
replace origin="Russia" if origin=="Russian Federation"
*replace origin="" if origin=="Sahrawi Arab Dem. Rep."
replace origin="São Tomé and Príncipe" if origin=="Sao Tome and Principe"
*replace origin="" if origin=="Serbia-Montenegro"
replace origin="Sint Maarten" if origin=="Sint Maarten (Dutch part)"
replace origin="Slovakia" if origin=="Slovak Rep."
replace origin="Saint Helena" if origin=="St. Helena"
replace origin="Saint Kitts and Nevis" if origin=="St. Kitts and Nevis"
replace origin="Saint Lucia" if origin=="St. Lucia"
replace origin="Saint Pierre and Miquelon" if origin=="St. Pierre and Miquelon"
replace origin="Saint Vincent and the Grenadines" if origin=="St. Vincent and the Grenadines"
replace origin="Syria" if origin=="Syrian Arab Rep."
*replace origin="" if origin=="USSR Soviet Union"
replace origin="United States" if origin=="United States of America"
replace origin="Vietnam" if origin=="Vietnam; Dem. Rep."
replace origin="Virgin Islands, U.S." if origin=="Virgin Islands (U.S.)"
replace origin="Palestina" if origin=="West Bank and Gaza"
*replace origin="" if origin=="Yugoslavia"

drop iso_or
merge m:1 origin using "Data\iso3\Clean\Dta\iso3clean origin.dta"
drop if _merge==2
drop _merge

replace iso3o="CSK" if origin=="Czechoslovakia"
replace iso3o="YUG" if origin=="Yugoslavia"
replace iso3o="VAT" if origin=="Holy See"
replace iso3o="ANT" if origin=="Netherlands Antilles"
replace iso3o="USR" if origin=="USSR Soviet Union"
replace iso3o="SCG" if origin=="Serbia-Montenegro"
replace iso3o="SYE" if origin=="Yemen; People's Rep."
replace origin="South Yemen" if origin=="Yemen; People's Rep."
replace iso3o="NYE" if origin=="Yemen Arab Rep."
replace origin="North Yemen" if origin=="Yemen Arab Rep."
* I made the iso3 codes for Yemen so we can keep the observations
replace origin="Yemen" if origin=="Yemen; Rep."
replace iso3o="YEM" if origin=="Yemen"

drop if iso3o==""

replace destination="Bahamas" if destination=="Bahamas; The"
replace destination="Bonaire, Sint Eustatius and Saba" if destination=="Bonaire; Sint Eustatius and Saba"
replace destination="Brunei" if destination=="Brunei Darussalam"
replace destination="Cape Verde" if destination=="Cabo Verde"
replace destination="Central African Republic" if destination=="Central African Rep."
replace destination="Democratic Republic of the Congo" if destination=="Congo; Dem. Rep."
replace destination="Republic of Congo" if destination=="Congo; Rep."
replace destination="Côte d'Ivoire" if destination=="Cote d'Ivoire"
replace destination="Curaçao" if destination=="Curacao"
replace destination="Czech Republic" if destination=="Czech Rep."
*replace destination="" if destination=="Czechoslovakia"
replace destination="Dominican Republic" if destination=="Dominican Rep."
*replace destination="" if destination=="East and West Pakistan"
replace destination="Egypt" if destination=="Egypt; Arab Rep."
replace destination="Gambia" if destination=="Gambia; The"
*replace destination="" if destination=="Holy See"
replace destination="Hong Kong" if destination=="Hong Kong; SAR China"
replace destination="Iran" if destination=="Iran; Islamic Rep."
replace destination="North Korea" if destination=="Korea; Dem. People's Rep."
replace destination="South Korea" if destination=="Korea; Rep."
replace destination="Kyrgyzstan" if destination=="Kyrgyz Rep."
replace destination="Laos" if destination=="Lao People's Dem. Rep."
replace destination="Macao" if destination=="Macao SAR; China"
replace destination="Micronesia" if destination=="Micronesia; Fed. Sts."
*replace destination="" if destination=="Netherlands Antilles"
replace destination="Netherlands" if destination=="Netherlands; The"
replace destination="Macedonia" if destination=="North Macedonia"
replace destination="Russia" if destination=="Russian Federation"
*replace destination="" if destination=="Sahrawi Arab Dem. Rep."
replace destination="São Tomé and Príncipe" if destination=="Sao Tome and Principe"
*replace destination="" if destination=="Serbia-Montenegro"
replace destination="Sint Maarten" if destination=="Sint Maarten (Dutch part)"
replace destination="Slovakia" if destination=="Slovak Rep."
replace destination="Saint Helena" if destination=="St. Helena"
replace destination="Saint Kitts and Nevis" if destination=="St. Kitts and Nevis"
replace destination="Saint Lucia" if destination=="St. Lucia"
replace destination="Saint Pierre and Miquelon" if destination=="St. Pierre and Miquelon"
replace destination="Saint Vincent and the Grenadines" if destination=="St. Vincent and the Grenadines"
replace destination="Syria" if destination=="Syrian Arab Rep."
*replace destination="" if destination=="USSR Soviet Union"
replace destination="United States" if destination=="United States of America"
*replace destination="" if destination=="Vietnam; Dem. Rep."
replace destination="Virgin Islands, U.S." if destination=="Virgin Islands (U.S.)"
replace destination="Palestina" if destination=="West Bank and Gaza"
*replace destination="" if destination=="Yugoslavia"

drop iso_des
merge m:1 destination using "Data\iso3\Clean\Dta\iso3clean dest.dta"
drop if _merge==2
drop _merge

replace iso3d="CSK" if destination=="Czechoslovakia"
replace iso3d="YUG" if destination=="Yugoslavia"
replace iso3d="VAT" if destination=="Holy See"
replace iso3d="ANT" if destination=="Netherlands Antilles"
replace iso3d="USR" if destination=="USSR Soviet Union"
replace iso3d="SCG" if destination=="Serbia-Montenegro"
replace iso3d="SYE" if destination=="Yemen; People's Rep."
replace destination="South Yemen" if destination=="Yemen; People's Rep."
replace iso3d="NYE" if destination=="Yemen Arab Rep."
replace destination="North Yemen" if destination=="Yemen Arab Rep."
* I made the iso3 codes for Yemen so we can keep the observations
replace destination="Yemen" if destination=="Yemen; Rep."
replace iso3d="YEM" if destination=="Yemen"

drop if iso3d==""

save "Data\Migration and network\Glenn Samuel\Glenn migration only.dta", replace

replace year=y+1
rename Stock Network

* Stock in year y will be network for potential migration in year y+1
* See below for explanation on why 1975-2017
drop if year<1975
drop if year>2017

collapse (sum) Network, by (iso3o iso3d year)
* It corrects some duplicates due to the iso cleaning for Vietnam in the 70s. It concerns 23 observations.

save "Data\Migration and network\Glenn Samuel\Glenn network only.dta", replace

clear all
use "Data\Migration and network\Glenn Samuel\Glenn migration only.dta"

* GTD starts in 1970, thus first complete index for 1970-1974 -> 1975
* GTD ends in 2016 -> with year+1 it matches migration in 2017
* Thus we want to keep 1975-2017 in the migration database, corresponding to 1970-2016 in GTD
drop if year<1975
drop if year>2017

collapse (sum) Stock Flow, by (iso3o iso3d year)
* It corrects some duplicates due to the iso cleaning for Vietnam in the 70s. It concerns 21 observations.

merge 1:1 iso3o iso3d year using "Data\Migration and network\Glenn Samuel\Glenn network only.dta"
* _merge==1 --> Info on migration but not on network because the observations for that particular corridor just started that year. --> Can drop
* _merge==2 --> Opposite. Info on network but not on migration due to the year+1. Basically if the info on migration for a corridor ends on year y (with y<=2017), we will have network for y+1 not matching anything --> Can drop

drop if _merge!=3
drop _merge

gen Network_ln=ln(0.000001 + Network)

preserve

egen TotalStock=sum(Stock), by(iso3d year)
keep iso3d year TotalStock
duplicates drop
rename iso3d iso3o
rename TotalStock TotalStock_or

save "Data\Migration and network\Glenn Samuel\Glenn total stock origin.dta", replace

rename iso3o iso3d
rename TotalStock_or TotalStock_dest

save "Data\Migration and network\Glenn Samuel\Glenn total stock dest.dta", replace
restore

merge m:1 year iso3o using "Data\Migration and network\Glenn Samuel\Glenn total stock origin.dta"
* There are 4,456 obs with merge==1 because the total stocks are based on the o-d corridor, with destination being the reference. So if there is more countries in origin/countries-years, then these observations will have missings.
drop _merge

merge m:1 year iso3d using "Data\Migration and network\Glenn Samuel\Glenn total stock dest.dta"
drop _merge

* Flow<0 --> 149,855 obs --> around 0.09% of the observations
gen FlowWithoutNeg=Flow
gen DummyNegFlow=0
replace DummyNegFlow=1 if FlowWithoutNeg<0
replace FlowWithoutNeg=0 if FlowWithoutNeg<0

preserve
keep iso3o iso3d year Flow
keep if Flow<0
rename iso3o iso3d2
rename iso3d iso3o
rename iso3d2 iso3d
gen NegFlow=-Flow
drop Flow
save "Data\Migration and network\Glenn Samuel\Glenn negative flows", replace
restore

merge 1:1 year iso3o iso3d using "Data\Migration and network\Glenn Samuel\Glenn negative flows.dta"
drop if _merge==2 
* No info on that corridor in that direction
replace NegFlow=0 if _merge==1
drop _merge
gen FlowWithNeg=FlowWithoutNeg+NegFlow

save "Data\Migration and network\Glenn Samuel\Glenn migration and network.dta", replace

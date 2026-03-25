********************************************************************************
* 15 - Descriptive Statistics
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Produces summary statistics (Table B.1), pairwise correlations (Table B.2), choropleth maps of migration rates and GTI (Figures 1-2), and country lists.
*
* Input:   Final Bilateral Database - JEBO revision.dta
*
* Output:  LaTeX tables, Stata graphs (.gph)
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

clear all
cd "D:\Dropbox\PhD Killian\Paper I\"

********************************************************************************
* List - origin countries
clear
use "Data/Merge/Dta/Clean/Final Bilateral Database - Glenn.dta"


keep if e(sample)







replace Origin="Western Sahara" if iso3o=="ESH"
replace Origin="Guadeloupe" if iso3o=="GLP"
replace Origin="French Guiana" if iso3o=="GUF"
replace Origin="Martinique" if iso3o=="MTQ"
replace Origin="Mayotte" if iso3o=="MYT"
replace Origin="Réunion" if iso3o=="REU"
replace Origin="Serbia and Montenegro" if iso3o=="SCG"
replace Origin="Taiwan" if iso3o=="TWN"
drop if iso3o=="SUD"
drop if _merge==2
drop _merge
keep Origin
duplicates drop
save "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\List origin countries.dta", replace


********************************************************************************
* List - Destination countries (pre-regressions)
clear
use "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Merge\Dta\Clean\Final Bilateral Database - Abel.dta"
merge m:1 iso3d using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\iso3\Clean\Dta\country code dest.dta"
replace Destination="Western Sahara" if iso3d=="ESH"
replace Destination="Guadeloupe" if iso3d=="GLP"
replace Destination="French Guiana" if iso3d=="GUF"
replace Destination="Martinique" if iso3d=="MTQ"
replace Destination="Mayotte" if iso3d=="MYT"
replace Destination="Réunion" if iso3d=="REU"
replace Destination="Serbia and Montenegro" if iso3d=="SCG"
replace Destination="Taiwan" if iso3d=="TWN"
drop if iso3d=="SUD"
drop if _merge==2
drop _merge
keep Destination
duplicates drop
save "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\List destination countries.dta", replace


********************************************************************************
* List - Pair-wise correlations
clear
set matsize 11000
use "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Merge\Dta\Clean\Final Bilateral Database - Abel.dta"
estpost corr MigrationRate_o_ln GTI_o AttacksIndex_o VictimsIndex_o BombingIndex_o NationalTargIndex_o TargViolPolIndex_o TargReligIndex_o AttackOccurrence_o GTI_d AttacksIndex_d VictimsIndex_d BombingIndex_d NationalTargIndex_d TargViolPolIndex_d TargReligIndex_d AttackOccurrence_d dist_ln contig comlang_ethno GDPpc_o_ln GDPpc_d_ln Network_ln polity2_o polity2_d PolInstability_o PolInstability_d WarOccurrence_low_o WarOccurrence_high_o WarOccurrence_o WarOccurrence_low_d WarOccurrence_high_d WarOccurrence_d, matrix
esttab . using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\pwcorrelation.tex", not unstack compress noobs replace booktabs page label
!texify -p -c -b --run-viewer pwcorrelation.tex


********************************************************************************
* Summary statistics for all the variables used
clear
use "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Merge\Dta\Clean\Final Bilateral Database - Abel.dta"
keep iso3o iso3d year MigrationRate_o_ln dist_ln contig comlang_ethno Network_ln GTI_o AttacksIndex_o VictimsIndex_o BombingIndex_o NationalTargIndex_o TargViolPolIndex_o TargReligIndex_o AttackOccurrence_o GDPpc_o_ln polity2_o PolInstability_o WarOccurrence_high_o WarOccurrence_low_o WarOccurrence_o GTI_d AttacksIndex_d VictimsIndex_d BombingIndex_d NationalTargIndex_d TargViolPolIndex_d TargReligIndex_d AttackOccurrence_d GDPpc_d_ln polity2_d PolInstability_d WarOccurrence_low_d WarOccurrence_high_d WarOccurrence_d
* General statistics
summarize
sutex, long lab par nobs minmax
* Specific at the origin - year level
*sort iso3o year
*by iso3o year: sutex *o*, long lab par nobs minmax
* Specific at the destination - year level
*sort iso3d year
*by iso3d year: sutex *d*, long lab par nobs minmax


********************************************************************************
* Map - Sending countries (origin)
clear
cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists"
set more off
shp2dta using "Shapefile/world", data(worlddata_MAPS) coordinates(worldcoor) genid(id) gencentroids(stub) replace
* Open final database
use "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Merge\Dta\Clean\Final Bilateral Database - Abel.dta"
gsort iso3o
collapse (sum) flowb MigrationRate_o, by(iso3o year)
collapse (mean) flowb MigrationRate_o, by(iso3o)
rename flowb MigFlow_avg
rename MigrationRate_o MigRate_avg
format %12.2f MigRate_avg MigFlow_avg
merge 1:1 iso3o using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\iso3\Clean\Dta\country code.dta"
* Match country names with those in the worlddata.dta file
replace Origin="Western Sahara" if iso3o=="ESH"
replace Origin="Guadeloupe" if iso3o=="GLP"
replace Origin="French Guiana" if iso3o=="GUF"
replace Origin="Martinique" if iso3o=="MTQ"
replace Origin="Mayotte" if iso3o=="MYT"
replace Origin="Reunion" if iso3o=="REU"
replace Origin="Serbia and Montenegro" if iso3o=="SCG"
replace Origin="Taiwan" if iso3o=="TWN"
replace Origin="Bahamas, The" if Origin=="Bahamas"
replace Origin="Byelarus" if Origin=="Belarus"
replace Origin="Brunei" if Origin=="Brunei Darussalam"
replace Origin="Ivory Coast" if Origin=="Côte d'Ivoire"
replace Origin="North Korea" if Origin=="Democratic People's Republic of Korea"
replace Origin="Gambia, The" if Origin=="Gambia"
replace Origin="Man, Isle of" if Origin=="Isle of Man"
replace Origin="South Korea" if Origin=="Korea, Rep."
replace Origin="Federated States of Micronesia" if Origin=="Micronesia"
replace Origin="Myanmar (Burma)" if Origin=="Myanmar"
replace Origin="St. Lucia" if Origin=="Saint Lucia"
replace Origin="St. Vincent and the Grenadines" if Origin=="Saint Vincent and the Grenadines"
replace Origin="Western Samoa" if Origin=="Samoa"
replace Origin="Netherlands Antilles" if Origin=="Sint Maarten (Dutch part)"
replace Origin="Slovakia" if Origin=="Slovak Republic"
replace Origin="Tanzania, United Republic of" if Origin=="Tanzania"
replace Origin="Vietnam" if Origin=="Viet Nam"
replace Origin="Virgin Islands" if Origin=="Virgin Islands (U.S.)"
replace Origin="West Bank" if Origin=="West Bank and Gaza Strip"
drop if iso3o=="SUD"
drop if _merge==2
drop _merge
rename Origin CNTRY_NAME
merge m:1 CNTRY_NAME using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\worlddata_MAPS.dta"
* Flow
spmap MigFlow_avg using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Blues) clnumber(5) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\Sending countries - avg flows.gph", replace
* Rate // Normal
spmap MigRate_avg using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Blues) clnumber(5) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\Sending countries - avg rates normal.gph", replace
* Rate // Custom
spmap MigRate_avg using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Blues) clmethod(custom) clbreaks(0 0.01 0.03 0.05 0.1 1) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\Sending countries - avg rates custom.gph", replace


********************************************************************************
* Map - Receiving countries (destination)
clear
cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists"
set more off
shp2dta using "Shapefile/world", data(worlddata_MAPS) coordinates(worldcoor) genid(id) gencentroids(stub) replace
* Open final database
use "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Merge\Dta\Clean\Final Bilateral Database - Abel.dta"
gsort iso3o
collapse (sum) flowb MigrationRate_d, by(iso3d year)
collapse (mean) flowb MigrationRate_d, by(iso3d)
rename flowb MigFlow_avg
rename MigrationRate_d MigRate_avg
format %12.2f MigRate_avg MigFlow_avg
merge 1:1 iso3d using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\iso3\Clean\Dta\country code dest.dta"
* Match country names with those in the worlddata.dta file
replace Destination="Western Sahara" if iso3d=="ESH"
replace Destination="Guadeloupe" if iso3d=="GLP"
replace Destination="French Guiana" if iso3d=="GUF"
replace Destination="Martinique" if iso3d=="MTQ"
replace Destination="Mayotte" if iso3d=="MYT"
replace Destination="Reunion" if iso3d=="REU"
replace Destination="Serbia and Montenegro" if iso3d=="SCG"
replace Destination="Taiwan" if iso3d=="TWN"
replace Destination="Bahamas, The" if Destination=="Bahamas"
replace Destination="Byelarus" if Destination=="Belarus"
replace Destination="Brunei" if Destination=="Brunei Darussalam"
replace Destination="Ivory Coast" if Destination=="Côte d'Ivoire"
replace Destination="North Korea" if Destination=="Democratic People's Republic of Korea"
replace Destination="Gambia, The" if Destination=="Gambia"
replace Destination="Man, Isle of" if Destination=="Isle of Man"
replace Destination="South Korea" if Destination=="Korea, Rep."
replace Destination="Federated States of Micronesia" if Destination=="Micronesia"
replace Destination="Myanmar (Burma)" if Destination=="Myanmar"
replace Destination="St. Lucia" if Destination=="Saint Lucia"
replace Destination="St. Vincent and the Grenadines" if Destination=="Saint Vincent and the Grenadines"
replace Destination="Western Samoa" if Destination=="Samoa"
replace Destination="Netherlands Antilles" if Destination=="Sint Maarten (Dutch part)"
replace Destination="Slovakia" if Destination=="Slovak Republic"
replace Destination="Tanzania, United Republic of" if Destination=="Tanzania"
replace Destination="Vietnam" if Destination=="Viet Nam"
replace Destination="Virgin Islands" if Destination=="Virgin Islands (U.S.)"
replace Destination="West Bank" if Destination=="West Bank and Gaza Strip"
drop if iso3d=="SUD"
drop if _merge==2
drop _merge
rename Destination CNTRY_NAME
merge m:1 CNTRY_NAME using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\worlddata_MAPS.dta"
* Flow
spmap MigFlow_avg using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Blues) clnumber(5) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\Receiving countries - avg flows.gph", replace
* Rate // Normal
spmap MigRate_avg using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Blues) clnumber(5) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\Receiving countries - avg rates normal.gph", replace
* Rate // Custom
spmap MigRate_avg using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Blues) clmethod(custom) clbreaks(0 0.01 0.03 0.05 0.1 1 1.51) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\Receiving countries - avg rates custom.gph", replace


********************************************************************************
* Map - GTI
clear
cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists"
set more off
shp2dta using "Shapefile/world", data(worlddata_MAPS) coordinates(worldcoor) genid(id) gencentroids(stub) replace
* Open final database
use "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Merge\Dta\Clean\Final Bilateral Database - Abel.dta"
gsort iso3o
collapse (mean) GTI_o, by(iso3o)
rename GTI_o GTI
format %12.2f GTI
merge 1:1 iso3o using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\iso3\Clean\Dta\country code.dta"
* Match country names with those in the worlddata.dta file
replace Origin="Western Sahara" if iso3o=="ESH"
replace Origin="Guadeloupe" if iso3o=="GLP"
replace Origin="French Guiana" if iso3o=="GUF"
replace Origin="Martinique" if iso3o=="MTQ"
replace Origin="Mayotte" if iso3o=="MYT"
replace Origin="Reunion" if iso3o=="REU"
replace Origin="Serbia and Montenegro" if iso3o=="SCG"
replace Origin="Taiwan" if iso3o=="TWN"
replace Origin="Bahamas, The" if Origin=="Bahamas"
replace Origin="Byelarus" if Origin=="Belarus"
replace Origin="Brunei" if Origin=="Brunei Darussalam"
replace Origin="Ivory Coast" if Origin=="Côte d'Ivoire"
replace Origin="North Korea" if Origin=="Democratic People's Republic of Korea"
replace Origin="Gambia, The" if Origin=="Gambia"
replace Origin="Man, Isle of" if Origin=="Isle of Man"
replace Origin="South Korea" if Origin=="Korea, Rep."
replace Origin="Federated States of Micronesia" if Origin=="Micronesia"
replace Origin="Myanmar (Burma)" if Origin=="Myanmar"
replace Origin="St. Lucia" if Origin=="Saint Lucia"
replace Origin="St. Vincent and the Grenadines" if Origin=="Saint Vincent and the Grenadines"
replace Origin="Western Samoa" if Origin=="Samoa"
replace Origin="Netherlands Antilles" if Origin=="Sint Maarten (Dutch part)"
replace Origin="Slovakia" if Origin=="Slovak Republic"
replace Origin="Tanzania, United Republic of" if Origin=="Tanzania"
replace Origin="Vietnam" if Origin=="Viet Nam"
replace Origin="Virgin Islands" if Origin=="Virgin Islands (U.S.)"
replace Origin="West Bank" if Origin=="West Bank and Gaza Strip"
drop if iso3o=="SUD"
drop if _merge==2
drop _merge
rename Origin CNTRY_NAME
merge m:1 CNTRY_NAME using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\worlddata_MAPS.dta"
* Normal
spmap GTI using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Reds) clnumber(5) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\GTI by country - normal.gph", replace
* Custom
spmap GTI using "worldcoor" if CNTRY_NAME!="Antarctica", id(id) fcolor(Reds) clmethod(custom) clbreaks(0 2 4 6 8) ndocolor(gs8) osize(vthin) legstyle(2) legcount legend(size(*2))
graph save Graph "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Descriptives\Clean\Graphs, maps and lists\GTI by country - custom.gph", replace

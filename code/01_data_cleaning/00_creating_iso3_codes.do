********************************************************************************
* 00 - ISO3 Country Codes (Prerequisite)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Extracts standardized ISO3 country codes from the GADM shapefile. These codes are used as merge keys across all subsequent scripts.
*
* Input:   GADM shapefile (gadm36_0.shp)
*
* Output:  iso3clean origin.dta, iso3clean dest.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

* Create iso3 codes
clear all

cd "D:\Dropbox\PhD Killian\Paper I\" // Killian fix PC
*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\" // Killian laptop

shp2dta using "Maps\gadm36_0.shp", data(D:\Dropbox\PhD Killian\Paper I\Data\iso3\Clean\Dta\iso3) coordinates(D:\Dropbox\PhD Killian\Paper I\Data\iso3\Clean\Dta\worldcoorlvl0) genid(id) replace

clear all

use "Data\iso3\Clean\Dta\iso3.dta", clear
drop id
rename NAME_0 origin
rename GID_0 iso3o
save "Data\iso3\Clean\Dta\iso3clean origin.dta", replace

rename origin destination
rename iso3o iso3d
save "Data\iso3\Clean\Dta\iso3clean dest.dta", replace



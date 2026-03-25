********************************************************************************
* 05 - GDP per Capita (Penn World Table)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans GDP per capita from the Penn World Table 10.0. Used as the main income control variable in the gravity model.
*
* Input:   pwt100.dta (Penn World Table)
*
* Output:  GDPpc origin cleaned.dta, GDPpc dest cleaned.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

clear all
*cd "D:\Dropbox\PhD Killian\Paper I\" // Fix computer
cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\" // Laptop

use "Data/PWT/pwt100.dta" 

keep country year countrycode rgdpna pop
drop if year<1974
gen GDPpc = rgdpna/pop
drop if year==. | rgdpna==.

keep country year countrycode GDPpc
rename countrycode iso3o
rename country origin

replace origin="Bolivia" if origin=="Bolivia (Plurinational State of)"
replace origin="Brunei" if origin=="Brunei Darussalam"
replace origin="Cape Verde" if origin=="Cabo Verde"
replace origin="Hong Kong" if origin=="China, Hong Kong SAR"
replace origin="Macao" if origin=="China, Macao SAR"
replace origin="Republic of Congo" if origin=="Congo"
replace origin="Democratic Republic of the Congo" if origin=="D.R. of the Congo"
replace origin="Swaziland" if origin=="Eswatini"
replace origin="Iran" if origin=="Iran (Islamic Republic of)"
replace origin="Laos" if origin=="Lao People's DR"
replace origin="Macedonia" if origin=="North Macedonia"
replace origin="South Korea" if origin=="Republic of Korea"
replace origin="Moldova" if origin=="Republic of Moldova"
replace origin="Russia" if origin=="Russian Federation"
replace origin="São Tomé and Príncipe" if origin=="Sao Tome and Principe"
replace origin="Sint Maarten" if origin=="Sint Maarten (Dutch part)"
replace origin="Saint Vincent and the Grenadines" if origin=="St. Vincent and the Grenadines"
replace origin="Palestina" if origin=="State of Palestine"
replace origin="Syria" if origin=="Syrian Arab Republic"
replace origin="Tanzania" if origin=="U.R. of Tanzania: Mainland"
replace origin="Venezuela" if origin=="Venezuela (Bolivarian Republic of)"
replace origin="Vietnam" if origin=="Viet Nam"

merge m:1 origin using "Data/iso3/Clean/Dta/iso3clean origin.dta"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                            73
        from master                         0  (_merge==1)
        from using                         73  (_merge==2)

    matched                             7,973  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
drop _merge

drop origin
sort iso3o year
order iso3o year GDPpc
rename GDPpc GDPpc_or
gen GDPpc_or_ln=ln(GDPpc_or)

replace year=year+1

save "Data/PWT/GDPpc origin cleaned", replace

rename GDPpc_or GDPpc_dest
rename GDPpc_or_ln GDPpc_dest_ln
rename iso3o iso3d

save "Data/PWT/GDPpc dest cleaned", replace

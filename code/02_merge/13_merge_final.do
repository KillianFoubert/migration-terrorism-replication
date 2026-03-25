********************************************************************************
* 13 - Final Merge
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Merges all cleaned datasets into the final bilateral panel (154 origin x 154 destination countries, 1975-2017). Constructs the dependent variable (bilateral migration rate), fixed effects, and auxiliary variables.
*
* Input:   All cleaned datasets from scripts 01-12
*
* Output:  Final Bilateral Database - JEBO revision.dta (456,439 observations)
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

clear all

*cd "C:/Users/kifouber/Dropbox/PhD Killian/Paper I/"
cd "/Users/ilseruyssen/Library/CloudStorage/Dropbox/PhD Killian/Paper I"
*cd "D:\Dropbox\PhD Killian\Paper I\"

*** ERROR IN LINE BELOW!!
*use "Data/Migration and network/Glenn Samuel/JEBO revision/Glenn migration and network.dta", clear // Note Ilse: there is no such folder so doesn't work for me!

use "Data/Migration and network/Glenn Samuel/Glenn migration and network.dta", clear
*** Terrorism
* Origin

merge m:1 iso3o year using "Data/GTD/Clean/Dta/Terror origin - JEBO revision.dta"

/* updated 07/01/2021  (and doublechecked 31 October 2023)
    Result                           # of obs.
    -----------------------------------------
    not matched                       265,735
        from master                   265,603  (_merge==1)
        from using                        132  (_merge==2)

    matched                         1,353,473  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2

foreach k of varlist BombingPCPY_o-TargReligIndex_o {
	replace `k'=0 if `k'==. & _merge==1
}

gen ambiguous_o=1 if _merge==1
drop _merge

* Destination

merge m:1 iso3d year using "Data/GTD/Clean/Dta/Terror dest - JEBO revision.dta"

/* updated 07/01/2021 (and doublechecked 31 October 2023)
    Result                           # of obs.
    -----------------------------------------
    not matched                       259,730
        from master                   259,386  (_merge==1)
        from using                        344  (_merge==2)

    matched                         1,359,690  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2

foreach k of varlist BombingPCPY_o-TargReligIndex_o {
	replace `k'=0 if `k'==. & _merge==1
}

gen ambiguous_d=1 if _merge==1
drop _merge

* Without 11/09

merge m:1 iso3o year using "Data/GTD/Clean/Dta/Terror origin without 1109.dta"

/* Doublechecked 31 October 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       265,735
        from master                   265,603  (_merge==1)
        from using                        132  (_merge==2)

    matched                         1,353,473  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
replace GTI_o_1109=0 if GTI_o_1109==. & _merge==1
drop _merge

merge m:1 iso3d year using "Data/GTD/Clean/Dta/Terror dest without 1109.dta"

/* Doublechecked 31 October 2023

    Result                           # of obs.
    -----------------------------------------
    not matched                       259,730
        from master                   259,386  (_merge==1)
        from using                        344  (_merge==2)

    matched                         1,359,690  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
replace GTI_d_1109=0 if GTI_d_1109==. & _merge==1
drop _merge

*** CEPII

merge m:1 iso3o iso3d using "Data/CEPII/Clean/Dta/CEPII_compatibleGWP.dta"

/* updated 08/01/2021 and doublechecked 31 October 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       102,956
        from master                   100,107  (_merge==1)
        from using                      2,849  (_merge==2)

    matched                         1,518,969  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
drop _merge

sort iso3o iso3d year
order iso3o iso3d year

gen dist_ln=ln(dist)
* (100,113 missing values generated) // Not sure why 100,113 and not 100,107

*** WDI
* Origin

merge m:1 year iso3o using "Data/WDI/Clean/Dta/WDI origin.dta"

/* updated 10/05/2021   BUT OLD!!! 
    Result                           # of obs.
    -----------------------------------------
    not matched                       136,944
        from master                   136,757  (_merge==1)
        from using                        187  (_merge==2)

    matched                         1,482,319  (_merge==3)
    -----------------------------------------
*** When starting the revision, we had merged like this, ie with the updated population data
merge m:1 year iso3d using "Data/WDI/Clean/Dta/WDI dest - JEBO revision.dta"
New merge results 31 October 2023, but then not continued with this:
    Result                           # of obs.
    -----------------------------------------
    not matched                       124,584
        from master                   123,529  (_merge==1)
        from using                      1,055  (_merge==2)

    matched                         1,495,547  (_merge==3)
    -----------------------------------------
*** but if we do, we run into trouble: our population data are slightly different
*** (probably updated by the Worldbank, but also for older years with a difference of for instance 
*** over 4 million in India in 1986... So need to stick to the old WDI data for our analysis,
*** and perhaps only use these updated ones for the computation of the population weighted GTIs...
*/

rename *or *o
drop if _merge==2
drop _merge

* Destination

merge m:1 year iso3d using "Data/WDI/Clean/Dta/WDI dest.dta"

/* updated 10/05/2021 BUT OLD!!!
    Result                           # of obs.
    -----------------------------------------
    not matched                       130,630
        from master                   130,357  (_merge==1)
        from using                        273  (_merge==2)

    matched                         1,488,719  (_merge==3)
    -----------------------------------------
*** When starting the revision, we had merged like this, ie with the updated population data
merge m:1 year iso3d using "Data/WDI/Clean/Dta/WDI dest - JEBO revision.dta"

	New merge results 31 October 2023 but then not continued with this
    Result                           # of obs.
    -----------------------------------------
    not matched                       118,972
        from master                   117,827  (_merge==1)
        from using                      1,145  (_merge==2)

    matched                         1,501,249  (_merge==3)
    -----------------------------------------
*/

rename *dest *d
drop if _merge==2
drop _merge

*** GDPpc from PWT
* Origin

merge m:1 year iso3o using "Data/PWT/GDPpc origin cleaned.dta"

/* updated 10/05/2021 and doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       401,432
        from master                   400,883  (_merge==1)
        from using                        549  (_merge==2)

    matched                         1,218,193  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
drop _merge

* Destination

merge m:1 year iso3d using "Data/PWT/GDPpc dest cleaned.dta"

/* updated 10/05/2021 and doublechecked 31 Oct 2023

    Result                           # of obs.
    -----------------------------------------
    not matched                       387,134
        from master                   386,562  (_merge==1)
        from using                        572  (_merge==2)

    matched                         1,232,514  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
drop _merge

*** Polity IV
* Origin

merge m:1 year iso3o using "Data/Polity 4/Clean/Dta/Polity 4 origin.dta"

/* updated 10/05/2021 and doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       520,456
        from master                   520,309  (_merge==1)
        from using                        147  (_merge==2)

    matched                         1,098,767  (_merge==3)
    -----------------------------------------
*/

rename *_or *_o
drop if _merge==2
drop _merge

* Destination

merge m:1 year iso3d using "Data/Polity 4/Clean/Dta/Polity 4 dest.dta"

/* updated 10/05/2021 and doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       507,980
        from master                   507,802  (_merge==1)
        from using                        178  (_merge==2)

    matched                         1,111,274  (_merge==3)
    -----------------------------------------
*/

rename *_dest *_d
drop if _merge==2
drop _merge

*** Conflicts
* Origin
merge m:1 year iso3o using "Data/Conflicts/Clean/Dta/Occurrence of conflict origin - JEBO revision.dta"

/* updated 10/05/2021 and doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       919,438
        from master                   918,894  (_merge==1)
        from using                        544  (_merge==2)

    matched                           700,182  (_merge==3)
    -----------------------------------------
*/

forval i = 1/5 {  
replace WarOccurrence_low`i'_or=0 if _merge==1
replace WarOccurrence_high`i'_or=0 if _merge==1
replace WarOccurrence`i'_or=0 if _merge==1
}

drop if _merge==2
drop _merge

* Destination
merge m:1 year iso3d using "Data/Conflicts/Clean/Dta/Occurrence of conflict dest - JEBO revision.dta"

/* updated 15/12/2021 and doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       938,590
        from master                   937,915  (_merge==1)
        from using                        675  (_merge==2)

    matched                           681,161  (_merge==3)
    -----------------------------------------
*/

forval i = 1/5 {  
replace WarOccurrence_low`i'_dest=0 if _merge==1
replace WarOccurrence_high`i'_dest=0 if _merge==1
replace WarOccurrence`i'_dest=0 if _merge==1
}

drop if _merge==2
drop _merge

*** Governments fractionalization

* Origin
merge m:1 iso3o year using "Data/Government fractionalization/frac_o.dta"

/*  doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       446,250
        from master                   446,204  (_merge==1)
        from using                         46  (_merge==2)

    matched                         1,172,872  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
drop _merge

* Destination
merge m:1 iso3d year using "Data/Government fractionalization/frac_d.dta"

/* doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       437,365
        from master                   437,259  (_merge==1)
        from using                        106  (_merge==2)

    matched                         1,181,817  (_merge==3)
    -----------------------------------------
*/

drop if _merge==2
drop _merge

*** Ethnic & Religious fractionalization

* Origin
merge m:1 iso3o year using "Data/Ethnic religious frac/FRAC_o.dta"

/*  doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       502,748
        from master                   498,132  (_merge==1)
        from using                      4,616  (_merge==2)

    matched                         1,120,944  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

* Destination
merge m:1 iso3d year using "Data/Ethnic religious frac/FRAC_d.dta"

/*  doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       492,057
        from master                   487,410  (_merge==1)
        from using                      4,647  (_merge==2)

    matched                         1,131,666  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

*** Quality of institutions

* Origin
merge m:1 iso3o year using "Data/Quality of institutions/Instits origin.dta"

/*  doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                     1,227,767
        from master                 1,227,307  (_merge==1)
        from using                        460  (_merge==2)

    matched                           391,769  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

* Destination
merge m:1 iso3d year using "Data/Quality of institutions/Instits dest.dta"

/*  doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                     1,225,312
        from master                 1,224,836  (_merge==1)
        from using                        476  (_merge==2)

    matched                           394,240  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

*** Refugees flows

* Origin
merge m:1 iso3o year using "Data/Refugees/RefugeesCleaned origin.dta"

/* Doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       134,076
        from master                   130,062  (_merge==1)
        from using                      4,014  (_merge==2)

    matched                         1,489,014  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

* Destination
merge m:1 iso3d year using "Data/Refugees/RefugeesCleaned dest.dta"

/*Doublechecked 31 Oct 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                       128,114
        from master                   124,014  (_merge==1)
        from using                      4,100  (_merge==2)

    matched                         1,495,062  (_merge==3)
    -----------------------------------------
*/
drop if _merge==2
drop _merge

*** Working on variables and fixed effects

* Dependent variable

sort iso3o iso3d year
egen dyad = group(iso3o iso3d)

* Detect duplicates

sort dyad year
xtset dyad year

gen Natives_o= PopTotal_o-TotalStock_o
gen Natives_d= PopTotal_d-TotalStock_d
replace Natives_o=. if Natives_o<0
replace Natives_d=. if Natives_d<0

* This gives a proxy for the number of natives per year

gen MigrationRateWithoutNeg=FlowWithoutNeg/Natives_o
gen MigrationRateWithoutNeg_ln=ln(0.000001+MigrationRateWithoutNeg)
sum MigrationRateWithoutNeg_ln

gen MigrationRateWithNeg=FlowWithNeg/Natives_o
gen MigrationRateWithNeg_ln=ln(0.000001+MigrationRateWithNeg)
sum MigrationRateWithNeg_ln

gen MigrationRateNHS=Flow/Natives_o

egen TotalFlowsWithoutNeg_o=sum(FlowWithoutNeg), by (iso3o year)
* Gives the total number of people who left the origin country that year (without neg flows)
egen TotalFlowsWithNeg_o=sum(FlowWithNeg), by (iso3o year)
* Gives the total number of people who left the origin country that year (with neg flows)
egen TotalFlowsWithoutNeg_d=sum(FlowWithoutNeg), by (iso3d year)
* Gives the total number of people who come to each destination country that year (without neg flows)
egen TotalFlowsWithNeg_d=sum(FlowWithNeg), by (iso3d year)
* Gives the total number of people who come to each destination country that year (with neg flows)

*** Construction Fixed Effects
egen oFE = group(iso3o)
egen dFE = group(iso3d)
egen yFE = group(year)
egen dyFE = group(iso3d year)

merge m:1 iso3o using "Data/iso3/Clean/Dta/iso3clean origin.dta"

replace origin="Netherlands Antilles" if iso3o=="ANT"
replace origin="Czechoslovakia" if iso3o=="CSK"
replace origin="North Yemen" if iso3o=="NYE"
replace origin="Serbia-Montenegro" if iso3o=="SCG"
replace origin="South Yemen" if iso3o=="SYE"
replace origin="USSR" if iso3o=="USR"
replace origin="Yugoslavia" if iso3o=="YUG"
drop if _merge==2
drop _merge 

merge m:1 iso3d using "Data/iso3/Clean/Dta/iso3clean dest.dta"
replace destination="Netherlands Antilles" if iso3d=="ANT"
replace destination="Czechoslovakia" if iso3d=="CSK"
replace destination="North Yemen" if iso3d=="NYE"
replace destination="Serbia-Montenegro" if iso3d=="SCG"
replace destination="USSR" if iso3d=="USR"
replace destination="Yugoslavia" if iso3d=="YUG"
drop if _merge==2
drop _merge

sort origin destination year 
order origin iso3o destination iso3d year

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
generate MigrationRateNHS_sinh = asinh(MigrationRateNHS)
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

generate MigrationRateNHS_sinhb = -((exp(MigrationRateNHS) - exp(-MigrationRateNHS)) / 2)
* I transform the dependant variable with NHS manually to ensure the change of sign is correct due to the very small magnitude of the obs
* For now I do not understand how it is helping, previously positive observations are now negative and previously negative observations are now positive, that is it.

save "Data/Merge/Dta/Clean/Final Bilateral Database - JEBO revision.dta", replace

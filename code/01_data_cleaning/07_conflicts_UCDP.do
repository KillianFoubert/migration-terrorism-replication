********************************************************************************
* 07 - Armed Conflicts (UCDP/PRIO)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans the UCDP/PRIO Armed Conflict Dataset. Constructs conflict occurrence dummies (low and high intensity) at the country-year level with 1- and 5-year windows.
*
* Input:   ucdp-prio-acd-181.dta (UCDP/PRIO)
*
* Output:  Occurrence of conflict origin.dta, Occurrence of conflict dest.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

* Origin corresponds to countries whose government(s) have a primary claim to the issue in dispute, not location per se.
* We lose some conflicts with NVietnam/SVietnam since it's not clear if I can attribute some of these conflicts to the whole territory

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

use "Data/Conflicts/Clean/Dta/ucdp-prio-acd-181.dta"

drop if year < 1970
drop if year > 2016
keep location territory_name side_a side_a_2nd side_b side_b_2nd incompatibility year intensity_level cumulative_intensity type_of_conflict
rename location origin

**************************************************************************************
*** Rearrange data on conflicts -> attribute them to the territory where it took place
**************************************************************************************

replace origin="Myanmar" if origin=="Myanmar (Burma)"
replace origin="Democratic Republic of the Congo" if origin=="DR Congo (Zaire)"
replace origin="Republic of Congo" if origin=="Congo"
replace origin="Cambodia" if origin=="Cambodia (Kampuchea)"
replace origin="Romania" if origin=="Rumania"
replace origin="Yugoslavia" if origin=="Serbia (Yugoslavia)"
replace origin="USSR Soviet Union" if origin=="Russia (Soviet Union)"
replace origin="Macedonia" if origin=="Macedonia, FYR"
replace origin="United States" if origin=="United States of America"
replace origin="Côte d'Ivoire" if origin=="Ivory Coast"
replace origin="Iraq" if origin=="Australia, Iraq, United Kingdom, United States of America"
replace origin="Afghanistan" if origin=="Afghanistan, United Kingdom, United States of America"
replace origin="Eritrea" if origin=="Eritrea, Ethiopia"
replace origin="Zimbabwe" if origin=="Zimbabwe (Rhodesia)"
replace origin="Grenada" if origin=="Grenada, United States of America"
replace origin="Panama" if origin=="Panama, United States of America"
replace origin="Afghanistan" if origin=="Afghanistan, Russia (Soviet Union)"

order year origin intensity_level
sort origin year
// We use Dreher methodology here
gen WarOccurrence_low = 1 if intensity_level == 1
replace WarOccurrence_low = 0 if WarOccurrence_low == .
gen WarOccurrence_high = 1 if intensity_level == 2
replace WarOccurrence_high = 0 if WarOccurrence_high == .

collapse (max) WarOccurrence_low WarOccurrence_high, by(origin year)
replace WarOccurrence_low = 0 if WarOccurrence_high == 1
gen WarOccurrence = 1

* Merge with iso3 codes
merge m:1 origin using "Data/iso3/Clean/Dta/iso3clean origin.dta"

/* updated 08/01/2021
    Result                           # of obs.
    -----------------------------------------
    not matched                           283
        from master                       116  (_merge==1)
        from using                        167  (_merge==2)

    matched                             1,154  (_merge==3)
    -----------------------------------------
*/

replace iso3o="BIH" if origin=="Bosnia-Herzegovina"
replace iso3o="SYE" if origin=="South Yemen"
replace iso3o="USR" if origin=="USSR Soviet Union"
replace iso3o="NYE" if origin=="Yemen (North Yemen)"
replace iso3o="YUG" if origin=="Yugoslavia"

drop if _merge==2
expand 2 if _merge==1 & iso3o==""
sort origin year
quietly by origin year:  gen dup = cond(_N==1,0,_n)

replace iso3o="ARG" if origin=="Argentina, United Kingdom" & dup==1
replace iso3o="GBR" if origin=="Argentina, United Kingdom" & dup==2

replace iso3o="BFA" if origin=="Burkina Faso, Mali" & dup==1
replace iso3o="MLI" if origin=="Burkina Faso, Mali" & dup==2

replace iso3o="KHM" if origin=="Cambodia (Kampuchea), Thailand" & dup==1
replace iso3o="THA" if origin=="Cambodia (Kampuchea), Thailand" & dup==2

replace iso3o="KHM" if origin=="Cambodia (Kampuchea), Vietnam (North Vietnam)" & dup==1
*replace iso3o="VNM" if origin=="Cambodia (Kampuchea), Vietnam (North Vietnam)" & dup==2
* Not clear if during that period I can consider NVietnam and SVietnam as simply "Vietnam". Same issue with Germany.

replace iso3o="CMR" if origin=="Cameroon, Nigeria" & dup==1
replace iso3o="NGA" if origin=="Cameroon, Nigeria" & dup==2

replace iso3o="TCD" if origin=="Chad, Libya" & dup==1
replace iso3o="LBY" if origin=="Chad, Libya" & dup==2

replace iso3o="TCD" if origin=="Chad, Nigeria" & dup==1
replace iso3o="NGA" if origin=="Chad, Nigeria" & dup==2

replace iso3o="CHN" if origin=="China, Vietnam (North Vietnam)" & dup==1
*replace iso3o="VNM" if origin=="China, Vietnam (North Vietnam)" & dup==2
* Not clear if during that period I can consider NVietnam and SVietnam as simply "Vietnam". Same issue with Germany.

replace iso3o="CYP" if origin=="Cyprus, Turkey" & dup==1
replace iso3o="TUR" if origin=="Cyprus, Turkey" & dup==2

replace iso3o="DJI" if origin=="Djibouti, Eritrea" & dup==1
replace iso3o="ERI" if origin=="Djibouti, Eritrea" & dup==2

replace iso3o="ECU" if origin=="Ecuador, Peru" & dup==1
replace iso3o="PER" if origin=="Ecuador, Peru" & dup==2

replace iso3o="ETH" if origin=="Ethiopia, Somalia" & dup==1
replace iso3o="SOM" if origin=="Ethiopia, Somalia" & dup==2

replace iso3o="IND" if origin=="India, Pakistan" & dup==1
replace iso3o="PAK" if origin=="India, Pakistan" & dup==2

replace iso3o="IRN" if origin=="Iran, Iraq" & dup==1
replace iso3o="IRQ" if origin=="Iran, Iraq" & dup==2

replace iso3o="IRQ" if origin=="Iraq, Kuwait" & dup==1
replace iso3o="KWT" if origin=="Iraq, Kuwait" & dup==2

replace iso3o="LAO" if origin=="Laos, Thailand" & dup==1
replace iso3o="THA" if origin=="Laos, Thailand" & dup==2

replace iso3o="SSD" if origin=="South Sudan, Sudan" & dup==1
replace iso3o="SDN" if origin=="South Sudan, Sudan" & dup==2

drop if origin=="South Vietnam, Vietnam (North Vietnam)" & dup==1
replace iso3o="VNM" if origin=="South Vietnam, Vietnam (North Vietnam)" & dup==2
* In that particular case it's in any case in Vietnam (the whole country). So we can safely replace by VNM.

replace iso3o="NYE" if origin=="South Yemen, Yemen (North Yemen)" & dup==1
replace iso3o="SYE" if origin=="South Yemen, Yemen (North Yemen)" & dup==2

replace iso3o="TZA" if origin=="Tanzania, Uganda" & dup==1
replace iso3o="UGA" if origin=="Tanzania, Uganda" & dup==2

drop origin _merge dup
sort iso3o year
order iso3o year

duplicates drop
drop if iso3o==""
collapse (max) WarOccurrence_low WarOccurrence_high WarOccurrence, by(iso3o year)
* This command gives occurrence=1 for duplicates we corrected above 

/////////
egen country = group(iso3o)
egen time = group(year)
order country year
sort country time
tsset country time
tsfill, full
* If we assume that there is no measurement error and all the conflicts are recorded
bysort time: carryforward year, gen(yearn)
bysort country: carryforward iso3o, gen(iso3on)
drop year iso3o
gsort country - time
bysort time: carryforward yearn, gen(yearnn)
bysort country: carryforward iso3on, gen(iso3onn)
drop yearn iso3on
sort country - time
bysort time: carryforward yearnn, gen(yearnnn)
bysort country: carryforward iso3onn, gen(iso3onnn)
drop yearnn iso3onn
gsort country - time
bysort time: carryforward yearnnn, gen(yearnnnn)
bysort country: carryforward iso3onnn, gen(iso3onnnn)
drop yearnnn iso3onnn
sort country - time
bysort time: carryforward yearnnnn, gen(yearnnnnn)
bysort country: carryforward iso3onnnn, gen(iso3onnnnn)
drop yearnnnn iso3onnnn

rename yearnnnnn year
rename iso3onnnnn iso3o

replace WarOccurrence_low=0 if WarOccurrence_low==.
replace WarOccurrence_high=0 if WarOccurrence_high==.
replace WarOccurrence=0 if WarOccurrence==.

order iso3o year
sort country time

forval i = 1/5 {  
gen WarOccurrence_low`i'=L`i'.WarOccurrence_low
gen WarOccurrence_high`i'=L`i'.WarOccurrence_high
gen WarOccurrence`i'=L`i'.WarOccurrence
}

gen WarOccurrence5y=1 if WarOccurrence1==1 | WarOccurrence2==1 | WarOccurrence3==1 | WarOccurrence4==1 | WarOccurrence5==1
replace WarOccurrence5y=0 if WarOccurrence5y==.

gen WarOccurrence_high5y=1 if WarOccurrence_high1==1 | WarOccurrence_high2==1 | WarOccurrence_high3==1 | WarOccurrence_high4==1 | WarOccurrence_high5==1
replace WarOccurrence_high5y=0 if WarOccurrence_high5y==.

gen WarOccurrence_low5y=1 if WarOccurrence_low1==1 | WarOccurrence_low2==1 | WarOccurrence_low3==1 | WarOccurrence_low4==1 | WarOccurrence_low5==1
replace WarOccurrence_low5y=0 if WarOccurrence_low5y==.

drop country time
/////////

*replace year=year+1 

rename * *_or
rename iso3o_or iso3o
rename year_or year

drop WarOccurrence_low_or WarOccurrence_high_or WarOccurrence_or

drop if year<1975

save "Data/Conflicts/Clean/Dta/Occurrence of conflict origin.dta", replace

rename *_or *_dest
rename iso3o iso3d

save "Data/Conflicts/Clean/Dta/Occurrence of conflict dest.dta", replace


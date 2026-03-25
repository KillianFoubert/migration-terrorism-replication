********************************************************************************
* 04 - World Development Indicators (Population, GNI)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Downloads and cleans population totals and GNI per capita from the World Bank WDI. Constructs time-varying income group thresholds for corridor classification.
*
* Input:   World Bank API (wbopendata)
*
* Output:  WDI origin.dta, WDI dest.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

/* GDP per capita, PPP (constant 2017 US$)
clear  
wbopendata, indicator(NY.GDP.PCAP.PP.KD) long nometadata clear

drop if year<1974
drop if year>2016

rename countryname origin
drop countrycode region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
tostring year, replace
rename ny_gdp_pcap_pp_kd GDPpercapitaPPPconstant
label variable GDPpercapitaPPPconstant "GDP per capita, PPP (constant 2017 US$), NY.GDP.PCAP.PP.KD"

save "D:\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\GDPpercapitaPPPconstant.dta",replace
*save "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\GDPpercapitaPPPconstant.dta", replace
*/



*cd "D:\Dropbox\PhD Killian\Paper I\"
*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\"
cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

* Total population
clear
wbopendata, indicator(SP.POP.TOTL) long nometadata clear

drop if year<1970
drop if year>2016

rename countryname origin
drop countrycode region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
tostring year, replace
rename sp_pop_totl PopulationTotal
label variable PopulationTotal "Population, total SP.POP.TOTL"

*save "D:\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\TotalPop.dta",replace

save "Data\WDI\Clean\Dta\TotalPop - JEBO revision.dta", replace
/* Total population (males)
clear
wbopendata, indicator(SP.POP.TOTL.MA.IN) long nometadata clear

drop if year<1970
drop if year>2016

rename countryname origin
drop countrycode region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
tostring year, replace
rename sp_pop_totl_ma_in PopulationMales
label variable PopulationMales "Males population, total SP.POP.TOTL.MA.IN"

*save "D:\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\MalesPop.dta",replace
save "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\MalesPop.dta", replace

* Total population (females)
clear
wbopendata, indicator(SP.POP.TOTL.FE.IN) long nometadata clear

drop if year<1970
drop if year>2016

rename countryname origin
drop countrycode region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
tostring year, replace
rename sp_pop_totl_fe_in PopulationFemales
label variable PopulationFemales "Females population, total SP.POP.TOTL.FE.IN"

*save "D:\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\FemalesPop.dta",replace
save "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\FemalesPop.dta", replace
*/

* GNI per capita, Atlas method (current US$)
clear
wbopendata, indicator(NY.GNP.PCAP.CD) long nometadata clear

drop if year<1974
drop if year>2016

rename countryname origin
drop countrycode region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
tostring year, replace
rename ny_gnp_pcap_cd GNIpc
label variable GNIpc "GNI per capita, Atlas method (current US$) NY.GNP.PCAP.CD"

*save "D:\Dropbox\PhD Killian\Paper I\Data\WDI\Clean\Dta\GNIpc.dta",replace
save "Data\WDI\Clean\Dta\GNIpc - JEBO revision.dta", replace

cls 
clear all 
set more off 
set scrollbufsize 500000 
set maxvar 10000
graph drop _all 
capture log close 

use "Data/WDI/Clean/Dta/TotalPop - JEBO revision.dta"

*merge 1:1 origin year using "Data/WDI/Clean/Dta/MalesPop.dta"
*drop _merge

*merge 1:1 origin year using "Data/WDI/Clean/Dta/FemalesPop.dta"
*drop _merge

merge 1:1 origin year using "Data/WDI/Clean/Dta/GNIpc - JEBO revision.dta"
drop _merge

*** Create index levels of development (source http://databank.worldbank.org/data/download/site-content/OGHIST.xls)
* NB: Each time it has to be inferior or equal to these limits

* Low income countries
gen LowIncome_zzzzz=480  if year=="1987"
replace LowIncome_zzzzz=545  if year=="1988"
replace LowIncome_zzzzz=580  if year=="1989"
replace LowIncome_zzzzz=610  if year=="1990"
replace LowIncome_zzzzz=635  if year=="1991"
replace LowIncome_zzzzz=675  if year=="1992"
replace LowIncome_zzzzz=695  if year=="1993"
replace LowIncome_zzzzz=725  if year=="1994"
replace LowIncome_zzzzz=765  if year=="1995"
replace LowIncome_zzzzz=785  if year=="1996"
replace LowIncome_zzzzz=785  if year=="1997"
replace LowIncome_zzzzz=760  if year=="1998"
replace LowIncome_zzzzz=755  if year=="1999"
replace LowIncome_zzzzz=755  if year=="2000"
replace LowIncome_zzzzz=745  if year=="2001"
replace LowIncome_zzzzz=735  if year=="2002"
replace LowIncome_zzzzz=765  if year=="2003"
replace LowIncome_zzzzz=825  if year=="2004"
replace LowIncome_zzzzz=875  if year=="2005"
replace LowIncome_zzzzz=905  if year=="2006"
replace LowIncome_zzzzz=935  if year=="2007"
replace LowIncome_zzzzz=975  if year=="2008"
replace LowIncome_zzzzz=995  if year=="2009"
replace LowIncome_zzzzz=1005  if year=="2010"
replace LowIncome_zzzzz=1025  if year=="2011"
replace LowIncome_zzzzz=1035  if year=="2012"
replace LowIncome_zzzzz=1045  if year=="2013"
replace LowIncome_zzzzz=1045  if year=="2014"
replace LowIncome_zzzzz=1025  if year=="2015"
replace LowIncome_zzzzz=1005  if year=="2016"

* Lower middle income countries
gen LowerMiddleIncome_zzzzz=1940  if year=="1987"
replace LowerMiddleIncome_zzzzz=2200  if year=="1988"
replace LowerMiddleIncome_zzzzz=2335  if year=="1989"
replace LowerMiddleIncome_zzzzz=2465  if year=="1990"
replace LowerMiddleIncome_zzzzz=2555  if year=="1991"
replace LowerMiddleIncome_zzzzz=2695  if year=="1992"
replace LowerMiddleIncome_zzzzz=2785  if year=="1993"
replace LowerMiddleIncome_zzzzz=2895  if year=="1994"
replace LowerMiddleIncome_zzzzz=3035  if year=="1995"
replace LowerMiddleIncome_zzzzz=3115  if year=="1996"
replace LowerMiddleIncome_zzzzz=3125  if year=="1997"
replace LowerMiddleIncome_zzzzz=3030  if year=="1998"
replace LowerMiddleIncome_zzzzz=2995  if year=="1999"
replace LowerMiddleIncome_zzzzz=2995  if year=="2000"
replace LowerMiddleIncome_zzzzz=2975  if year=="2001"
replace LowerMiddleIncome_zzzzz=2935  if year=="2002"
replace LowerMiddleIncome_zzzzz=3035  if year=="2003"
replace LowerMiddleIncome_zzzzz=3255  if year=="2004"
replace LowerMiddleIncome_zzzzz=3465  if year=="2005"
replace LowerMiddleIncome_zzzzz=3595  if year=="2006"
replace LowerMiddleIncome_zzzzz=3705  if year=="2007"
replace LowerMiddleIncome_zzzzz=3855  if year=="2008"
replace LowerMiddleIncome_zzzzz=3945  if year=="2009"
replace LowerMiddleIncome_zzzzz=3975  if year=="2010"
replace LowerMiddleIncome_zzzzz=4035  if year=="2011"
replace LowerMiddleIncome_zzzzz=4085  if year=="2012"
replace LowerMiddleIncome_zzzzz=4125  if year=="2013"
replace LowerMiddleIncome_zzzzz=4125  if year=="2014"
replace LowerMiddleIncome_zzzzz=4035  if year=="2015"
replace LowerMiddleIncome_zzzzz=3955  if year=="2016"

* Upper middle income countries
gen UpperMiddleIncome_zzzzz=6000  if year=="1987"
replace UpperMiddleIncome_zzzzz=6000  if year=="1988"
replace UpperMiddleIncome_zzzzz=6000  if year=="1989"
replace UpperMiddleIncome_zzzzz=7620  if year=="1990"
replace UpperMiddleIncome_zzzzz=7910  if year=="1991"
replace UpperMiddleIncome_zzzzz=8355  if year=="1992"
replace UpperMiddleIncome_zzzzz=8625  if year=="1993"
replace UpperMiddleIncome_zzzzz=8955  if year=="1994"
replace UpperMiddleIncome_zzzzz=9385  if year=="1995"
replace UpperMiddleIncome_zzzzz=9645  if year=="1996"
replace UpperMiddleIncome_zzzzz=9655  if year=="1997"
replace UpperMiddleIncome_zzzzz=9360  if year=="1998"
replace UpperMiddleIncome_zzzzz=9265  if year=="1999"
replace UpperMiddleIncome_zzzzz=9265  if year=="2000"
replace UpperMiddleIncome_zzzzz=9205  if year=="2001"
replace UpperMiddleIncome_zzzzz=9075  if year=="2002"
replace UpperMiddleIncome_zzzzz=9385  if year=="2003"
replace UpperMiddleIncome_zzzzz=10065  if year=="2004"
replace UpperMiddleIncome_zzzzz=10725  if year=="2005"
replace UpperMiddleIncome_zzzzz=11115  if year=="2006"
replace UpperMiddleIncome_zzzzz=11455  if year=="2007"
replace UpperMiddleIncome_zzzzz=11905  if year=="2008"
replace UpperMiddleIncome_zzzzz=12195  if year=="2009"
replace UpperMiddleIncome_zzzzz=12275  if year=="2010"
replace UpperMiddleIncome_zzzzz=12475  if year=="2011"
replace UpperMiddleIncome_zzzzz=12615  if year=="2012"
replace UpperMiddleIncome_zzzzz=12745  if year=="2013"
replace UpperMiddleIncome_zzzzz=12735  if year=="2014"
replace UpperMiddleIncome_zzzzz=12475  if year=="2015"
replace UpperMiddleIncome_zzzzz=12235  if year=="2016"

* For high income it has to be strictly superior to the previous limit
gen HighIncome_zzzzz=6000  if year=="1987"
replace HighIncome_zzzzz=6000  if year=="1988"
replace HighIncome_zzzzz=6000  if year=="1989"
replace HighIncome_zzzzz=7620  if year=="1990"
replace HighIncome_zzzzz=7910  if year=="1991"
replace HighIncome_zzzzz=8355  if year=="1992"
replace HighIncome_zzzzz=8625  if year=="1993"
replace HighIncome_zzzzz=8955  if year=="1994"
replace HighIncome_zzzzz=9385  if year=="1995"
replace HighIncome_zzzzz=9645  if year=="1996"
replace HighIncome_zzzzz=9655  if year=="1997"
replace HighIncome_zzzzz=9360  if year=="1998"
replace HighIncome_zzzzz=9265  if year=="1999"
replace HighIncome_zzzzz=9265  if year=="2000"
replace HighIncome_zzzzz=9205  if year=="2001"
replace HighIncome_zzzzz=9075  if year=="2002"
replace HighIncome_zzzzz=9385  if year=="2003"
replace HighIncome_zzzzz=10065  if year=="2004"
replace HighIncome_zzzzz=10725  if year=="2005"
replace HighIncome_zzzzz=11115  if year=="2006"
replace HighIncome_zzzzz=11455  if year=="2007"
replace HighIncome_zzzzz=11905  if year=="2008"
replace HighIncome_zzzzz=12195  if year=="2009"
replace HighIncome_zzzzz=12275  if year=="2010"
replace HighIncome_zzzzz=12475  if year=="2011"
replace HighIncome_zzzzz=12615  if year=="2012"
replace HighIncome_zzzzz=12745  if year=="2013"
replace HighIncome_zzzzz=12735  if year=="2014"
replace HighIncome_zzzzz=12475  if year=="2015"
replace HighIncome_zzzzz=12235  if year=="2016"

destring year, replace

*rename GDPpercapitaPPPconstant GDPpc_zzzzz
rename PopulationTotal PopTotal_zzzzz
*rename PopulationMales PopMales_zzzzz
*rename PopulationFemales PopFemales_zzzzz
rename GNIpc GNIpc_zzzzz

replace origin="Bahamas" if origin=="Bahamas, The"
replace origin="Brunei" if origin=="Brunei Darussalam"
replace origin="Cape Verde" if origin=="Cabo Verde"
replace origin="Democratic Republic of the Congo" if origin=="Congo, Dem Rep"
replace origin="Republic of Congo" if origin=="Congo, Rep"
replace origin="Côte d'Ivoire" if origin=="Cote d'Ivoire"
replace origin="Curaçao" if origin=="Curacao"
replace origin="Egypt" if origin=="Egypt, Arab Rep"
replace origin="Gambia" if origin=="Gambia, The"
replace origin="Hong Kong" if origin=="Hong Kong SAR, China"
replace origin="Iran" if origin=="Iran, Islamic Rep"
replace origin="North Korea" if origin=="Korea, Dem People’s Rep"
replace origin="South Korea" if origin=="Korea, Rep"
replace origin="Kyrgyzstan" if origin=="Kyrgyz Republic"
replace origin="Laos" if origin=="Lao PDR"
replace origin="Macao" if origin=="Macao SAR, China"
replace origin="Micronesia" if origin=="Micronesia, Fed Sts"
replace origin="Macedonia" if origin=="North Macedonia"
replace origin="Russia" if origin=="Russian Federation"
replace origin="São Tomé and Príncipe" if origin=="Sao Tome and Principe"
replace origin="Sint Maarten" if origin=="Sint Maarten (Dutch part)"
replace origin="Slovakia" if origin=="Slovak Republic"
replace origin="Saint Kitts and Nevis" if origin=="St Kitts and Nevis"
replace origin="Saint Lucia" if origin=="St Lucia"
replace origin="Saint-Martin" if origin=="St Martin (French part)"
replace origin="Saint Vincent and the Grenadines" if origin=="St Vincent and the Grenadines"
replace origin="Syria" if origin=="Syrian Arab Republic"
replace origin="Venezuela" if origin=="Venezuela, RB"
replace origin="Virgin Islands, U.S." if origin=="Virgin Islands (US)"
replace origin="Palestina" if origin=="West Bank and Gaza"
replace origin="Yemen" if origin=="Yemen, Rep"

merge m:1 origin using "Data/iso3/Clean/Dta/iso3clean origin.dta"
drop if _merge==1 // Mostly groups of countries or regions rather than countries per se
drop if _merge==2
drop _merge

rename *_zzzzz *_or
drop origin
order iso3o year
sort iso3o year

replace year=year+1

save "Data/WDI/Clean/Dta/WDI origin - JEBO revision.dta", replace

rename *_or *_dest
rename iso3o iso3d

save "Data/WDI/Clean/Dta/WDI dest - JEBO revision.dta", replace

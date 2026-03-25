********************************************************************************
* 12 - Refugee Flows (WDI)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans refugee stock data from the World Bank and computes refugee flows as first differences. Constructs percentile-based dummies used in IV robustness checks (Table B.7).
*
* Input:   API_SM.POP.REFG (World Bank WDI)
*
* Output:  RefugeesCleaned origin.dta, RefugeesCleaned dest.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

clear all
import delimited "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Refugees\API_SM.POP.REFG_DS2_en_csv_v2_3161438.csv"
drop if v2=="World Development Indicators"
drop if v2=="2021-10-28"
drop v3 v4 v66
rename v1 origin
rename v2 iso3o
rename v5 y1960
rename v6 y1961
rename v7 y1962
rename v8 y1963
rename v9 y1964
rename v10 y1965
rename v11 y1966
rename v12 y1967
rename v13 y1968
rename v14 y1969
rename v15 y1970
rename v16 y1971
rename v17 y1972
rename v18 y1973
rename v19 y1974
rename v20 y1975
rename v21 y1976
rename v22 y1977
rename v23 y1978
rename v24 y1979
rename v25 y1980
rename v26 y1981
rename v27 y1982
rename v28 y1983
rename v29 y1984
rename v30 y1985
rename v31 y1986
rename v32 y1987
rename v33 y1988
rename v34 y1989
rename v35 y1990
rename v36 y1991
rename v37 y1992
rename v38 y1993
rename v39 y1994
rename v40 y1995
rename v41 y1996
rename v42 y1997
rename v43 y1998
rename v44 y1999
rename v45 y2000
rename v46 y2001
rename v47 y2002
rename v48 y2003
rename v49 y2004
rename v50 y2005
rename v51 y2006
rename v52 y2007
rename v53 y2008
rename v54 y2009
rename v55 y2010
rename v56 y2011
rename v57 y2012
rename v58 y2013
rename v59 y2014
rename v60 y2015
rename v61 y2016
rename v62 y2017
rename v63 y2018
rename v64 y2019
rename v65 y2020
drop if iso3o=="Country Code"

reshape long y, i(origin) j(year)
rename y refugeestocks
merge m:1 iso3o using "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\iso3\Clean\Dta\iso3clean origin.dta"
drop if _merge!=3
drop _merge
sort origin year
egen o = group(origin)
egen y = group(year)
tsset o y
gen refugeestocksL1=L1.refugeestocks
gen refugeesflows=refugeestocks - refugeestocksL1
replace refugeesflows=. if refugeesflows<0
drop refugeestocks refugeestocksL1
summarize refugeesflows, detail

/*
                        refugeesflows
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs               3,846
25%           30              0       Sum of Wgt.       3,846

50%          500                      Mean           15937.18
                        Largest       Std. Dev.      72105.22
75%         5748        1028230
90%        27298        1152295       Variance       5.20e+09
95%        58659        1235000       Skewness       10.26948
99%       282031        1324401       Kurtosis       134.7679
*/

gen dummy75_o=1 if refugeesflows>5748
replace dummy75_o=0 if refugeesflows<=5748
replace dummy75_o=. if refugeesflows==.

gen dummy90_o=1 if refugeesflows>27298
replace dummy90_o=0 if refugeesflows<=27298
replace dummy90_o=. if refugeesflows==.

gen dummy99_o=1 if refugeesflows>282031
replace dummy99_o=0 if refugeesflows<=282031
replace dummy99_o=. if refugeesflows==.

drop o y origin
rename refugeesflows refugeesflows_o

save "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Refugees\RefugeesCleaned origin.dta", replace


////////////////////////////////////////////////////////////////////////////////


rename iso3o iso3d
rename *_o *_d

save "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\Data\Refugees\RefugeesCleaned dest.dta", replace

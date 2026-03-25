********************************************************************************
* 06 - Political Instability (Polity IV)
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Cleans the Polity IV dataset and constructs a political instability dummy defined as a 3+ point change in the Polity2 score over the preceding 3 years.
*
* Input:   p4v2017.xls (Polity IV Project)
*
* Output:  Polity 4 origin.dta, Polity 4 dest.dta
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

/* 
* Fragment: operational existence of a separate polity, or polities, comprising substantial territory and population within the recognized borders of the state and over
which the coded polity exercises no effective authority (effective authority may be participatory or coercive). Local autonomy arrangements voluntarily established and accepted by both
central and local authorities are not considered fragmentation. A polity that can not exercise relatively effective authority over at least 50 percent of its established territory is necessarily
considered to be in a condition of “state failure”
(0) No overt fragmentation
(1) Slight fragmentation
(2) Moderate fragmentation
(3) Serious fragmentation

* DEMOC: Democracy is conceived as three essential, interdependent elements.
One is the presence of institutions and procedures through which citizens can express effective preferences about alternative policies and leaders. 
Second is the existence of institutionalized constraints on the exercise of power by the executive. 
Third is the guarantee of civil liberties to all citizens in their daily lives and in acts of political participation.

* AUTOC: Autocracies sharply restrict or suppress competitive political participation. Their
chief executives are chosen in a regularized process of selection within the political elite, and once
in office they exercise power with few institutional constraints.

Note that the two scales do not share any categories in common. Nonetheless many polities have mixed authority traits, and thus can have middling scores on both
Autocracy and Democracy scales. These are the kinds of polities which were characterized as "anocratic" and "incoherent" in the Polity I studies. As a group they proved to less durable than coherent democracies and autocracies

* POLITY: The POLITY score is computed by subtracting the AUTOC score from the DEMOC score; the resulting unified polity scale ranges from +10 (strongly democratic) to !10 (strongly autocratic).

*  POLITY2: This variable is a modified version of the POLITY variable added in order to facilitate the use of the POLITY regime measure in time-series analyses. It modifies the
combined annual POLITY score by applying a simple treatment, or ““fix,” to convert instances of “standardized authority scores” (i.e., -66, -77, and -88) to conventional polity scores (i.e., within the range, -10 to +10)

Political instability: in polity, when take the value !66, !77, !88 

*/ 

cls 
clear all 
set more off 
set scrollbufsize 500000 
set maxvar 10000
graph drop _all 
capture log close 

cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I\"
*cd "D:\Dropbox\PhD Killian\Paper I\"

*cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

import excel "Data\Polity 4\Clean\Dta\p4v2017.xls", sheet("p4v2017") firstrow

keep country year polity polity2
sort year country

destring year, replace
sort country year
rename country origin
order year origin polity2 polity

br if origin =="Sudan-North"

replace origin="Republic of Congo" if origin=="Congo Brazzaville"
replace origin="Democratic Republic of the Congo" if origin=="Congo Kinshasa"
replace origin="Côte d'Ivoire" if origin=="Ivory Coast"
replace origin="North Korea" if origin=="Korea North"
replace origin="South Korea" if origin=="Korea South"
replace origin="Myanmar" if origin=="Myanmar (Burma)"
replace origin="Vietnam" if origin=="Vietnam"
replace origin="United Arab Emirates" if origin=="UAE"
replace origin="Bosnia and Herzegovina" if origin=="Bosnia"
replace origin="Timor-Leste" if origin=="East Timor"
replace origin="Sudan" if origin=="Sudan-North" // This creates a duplicate value for Sudan in the year 2011
replace origin="Slovakia" if origin=="Slovak Republic"
replace origin="Côte d'Ivoire" if origin=="Cote D'Ivoire"
replace origin="Timor-Leste" if origin=="Timor Leste"

duplicates list origin year
/*
Duplicates in terms of origin year
  +------------------------------------+
  | group:    obs:       origin   year |
  |------------------------------------|
  |      1    5175     Ethiopia   1993 |
  |      1    5176     Ethiopia   1993 |
  |      2   14429        Sudan   2011 |
  |      2   14430        Sudan   2011 |
  |      3   17281   Yugoslavia   1991 |
  |      3   17282   Yugoslavia   1991 |
  +------------------------------------+
*/
drop in 17281
drop in 14429
drop in 5176

gen PolInstability=0
replace PolInstability=1 if polity==-66
gen polity2_sq = polity2^2

egen o = group(origin)
xtset o year
gen polityL1 = L1.polity2
gen polityL2 = L2.polity2
gen polityL3 = L3.polity2
gen politybisL1 = L1.polity
gen politybisL2 = L2.polity
gen politybisL3 = L3.polity
gen polity_sqL1 = L1.polity2_sq
*
gen PolInstab3y = 0
*** Set Polinstab to 1 if in the past 3 years there was a change of at least 3 values in the polity2
bysort o year: replace PolInstab3y = 1 if  abs(polityL3 - polityL1) > 2 | abs(polityL2 - polityL1) > 2 | abs(polityL3 - polityL2) > 2 // Coded as a 3 or greater change in the polity2 score in the previous 3 years before the year of the interview OR if case of foreign “interruption” in the last 3y before the survey (ie replace if =-66)
replace PolInstab3y = . if polityL1==. | polityL2==. | polityL3==. // This is ok as the timeseries goes back far enough in time (we don't lose observations)

drop if year<1974

*** THere were missing values in 3 countries (which would reduce the sample size in the estimations
tab origin  year if PolInstab3y==. // The table below is actually made on the basis of the estimation sample while in the sample here we still keep more values

/*
                       |                                                                      year
              country |      1974       1975       1976       1977       1978       1979       1980       1981       1982       1983       1984       1985       1986 |     Total
----------------------+-----------------------------------------------------------------------------------------------------------------------------------------------+----------
          Afghanistan |         0          0          0          0          0          0          1          1          1          1          1          1          1 |        27 
               Angola |         0          1          1          1          0          0          0          0          0          0          0          0          0 |         3 
              Armenia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Azerbaijan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Bangladesh |         1          0          0          0          0          0          0          0          0          0          0          0          0 |         1 
              Belarus |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
Bosnia and Herzegov.. |         0          0          0          0          0          0          0          0          0          0          0          0          0 |        25 
             Cambodia |         0          0          0          0          0          0          1          1          1          1          1          1          1 |        11 
           Cape Verde |         0          1          1          1          0          0          0          0          0          0          0          0          0 |         3 
              Comoros |         0          1          1          1          0          0          0          0          0          0          0          0          0 |         3 
              Croatia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
       Czech Republic |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Djibouti |         0          0          0          1          1          1          0          0          0          0          0          0          0 |         3 
              Eritrea |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Estonia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Georgia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Germany |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
         Germany East |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         1 
        Guinea-Bissau |         1          1          1          0          0          0          0          0          0          0          0          0          0 |         3 
                 Iraq |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         9 
           Kazakhstan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Kosovo |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Kuwait |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Kyrgyzstan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Latvia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Lebanon |         0          0          0          0          0          0          0          0          0          0          0          0          0 |        17 
            Lithuania |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
            Macedonia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Moldova |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Montenegro |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Mozambique |         0          1          1          1          0          0          0          0          0          0          0          0          0 |         3 
              Namibia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
     Papua New Guinea |         0          1          1          1          0          0          0          0          0          0          0          0          0 |         3 
               Russia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Serbia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
Serbia and Montenegro |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Slovakia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Slovenia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
      Solomon Islands |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         6 
              Somalia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
          South Sudan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Suriname |         0          1          1          1          0          0          0          0          0          0          0          0          0 |         3 
           Tajikistan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
          Timor-Leste |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
         Turkmenistan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Uganda |         0          0          0          0          0          0          1          1          1          0          0          0          0 |         3 
              Ukraine |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Uzbekistan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Vietnam |         0          0          1          1          1          0          0          0          0          0          0          0          0 |         3 
        Vietnam South |         1          1          0          0          0          0          0          0          0          0          0          0          0 |         2 
                Yemen |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
----------------------+-----------------------------------------------------------------------------------------------------------------------------------------------+----------
                Total |         3          8          8          8          3          2          4          3          3          2          2          2          2 |       225 

                      |                                                                      year
              country |      1987       1988       1989       1990       1991       1992       1993       1994       1995       1996       1997       1998       1999 |     Total
----------------------+-----------------------------------------------------------------------------------------------------------------------------------------------+----------
          Afghanistan |         1          1          1          1          1          0          0          0          0          0          0          0          0 |        27 
               Angola |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Armenia |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
           Azerbaijan |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
           Bangladesh |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         1 
              Belarus |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
Bosnia and Herzegov.. |         0          0          0          0          0          1          1          1          0          1          1          1          1 |        25 
             Cambodia |         1          1          1          1          0          0          0          0          0          0          0          0          0 |        11 
           Cape Verde |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Comoros |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Croatia |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
       Czech Republic |         0          0          0          0          0          0          1          1          1          0          0          0          0 |         3 
             Djibouti |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Eritrea |         0          0          0          0          0          0          1          1          1          0          0          0          0 |         3 
              Estonia |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
              Georgia |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
              Germany |         0          0          0          1          1          1          0          0          0          0          0          0          0 |         3 
         Germany East |         0          0          0          1          0          0          0          0          0          0          0          0          0 |         1 
        Guinea-Bissau |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
                 Iraq |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         9 
           Kazakhstan |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
               Kosovo |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Kuwait |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
           Kyrgyzstan |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
               Latvia |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
              Lebanon |         0          0          0          0          1          1          1          1          1          1          1          1          1 |        17 
            Lithuania |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
            Macedonia |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
              Moldova |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
           Montenegro |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Mozambique |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Namibia |         0          0          0          1          1          1          0          0          0          0          0          0          0 |         3 
     Papua New Guinea |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Russia |         0          0          0          0          0          1          1          1          0          0          0          0          0 |         3 
               Serbia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
Serbia and Montenegro |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Slovakia |         0          0          0          0          0          0          1          1          1          0          0          0          0 |         3 
             Slovenia |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
      Solomon Islands |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         6 
              Somalia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
          South Sudan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Suriname |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Tajikistan |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
          Timor-Leste |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
         Turkmenistan |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
               Uganda |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Ukraine |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
           Uzbekistan |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         3 
              Vietnam |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
        Vietnam South |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         2 
                Yemen |         0          0          0          1          1          1          0          0          0          0          0          0          0 |         3 
----------------------+-----------------------------------------------------------------------------------------------------------------------------------------------+----------
                Total |         2          2          2          6         23         24         24          6          4          2          2          2          2 |       225 

                      |                                                                      year
              country |      2000       2001       2002       2003       2004       2005       2006       2007       2008       2009       2010       2011       2012 |     Total
----------------------+-----------------------------------------------------------------------------------------------------------------------------------------------+----------
          Afghanistan |         0          0          1          1          1          1          1          1          1          1          1          1          1 |        27 
               Angola |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Armenia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Azerbaijan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Bangladesh |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         1 
              Belarus |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
Bosnia and Herzegov.. |         1          1          1          1          1          1          1          1          1          1          1          1          1 |        25 
             Cambodia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |        11 
           Cape Verde |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Comoros |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Croatia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
       Czech Republic |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Djibouti |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Eritrea |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Estonia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Georgia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Germany |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
         Germany East |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         1 
        Guinea-Bissau |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
                 Iraq |         0          0          0          0          1          1          1          1          1          1          1          1          1 |         9 
           Kazakhstan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Kosovo |         0          0          0          0          0          0          0          0          1          1          1          0          0 |         3 
               Kuwait |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Kyrgyzstan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Latvia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Lebanon |         1          1          1          1          1          1          1          1          0          0          0          0          0 |        17 
            Lithuania |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
            Macedonia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Moldova |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Montenegro |         0          0          0          0          0          0          1          1          1          0          0          0          0 |         3 
           Mozambique |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Namibia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
     Papua New Guinea |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Russia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Serbia |         0          0          0          0          0          0          1          1          1          0          0          0          0 |         3 
Serbia and Montenegro |         0          0          0          1          1          1          0          0          0          0          0          0          0 |         3 
             Slovakia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
             Slovenia |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
      Solomon Islands |         0          0          0          0          1          1          1          0          0          0          0          0          0 |         6 
              Somalia |         0          0          0          0          0          0          0          0          0          0          0          0          1 |         3 
          South Sudan |         0          0          0          0          0          0          0          0          0          0          0          1          1 |         3 
             Suriname |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Tajikistan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
          Timor-Leste |         0          0          1          1          1          0          0          0          0          0          0          0          0 |         3 
         Turkmenistan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
               Uganda |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Ukraine |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
           Uzbekistan |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
              Vietnam |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
        Vietnam South |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         2 
                Yemen |         0          0          0          0          0          0          0          0          0          0          0          0          0 |         3 
----------------------+-----------------------------------------------------------------------------------------------------------------------------------------------+----------
                Total |         2          2          4          5          7          6          7          6          6          4          4          4          5 |       225 

                      |                          year
              country |      2013       2014       2015       2016       2017 |     Total
----------------------+-------------------------------------------------------+----------
          Afghanistan |         1          1          1          1          0 |        27 
               Angola |         0          0          0          0          0 |         3 
              Armenia |         0          0          0          0          0 |         3 
           Azerbaijan |         0          0          0          0          0 |         3 
           Bangladesh |         0          0          0          0          0 |         1 
              Belarus |         0          0          0          0          0 |         3 
Bosnia and Herzegov.. |         1          1          1          1          1 |        25 
             Cambodia |         0          0          0          0          0 |        11 
           Cape Verde |         0          0          0          0          0 |         3 
              Comoros |         0          0          0          0          0 |         3 
              Croatia |         0          0          0          0          0 |         3 
       Czech Republic |         0          0          0          0          0 |         3 
             Djibouti |         0          0          0          0          0 |         3 
              Eritrea |         0          0          0          0          0 |         3 
              Estonia |         0          0          0          0          0 |         3 
              Georgia |         0          0          0          0          0 |         3 
              Germany |         0          0          0          0          0 |         3 
         Germany East |         0          0          0          0          0 |         1 
        Guinea-Bissau |         0          0          0          0          0 |         3 
                 Iraq |         0          0          0          0          0 |         9 
           Kazakhstan |         0          0          0          0          0 |         3 
               Kosovo |         0          0          0          0          0 |         3 
               Kuwait |         0          0          0          0          0 |         3 
           Kyrgyzstan |         0          0          0          0          0 |         3 
               Latvia |         0          0          0          0          0 |         3 
              Lebanon |         0          0          0          0          0 |        17 
            Lithuania |         0          0          0          0          0 |         3 
            Macedonia |         0          0          0          0          0 |         3 
              Moldova |         0          0          0          0          0 |         3 
           Montenegro |         0          0          0          0          0 |         3 
           Mozambique |         0          0          0          0          0 |         3 
              Namibia |         0          0          0          0          0 |         3 
     Papua New Guinea |         0          0          0          0          0 |         3 
               Russia |         0          0          0          0          0 |         3 
               Serbia |         0          0          0          0          0 |         3 
Serbia and Montenegro |         0          0          0          0          0 |         3 
             Slovakia |         0          0          0          0          0 |         3 
             Slovenia |         0          0          0          0          0 |         3 
      Solomon Islands |         0          0          0          0          0 |         6 
              Somalia |         1          1          0          0          0 |         3 
          South Sudan |         1          0          0          0          0 |         3 
             Suriname |         0          0          0          0          0 |         3 
           Tajikistan |         0          0          0          0          0 |         3 
          Timor-Leste |         0          0          0          0          0 |         3 
         Turkmenistan |         0          0          0          0          0 |         3 
               Uganda |         0          0          0          0          0 |         3 
              Ukraine |         0          0          0          0          0 |         3 
           Uzbekistan |         0          0          0          0          0 |         3 
              Vietnam |         0          0          0          0          0 |         3 
        Vietnam South |         0          0          0          0          0 |         2 
                Yemen |         0          0          0          0          0 |         3 
----------------------+-------------------------------------------------------+----------
                Total |         4          3          2          2          1 |       225 
*/

br if origin=="Afghanistan"
replace PolInstab3y = 1 if origin =="Afghanistan" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66)
br if origin=="Angola"
* No changes because no information before 1975
br if origin=="Armenia"
* No changes because no information before 1992
br if origin=="Azerbaijan"
* No changes because no information before 1991
br if origin=="Bangladesh"
* No changes because no information before 1971
br if origin=="Belarus"
* No changes because no information before 1992
br if origin=="Bosnia and Herzegovina"
replace PolInstab3y = 1 if origin =="Bosnia and Herzegovina" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66) // To overcome some missings for Bosnia and Herzegovina, set this variable also to 1 if there was the code -66 (as we did originally)
br if origin=="Cambodia"
replace PolInstab3y = 1 if origin =="Cambodia" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66) // To overcome some missings for Cambodia, set this variable also to 1 if there was the code -66 (as we did originally)
br if origin=="Cape Verde"
* No changes because no information before 1975
br if origin=="Comoros"
* No changes because no information before 1975
br if origin=="Croatia"
* No changes because no information before 1991
br if origin=="Czech Republic"
* No changes because no information before 1993
br if origin=="Djibouti"
* No changes because no information before 1978
br if origin=="Eritrea"
* No changes because no information before 1993
br if origin=="Estonia"
* No changes because no information before 1991
br if origin=="Georgia"
* No changes because no information before 1991
br if origin=="Germany"
* No changes because no information before 1990
br if origin=="Germany East"
* No changes because no information after 1989
br if origin=="Guinea-Bissau"
* No changes because no information after 1975
br if origin=="Iraq"
replace PolInstab3y = 1 if origin =="Iraq" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66) // To overcome some missings for Iraq, set this variable also to 1 if there was the code -66 (as we did originally)
br if origin=="Kazakhstan"
* No changes because no information after 1991
br if origin=="Kosovo"
* No changes because no information before 2008
br if origin=="Kuwait"
replace PolInstab3y = 1 if origin =="Kuwait" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66) // To overcome missing in 1990
br if origin=="Kyrgyzstan"
* No changes because no information before 1991
br if origin=="Latvia"
* No changes because no information before 1991
br if origin=="Lebanon"
replace PolInstab3y = 1 if origin =="Lebanon" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66)
br if origin=="Lithuania"
* No changes because no information before 1991
br if origin=="Macedonia"
* No changes because no information before 1991
br if origin=="Moldova"
* No changes because no information before 1991
br if origin=="Montenegro"
* No changes because no information before 2006
br if origin=="Mozambique"
* No changes because no information before 1975
br if origin=="Namibia"
* No changes because no information before 1990
br if origin=="Papua New Guinea"
* No changes because no information before 1975
br if origin=="Russia"
* No changes because no information before 1992
br if origin=="Serbia"
* No changes because no information before 2006
br if origin=="Serbia and Montenegro"
* No changes because no information before 2003
br if origin=="Slovakia"
* No changes because no information before 1993
br if origin=="Slovenia"
* No changes because no information before 1991
br if origin=="Solomon Islands"
replace PolInstab3y = 1 if origin =="Solomon Islands" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66)
br if origin=="Suriname"
* No changes because no information before 1975
br if origin=="Tajikistan"
* No changes because no information before 1991
br if origin=="Timor-Leste"
* No changes because no information before 2002
br if origin=="Turkmenistan"
* No changes because no information before 1991
br if origin=="Uganda"
replace PolInstab3y = 1 if origin =="Uganda" & (politybisL1==-66 | politybisL2==-66 | politybisL3==-66)
br if origin=="Ukraine"
* No changes because no information before 1991
br if origin=="Uzbekistan"
* No changes because no information before 1991
br if origin=="Vietnam"
* No changes because no information before 1976
br if origin=="Vietnam South"
* No changes because no information before 1975 and after 1977
br if origin=="Yemen"
* No changes because no information before 1990
drop o

***************************************
*** Merging with iso3o & last cleaning
***************************************

merge m:1 origin using "Data\iso3\Clean\Dta\iso3clean origin.dta"

/*
   Result                           # of obs.
    -----------------------------------------
    not matched                           232
        from master                       143  (_merge==1)
        from using                         89  (_merge==2)

    matched                             6,740  (_merge==3)
    -----------------------------------------
*/

replace iso3="SCG" if origin=="Serbia and Montenegro"
replace iso3="USR" if origin=="USSR"
replace iso3="NYE" if origin=="Yemen North"
replace iso3="SYE" if origin=="Yemen South"

drop if _merge==2
drop if _merge!=3 & iso3o==""
drop _merge

drop origin o polity polity2 polity2_sq polityL2 polityL3 politybisL2 politybisL3 PolInstability
rename polityL1 polity2
rename politybisL1 polity
rename polity_sqL1 polity2_sq

rename * *_or
rename year_or year
rename iso3o_or iso3o

duplicates drop

save "Data/Polity 4/Clean/Dta/Polity 4 origin.dta", replace

rename iso3o iso3d 
rename *_or *_dest

save "Data/Polity 4/Clean/Dta/Polity 4 dest.dta", replace

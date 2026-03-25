********************************************************************************
* 14 - Estimations
* Foubert, K. & Ruyssen, I. (2024) - JEBO
********************************************************************************
*
* Purpose: Runs all PPML and IV (2SLS) estimations reported in the paper: benchmark (Table 1), robustness checks (Tables 2-3), IV regressions and first-stage results (Table 4), placebo tests (Table B.6), and geographical heterogeneity by migration corridor (Table 5).
*
* Input:   Final Bilateral Database - JEBO revision.dta, frac_o2020.dta, frac_d2020.dta
*
* Output:  LaTeX tables (Tables 1-5, appendix tables B.3-B.10)
*
* Note: These scripts were developed as part of a collaborative research workflow
* between two co-authors over several years. Internal annotations, commented-out
* file paths, and exploratory code blocks reflect this iterative process and have
* been preserved for transparency and reproducibility.
********************************************************************************

/*
Notes:
This file provides an exploration of the model

1/ CLUSTERING SE's (Glenn): Clustering of the standard errors is not always innocent and there is more discussion 
about how and when to cluster than you perhaps expect.  In any case, it should be judicously 
considered and the choice for mere standard errors can be the right one (see e.g. 
https://blogs.worldbank.org/impactevaluations/when-should-you-cluster-standard-errors-new-wisdom-econometrics-oracle ).

Underidentification test: 
_________________________
The underidentification test is an LM test of whether the equation is identified, i.e., that the
excluded instruments are "relevant", meaning correlated with the endogenous regressors.  The
test is essentially the test of the rank of a matrix:  under the null hypothesis that the
equation is underidentified, the matrix of reduced form coefficients on the L1 excluded
instruments has rank=K1-1 where K1=number of endogenous regressors.  Under the null, the
statistic is distributed as chi-squared with degrees of freedom=(L1-K1+1).  A rejection of the
null indicates that the matrix is full column rank, i.e., the model is identified.

--> so we want to reject the null hence need p<0.05


Weak identification test:
-________________________
"Weak identification" arises when the excluded instruments are correlated with the endogenous
regressors, but only weakly.  Estimators can perform poorly when instruments are weak

The second test proposed by Stock and Yogo is based on the performance of the Wald test statistic 
for the endogenous regressors. Under weak identification, the test rejects too often. The test 
statistic is based on the rejection rate r tolerable to the researcher if the true rejection rate 
is 5%. Their tabulated values consider various values for r. To be able to reject the null that 
the size of the test is unacceptably large (versus 5%), the Cragg–Donald F statistic must exceed 
the tabulated critical value.

--> so the F-stat reported first should exceed the critical values

Overidentification test:
________________________
These are tests of the joint null hypothesis that the excluded instruments are valid instruments, i.e.,
uncorrelated with the error term and correctly excluded from the estimated
equation.  A rejection casts doubt on the validity of the instruments.

we would reject the null hypothesis that all overidentifying restrictions are jointly 
valid if the p-value is smaller than the significance level

--> so we do not want to reject the null hence need p>0.05




2/ Updates by Ilse July 2022:
- Put back the US in the corridor splits for Global North

- Notice how sample is smaller than with o and d FE separately!
(dropped 188587 observations that are either singletons or separated by a fixed effect)

- Say in appendix that linear models gives similar results, and then in instrumenting strat using ivreg

- NEW: replace MigrationRateWithoutNeg=MigrationRateWithoutNeg*1000
- update gov fractionalisation to 2020 data(was now running only til 2012) 

*/

********************************************************************************
*********************** BENCHMARK DATABASE & MODELS ****************************
********************************************************************************

cls 
clear all 
set more off 
set scrollbufsize 500000 
set maxvar 120000
graph drop _all 
capture log close 
set matsize 11000

*cd "D:\Dropbox\PhD Killian\Paper I"
*cd "C:\Users\kifouber\Dropbox\PhD Killian\Paper I"
cd "/Users/ilseruyssen/Dropbox/PhD Killian/Paper I/"

/*** Glenn & Samuel 
- Flow data interpolated from the World Bank, UN and OECD stock data, and allowing for demographic dynamics. Use more data than Abel (3 sources) 
- Yearly periods 
- 1932-2018, 242 origin 240 dest 
- Final database: 1975-2017, 1y interval, 239 origin 237 dest, but only 154 and 153 countries of o and d
- Share zeroes MigrationRateWithoutNeg: 66.07% MigrationRateWithNeg: 61.39% --> though former becomes 45,26% as of April 2023

Two versions for the dependent variable:
________________________________________
The migration rate in this database contains negative flows. 
Two alternative dependents were constructed either (i) setting these negative values to zero 
in "MigrationRateWithoutNeg":

gen FlowWithoutNeg=Flow
gen DummyNegFlow=0
replace DummyNegFlow=1 if FlowWithoutNeg<0
replace FlowWithoutNeg=0 if FlowWithoutNeg<0

gen MigrationRateWithoutNeg=FlowWithoutNeg/Natives_o
gen MigrationRateWithoutNeg_ln=ln(0.000001+MigrationRateWithoutNeg)

or (ii) adding the negative flows to the reverse corridor in "MigrationRateWithNeg":

gen FlowWithNeg=FlowWithoutNeg+NegFlow (after merging again)

gen MigrationRateWithNeg=FlowWithNeg/Natives_o
gen MigrationRateWithNeg_ln=ln(0.000001+MigrationRateWithNeg)

_________________________________________
Baseline results:
-	Dependent variable “MigrationRateWithoutNeg” (which sets negative values to zero rather than adding them to the reverse corridor)
-	PPML
-	FE structure: od y 
-	Considering both GTI_o and GTI_d as well as other relevant destination characteristics 
- 	Update government fractionalisation to 2020 dataset
*/
 
use "Data/Merge/Dta/Clean/Final Bilateral Database - JEBO revision", clear


merge m:1 iso3o year using "Data/Government fractionalization/frac_o2020.dta"
drop if _merge==2
drop _merge
merge m:1 iso3d year using "Data/Government fractionalization/frac_d2020.dta"
drop if _merge==2
drop _merge

gen PopTotal_o_ln = ln(PopTotal_o) // Added by Ilse 29 Okt 2023
gen PopTotal_d_ln = ln(PopTotal_d) // Added by Ilse 29 Okt 2023

rename WarOccurrence_high1_or WarOccurrence_o
rename WarOccurrence_high1_dest WarOccurrence_d

replace MigrationRateWithoutNeg=MigrationRateWithoutNeg*1000

* NOTE ILSE: KEEP ORIGINAL CONTROLS SET AND ADD POPULATION AS ROBUSTNESS
global controlsppml "GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d WarOccurrence_o WarOccurrence_d Network_ln dist_ln contig comlang_ethno"
global controlsOD "GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d WarOccurrence_o WarOccurrence_d Network_ln"

label var GTI_o "GTI o"
label var GTI_d "GTI d"
label var GTI_score_lag1_o "GTI o L1"
label var GTI_score_lag2_o "GTI o L2"
label var GTI_score_lag3_o "GTI o L3"
label var GTI_score_lag4_o "GTI o L4"
label var GTI_score_lag5_o "GTI o L5"
label var GTI_score_lag1_d "GTI d L1"
label var GTI_score_lag2_d "GTI d L2"
label var GTI_score_lag3_d "GTI d L3"
label var GTI_score_lag4_d "GTI d L4"
label var GTI_score_lag5_d "GTI d L5"
label var GTIPCPYL1_o "GTI o raw L1"
label var GTIPCPYL2_o "GTI o raw L2"
label var GTIPCPYL3_o "GTI o raw L3"
label var GTIPCPYL4_o "GTI o raw L4"
label var GTIPCPYL5_o "GTI o raw L5"
label var GTIPCPYL1_d "GTI d raw L1"
label var GTIPCPYL2_d "GTI d raw L2"
label var GTIPCPYL3_d "GTI d raw L3"
label var GTIPCPYL4_d "GTI d raw L4"
label var GTIPCPYL5_d "GTI d raw L5"
label var WarOccurrence_o "Conflict o L1"
label var WarOccurrence_high2_or "Conflict o L2"
label var WarOccurrence_high3_or "Conflict o L3"
label var WarOccurrence_high4_or "Conflict o L4"
label var WarOccurrence_high5_or "Conflict o L5"
label var WarOccurrence_d "Conflict d L1"
label var WarOccurrence_high2_dest "Conflict d L2"
label var WarOccurrence_high3_dest "Conflict d L3"
label var WarOccurrence_high4_dest "Conflict d L4"
label var WarOccurrence_high5_dest "Conflict d L5"
label var GDPpc_or_ln "Ln GDPpc o"
label var GDPpc_dest_ln "Ln GDPpc d"
label var PolInstab3y_o "Pol instab o"
label var PolInstab3y_d "Pol instab d"
label var WarOccurrence_o "Conflict o"
label var WarOccurrence_d "Conflict d"
label var Network_ln "Network"
label var dist_ln "Ln distance"
label var contig "Common border"
label var comlang_ethno "Common language"

egen FE_PPML_o=group(iso3o)
egen FE_PPML_d=group(iso3d)
egen FE_PPML_od=group(iso3o iso3d)
egen FE_PPML_y=group(year)
*egen FE_PPML_oy=group(iso3o year)
*egen FE_PPML_dy=group(iso3d year)


quietly {
tab year,gen(year_dum)
*tab FE_PPML_o, gen(o_dum)
*tab FE_PPML_d, gen(d_dum)
*tab FE_PPML_dy, gen(dy_dum)
*tab FE_PPML_oy, gen(oy_dum)
*tab FE_PPML_od, gen(od_dum) // error message (too many values, even with maximum allowed maxvar size)
} 

xtset dyad year
tab year

********************************************************************************
********************************* BENCHMARK ************************************
********************************************************************************
// Originally reported in Dissertation Killian
//--------------------------------------------
*ppml MigrationRateWithoutNeg GTI_o GTI_d $controlsppml o_dum* d_dum* year_dum* // PERFECT! Significant & positive at origin, significant & negative at dest, both at 5%
*est sto T1a
*keep if e(sample)

/* 
// REGRESSIONS WITH ALTERNATIVE FE STRUCTURES AND CLUSTERING OR NOT
//-----------------------------------------------------------------
*** Use instead ppmlhdfe, which is much faster and allows for multiple fixed effects structures
*** Should give the same results and that is indeed the case.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsppml, absorb(FE_PPML_o FE_PPML_d FE_PPML_y) vce(robust)

*** Question by Referee1: how are standard errors clustered? They weren't, try with od clusters
*** Note that with this estimation technique, vce(robust) and cluster cannot be specified together
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsppml, absorb(FE_PPML_o FE_PPML_d FE_PPML_y) cluster(FE_PPML_od) // Makes effects of terrorism insig
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsppml, absorb(FE_PPML_o FE_PPML_d FE_PPML_y) cluster(FE_PPML_o FE_PPML_d) // Makes effects of terrorism insig

*** Comment to use od FEs instead
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsppml, absorb(FE_PPML_od FE_PPML_y) vce(robust) // very similar results as in the benchmark with larger coefficients!!!!!
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsppml, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_o FE_PPML_d) // Sig effect at 10% in o but insig in d
*/

// PREFERRED SPECIFICATION (WITH ORIGIN AND DEST POP SIZE)
//------------------------
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d // Effects become slightly less significant but survive!!! 

/*
(dropped 188587 observations that are either singletons or separated by a fixed effect)

HDFE PPML regression                              No. of obs      =    456,439
Absorbing 2 HDFE groups                           Residual df     =     14,282
Statistics robust to heteroskedasticity           Wald chi2(9)    =     347.97
Deviance             =  13049.90124               Prob > chi2     =     0.0000
Log pseudolikelihood = -23283.86922               Pseudo R2       =     0.6370

Number of clusters (FE_PPML_od)=    14,283
                           (Std. Err. adjusted for 14,283 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0367461   .0199488     1.84   0.065    -.0023529    .0758451
          GTI_d |  -.0508217   .0240436    -2.11   0.035    -.0979464   -.0036971
    GDPpc_or_ln |   .0841411   .1521997     0.55   0.580    -.2141649     .382447
  GDPpc_dest_ln |   .2930153   .1615233     1.81   0.070    -.0235646    .6095952
  PolInstab3y_o |  -.0339602   .0834008    -0.41   0.684    -.1974227    .1295023
  PolInstab3y_d |   .0321894   .0814566     0.40   0.693    -.1274625    .1918414
WarOccurrence_o |   .4164292   .1122862     3.71   0.000     .1963523    .6365062
WarOccurrence_d |   -.487546   .2553065    -1.91   0.056    -.9879375    .0128454
     Network_ln |    .368402   .0258094    14.27   0.000     .3178164    .4189875
          _cons |  -7.579249   2.084889    -3.64   0.000    -11.66556   -3.492942
---------------------------------------------------------------------------------
*/


// So this shows the importance of aligning the clustering terms with the FE structure!!!
est sto T1a
keep if e(sample) // (1,166,582 observations deleted)


********************************************************************************
*************************** DESCRIPTIVE STATISTICS *****************************
********************************************************************************
* Number of observations per year
tab year // 1975 2017
/*
       year |      Freq.     Percent        Cum.
------------+-----------------------------------
       1975 |      9,531        2.11        2.11
       1976 |      9,531        2.11        4.21
       1977 |      9,640        2.13        6.34
       1978 |     10,268        2.27        8.61
       1979 |     10,268        2.27       10.88
       1980 |     10,382        2.29       13.18
       1981 |     10,650        2.35       15.53
       1982 |     10,650        2.35       17.88
       1983 |     10,650        2.35       20.24
       1984 |     10,650        2.35       22.59
       1985 |     10,650        2.35       24.94
       1986 |     10,650        2.35       27.30
       1987 |     10,650        2.35       29.65
       1988 |     10,585        2.34       31.99
       1989 |     10,585        2.34       34.33
       1990 |     10,585        2.34       36.67
       1991 |     10,650        2.35       39.02
       1992 |     10,650        2.35       41.38
       1993 |     10,982        2.43       43.80
       1994 |     13,239        2.93       46.73
       1995 |     13,581        3.00       49.73
       1996 |     13,986        3.09       52.82
       1997 |     13,987        3.09       55.91
       1998 |     13,987        3.09       59.00
       1999 |     13,988        3.09       62.09
       2000 |     13,990        3.09       65.19
       2001 |      9,906        2.19       67.38
       2002 |      9,899        2.19       69.56
       2003 |      9,899        2.19       71.75
       2004 |      9,889        2.19       73.94
       2005 |      9,889        2.19       76.12
       2006 |      9,831        2.17       78.29
       2007 |      9,825        2.17       80.47
       2008 |      9,754        2.16       82.62
       2009 |      9,704        2.14       84.77
       2010 |      9,681        2.14       86.91
       2011 |      9,104        2.01       88.92
       2012 |      9,063        2.00       90.92
       2013 |      8,938        1.98       92.90
       2014 |      8,059        1.78       94.68
       2015 |      8,046        1.78       96.45
       2016 |      8,027        1.77       98.23
       2017 |      8,015        1.77      100.00
------------+-----------------------------------
      Total |    452,494      100.00
*/

* Number of countries
*tab origin  // 154 countries
preserve
keep origin
duplicates drop
count // 154
restore

*tab destination // 151 countries
preserve
keep destination 
duplicates drop
count // 151
restore

* Summary GTI
sum GTI_o 
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTI_o |    452,494    3.372964    2.454006          0         10
   
*/

sum GTI_d 
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTI_d |    452,494    3.303766    2.347314          0         10

*/

* Marginal effects
/*
If you use -atmeans-, you get MEMs, Marginal Effects at the Means. If you don't use -atmeans- 
you are basically using -asobserved-, which gives you AMEs, Average Marginal Effects. 
The differences between the two (for categorical variables, anyway) are described in
http://www3.nd.edu/~rwilliam/xsoc73994/Margins01.pdf

For continuous variables, see

http://www3.nd.edu/~rwilliam/xsoc73994/Margins02.pdf
http://www3.nd.edu/~rwilliam/xsoc73994/Margins03.pdf
*/

est resto T1a
margins, dydx(GTI_o) post vce(unconditional) // dydx = Marginal effects!
/*
Average marginal effects                        Number of obs     =    452,494

Expression   : Predicted mean of MigrationRateWithoutNeg, predict()
dy/dx w.r.t. : GTI_o

                        (Std. Err. adjusted for 14,143 clusters in FE_PPML_od)
------------------------------------------------------------------------------
             |            Unconditional
             |      dy/dx   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       GTI_o |   .0009151   .0108276     0.08   0.933    -.0203065    .0221367
------------------------------------------------------------------------------
*/
est store ME1

est resto T1a
margins, at(GTI_o=(0 1 2 3 4 5 6 7 8 9 10)) atmeans post noatlegend  // Marginal effects at the Means
/*
Adjusted predictions                            Number of obs     =    452,494
Model VCE    : Robust

Expression   : Predicted mean of MigrationRateWithoutNeg, predict()

------------------------------------------------------------------------------
             |            Delta-method
             |     Margin   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
         _at |
          1  |   .0000892   .0000205     4.35   0.000      .000049    .0001293
          2  |   .0000921   .0000204     4.51   0.000     .0000521    .0001322
          3  |   .0000951   .0000205     4.64   0.000     .0000549    .0001354
          4  |   .0000983   .0000208     4.73   0.000     .0000576     .000139
          5  |   .0001015   .0000212     4.79   0.000       .00006    .0001431
          6  |   .0001049   .0000218     4.80   0.000     .0000621    .0001477
          7  |   .0001083   .0000227     4.77   0.000     .0000638    .0001528
          8  |   .0001119   .0000238     4.69   0.000     .0000652    .0001586
          9  |   .0001156   .0000252     4.58   0.000     .0000661    .0001651
         10  |   .0001194   .0000269     4.44   0.000     .0000666    .0001721
         11  |   .0001233   .0000289     4.27   0.000     .0000668    .0001799
------------------------------------------------------------------------------
*/
est store ME2

est resto T1a
margins, at(GTI_d=(0 1 2 3 4 5 6 7 8 9 10)) atmeans post noatlegend  // Marginal effects at the Means
/*
Adjusted predictions                            Number of obs     =    452,494
Model VCE    : Robust

Expression   : Predicted mean of MigrationRateWithoutNeg, predict()

------------------------------------------------------------------------------
             |            Delta-method
             |     Margin   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
         _at |
          1  |   .0001146   .0000277     4.14   0.000     .0000603    .0001689
          2  |   .0001098   .0000252     4.35   0.000     .0000604    .0001592
          3  |   .0001052   .0000231     4.55   0.000     .0000599    .0001505
          4  |   .0001008   .0000214     4.72   0.000     .0000589    .0001426
          5  |   .0000966     .00002     4.84   0.000     .0000574    .0001357
          6  |   .0000925   .0000189     4.89   0.000     .0000554    .0001296
          7  |   .0000886   .0000182     4.88   0.000      .000053    .0001243
          8  |   .0000849   .0000177     4.79   0.000     .0000502    .0001197
          9  |   .0000814   .0000175     4.65   0.000     .0000471    .0001156
         10  |    .000078   .0000174     4.47   0.000     .0000438    .0001121
         11  |   .0000747   .0000175     4.26   0.000     .0000404     .000109
------------------------------------------------------------------------------
*/
est store ME3

est resto T1a
margins, at(GTI_o=(0 1 2 3 4 5 6 7 8 9 10)) post noatlegend // average marginal effects
marginsplot,  xlabel(0(1)10) saving("Results/Revision JEBO/ME_o.png", replace) 
est resto T1a
margins, at(GTI_d=(0 1 2 3 4 5 6 7 8 9 10)) post noatlegend  // average marginal effects
marginsplot,  xlabel(0(1)10) saving("Results/Revision JEBO/ME_d.png", replace) 
/*
est resto T1a
margins, eyex(GTI_o) at(GTI_o=(0 1 2 3 4 5 6 7 8 9 10))  post noatlegend //eyex = elasticities but doesn't work without atmeans 
est resto T1a
margins, eyex(GTI_d) at(GTI_d=(0 1 2 3 4 5 6 7 8 9 10))  post noatlegend //eyex = elasticities but not interestingbut doesn't work without atmeans 
*/

esttab  ME2 ME3 using "Results/Revision JEBO/Table ME.tex", label title("Impact of terrorist attacks on global bilateral migration rates - Marginal effects") /// 
mtitles("GTI_o" "GTI_d") nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") obslast 
//but this posts these numbers that are so small...


*** Other ways to compute the size of the effect 
*** Check extremes for origin (checked and is exactly the same for destinations)
preserve
est resto T1a
keep if e(sample)
gen GTI_o_L1 = L.GTI_o
gen GTI_d_L1 = L.GTI_d
gen GTI_o_diff = GTI_o - GTI_o_L1
gen GTI_d_diff = GTI_d - GTI_d_L1
keep origin year GTI_o_diff 
duplicates drop
drop if GTI_o_diff == .
sum GTI_o_diff 
sort origin year GTI_o_diff
list origin year GTI_o_diff if GTI_o_diff < -3
/*
      +---------------------------------+
      |       origin   year   GTI_o_d~f |
      |---------------------------------|
 114. |       Angola   2008   -3.719816 |
1048. |         Chad   2014   -3.712554 |
2286. |       Guyana   2014   -3.084016 |
2869. |        Kenya   1986   -3.173416 |
3309. |       Malawi   1998   -3.252781 |
      |---------------------------------|
4052. |       Norway   2017   -3.977271 |
4687. | Sierra Leone   2006     -3.8292 |
5361. |      Tunisia   1986   -3.651978 |
      +---------------------------------+
*/
list origin year GTI_o_diff if GTI_o_diff > 5
/*
      +----------------------------------+
      |         origin   year   GTI_o_~f |
      |----------------------------------|
 124. |      Argentina   1976   6.443477 |
 777. |        Burundi   1992   6.164766 |
 861. |       Cameroon   1992   5.302772 |
 877. |       Cameroon   2008   5.178749 |
1026. |           Chad   1992   5.076291 |
      |----------------------------------|
1867. |         France   1976   5.478209 |
2082. |         Greece   1976   5.611829 |
2124. |      Guatemala   1976   5.038109 |
2584. |        Ireland   1976   5.127013 |
2626. |         Israel   1976    5.98465 |
      |----------------------------------|
2668. |          Italy   1976   5.471705 |
2859. |          Kenya   1976   5.465768 |
2941. |         Kuwait   2016   5.224537 |
3031. |        Lebanon   1976   5.482819 |
3304. |         Malawi   1993   5.215434 |
      |----------------------------------|
3497. |         Mexico   1976   5.494665 |
3640. |        Morocco   2004   5.676902 |
3959. |          Niger   2008   5.833369 |
4673. |   Sierra Leone   1992   6.191378 |
4869. |          Spain   1976   6.193064 |
      |----------------------------------|
5565. | United Kingdom   1976   7.349557 |
5607. |  United States   1976   6.550374 |
5860. |       Zimbabwe   1981   5.151888 |
      +----------------------------------+
	  */
list origin year GTI_o_diff if GTI_o_diff < 1.01 & GTI_o_diff > 0.99
/*
      +------------------------------+
      |     origin   year   GTI_o_~f |
      |------------------------------|
1133. |      China   2015   1.000432 |
2835. |     Jordan   2017   1.009017 |
4220. |       Peru   1981   1.005325 |
5181. | Tajikistan   2016   .9995718 |
5239. |   Thailand   1990   1.009742 |
      |------------------------------|
5478. |     Uganda   1996   1.001428 |
      +------------------------------+
*/
label var GTI_o_diff "GTI changes"
histogram GTI_o_diff, fraction scheme(stcoloralt) bcolor(blue%70) graphregion(color(white))
graph export "Results/Revision JEBO/HistogramChanges.png", replace //, width(600) height(450)
restore


*** For the countries in that last table (eg China), estimate for an example the total emigration flow in a given year (eg 2014)
preserve
bysort origin year: egen A = mean(TotalFlowsWithoutNeg_o)
bysort origin year: egen B = mean(Natives_o) // is indeed the size of the native population (not in thousands or anything)
keep origin year A B
duplicates drop
gen C=A*1000/B // NEW APRIL 2023: So will be in 1000ths of the native population
gen D = C*1.0037 // Looking eg at China in 2014, this gives the migration rate after the GTI rise by one unit
gen E = D*(B/1000) // gives the total number of migrants after this GTI rise
gen F = E - A
sort F origin year
/* NOT SURE HOW TO UPDATE THOSE NUMBERS BELOW
China 2014: 128 less migrants
Jordan 2007: 328 less migrants
Tajikistan 2016: 1.75 migrants (nobody moves there)
Thailand 1990: 138 less migrants
Uganda 1996: 182 less migrants

origin	year	A	B	C	D	E	F
Syria	2011	924110	2.14e+07	43.27619	43.43631	927529.3	3419.25
Syria	2012	1067786	2.11e+07	50.6678	50.85527	1071737	3950.75
Syria	2013	1106922	2.04e+07	54.17028	54.37071	1111018	4095.625
Syria	2014	1111151	1.96e+07	56.75127	56.96125	1115262	4111.25
Syria	2015	1004560	1.87e+07	53.68884	53.88749	1008277	3716.875
Syria	2016	426528	1.80e+07	23.70592	23.79363	428106.2	1578.156
Syria	2017	300821	1.74e+07	17.24007	17.30385	301934	1113
*/
restore



*** For the countries in that last table, estimate for an example the total immigration flow in 2014
preserve // NEED TO UPDATE THOSE NUMBERS TOO
bysort destination year: egen A = mean(TotalFlowsWithoutNeg_d)
bysort destination year: egen B = mean(Natives_o) // is indeed the size of the native population (not in thousands or anything)
keep destination year A B
duplicates drop
gen C=A*1000/B // NEW APRIL 2023: So will be in 1000ths of the native population
gen D = C*1.0051 // Looking eg at China in 2014, this gives the migration rate after the GTI rise by one unit
gen E = D*(B/1000) // gives the total number of migrants after this GTI rise
gen F = E - A
sort destination year F // 128 less migrants for China in 2014
/*origin	year	A	B	C	D	E	F
Syria	2011	924110	2.14e+07	43.27619	43.43631	927529.3	3419.25
Syria	2012	1067786	2.11e+07	50.6678	50.85527	1071737	3950.75
Syria	2013	1106922	2.04e+07	54.17028	54.37071	1111018	4095.625
Syria	2014	1111151	1.96e+07	56.75127	56.96125	1115262	4111.25
Syria	2015	1004560	1.87e+07	53.68884	53.88749	1008277	3716.875
Syria	2016	426528	1.80e+07	23.70592	23.79363	428106.2	1578.156
Syria	2017	300821	1.74e+07	17.24007	17.30385	301934	1113
*/
restore



*** Share of zeroes
count if MigrationRateWithoutNeg==0 & e(sample) //  [401,872] --> NOW 204,111
count if MigrationRateWithoutNeg>0 & e(sample) // [251,103] --> 248,383
* gen zeroes = [401872/(401872+251103)  = 0.6154] --> .45264319 (see next line)
gen zeroes = 206604/(249835+206604) // .4526432
count if DummyNegFlow==1 & e(sample) // 75,132
gen zeroes_duetonegflows = 75516/(249835+206604) // .165446
gen purezeroes = zeroes - zeroes_duetonegflows // .2871972

*** Summary statistics
est resto T1a
estpost sum MigrationRateWithoutNeg GTI_o GTI_d $controlsOD if e(sample)
esttab using "Results/Revision JEBO/DescrStats ppml MigrationRateWithoutNeg.tex", cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3))") nomtitle nonumber replace label

*** Pairwise correlations
estpost corr MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, matrix
esttab . using "Results/Revision JEBO/Pwcorr ppml MigrationRateWithoutNeg.tex", not unstack compress noobs replace booktabs page label b(3) // corr max 0.478
esttab . using "Results/Revision JEBO/Pwcorr ppml MigrationRateWithoutNeg.xls", not unstack compress noobs replace booktabs page label b(3)



********************************************************************************
*** Migration maps
// ORIGIN: Average yearly emigration flow (without neg flows) - not based on our sample, divided by average yearly native population 
preserve
bysort origin: egen avgTotalFlows = mean(TotalFlowsWithoutNeg_o)
bysort origin: egen avgnatives=mean(Natives_o) // is indeed the size of the native population (not in thousands or anything)
keep origin iso3o avgTotalFlows avgnatives
duplicates drop
gen MigRate=avgTotalFlows*1000/avgnatives // NEW APRIL 2023: So will be in 1000ths of the native population
format (MigRate) %12.3f
sum MigRate avgTotalFlows avgnatives
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
     MigRate |        154    2.381923    2.686448   .0642709   15.91975
avgTotalFl~s |        154    18985.96    22468.92   441.9456   131578.1
  avgnatives |        154    3.53e+07    1.24e+08   116340.6   1.17e+09
*/
export excel origin MigRate using "Results/Revision JEBO/MigRate average.xls", firstrow(variables) replace
rename iso3o GID_0
save "Results/Revision JEBO/TOTALMigRateWithoutNeg_o.dta", replace
restore


// DESTINATION: Average yearly immigration flow (without neg flows) divided by average yearly native population
preserve
bysort destination: egen avgTotalFlows = mean(TotalFlowsWithoutNeg_d)
bysort destination: egen avgnatives=mean(Natives_d)
keep destination iso3d avgTotalFlows avgnatives
duplicates drop
gen MigRate=avgTotalFlows*1000/avgnatives
format (MigRate) %12.3f
sum MigRate
/*
sum MigRate

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
     MigRate |        151    5.787028    38.66914   .0010019   467.8653

*/
tab destination if MigRate >450
/*
                                 NAME_0 |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                  Qatar |          1      100.00      100.00
----------------------------------------+-----------------------------------
                                  Total |          1      100.00
*/
rename iso3d GID_0
save "Results/Revision JEBO/TOTALMigRateWithoutNeg_d.dta", replace
restore


*** Origin without negative flows (ie on the most sending countries)
preserve
clear
set more off
shp2dta using "Results/Revision JEBO/gadm36_0.shp", data("Results/Revision JEBO/worlddata.dta") coordinates("Results/Revision JEBO/worldcoor.dta") genid(id) replace
clear
use "Results/Revision JEBO/worlddata.dta"
merge 1:1 GID_0 using "Results/Revision JEBO/TOTALMigRateWithoutNeg_o.dta"
/* NEW AS OF APRIL 2023
    Result                           # of obs.
    -----------------------------------------
    not matched                           102
        from master                       102  (_merge==1)
        from using                          0  (_merge==2)

    matched                               154  (_merge==3)
    -----------------------------------------
*/
drop _merge
format (MigRate) %12.2f 
spmap MigRate using "Results/Revision JEBO/worldcoor.dta" if NAME_0!="Antarctica", id(id) fcolor(Blues) clnumber(5) ndocolor(gs8) ndsize(vvthin) osize(vvthin vvthin vvthin vvthin vvthin) legstyle(2) legcount legend(size(*2))
graph export "Results/Revision JEBO/MigOriginv1.png", as(png) replace

tabstat MigRate, stat(mean min max p1 p5 p10 p25 p50 p75 p90 p95 p99)
/* NEW AS OF 25/10/2023
    variable |      mean       min       max        p1        p5       p10       p25       p50       p75
-------------+------------------------------------------------------------------------------------------
     MigRate |  2.381923  .0642709  15.91975  .0728912   .181745  .2503684  .5138518  1.442347  3.089674
--------------------------------------------------------------------------------------------------------

    variable |       p90       p95       p99
-------------+------------------------------
     MigRate |  5.762879  8.499538  11.18573
--------------------------------------------
*/
tab origin if MigRate >900 // no observation
* p25 p50 p90
spmap MigRate using "Results/Revision JEBO/worldcoor.dta" if NAME_0!="Antarctica", id(id) fcolor(Blues) clmethod(custom) clbreaks(0 .5138518 1.442347 5.762879 16) ndocolor(gs8) ndsize(vvthin) osize(vvthin vvthin vvthin vvthin vvthin) legstyle(2) legcount legend(size(*2))
graph export "Results/Revision JEBO/MigOriginv2.png", as(png) replace
restore

*** Destination without negative flows (ie the most receiving countries)
preserve
clear
use "Results/Revision JEBO/worlddata.dta"
merge 1:1 GID_0 using "Results/Revision JEBO/TOTALMigRateWithoutNeg_d.dta"
/* NEW AS OF 25/10/2023
    Result                           # of obs.
    -----------------------------------------
    not matched                           105
        from master                       105  (_merge==1)
        from using                          0  (_merge==2)

    matched                               151  (_merge==3)
    -----------------------------------------
*/
drop _merge
format (MigRate) %12.2f 
spmap MigRate using "Results/Revision JEBO/worldcoor.dta" if NAME_0!="Antarctica", id(id) fcolor(Blues) clnumber(5) ndocolor(gs8) ndsize(vvthin) osize(vvthin vvthin vvthin vvthin vvthin) legstyle(2) legcount legend(size(*2))
graph export "Results/Revision JEBO/MigDestv1.png", as(png) replace
tabstat MigRate, stat(mean min max p1 p5 p10 p25 p50 p75 p90 p95 p99)
/*
NEW SINCE 25/10/2023:
    variable |      mean       min       max        p1        p5       p10       p25       p50       p75
-------------+------------------------------------------------------------------------------------------
     MigRate |  5.787028  .0010019  467.8653  .0151956  .0438975  .0686449  .3731959  .9286178  1.994341
--------------------------------------------------------------------------------------------------------

    variable |       p90       p95       p99
-------------+------------------------------
     MigRate |  5.245742  9.491466   75.7227
--------------------------------------------
*/
* p25 p50 p90
spmap MigRate using "Results/Revision JEBO/worldcoor.dta" if NAME_0!="Antarctica", id(id) fcolor(Blues) clmethod(custom) clbreaks(0 .3731959 .9286178 5.245742 468) ndocolor(gs8) ndsize(vvthin) osize(vvthin vvthin vvthin vvthin vvthin) legstyle(2) legcount legend(size(*2))
graph export "Results/Revision JEBO/MigDestv2.png", as(png) replace
restore

*** Map terrorism
preserve
keep GTI_o iso3o year origin
duplicates drop
histogram GTI_o, fraction
count // 6,052
count if GTI_o==0 //1,525
rename GTI_o GTI
label var GTI "GTI"
histogram GTI if GTI!=0, fraction scheme(stcoloralt) bcolor(blue%70) graphregion(color(white))
graph export "Results/Revision JEBO/HistogramAllYears.png", replace //, width(600) height(450)
rename GTI GTI_o
label var GTI_o "GTI o"
egen GTIavg=mean(GTI_o), by(iso3o)
keep iso3o GTIavg origin
duplicates drop
histogram GTIavg, fraction
count //154
count if GTIavg==0 //3
tab origin if GTIavg==0 
sort  GTIavg origin
list origin GTIavg
label var GTIavg "Average GTI"
histogram GTIavg if GTIavg!=0, fraction scheme(stcoloralt) bcolor(blue%70) graphregion(color(white))
graph export "Results/Revision JEBO/HistogramAverage.png",  replace //, width(600) height(450)
rename iso3o GID_0
drop origin
save "Results/Revision JEBO/GTIavg.dta", replace
restore

preserve
clear
use "Results/Revision JEBO/worlddata.dta"
merge 1:1 GID_0 using "Results/Revision JEBO/GTIavg.dta"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           102
        from master                       102  (_merge==1)
        from using                          0  (_merge==2)

    matched                               154  (_merge==3)
    -----------------------------------------
*/
drop _merge
format (GTIavg) %12.2f 
spmap GTIavg using "Results/Revision JEBO/worldcoor.dta" if NAME_0!="Antarctica", id(id) fcolor(Reds) clnumber(5) ndocolor(gs8) ndsize(vvthin) osize(vvthin vvthin vvthin vvthin vvthin) legstyle(2) legcount legend(size(*2))
graph export "Results/Revision JEBO/GTIagv1.png", as(png) replace
tabstat GTIavg, stat(mean min max p1 p5 p10 p25 p50 p75 p90 p95 p99)
/* 
NEW SINCE 25/10/2023:
    variable |      mean       min       max        p1        p5       p10       p25       p50       p75
-------------+------------------------------------------------------------------------------------------
      GTIavg |  3.191378         0  7.254505         0  .6400782  .8787953   1.88536  3.055795  4.488933
--------------------------------------------------------------------------------------------------------

    variable |       p90       p95       p99
-------------+------------------------------
      GTIavg |  5.648711  6.312266  7.137112
--------------------------------------------
*/
* p25 p75 p95
spmap GTIavg using "Results/Revision JEBO/worldcoor.dta" if NAME_0!="Antarctica", id(id) fcolor(Reds) clmethod(custom) clbreaks(0 1.88536 4.488933 6.312266 8) ndocolor(gs8) ndsize(vvthin) osize(vvthin vvthin vvthin vvthin vvthin) legstyle(2) legcount legend(size(*2))
graph export "Results/Revision JEBO/GTIagv2.png", as(png) replace
restore




********************************************************************************
************************** TABLE 1 : GTI + Other indexes ***********************
**** NOTE: update for revision with the parsimoneous model first
********************************************************************************
* Parsimoneous model
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d
est sto T1f

rename GTI_o GTIooriginal
rename GTI_d GTIdoriginal

* Terror Occurrence
rename AttackOccurrence_o GTI_o
rename AttackOccurrence_d GTI_d
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T1b
rename GTI_o AttackOccurrence_o
rename GTI_d AttackOccurrence_d

* Attacks index
rename AttacksIndex_o GTI_o
rename AttacksIndex_d GTI_d
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T1c
rename GTI_o AttacksIndex_o
rename GTI_d AttacksIndex_d

* Victims
rename VictimsIndex_o GTI_o
rename VictimsIndex_d GTI_d
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T1d
rename GTI_o VictimsIndex_o
rename GTI_d VictimsIndex_d

* Bombings
rename BombingIndex_o GTI_o
rename BombingIndex_d GTI_d
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T1e
rename GTI_o BombingIndex_o
rename GTI_d BombingIndex_d

rename GTIooriginal GTI_o
rename GTIdoriginal GTI_d

label variable GTI_o "Terror o"
label variable GTI_d "Terror d"

esttab  T1f T1a T1b T1c T1d T1e using "Results/Revision JEBO/Table 1.tex", label title("Impact of terrorist attacks on global bilateral migration rates") /// 
mtitles("Parsimonious" "Benchmark" "Terror occurrence" "Attacks index" "Victims index" "Bombings index") nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers ///
t(2) b(3) nogaps scalars("ll Log likelihood") obslast ///
addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad.")

label variable GTI_o "GTI o"
label variable GTI_d "GTI d"



********************************************************************************
**************************** TABLE 2: Robustness tests *************************
********************************************************************************

* INSTRUMENTING 
* With both GTI_o & GTI_d, o d y FE, robust only (if we add cluster then we do not obtain all the results -> "estimated covariance matrix of moment conditions not of full rank")
*xi: ivreg2 MigrationRateWithoutNeg_ln $controlsppml i.oFE i.dFE i.yFE (GTI_o GTI_d = GTI_o_lag govfrac_o GTI_d_lag govfrac_d), robust 
/* PERFECT!
                                                      Number of obs =   419767
                                                      F(344,419422) =   436.80
                                                      Prob > F      =   0.0000
Total (centered) SS     =  610774.5428                Centered R2   =   0.4209
Total (uncentered) SS   =  74457528.54                Uncentered R2 =   0.9952
Residual SS             =  353701.7841                Root MSE      =    .9179

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0140107   .0027006     5.19   0.000     .0087177    .0193038
          GTI_d |  -.0227045   .0032119    -7.07   0.000    -.0289997   -.0164093
        dist_ln |  -.3132269   .0034003   -92.12   0.000    -.3198915   -.3065624
         contig |   .6391975   .0207209    30.85   0.000     .5985852    .6798098
  comlang_ethno |   .1781392   .0062331    28.58   0.000     .1659225    .1903559
    GDPpc_or_ln |   .0444968   .0084827     5.25   0.000     .0278709    .0611226
  GDPpc_dest_ln |   .0032101   .0073958     0.43   0.664    -.0112854    .0177056
     Network_ln |   .0504176   .0002174   231.95   0.000     .0499916    .0508436
  PolInstab3y_o |  -.0008073   .0058033    -0.14   0.889    -.0121816     .010567
  PolInstab3y_d |   .0304922   .0051402     5.93   0.000     .0204177    .0405668
WarOccurrence_o |   .0161216   .0067474     2.39   0.017     .0028969    .0293464
WarOccurrence_d |   .0041074   .0073567     0.56   0.577    -.0103115    .0185263

------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):            3.0e+04
                                                   Chi-sq(3) P-val =    0.0000 --> good
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):              1.4e+04 --> good
                         (Kleibergen-Paap rk Wald F statistic):        1.2e+04 --> good
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         0.885
                                                   Chi-sq(2) P-val =    0.6423 --> good: cannot reject the null of the instruments being jointly valid at 5% significant level so GOOD
*/

*******************************************************************************
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstboth) // same results: good!!!!!!
est sto T2a

/*
ereturn list // Choose:
e(idstat) //Underidentification test (Kleibergen-Paap rk LM statistic):  
e(iddf) //  Chi-sq(XXX)
e(idp) // P-val 
 
e(cdf) // Weak identification test (Cragg-Donald Wald F statistic):  
e(widstat) // Weak identification test  (Kleibergen-Paap rk Wald F statistic)

e(j) // Hansen J statistic (overidentification test of all instruments)
e(jdf) //  Chi-sq(2)
e(jp) // P-val 
*/


mat X = e(first)
estadd scalar F_GTIo =  X[4,1] : firstbothGTI_o
estadd scalar F_GTId =  X[4,2] : firstbothGTI_d
estadd scalar df_GTIo =  X[5,1] : firstbothGTI_o
estadd scalar df_GTId =  X[5,2] : firstbothGTI_d
estadd scalar p_GTIo =  X[7,1] : firstbothGTI_o
estadd scalar p_GTId =  X[7,2] : firstbothGTI_d
estadd scalar SWF_GTIo = X[8,1] : firstbothGTI_o
estadd scalar SWF_GTId = X[8,2] : firstbothGTI_d
estadd scalar SWFdf_GTIo =  X[9,1] : firstbothGTI_o
estadd scalar SWFdf_GTId =  X[9,2] : firstbothGTI_d
estadd scalar SWFp_GTIo =  X[11,1] : firstbothGTI_o
estadd scalar SWFp_GTId = X[11,2] : firstbothGTI_d
estadd scalar SWFchi_GTIo =  X[12,1] : firstbothGTI_o
estadd scalar SWFchi_GTId =  X[12,2] : firstbothGTI_d
estadd scalar SWFchip_GTIo =X[13,1] : firstbothGTI_o
estadd scalar SWFchip_GTId =  X[13,2] : firstbothGTI_d


/* NOTICE THIS WAS RUN ON THE ESTIMATION SAMPLE AFTER PPML WITH DYADIC FE AND CLUSTERED ST ERRORS AT DYADIC LEVEL!
(dropped 45 singleton observations)
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstbothG~o | ivreg2       GTI_o          11  First-stage regression: GTI_o
firstbothG~d | ivreg2       GTI_d          11  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .1090725   .0012314    88.57   0.000     .1066589     .111486
  govfrac2020_o |   .8002715   .0296808    26.96   0.000      .742098    .8584451
      GTI_d_lag |   .0043208   .0014225     3.04   0.002     .0015328    .0071089
  govfrac2020_d |   .0150639   .0250327     0.60   0.547    -.0339994    .0641273
    GDPpc_or_ln |  -.5754646   .0332758   -17.29   0.000    -.6406842    -.510245
  GDPpc_dest_ln |   .0024532   .0329338     0.07   0.941    -.0620962    .0670025
  PolInstab3y_o |   .5736646   .0161534    35.51   0.000     .5420045    .6053248
  PolInstab3y_d |   .0069798   .0132838     0.53   0.599     -.019056    .0330156
WarOccurrence_o |   1.202211    .030014    40.06   0.000     1.143385    1.261038
WarOccurrence_d |    .035713   .0263121     1.36   0.175    -.0158579    .0872839
     Network_ln |   .0068141   .0018988     3.59   0.000     .0030925    .0105356
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  2203.77
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2880.05
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0033009    .001365     2.42   0.016     .0006256    .0059762
  govfrac2020_o |   .0152631   .0242497     0.63   0.529    -.0322656    .0627918
      GTI_d_lag |   .1037854   .0012626    82.20   0.000     .1013106    .1062601
  govfrac2020_d |   .4057364   .0268828    15.09   0.000      .353047    .4584258
    GDPpc_or_ln |   .0394167   .0276784     1.42   0.154    -.0148322    .0936657
  GDPpc_dest_ln |  -.6048366   .0389948   -15.51   0.000    -.6812653   -.5284079
  PolInstab3y_o |   .0150739   .0119396     1.26   0.207    -.0083273    .0384751
  PolInstab3y_d |   .4556392   .0178464    25.53   0.000     .4206608    .4906175
WarOccurrence_o |   .0225867   .0222199     1.02   0.309    -.0209636     .066137
WarOccurrence_d |   1.035103   .0338287    30.60   0.000     .9687993    1.101406
     Network_ln |   .0037706   .0017708     2.13   0.033     .0002998    .0072414
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  1724.68
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2263.13
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  4, 13302)  P-val | SW Chi-sq(  3) P-val | SW F(  3, 13302)
GTI_o        |    2203.77    0.0000 |     8642.14   0.0000 |     2880.05
GTI_d        |    1724.68    0.0000 |     6790.95   0.0000 |     2263.13

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                    5% maximal IV relative bias    16.85
                                   10% maximal IV relative bias    10.27
                                   20% maximal IV relative bias     6.71
                                   30% maximal IV relative bias     5.34
                                   10% maximal IV size             24.58
                                   15% maximal IV size             13.96
                                   20% maximal IV size             10.26
                                   25% maximal IV size              8.31
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(3)=1839.21  P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                   10180.99
Kleibergen-Paap Wald rk F statistic                              1560.85

Stock-Yogo weak ID test critical values for K1=2 and L1=4:
                                    5% maximal IV relative bias    11.04
                                   10% maximal IV relative bias     7.56
                                   20% maximal IV relative bias     5.57
                                   30% maximal IV relative bias     4.73
                                   10% maximal IV size             16.87
                                   15% maximal IV size              9.93
                                   20% maximal IV size              7.54
                                   25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(4,13302)=     6.00     P-val=0.0001
Anderson-Rubin Wald test           Chi-sq(4)=     24.01     P-val=0.0001
Stock-Wright LM S statistic        Chi-sq(4)=     24.46     P-val=0.0001

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =         11
Number of excluded instruments       L1 =          4

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    77.42
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =   0.0094
Total (uncentered) SS   =  170701.4477                Uncentered R2 =   0.0094
Residual SS             =  169096.7373                Root MSE      =    .7119

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0121152   .0062827     1.93   0.054    -.0001998    .0244302
          GTI_d |  -.0359705    .008426    -4.27   0.000    -.0524867   -.0194542
    GDPpc_or_ln |   .0136359   .0202155     0.67   0.500    -.0259894    .0532612
  GDPpc_dest_ln |   .1436143   .0216888     6.62   0.000     .1011011    .1861275
  PolInstab3y_o |   .0049762   .0087505     0.57   0.570     -.012176    .0221285
  PolInstab3y_d |    .033694   .0081636     4.13   0.000     .0176923    .0496958
WarOccurrence_o |   .0640726   .0168127     3.81   0.000     .0311174    .0970278
WarOccurrence_d |   .0729378   .0184336     3.96   0.000     .0368053    .1090702
     Network_ln |   .0248434   .0010224    24.30   0.000     .0228393    .0268475
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):           1839.215
                                                   Chi-sq(3) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):              1.0e+04
                         (Kleibergen-Paap rk Wald F statistic):       1560.846
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         2.475
                                                   Chi-sq(2) P-val =    0.2901
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

*/







*** Redo for one instrument at a time!
est resto T2a
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag  GTI_d_lag ) if e(sample), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstGTIlag) // same results in first stage: good!!!!!!
est sto TIVb
mat W = e(first)
estadd scalar F_GTIo =  W[4,1] : firstGTIlagGTI_o
estadd scalar F_GTId =  W[4,2] : firstGTIlagGTI_d
estadd scalar df_GTIo =  W[5,1] : firstGTIlagGTI_o
estadd scalar df_GTId =  W[5,2] : firstGTIlagGTI_d
estadd scalar p_GTIo =  W[7,1] : firstGTIlagGTI_o
estadd scalar p_GTId =  W[7,2] : firstGTIlagGTI_d
estadd scalar SWF_GTIo = W[8,1] : firstGTIlagGTI_o
estadd scalar SWF_GTId = W[8,2] : firstGTIlagGTI_d
estadd scalar SWFdf_GTIo =  W[9,1] : firstGTIlagGTI_o
estadd scalar SWFdf_GTId =  W[9,2] : firstGTIlagGTI_d
estadd scalar SWFp_GTIo =  W[11,1] : firstGTIlagGTI_o
estadd scalar SWFp_GTId = W[11,2] : firstGTIlagGTI_d
estadd scalar SWFchi_GTIo =  W[12,1] : firstGTIlagGTI_o
estadd scalar SWFchi_GTId =  W[12,2] : firstGTIlagGTI_d
estadd scalar SWFchip_GTIo =W[13,1] : firstGTIlagGTI_o
estadd scalar SWFchip_GTId =  W[13,2] : firstGTIlagGTI_d
/*
First-stage regressions --> F-statistics are good!
-----------------------
First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |    .111742   .0012187    91.69   0.000     .1093534    .1141306
      GTI_d_lag |   .0043522   .0014511     3.00   0.003      .001508    .0071963
    GDPpc_or_ln |  -.6062868   .0344552   -17.60   0.000     -.673818   -.5387556
  GDPpc_dest_ln |   .0029621   .0334691     0.09   0.929    -.0626364    .0685606
  PolInstab3y_o |   .5805609   .0167345    34.69   0.000     .5477619      .61336
  PolInstab3y_d |   .0064684   .0134121     0.48   0.630     -.019819    .0327557
WarOccurrence_o |    1.24479   .0302481    41.15   0.000     1.185505    1.304076
WarOccurrence_d |    .035002   .0268257     1.30   0.192    -.0175756    .0875797
     Network_ln |    .007204   .0019341     3.72   0.000     .0034132    .0109948
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  2, 13302) =  4208.97
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  1, 13302) =  8256.56
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0034161   .0013759     2.48   0.013     .0007194    .0061127
      GTI_d_lag |   .1051168   .0012619    83.30   0.000     .1026435    .1075902
    GDPpc_or_ln |    .038526   .0278436     1.38   0.166    -.0160467    .0930987
  GDPpc_dest_ln |   -.618248   .0393979   -15.69   0.000    -.6954668   -.5410292
  PolInstab3y_o |    .015106   .0119787     1.26   0.207     -.008372     .038584
  PolInstab3y_d |   .4582655    .018217    25.16   0.000     .4225606    .4939703
WarOccurrence_o |   .0227531   .0223833     1.02   0.309    -.0211175    .0666238
WarOccurrence_d |   1.054181   .0341501    30.87   0.000     .9872481    1.121115
     Network_ln |   .0040789   .0017785     2.29   0.022      .000593    .0075648
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  2, 13302) =  3472.59
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  1, 13302) =  6826.45
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  2, 13302)  P-val | SW Chi-sq(  1) P-val | SW F(  1, 13302)
GTI_o        |    4208.97    0.0000 |     8258.42   0.0000 |     8256.56
GTI_d        |    3472.59    0.0000 |     6827.98   0.0000 |     6826.45

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                   10% maximal IV size             19.93
                                   15% maximal IV size             11.59
                                   20% maximal IV size              8.75
                                   25% maximal IV size              7.25
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(1)=1654.82  P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                   19401.88
Kleibergen-Paap Wald rk F statistic                              2954.06

Stock-Yogo weak ID test critical values for K1=2 and L1=2:
                                   10% maximal IV size              7.03
                                   15% maximal IV size              4.58
                                   20% maximal IV size              3.95
                                   25% maximal IV size              3.63
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(2,13302)=     9.91     P-val=0.0001
Anderson-Rubin Wald test           Chi-sq(2)=     19.82     P-val=0.0000
Stock-Wright LM S statistic        Chi-sq(2)=     20.30     P-val=0.0000

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =          9
Number of excluded instruments       L1 =          2

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    77.29
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =   0.0096
Total (uncentered) SS   =  170701.4477                Uncentered R2 =   0.0096
Residual SS             =    169057.27                Root MSE      =    .7118

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0094959   .0064595     1.47   0.142    -.0031656    .0221574
          GTI_d |  -.0352031   .0084481    -4.17   0.000    -.0517626   -.0186436
    GDPpc_or_ln |   .0123687   .0202239     0.61   0.541    -.0272731    .0520105
  GDPpc_dest_ln |   .1439947    .021692     6.64   0.000     .1014752    .1865142
  PolInstab3y_o |   .0065585   .0087937     0.75   0.456    -.0106784    .0237953
  PolInstab3y_d |    .033368    .008175     4.08   0.000     .0173438    .0493921
WarOccurrence_o |   .0676634   .0170512     3.97   0.000     .0342406    .1010861
WarOccurrence_d |   .0721377   .0184663     3.91   0.000      .035941    .1083343
     Network_ln |   .0248612   .0010226    24.31   0.000     .0228568    .0268655
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):           1654.817
                                                   Chi-sq(1) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):              1.9e+04
                         (Kleibergen-Paap rk Wald F statistic):       2954.056
Stock-Yogo weak ID test critical values: 10% maximal IV size              7.03
                                         15% maximal IV size              4.58
                                         20% maximal IV size              3.95
                                         25% maximal IV size              3.63
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         0.000
                                                 (equation exactly identified)
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: GTI_o_lag GTI_d_lag
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation
*/

est resto T2a
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = govfrac2020_o govfrac2020_d) if e(sample), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstfrac) // same results: good!!!!!!
est sto TIVc
mat U = e(first)
estadd scalar F_GTIo =  U[4,1] : firstfracGTI_o
estadd scalar F_GTId =  U[4,2] : firstfracGTI_d
estadd scalar df_GTIo =  U[5,1] : firstfracGTI_o
estadd scalar df_GTId =  U[5,2] : firstfracGTI_d
estadd scalar p_GTIo =  U[7,1] : firstfracGTI_o
estadd scalar p_GTId =  U[7,2] : firstfracGTI_d
estadd scalar SWF_GTIo = U[8,1] : firstfracGTI_o
estadd scalar SWF_GTId = U[8,2] : firstfracGTI_d
estadd scalar SWFdf_GTIo =  U[9,1] : firstfracGTI_o
estadd scalar SWFdf_GTId =  U[9,2] : firstfracGTI_d
estadd scalar SWFp_GTIo =  U[11,1] : firstfracGTI_o
estadd scalar SWFp_GTId = U[11,2] : firstfracGTI_d
estadd scalar SWFchi_GTIo =  U[12,1] : firstfracGTI_o
estadd scalar SWFchi_GTId =  U[12,2] : firstfracGTI_d
estadd scalar SWFchip_GTIo =U[13,1] : firstfracGTI_o
estadd scalar SWFchip_GTId =  U[13,2] : firstfracGTI_d
/*
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstfracG~o | ivreg2       GTI_o           9  First-stage regression: GTI_o
firstfracG~d | ivreg2       GTI_d           9  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
  govfrac2020_o |   1.000755   .0332417    30.11   0.000     .9356025    1.065908
  govfrac2020_d |   .0382409   .0286261     1.34   0.182    -.0178655    .0943473
    GDPpc_or_ln |   -.435702   .0459042    -9.49   0.000    -.5256728   -.3457312
  GDPpc_dest_ln |   -.007733   .0414463    -0.19   0.852    -.0889665    .0735004
  PolInstab3y_o |   .6031042   .0172759    34.91   0.000     .5692439    .6369645
  PolInstab3y_d |   .0195917   .0147306     1.33   0.184    -.0092798    .0484632
WarOccurrence_o |   1.327283   .0302176    43.92   0.000     1.268058    1.386509
WarOccurrence_d |   .0456196   .0303475     1.50   0.133    -.0138606    .1050997
     Network_ln |   .0080952   .0021428     3.78   0.000     .0038954    .0122949
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  2, 13302) =   453.36
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  1, 13302) =   896.96
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
  govfrac2020_o |   .0258524   .0274585     0.94   0.346    -.0279655    .0796702
  govfrac2020_d |   .5819641   .0301333    19.31   0.000     .5229037    .6410245
    GDPpc_or_ln |   .0475382   .0334114     1.42   0.155    -.0179472    .1130235
  GDPpc_dest_ln |  -.5058219   .0484883   -10.43   0.000    -.6008574   -.4107863
  PolInstab3y_o |   .0290547   .0129774     2.24   0.025     .0036194    .0544901
  PolInstab3y_d |   .4869835   .0193042    25.23   0.000     .4491478    .5248193
WarOccurrence_o |    .046044   .0254762     1.81   0.071    -.0038885    .0959766
WarOccurrence_d |    1.16948   .0353947    33.04   0.000     1.100108    1.238853
     Network_ln |   .0058431   .0019781     2.95   0.003      .001966    .0097202
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  2, 13302) =   186.96
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  1, 13302) =   371.26
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  2, 13302)  P-val | SW Chi-sq(  1) P-val | SW F(  1, 13302)
GTI_o        |     453.36    0.0000 |      897.16   0.0000 |      896.96
GTI_d        |     186.96    0.0000 |      371.34   0.0000 |      371.26

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                   10% maximal IV size             19.93
                                   15% maximal IV size             11.59
                                   20% maximal IV size              8.75
                                   25% maximal IV size              7.25
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(1)=332.49   P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                    1089.72
Kleibergen-Paap Wald rk F statistic                               185.62

Stock-Yogo weak ID test critical values for K1=2 and L1=2:
                                   10% maximal IV size              7.03
                                   15% maximal IV size              4.58
                                   20% maximal IV size              3.95
                                   25% maximal IV size              3.63
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(2,13302)=     3.73     P-val=0.0239
Anderson-Rubin Wald test           Chi-sq(2)=      7.47     P-val=0.0239
Stock-Wright LM S statistic        Chi-sq(2)=      7.53     P-val=0.0232

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =          9
Number of excluded instruments       L1 =          2

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    76.71
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =   0.0032
Total (uncentered) SS   =  170701.4477                Uncentered R2 =   0.0032
Residual SS             =   170158.573                Root MSE      =    .7142

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0340388   .0162417     2.10   0.036     .0022028    .0658748
          GTI_d |   -.050327   .0264757    -1.90   0.057    -.1022231     .001569
    GDPpc_or_ln |   .0246102   .0214974     1.14   0.252    -.0175278    .0667482
  GDPpc_dest_ln |   .1362783   .0254697     5.35   0.000     .0863541    .1862025
  PolInstab3y_o |  -.0080334   .0126979    -0.63   0.527    -.0329232    .0168563
  PolInstab3y_d |   .0403217   .0147148     2.74   0.006     .0114786    .0691649
WarOccurrence_o |   .0343914   .0260426     1.32   0.187    -.0166558    .0854386
WarOccurrence_d |   .0891512   .0351347     2.54   0.011     .0202822    .1580203
     Network_ln |   .0247448   .0010433    23.72   0.000     .0226998    .0267899
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):            332.491
                                                   Chi-sq(1) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):             1089.722
                         (Kleibergen-Paap rk Wald F statistic):        185.617
Stock-Yogo weak ID test critical values: 10% maximal IV size              7.03
                                         15% maximal IV size              4.58
                                         20% maximal IV size              3.95
                                         25% maximal IV size              3.63
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         0.000
                                                 (equation exactly identified)
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: govfrac2020_o govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

*/


label var GTI_o_lag "GTI o splag"
label var GTI_d_lag "GTI d splag"
label var govfrac2020_o "Gov frac o"
label var govfrac2020_d "Gov frac d"

esttab firstboth* firstGTI* firstfrac* using "Results/Revision JEBO/Table IVfirststage.tex", label title("First stage IV results") mtitles("BothIVs GTIo" "Both IVs GTId" "Lag GTI GTIo" "Lag GTI GTId" "Frac GTIo" "Frac GTId") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") obslast addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad.") ///
stats (F_GTIo F_GTId df_GTIo df_GTId SWF_GTIo SWF_GTId SWFdf_GTIo SWFdf_GTId SWFp_GTIo SWFp_GTId SWFchi_GTIo SWFchi_GTId SWFchip_GTIo SWFchip_GTId)




//---------------------------
*** Now run a spatial Durbin model where also spatially lagged terror variables are included: not significant as we want!!! Good for the empirical analysis!!!
//---------------------------
*ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d GTI_o_lag GTI_d_lag $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) // Effects become slightly less significant but survive!!! 
/*

HDFE PPML regression                              No. of obs      =    448,781
Absorbing 2 HDFE groups                           Residual df     =     14,043
Statistics robust to heteroskedasticity           Wald chi2(11)   =     355.74
Deviance             =  12317.27931               Prob > chi2     =     0.0000
Log pseudolikelihood = -22268.26112               Pseudo R2       =     0.6309

Number of clusters (FE_PPML_od)=    14,044
                           (Std. Err. adjusted for 14,044 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0367686   .0209395     1.76   0.079     -.004272    .0778092
          GTI_d |  -.0602571   .0290772    -2.07   0.038    -.1172475   -.0032668
      GTI_o_lag |  -.0010948   .0074644    -0.15   0.883    -.0157247    .0135352
      GTI_d_lag |   .0036506   .0090045     0.41   0.685     -.013998    .0212992
    GDPpc_or_ln |   .0857187   .1499317     0.57   0.568     -.208142    .3795793
  GDPpc_dest_ln |   .3158939    .168677     1.87   0.061     -.014707    .6464948
  PolInstab3y_o |  -.0383192   .0827915    -0.46   0.643    -.2005876    .1239492
  PolInstab3y_d |    .031021   .0821411     0.38   0.706    -.1299726    .1920146
WarOccurrence_o |   .4165643   .1125825     3.70   0.000     .1959067    .6372219
WarOccurrence_d |  -.2871428   .1793179    -1.60   0.109    -.6385993    .0643138
     Network_ln |   .3685758   .0263683    13.98   0.000     .3168949    .4202568
          _cons |  -7.900605   2.031709    -3.89   0.000    -11.88268   -3.918528
---------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     14044       14044           0    *|
   FE_PPML_y |        43           0          43     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation
*/

*** Actually this should be done on a subsample where we know there is no terrorism playing!!!
/*
https://www.linkedin.com/pulse/instrumental-variables-smart-way-support-exclusion-filippo-pisello/

Restricting the scope to our case, what we have to do is find an instance for which 
we can test that, assuming the exclusion restriction to be holding, the estimated 
effect of Z on Y is zero.
The "trick" consists in checking our dataset to see if there happens to be a portion 
of the population whose first stage effect, thus the impact of the instrument on the 
instrumented variable, is null or very small. Ideally, supposing a case where T is a 
binary treatment, we should identify a subsample for which the treatment status is 
always 0, as suggested by some prior information.

At this point, running the regression of the instrument (Z) on the dependent variable (Y), 
we should find no effect and this would make our assumption more trustworthy. If this is not 
the case, and our previous knowledge is well-founded, then we have shown that Z has some effect 
on Y which is not due to the variation caused on T: the exclusion restriction is endangered.
*/


preserve
est resto T1a
keep if e(sample)
keep if GTI_o==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d GTI_o_lag GTI_d_lag $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) 
est sto Placebo_lag_o
/*
HDFE PPML regression                              No. of obs      =     80,383
Absorbing 2 HDFE groups                           Residual df     =      6,282
Statistics robust to heteroskedasticity           Wald chi2(10)   =     106.53
Deviance             =  2714.688132               Prob > chi2     =     0.0000
Log pseudolikelihood = -5629.691507               Pseudo R2       =     0.6686

Number of clusters (FE_PPML_od)=     6,283
                            (Std. Err. adjusted for 6,283 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |          0  (omitted)
          GTI_d |  -.0790597   .0270573    -2.92   0.003    -.1320909   -.0260284
      GTI_o_lag |   .0053692   .0110528     0.49   0.627    -.0162939    .0270324 --> good
      GTI_d_lag |   .0057073   .0100223     0.57   0.569    -.0139361    .0253507
    GDPpc_or_ln |  -.0085238   .1158918    -0.07   0.941    -.2356676      .21862
  GDPpc_dest_ln |   .6331583   .1598501     3.96   0.000     .3198579    .9464587
  PolInstab3y_o |  -.3223215   .1288201    -2.50   0.012    -.5748042   -.0698388
  PolInstab3y_d |   .0038672   .1300906     0.03   0.976    -.2511057    .2588401
WarOccurrence_o |  -.1434789   .3573421    -0.40   0.688    -.8438566    .5568988
WarOccurrence_d |  -.7950714   .3721701    -2.14   0.033    -1.524511   -.0656314
     Network_ln |   .2004214   .0266089     7.53   0.000     .1482689    .2525739
          _cons |  -7.479221   1.780049    -4.20   0.000    -10.96805   -3.990389
---------------------------------------------------------------------------------
*/
restore

preserve
est resto T1a
keep if e(sample)
keep if GTI_d==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d GTI_o_lag GTI_d_lag $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) 
est sto Placebo_lag_d
/*
HDFE PPML regression                              No. of obs      =     81,141
Absorbing 2 HDFE groups                           Residual df     =      6,758
Statistics robust to heteroskedasticity           Wald chi2(10)   =      43.52
Deviance             =  1069.921863               Prob > chi2     =     0.0000
Log pseudolikelihood = -2655.895044               Pseudo R2       =     0.7126

Number of clusters (FE_PPML_od)=     6,759
                            (Std. Err. adjusted for 6,759 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   -.030264   .0358761    -0.84   0.399    -.1005798    .0400518
          GTI_d |          0  (omitted)
      GTI_o_lag |   .0363396   .0138936     2.62   0.009     .0091087    .0635706
      GTI_d_lag |    .021957   .0155549     1.41   0.158    -.0085301    .0524441--> good
    GDPpc_or_ln |   .3077476   .1721147     1.79   0.074    -.0295911    .6450862
  GDPpc_dest_ln |   .8914675   .2747005     3.25   0.001     .3530643    1.429871
  PolInstab3y_o |   .0168026   .1076402     0.16   0.876    -.1941683    .2277734
  PolInstab3y_d |   .1868706   .1521813     1.23   0.219    -.1113993    .4851405
WarOccurrence_o |   .1988237   .2158862     0.92   0.357    -.2243054    .6219529
WarOccurrence_d |    .342603   .4678941     0.73   0.464    -.5744526    1.259659
     Network_ln |   .2077058   .0467968     4.44   0.000     .1159857    .2994258
          _cons |  -12.66952   3.257615    -3.89   0.000    -19.05432   -6.284708
---------------------------------------------------------------------------------
*/
restore

preserve
est resto T1a
keep if e(sample)
keep if GTI_o==0 & GTI_d==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d GTI_o_lag GTI_d_lag $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) 
/*HDFE PPML regression                              No. of obs      =     18,060
Absorbing 2 HDFE groups                           Residual df     =      2,323
Statistics robust to heteroskedasticity           Wald chi2(9)    =      96.34
Deviance             =  382.9645405               Prob > chi2     =     0.0000
Log pseudolikelihood = -1168.449242               Pseudo R2       =     0.7325

Number of clusters (FE_PPML_od)=     2,324
                            (Std. Err. adjusted for 2,324 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |          0  (omitted)
          GTI_d |          0  (omitted)
      GTI_o_lag |   .0180096   .0191922     0.94   0.348    -.0196064    .0556256--> good
      GTI_d_lag |   .0099337     .01668     0.60   0.551    -.0227585     .042626--> good
    GDPpc_or_ln |   .0914412   .2379872     0.38   0.701     -.375005    .5578875
  GDPpc_dest_ln |   1.338619   .3899257     3.43   0.001     .5743785    2.102859
  PolInstab3y_o |   -.260144   .2766665    -0.94   0.347    -.8024005    .2821124
  PolInstab3y_d |   .0905284   .2259362     0.40   0.689    -.3522984    .5333551
WarOccurrence_o |  -.8470542   .6263936    -1.35   0.176    -2.074763    .3806547
WarOccurrence_d |    .038235   .5362459     0.07   0.943    -1.012788    1.089258
     Network_ln |   .1285721   .0180067     7.14   0.000     .0932796    .1638647
          _cons |  -12.43397   4.755843    -2.61   0.009    -21.75526   -3.112693
---------------------------------------------------------------------------------
*/
restore


//---------------------------
*** Now see if also this government fractionalisation also doesn't matter... (as we need to convince the reviewers of) Indeed the case!!!!
//---------------------------
*ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d govfrac_o govfrac_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) // Effects become slightly less significant but survive!!! 


*** But as explained above, different strategy needed!
preserve
est resto T1a
keep if e(sample)
keep if GTI_o==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d govfrac2020_o govfrac2020_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) // Effects become slightly less significant but survive!!! 
est sto Placebo_frac_o
/*
HDFE PPML regression                              No. of obs      =     56,499
Absorbing 2 HDFE groups                           Residual df     =      5,050
Statistics robust to heteroskedasticity           Wald chi2(10)   =      41.90
Deviance             =   1792.44761               Prob > chi2     =     0.0000
Log pseudolikelihood = -4260.038917               Pseudo R2       =     0.6529

Number of clusters (FE_PPML_od)=     5,051
                            (Std. Err. adjusted for 5,051 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |          0  (omitted)
          GTI_d |   .0140147   .0254423     0.55   0.582    -.0358513    .0638808
  govfrac2020_o |   .2072473   .3118912     0.66   0.506    -.4040482    .8185428--> good
  govfrac2020_d |  -.0104448   .2005186    -0.05   0.958     -.403454    .3825645
    GDPpc_or_ln |  -.1442664   .1071885    -1.35   0.178    -.3543519    .0658191
  GDPpc_dest_ln |      .4963   .2193724     2.26   0.024      .066338    .9262619
  PolInstab3y_o |  -.1882614   .1031485    -1.83   0.068    -.3904288     .013906
  PolInstab3y_d |  -.1592645   .1158367    -1.37   0.169    -.3863004    .0677713
WarOccurrence_o |  -1.261423   .7096217    -1.78   0.075    -2.652256    .1294096
WarOccurrence_d |  -1.299005   .5486469    -2.37   0.018    -2.374333   -.2236772
     Network_ln |   .2352796   .0505788     4.65   0.000      .136147    .3344121
          _cons |  -6.023794   2.458144    -2.45   0.014    -10.84167   -1.205919
---------------------------------------------------------------------------------
*/
restore


preserve
est resto T1a
keep if e(sample)
keep if GTI_d==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d govfrac2020_o govfrac2020_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) // Effects become slightly less significant but survive!!! 
est sto Placebo_frac_d
/*
HDFE PPML regression                              No. of obs      =     52,269
Absorbing 2 HDFE groups                           Residual df     =      5,136
Statistics robust to heteroskedasticity           Wald chi2(10)   =      53.59
Deviance             =  459.1057675               Prob > chi2     =     0.0000
Log pseudolikelihood = -1527.141433               Pseudo R2       =     0.6681

Number of clusters (FE_PPML_od)=     5,137
                            (Std. Err. adjusted for 5,137 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |  -.0612394   .0364682    -1.68   0.093    -.1327157    .0102369
          GTI_d |          0  (omitted)
  govfrac2020_o |   1.008668   .4635921     2.18   0.030     .1000442    1.917292
  govfrac2020_d |   .2805463   .3522918     0.80   0.426    -.4099329    .9710255--> good
    GDPpc_or_ln |   .0679158   .1674523     0.41   0.685    -.2602846    .3961163
  GDPpc_dest_ln |   1.190885    .347194     3.43   0.001     .5103978    1.871373
  PolInstab3y_o |  -.2123315   .1141958    -1.86   0.063    -.4361512    .0114882
  PolInstab3y_d |   .2615076    .132578     1.97   0.049     .0016595    .5213556
WarOccurrence_o |   .8822954   .2640316     3.34   0.001     .3648031    1.399788
WarOccurrence_d |   .0138898     .56078     0.02   0.980    -1.085219    1.112998
     Network_ln |   .1433458   .0507932     2.82   0.005     .0437929    .2428986
          _cons |  -13.30458   4.415436    -3.01   0.003    -21.95868   -4.650486
---------------------------------------------------------------------------------
*/
restore

preserve
est resto T1a
keep if e(sample)
keep if GTI_o==0 & GTI_d==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d govfrac2020_o govfrac2020_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) // Effects become slightly less significant but survive!!! 
/*
HDFE PPML regression                              No. of obs      =     10,276
Absorbing 2 HDFE groups                           Residual df     =      1,586
Statistics robust to heteroskedasticity           Wald chi2(9)    =      71.59
Deviance             =  136.9816826               Prob > chi2     =     0.0000
Log pseudolikelihood = -602.1442541               Pseudo R2       =     0.6792

Number of clusters (FE_PPML_od)=     1,587
                            (Std. Err. adjusted for 1,587 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |          0  (omitted)
          GTI_d |          0  (omitted)
  govfrac2020_o |      1.213   .4824527     2.51   0.012     .2674104     2.15859--> not good but sample very small!
  govfrac2020_d |  -.5426077   .3131747    -1.73   0.083    -1.156419    .0712034--> not good but sample very small!
    GDPpc_or_ln |   -.428586   .1296976    -3.30   0.001    -.6827886   -.1743834
  GDPpc_dest_ln |   .7806855   .2510365     3.11   0.002     .2886629    1.272708
  PolInstab3y_o |  -.0580893   .2700909    -0.22   0.830    -.5874578    .4712792
  PolInstab3y_d |   .3246489   .2170652     1.50   0.135    -.1007912    .7500889
WarOccurrence_o |  -.1406377   .2064871    -0.68   0.496     -.545345    .2640696
WarOccurrence_d |  -.3944204    .823933    -0.48   0.632    -2.009299    1.220459
     Network_ln |   .0737689   .0182069     4.05   0.000     .0380841    .1094538
          _cons |  -4.107801   2.971101    -1.38   0.167    -9.931051     1.71545
---------------------------------------------------------------------------------
*/
restore

esttab Placebo_lag_o Placebo_lag_d Placebo_frac_o Placebo_frac_d using "Results/Revision JEBO/Table IVplacebo.tex", label title("Placebo estimations in support of IVs") mtitles("Placebo lag o" "Placebo lag d" "Placebo frac o" "Placebo frac d") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") obslast addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad.")

tab  dummy99_o

ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)  
*** Repeat IV regressions with country-years with largest refugee flows dropped
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d) ///
if (dummy99_o==0 | dummy99_d==0), robust absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)  
est sto IVref99

ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d) ///
if (dummy90_o==0 | dummy90_d==0), robust absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)  
est sto IVref90

ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d) ///
if (dummy75_o==0 | dummy75_d==0), robust absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)  
est sto IVref75

esttab IVref99 IVref90 IVref75 using "Results/Revision JEBO/Table IVrefugees.tex", label title("IV estimates dropping large refugee flows") mtitles("1" "10" "25") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") obslast addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad.")








*******************************************************************************
*** Other robustness checks
*******************************************************************************
est resto T2a
estadd scalar idstat1 = `e(idstat)'
estadd scalar iddf1 = `e(iddf)'
estadd scalar idp1 = `e(idp)'
estadd scalar cdf1 = `e(cdf)'
estadd scalar widstat1 = `e(widstat)'
estadd scalar j1 = `e(j)'
estadd scalar jdf1 = `e(jdf)'
estadd scalar jp1 = `e(jp)'

* Drop ambiguous data //NOTE: UPDATED BY ILSE APRIL 2023!!!
preserve
tab origin if e(sample) & ambiguous_o!=1 // Drop those below 1,000obs
drop if origin=="Montenegro"
drop if origin=="Serbia"
drop if origin=="Yemen"
tab destination if e(sample) & ambiguous_d!=1
drop if destination=="Algeria"
drop if destination=="Armenia"
drop if destination=="Azerbaijan"
drop if destination=="Bosnia and Herzegovina"
drop if destination=="Iraq"
drop if destination=="Kazakhstan"
drop if destination=="Laos"
drop if destination=="Moldova"
drop if destination=="Montenegro"
drop if destination=="Morocco"
drop if destination=="Pakistan"
drop if destination=="Serbia"
drop if destination=="Suriname"
drop if destination=="Tajikistan"
drop if destination=="Turkmenistan"
drop if destination=="Uzbekistan"
drop if destination=="Yemen"
drop if ambiguous_o==1
drop if ambiguous_d==1
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T2b
restore

* Drop World Trade Center attack (outlier)
rename GTI_o GTIooriginal
rename GTI_d GTIdoriginal
rename GTI_o_1109 GTI_o
rename GTI_d_1109 GTI_d
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T2c
rename GTI_o GTI_o_1109
rename GTI_d GTI_d_1109
rename GTIooriginal GTI_o
rename GTIdoriginal GTI_d


* Conflicts v1: Drop if conflict at some point in the country
preserve
egen max_WarOccurrence_high_o = max(WarOccurrence_o), by(iso3o)
egen max_WarOccurrence_high_d = max(WarOccurrence_d), by(iso3d)
drop if WarOccurrence_o==1
drop if WarOccurrence_d==1
tab origin // 152 when WarOccurrence_high_o is dropped, 108 when max_WarOccurrence_high_o is dropped
tab destination // 155 when WarOccurrence_high_d is dropped, 111 when max_WarOccurrence_high_d is dropped
*qui ppml MigrationRateWithoutNeg GTI_o GTI_d $controlsppml o_dum* d_dum* year_dum*
/*
WARNING: Network_ln has very large values, consider rescaling  or recentering
Number of regressors excluded to ensure that the estimates exist: 175
Number of observations excluded: 0
WARNING: The model appears to overfit some observations with MigrationRateWithoutNeg=0
The warning about overfitting is important. You should estimate the model using a different base category for your dummies. 
Better, you should estimate the model including the dummies for all categories and let Stata choose which category to exclude.
https://personal.lse.ac.uk/tenreyro/Pisch.do
*/
*xi, prefix(_D) noomit i.oFE i.dFE i.yFE
*ppml MigrationRateWithoutNeg GTI_o GTI_d $controlsppml _D*

ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T2d
restore

* Conflicts v2: Interaction terms
gen interact_o= WarOccurrence_o*GTI_o
gen interact_d= WarOccurrence_d*GTI_d 
label variable interact_o "GTIxConflict o"
label variable interact_d "GTIxConflict d"
*ppml MigrationRateWithoutNeg GTI_o GTI_d interact_o interact_d dist_ln contig comlang_ethno GDPpc_or_ln GDPpc_dest_ln Network_ln PolInstab3y_o PolInstab3y_d WarOccurrence_o WarOccurrence_d o_dum* d_dum* year_dum*
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d interact_o interact_d  $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T2e

* Non-linear effect
sum GTI_o // mean is 3.413323 (updated April 2023)
sum GTI_d // mean is 3.331401 (updated April 2023)
gen GTIoCen=GTI_o - 3.413323
gen GTIdCen=GTI_d - 3.331401
gen GTIoCen_sq = GTIoCen*GTIoCen
gen GTIdCen_sq = GTIdCen*GTIdCen
label variable GTIoCen_sq "GTI o^2"
label variable GTIdCen_sq "GTI d^2"

*qui ppml MigrationRateWithoutNeg GTIoCen_sq GTIdCen_sq $controlsppml o_dum* d_dum* year_dum*
/*
WARNING: GTIoCen_sq has very large values, consider rescaling  or recentering
WARNING: GTIdCen_sq has very large values, consider rescaling  or recentering
WARNING: Network_ln has very large values, consider rescaling  or recentering
Number of regressors excluded to ensure that the estimates exist: 167
Number of observations excluded: 0
WARNING: The model appears to overfit some observations with MigrationRateWithoutNeg=0
*/
*xi, prefix(_D) noomit i.oFE i.dFE i.yFE
*ppml MigrationRateWithoutNeg GTI_o GTI_d GTIoCen_sq GTIdCen_sq $controlsppml _D*
/*
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0261338   .0084995     3.07   0.002      .009475    .0427925
          GTI_d |   -.026286   .0123805    -2.12   0.034    -.0505514   -.0020205
     GTIoCen_sq |   .0092565   .0030275     3.06   0.002     .0033227    .0151902
     GTIdCen_sq |   .0029632   .0033034     0.90   0.370    -.0035114    .0094378
        dist_ln |   -.206579   .0149248   -13.84   0.000     -.235831   -.1773269
         contig |   .1045839   .0429561     2.43   0.015     .0203914    .1887764
  comlang_ethno |   .0578872   .0311849     1.86   0.063     -.003234    .1190084
    GDPpc_or_ln |   .1149159   .0465543     2.47   0.014     .0236711    .2061606
  GDPpc_dest_ln |   .3124527   .0619208     5.05   0.000     .1910901    .4338153
     Network_ln |   .7749487   .0096284    80.49   0.000     .7560774      .79382
  PolInstab3y_o |  -.0461667   .0447622    -1.03   0.302     -.133899    .0415655
  PolInstab3y_d |   .0127033   .0792442     0.16   0.873    -.1426124     .168019
WarOccurrence_o |   .2724231   .0474312     5.74   0.000     .1794597    .3653865
WarOccurrence_d |  -.3665554   .0576114    -6.36   0.000    -.4794717   -.2536391
*/

ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d GTIoCen_sq GTIdCen_sq  $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T2f



*** Alternative to tresholds as published in Killian's dissertation (appendix table): create from the GTI instead 5 variables by splitting it
est resto T1a

xtile GTI_o_quint = GTI_o, nq(5)
xtile GTI_d_quint = GTI_d, nq(5)

forvalues k = 1/5 {
gen GTI_o_`k' = 0
replace GTI_o_`k' = GTI_o if GTI_o_quint == `k'
gen GTI_d_`k' = 0
replace GTI_d_`k' = GTI_d if GTI_d_quint == `k'
}

ppmlhdfe MigrationRateWithoutNeg GTI_o_1 GTI_o_2 GTI_o_3 GTI_o_4 GTI_o_5 GTI_d_1 GTI_d_2 GTI_d_3 GTI_d_4 GTI_d_5 /// 
$controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T2g
/*
HDFE PPML regression                              No. of obs      =    456,439
Absorbing 2 HDFE groups                           Residual df     =     14,282
Statistics robust to heteroskedasticity           Wald chi2(15)   =     392.70
Deviance             =  13015.46961               Prob > chi2     =     0.0000
Log pseudolikelihood = -23266.65341               Pseudo R2       =     0.6372

Number of clusters (FE_PPML_od)=    14,283
                           (Std. Err. adjusted for 14,283 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
        GTI_o_1 |          0  (omitted)
        GTI_o_2 |   .0106065   .0362547     0.29   0.770    -.0604515    .0816644
        GTI_o_3 |   .0076751   .0272183     0.28   0.778    -.0456718    .0610221
        GTI_o_4 |    .024359   .0211316     1.15   0.249    -.0170583    .0657763
        GTI_o_5 |   .0564986   .0190086     2.97   0.003     .0192425    .0937548
        GTI_d_1 |          0  (omitted)
        GTI_d_2 |  -.0528797   .0373558    -1.42   0.157    -.1260958    .0203363
        GTI_d_3 |  -.0611425   .0258387    -2.37   0.018    -.1117853   -.0104996
        GTI_d_4 |  -.0537551   .0193568    -2.78   0.005    -.0916937   -.0158165
        GTI_d_5 |  -.0514118   .0246185    -2.09   0.037    -.0996632   -.0031603
    GDPpc_or_ln |   .0871846   .1481115     0.59   0.556    -.2031086    .3774777
  GDPpc_dest_ln |   .2969864   .1590431     1.87   0.062    -.0147324    .6087052
  PolInstab3y_o |  -.0319203   .0818288    -0.39   0.696    -.1923017    .1284612
  PolInstab3y_d |   .0328874   .0824192     0.40   0.690    -.1286512    .1944261
WarOccurrence_o |   .3462929   .1084951     3.19   0.001     .1336465    .5589394
WarOccurrence_d |  -.4889376   .2512501    -1.95   0.052    -.9813787    .0035035
     Network_ln |    .359882   .0253381    14.20   0.000     .3102201    .4095438
          _cons |  -7.522281   2.034177    -3.70   0.000    -11.50919   -3.535368
---------------------------------------------------------------------------------
*/

esttab T2b T2c T2d T2e T2f  using "Results/Revision JEBO/Table 2.tex", label title("Alterations to the empirical sample and model specification") mtitles("GTD-obs" "Drop 9/11" "Drop conflicts" "Interaction"  "GTI^2" ) ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") ///
obslast addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad. In column 6, the variable GTI has been centred at its mean before computing its squared term in order to reduce multicollinearity.") 


********************************************************************************
************************* TABLE 3: Corridors sub-samples ***********************
********************************************************************************

* IVreg on sub-samples
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1440566-statistically-significant-squared-term-but-insignificant-level-term
* South - South
preserve
keep if GNIpc_o <= HighIncome_o & GNIpc_d <= HighIncome_d & GNIpc_o!=. & GNIpc_d!=.
*ppml MigrationRateWithoutNeg GTI_o GTI_d $controlsppml o_dum* d_dum* year_dum* // Non-significant & negative origin, significant & negative destination
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T3a
keep if e(sample)
*xi: ivreg2 MigrationRateWithoutNeg_ln $controlsppml i.oFE i.dFE i.yFE (GTI_o GTI_d = GTI_o_lag govfrac_o GTI_d_lag govfrac_d), robust // Significant (10%) & positive origin, significant & positive destination // APPENDIX
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto T4a 
restore 

* South - North (S-N) 
preserve
keep if GNIpc_o <= HighIncome_o & GNIpc_d > HighIncome_d & GNIpc_o!=. & GNIpc_d!=.
*drop if iso3d=="USA"
*ppml MigrationRateWithoutNeg GTI_o GTI_d $controlsppml o_dum* d_dum* year_dum* // Non-significant & positive origin, significant & positive destination
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T3b
keep if e(sample)
*xi: ivreg2 MigrationRateWithoutNeg_ln $controlsppml i.oFE i.dFE i.yFE (GTI_o GTI_d = GTI_o_lag govfrac_o GTI_d_lag govfrac_d), robust // Non-significant & positive origin, significant & negative destination // APPENDIX
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto T4b
restore

* North - North (N-N) 
preserve
keep if GNIpc_o > HighIncome_o & GNIpc_d > HighIncome_d & GNIpc_o!=. & GNIpc_d!=.
*drop if iso3o=="USA"
*drop if iso3d=="USA"
*ppml MigrationRateWithoutNeg GTI_o GTI_d $controlsppml o_dum* d_dum* year_dum* // Significant & positive origin, Non-significant & positive destination
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto T3c
keep if e(sample)
*xi: ivreg2 MigrationRateWithoutNeg_ln $controlsppml i.oFE i.dFE i.yFE (GTI_o GTI_d = GTI_o_lag govfrac_o GTI_d_lag govfrac_d), robust // Non-significant & negative origin, significant & negative destination // APPENDIX
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto T4c
*Test without US
drop if iso3o=="USA"
drop if iso3d=="USA"
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) // Same results
restore

/* North - South 
preserve
keep if GNIpc_o > HighIncome_o & GNIpc_d <= HighIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppml MigrationRateWithoutNeg GTI_o GTI_d $controlsppml o_dum* d_dum* year_dum* // Non-significant & positive origin, signficant & negative destination
est sto Tc4
xi: ivreg2 MigrationRateWithoutNeg_ln $controlsppml i.oFE i.dFE i.yFE (GTI_o GTI_d = GTI_o_lag govfrac_o GTI_d_lag govfrac_d), robust // Non-significant & negative origin, significant & negative destination // APPENDIX
est sto Td4
restore
*/

esttab T3a T3b T3c using "Results/Revision JEBO/Table 3.tex", label title("Corridors sub-samples") mtitles("South-South" "South-North" "North-North") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.")

esttab T4a T4b T4c using "Results/Revision JEBO/Table 4.tex", label title("Corridors sub-samples - IV approach") mtitles("South-South" "South-North" "North-North") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.") // APPENDIX


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************** ADDITIONAL FOR JEBO REVISION ****************************
********************************************************************************
*** R1.4 POPULATION-RELATED ROBUSTNESS CHECKS
***  Below are the estimates with population. We don't have to replace this as our benchmark, but it means updating EVERYTHING!!
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD PopTotal_o_ln PopTotal_d_ln, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d // Effects become slightly less significant but survive!!! 
est sto T5a
/*
(dropped 184869 observations that are either singletons or separated by a fixed effect)
HDFE PPML regression                              No. of obs      =    452,090
Absorbing 2 HDFE groups                           Residual df     =     14,139
Statistics robust to heteroskedasticity           Wald chi2(11)   =     370.57
Deviance             =  12998.45111               Prob > chi2     =     0.0000
Log pseudolikelihood = -23219.41445               Pseudo R2       =     0.6370

Number of clusters (FE_PPML_od)=    14,140
                           (Std. Err. adjusted for 14,140 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0355549    .019823     1.79   0.073    -.0032975    .0744073
          GTI_d |  -.0506074   .0240517    -2.10   0.035    -.0977479    -.003467
    GDPpc_or_ln |    .053909   .1594066     0.34   0.735    -.2585223    .3663402
  GDPpc_dest_ln |   .3083052   .1900958     1.62   0.105    -.0642757     .680886
  PolInstab3y_o |  -.0314942   .0843045    -0.37   0.709     -.196728    .1337397
  PolInstab3y_d |   .0353283   .0819508     0.43   0.666    -.1252922    .1959489
WarOccurrence_o |   .4100938   .1136746     3.61   0.000     .1872957    .6328918
WarOccurrence_d |  -.4785921   .2446234    -1.96   0.050    -.9580451    .0008609
     Network_ln |   .3663765   .0260665    14.06   0.000     .3152871    .4174659
  PopTotal_o_ln |  -.3162572   .1601911    -1.97   0.048     -.630226   -.0022883
  PopTotal_d_ln |   .1282631    .222234     0.58   0.564    -.3073075    .5638336
          _cons |  -4.898726   5.558752    -0.88   0.378    -15.79368    5.996228
---------------------------------------------------------------------------------

HDFE PPML regression                              No. of obs      =    452,090
Absorbing 2 HDFE groups                           Residual df     =     14,139
Statistics robust to heteroskedasticity           Wald chi2(11)   =     370.57
Deviance             =  12998.45111               Prob > chi2     =     0.0000
Log pseudolikelihood = -23219.41445               Pseudo R2       =     0.6370

Number of clusters (FE_PPML_od)=    14,140
                           (Std. Err. adjusted for 14,140 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0355549    .019823     1.79   0.073    -.0032975    .0744073
          GTI_d |  -.0506074   .0240517    -2.10   0.035    -.0977479    -.003467
    GDPpc_or_ln |    .053909   .1594066     0.34   0.735    -.2585223    .3663402
  GDPpc_dest_ln |   .3083052   .1900958     1.62   0.105    -.0642757     .680886
  PolInstab3y_o |  -.0314942   .0843045    -0.37   0.709     -.196728    .1337397
  PolInstab3y_d |   .0353283   .0819508     0.43   0.666    -.1252922    .1959489
WarOccurrence_o |   .4100938   .1136746     3.61   0.000     .1872957    .6328918
WarOccurrence_d |  -.4785921   .2446234    -1.96   0.050    -.9580451    .0008609
     Network_ln |   .3663765   .0260665    14.06   0.000     .3152871    .4174659
  PopTotal_o_ln |  -.3162572   .1601911    -1.97   0.048     -.630226   -.0022883
  PopTotal_d_ln |   .1282631    .222234     0.58   0.564    -.3073075    .5638336
          _cons |  -4.898726   5.558752    -0.88   0.378    -15.79368    5.996228
---------------------------------------------------------------------------------
*/

*** R1.4 Replacing our GTI by GTI per capita
ppmlhdfe MigrationRateWithoutNeg GTIpc_o GTIpc_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d // Effects become slightly less significant but survive!!! 
est sto T5b
/*
HDFE PPML regression                              No. of obs      =    448,781
Absorbing 2 HDFE groups                           Residual df     =     14,043
Statistics robust to heteroskedasticity           Wald chi2(9)    =     347.79
Deviance             =  12331.77478               Prob > chi2     =     0.0000
Log pseudolikelihood = -22275.50885               Pseudo R2       =     0.6308

Number of clusters (FE_PPML_od)=    14,044
                           (Std. Err. adjusted for 14,044 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
        GTIpc_o |   .0331012   .0187059     1.77   0.077    -.0035616     .069764
        GTIpc_d |  -.0480585   .0233635    -2.06   0.040    -.0938501   -.0022669
    GDPpc_or_ln |   .0811693    .156578     0.52   0.604    -.2257179    .3880564
  GDPpc_dest_ln |   .3435262    .170477     2.02   0.044     .0093975    .6776548
  PolInstab3y_o |  -.0372966   .0829725    -0.45   0.653    -.1999196    .1253264
  PolInstab3y_d |   .0315295   .0825721     0.38   0.703    -.1303089    .1933679
WarOccurrence_o |   .4204544   .1143221     3.68   0.000     .1963872    .6445216
WarOccurrence_d |  -.2911037   .1828893    -1.59   0.111    -.6495602    .0673528
     Network_ln |   .3678159   .0265276    13.87   0.000     .3158226    .4198091
          _cons |  -8.173478   2.138714    -3.82   0.000    -12.36528   -3.981676
---------------------------------------------------------------------------------

pwcorr GTI_o GTIpc_o GTI_d GTIpc_d if e(sample), star(0.05)
            |    GTI_o  GTIpc_o    GTI_d  GTIpc_d
-------------+------------------------------------
       GTI_o |   1.0000 
     GTIpc_o |   0.8984*  1.0000 
       GTI_d |   0.0660*  0.0875*  1.0000 
     GTIpc_d |   0.0941*  0.1172*  0.8926*  1.0000 
 
*/

*** R1.6 PARSIMONIOUS MODEL (Already integrated above)
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d
/*
HDFE PPML regression                              No. of obs      =    456,439
Absorbing 2 HDFE groups                           Residual df     =     14,282
Statistics robust to heteroskedasticity           Wald chi2(2)    =      15.30
Deviance             =  15606.59952               Prob > chi2     =     0.0005
Log pseudolikelihood = -24562.21836               Pseudo R2       =     0.6170

Number of clusters (FE_PPML_od)=    14,283
                        (Std. Err. adjusted for 14,283 clusters in FE_PPML_od)
------------------------------------------------------------------------------
             |               Robust
Migrati~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       GTI_o |   .0728578   .0266725     2.73   0.006     .0205806    .1251351
       GTI_d |  -.0505265   .0212108    -2.38   0.017    -.0920988   -.0089541
       _cons |  -.4961964   .1197309    -4.14   0.000    -.7308646   -.2615281
------------------------------------------------------------------------------
*/

*** R1.10b Alternative weights for the GTI
ppmlhdfe MigrationRateWithoutNeg GTInoweight_o GTInoweight_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d
est sto T5c
/*
HDFE PPML regression                              No. of obs      =    448,781
Absorbing 2 HDFE groups                           Residual df     =     14,043
Statistics robust to heteroskedasticity           Wald chi2(9)    =     346.89
Deviance             =  12317.03127               Prob > chi2     =     0.0000
Log pseudolikelihood = -22268.13709               Pseudo R2       =     0.6309

Number of clusters (FE_PPML_od)=    14,044
                           (Std. Err. adjusted for 14,044 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
  GTInoweight_o |   .0388194   .0191691     2.03   0.043     .0012485    .0763902
  GTInoweight_d |  -.0595142   .0242846    -2.45   0.014    -.1071113   -.0119172
    GDPpc_or_ln |   .0772813    .154299     0.50   0.616    -.2251391    .3797017
  GDPpc_dest_ln |   .3206965   .1704604     1.88   0.060    -.0133997    .6547926
  PolInstab3y_o |  -.0375433   .0836134    -0.45   0.653    -.2014225    .1263359
  PolInstab3y_d |   .0338368   .0823306     0.41   0.681    -.1275282    .1952018
WarOccurrence_o |   .4236149    .111836     3.79   0.000     .2044203    .6428095
WarOccurrence_d |  -.2918397     .18308    -1.59   0.111      -.65067    .0669905
     Network_ln |   .3682301    .026267    14.02   0.000     .3167477    .4197124
          _cons |  -7.833653   2.130635    -3.68   0.000    -12.00962   -3.657686
---------------------------------------------------------------------------------
*/

*** R1.3 Alternative dependent variable dropping negative values 
gen MigrationRateNegDrop=Flow/Natives_o
replace MigrationRateNegDrop = . if Flow < 0

ppmlhdfe MigrationRateNegDrop GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d 
est sto T5d
/*
HDFE PPML regression                              No. of obs      =    380,902
Absorbing 2 HDFE groups                           Residual df     =     14,261
Statistics robust to heteroskedasticity           Wald chi2(9)    =     210.42
Deviance             =  7.144322612               Prob > chi2     =     0.0000
Log pseudolikelihood =  -98.1284257               Pseudo R2       =     0.2970

Number of clusters (FE_PPML_od)=    14,262
                           (Std. Err. adjusted for 14,262 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationRate~p |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0473525   .0151531     3.12   0.002      .017653     .077052 --> fine
          GTI_d |  -.0417144   .0160329    -2.60   0.009    -.0731383   -.0102906 --> fine
    GDPpc_or_ln |   -.004202   .0909549    -0.05   0.963    -.1824704    .1740663
  GDPpc_dest_ln |   .3075287   .1224143     2.51   0.012      .067601    .5474564
  PolInstab3y_o |  -.0270501   .0552908    -0.49   0.625     -.135418    .0813178
  PolInstab3y_d |   .0672947   .0740976     0.91   0.364    -.0779339    .2125234
WarOccurrence_o |   .1820805   .0853554     2.13   0.033      .014787    .3493741
WarOccurrence_d |  -.3677575   .2306311    -1.59   0.111    -.8197861    .0842711
     Network_ln |   .3095971   .0280364    11.04   0.000     .2546468    .3645473
          _cons |  -13.08232   1.420767    -9.21   0.000    -15.86697   -10.29767
---------------------------------------------------------------------------------
*/

*** R1.3 Alternative dependent variable adding negative values to the opposite corridor
ppmlhdfe MigrationRateWithNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d 

/*
HDFE PPML regression                              No. of obs      =    456,439
Absorbing 2 HDFE groups                           Residual df     =     14,282
Statistics robust to heteroskedasticity           Wald chi2(9)    =      29.04
Deviance             =  25.81390139               Prob > chi2     =     0.0006
Log pseudolikelihood =  -140.882644               Pseudo R2       =     0.3254

Number of clusters (FE_PPML_od)=    14,283
                           (Std. Err. adjusted for 14,283 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~hNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0715715   .0260874     2.74   0.006     .0204411     .122702
          GTI_d |  -.0416639   .0390161    -1.07   0.286    -.1181341    .0348064 --> becomes insignificant so not ideal!
    GDPpc_or_ln |  -.0373134   .1312555    -0.28   0.776    -.2945694    .2199426
  GDPpc_dest_ln |   .0343268   .1933161     0.18   0.859    -.3445657    .4132194
  PolInstab3y_o |  -.0997497   .0760485    -1.31   0.190     -.248802    .0493027
  PolInstab3y_d |   .0789972   .0940524     0.84   0.401    -.1053422    .2633366
WarOccurrence_o |   .3558559    .150966     2.36   0.018     .0599679    .6517438
WarOccurrence_d |  -.2930805   .2685239    -1.09   0.275    -.8193777    .2332166
     Network_ln |   .1263944   .0396276     3.19   0.001     .0487257    .2040632
          _cons |  -7.622224   2.116061    -3.60   0.000    -11.76963   -3.474821
---------------------------------------------------------------------------------
*/

esttab T2g T5b T5c  T5a T5d  using "Results/Revision JEBO/Table 5.tex", label title("Alterations to the empirical sample and model specification II") mtitles("GTI quintiles" "GTI pc" "GTI unweighted" "Adding pop" "Dropping neg mig") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") ///
obslast addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad. In column 6, the variable GTI has been centred at its mean before computing its squared term in order to reduce multicollinearity.") 



********************************************************************************************
********************************************* IV *******************************************
********************************************************************************************
*** R1.8 Reproduce all their main findings (Table 1) using their IV-approach.
* ORIGINAL IV ESTIMATION FOR OUR BENCHMARK MODEL
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstbothb) // same results: good!!!!!!
est sto TIVb
mat Xb = e(first)
estadd scalar F_GTIo =  Xb[4,1] : firstbothbGTI_o
estadd scalar F_GTId =  Xb[4,2] : firstbothbGTI_d
estadd scalar df_GTIo =  Xb[5,1] : firstbothbGTI_o
estadd scalar df_GTId =  Xb[5,2] : firstbothbGTI_d
estadd scalar p_GTIo =  Xb[7,1] : firstbothbGTI_o
estadd scalar p_GTId =  Xb[7,2] : firstbothbGTI_d
estadd scalar SWF_GTIo = Xb[8,1] : firstbothbGTI_o
estadd scalar SWF_GTId = Xb[8,2] : firstbothbGTI_d
estadd scalar SWFdf_GTIo =  Xb[9,1] : firstbothbGTI_o
estadd scalar SWFdf_GTId =  Xb[9,2] : firstbothbGTI_d
estadd scalar SWFp_GTIo =  Xb[11,1] : firstbothbGTI_o
estadd scalar SWFp_GTId = Xb[11,2] : firstbothbGTI_d
estadd scalar SWFchi_GTIo =  Xb[12,1] : firstbothbGTI_o
estadd scalar SWFchi_GTId =  Xb[12,2] : firstbothbGTI_d
estadd scalar SWFchip_GTIo =Xb[13,1] : firstbothbGTI_o
estadd scalar SWFchip_GTId =  Xb[13,2] : firstbothbGTI_d

* Same for parsimoneous model
ivreghdfe MigrationRateWithoutNeg_ln (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstbotha) // same results: good!!!!!!
est sto TIVa
mat Xa = e(first)
estadd scalar F_GTIo =  Xa[4,1] : firstbothaGTI_o
estadd scalar F_GTId =  Xa[4,2] : firstbothaGTI_d
estadd scalar df_GTIo =  Xa[5,1] : firstbothaGTI_o
estadd scalar df_GTId =  Xa[5,2] : firstbothaGTI_d
estadd scalar p_GTIo =  Xa[7,1] : firstbothaGTI_o
estadd scalar p_GTId =  Xa[7,2] : firstbothaGTI_d
estadd scalar SWF_GTIo = Xa[8,1] : firstbothaGTI_o
estadd scalar SWF_GTId = Xa[8,2] : firstbothaGTI_d
estadd scalar SWFdf_GTIo =  Xa[9,1] : firstbothaGTI_o
estadd scalar SWFdf_GTId =  Xa[9,2] : firstbothaGTI_d
estadd scalar SWFp_GTIo =  Xa[11,1] : firstbothaGTI_o
estadd scalar SWFp_GTId = Xa[11,2] : firstbothaGTI_d
estadd scalar SWFchi_GTIo =  Xa[12,1] : firstbothaGTI_o
estadd scalar SWFchi_GTId =  Xa[12,2] : firstbothaGTI_d
estadd scalar SWFchip_GTIo =Xa[13,1] : firstbothaGTI_o
estadd scalar SWFchip_GTId =  Xa[13,2] : firstbothaGTI_d
rename GTI_o GTIooriginal
rename GTI_d GTIdoriginal

* Terror Occurrence
rename AttackOccurrence_o GTI_o
rename AttackOccurrence_d GTI_d
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstbothc) // same results: good!!!!!!
est sto TIVc
mat Xc = e(first)
estadd scalar F_GTIo =  Xc[4,1] : firstbothcGTI_o
estadd scalar F_GTId =  Xc[4,2] : firstbothcGTI_d
estadd scalar df_GTIo =  Xc[5,1] : firstbothcGTI_o
estadd scalar df_GTId =  Xc[5,2] : firstbothcGTI_d
estadd scalar p_GTIo =  Xc[7,1] : firstbothcGTI_o
estadd scalar p_GTId =  Xc[7,2] : firstbothcGTI_d
estadd scalar SWF_GTIo = Xc[8,1] : firstbothcGTI_o
estadd scalar SWF_GTId = Xc[8,2] : firstbothcGTI_d
estadd scalar SWFdf_GTIo =  Xc[9,1] : firstbothcGTI_o
estadd scalar SWFdf_GTId =  Xc[9,2] : firstbothcGTI_d
estadd scalar SWFp_GTIo =  Xc[11,1] : firstbothcGTI_o
estadd scalar SWFp_GTId = Xc[11,2] : firstbothcGTI_d
estadd scalar SWFchi_GTIo =  Xc[12,1] : firstbothcGTI_o
estadd scalar SWFchi_GTId =  Xc[12,2] : firstbothcGTI_d
estadd scalar SWFchip_GTIo =Xc[13,1] : firstbothcGTI_o
estadd scalar SWFchip_GTId =  Xc[13,2] : firstbothcGTI_d
rename GTI_o AttackOccurrence_o
rename GTI_d AttackOccurrence_d

* Attacks index
rename AttacksIndex_o GTI_o
rename AttacksIndex_d GTI_d
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstbothd) // same results: good!!!!!!
est sto TIVd
mat Xd = e(first)
estadd scalar F_GTIo =  Xd[4,1] : firstbothdGTI_o
estadd scalar F_GTId =  Xd[4,2] : firstbothdGTI_d
estadd scalar df_GTIo =  Xd[5,1] : firstbothdGTI_o
estadd scalar df_GTId =  Xd[5,2] : firstbothdGTI_d
estadd scalar p_GTIo =  Xd[7,1] : firstbothdGTI_o
estadd scalar p_GTId =  Xd[7,2] : firstbothdGTI_d
estadd scalar SWF_GTIo = Xd[8,1] : firstbothdGTI_o
estadd scalar SWF_GTId = Xd[8,2] : firstbothdGTI_d
estadd scalar SWFdf_GTIo =  Xd[9,1] : firstbothdGTI_o
estadd scalar SWFdf_GTId =  Xd[9,2] : firstbothdGTI_d
estadd scalar SWFp_GTIo =  Xd[11,1] : firstbothdGTI_o
estadd scalar SWFp_GTId = Xd[11,2] : firstbothdGTI_d
estadd scalar SWFchi_GTIo =  Xd[12,1] : firstbothdGTI_o
estadd scalar SWFchi_GTId =  Xd[12,2] : firstbothdGTI_d
estadd scalar SWFchip_GTIo =Xd[13,1] : firstbothdGTI_o
estadd scalar SWFchip_GTId =  Xd[13,2] : firstbothdGTI_d
rename GTI_o AttacksIndex_o
rename GTI_d AttacksIndex_d

* Victims
rename VictimsIndex_o GTI_o
rename VictimsIndex_d GTI_d
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstbothe) // same results: good!!!!!!
est sto TIVe
mat Xe = e(first)
estadd scalar F_GTIo =  Xe[4,1] : firstbotheGTI_o
estadd scalar F_GTId =  Xe[4,2] : firstbotheGTI_d
estadd scalar df_GTIo =  Xe[5,1] : firstbotheGTI_o
estadd scalar df_GTId =  Xe[5,2] : firstbotheGTI_d
estadd scalar p_GTIo =  Xe[7,1] : firstbotheGTI_o
estadd scalar p_GTId =  Xe[7,2] : firstbotheGTI_d
estadd scalar SWF_GTIo = Xe[8,1] : firstbotheGTI_o
estadd scalar SWF_GTId = Xe[8,2] : firstbotheGTI_d
estadd scalar SWFdf_GTIo =  Xe[9,1] : firstbotheGTI_o
estadd scalar SWFdf_GTId =  Xe[9,2] : firstbotheGTI_d
estadd scalar SWFp_GTIo =  Xe[11,1] : firstbotheGTI_o
estadd scalar SWFp_GTId = Xe[11,2] : firstbotheGTI_d
estadd scalar SWFchi_GTIo =  Xe[12,1] : firstbotheGTI_o
estadd scalar SWFchi_GTId =  Xe[12,2] : firstbotheGTI_d
estadd scalar SWFchip_GTIo =Xe[13,1] : firstbotheGTI_o
estadd scalar SWFchip_GTId =  Xe[13,2] : firstbotheGTI_d
rename GTI_o VictimsIndex_o
rename GTI_d VictimsIndex_d

* Bombings
rename BombingIndex_o GTI_o
rename BombingIndex_d GTI_d
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(firstbothf) // same results: good!!!!!!
est sto TIVf
mat Xf = e(first)
estadd scalar F_GTIo =  Xf[4,1] : firstbothfGTI_o
estadd scalar F_GTId =  Xf[4,2] : firstbothfGTI_d
estadd scalar df_GTIo =  Xf[5,1] : firstbothfGTI_o
estadd scalar df_GTId =  Xf[5,2] : firstbothfGTI_d
estadd scalar p_GTIo =  Xf[7,1] : firstbothfGTI_o
estadd scalar p_GTId =  Xf[7,2] : firstbothfGTI_d
estadd scalar SWF_GTIo = Xf[8,1] : firstbothfGTI_o
estadd scalar SWF_GTId = Xf[8,2] : firstbothfGTI_d
estadd scalar SWFdf_GTIo =  Xf[9,1] : firstbothfGTI_o
estadd scalar SWFdf_GTId =  Xf[9,2] : firstbothfGTI_d
estadd scalar SWFp_GTIo =  Xf[11,1] : firstbothfGTI_o
estadd scalar SWFp_GTId = Xf[11,2] : firstbothfGTI_d
estadd scalar SWFchi_GTIo =  Xf[12,1] : firstbothfGTI_o
estadd scalar SWFchi_GTId =  Xf[12,2] : firstbothfGTI_d
estadd scalar SWFchip_GTIo =Xf[13,1] : firstbothfGTI_o
estadd scalar SWFchip_GTId =  Xf[13,2] : firstbothfGTI_d
rename GTI_o BombingIndex_o
rename GTI_d BombingIndex_d
rename GTIooriginal GTI_o
rename GTIdoriginal GTI_d

label variable GTI_o "Terror o"
label variable GTI_d "Terror d"

esttab  TIVa TIVb TIVc TIVd TIVe TIVf using "Results/Revision JEBO/Table IV.tex", label title("Impact of terrorist attacks on global bilateral migration rates - IV") /// 
mtitles("Parsimonious" "Benchmark" "Terror occurrence" "Attacks index" "Victims index" "Bombings index") nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers ///
t(2) b(3) nogaps scalars("ll Log likelihood" "idstat KP LM stat" "iddf Chi-sq(X)" "idp p-val" "cdf CD Wald F" "widstat KP Wald F" "j Hansen J" "jdf Chi-sq(X)" "jp p-val") obslast ///
addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad.")


esttab firstbotha* firstbothb* firstbothc* using "Results/Revision JEBO/Table IV_firststageA_full.tex", label title("First stage IV results") mtitles("Parsimonious" "Parsimonious" "Benchmark" "Benchmark" "Terror occurrence" "Terror occurrence" ) ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") obslast addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad.") ///
stats (F_GTIo F_GTId df_GTIo df_GTId SWF_GTIo SWF_GTId SWFdf_GTIo SWFdf_GTId SWFp_GTIo SWFp_GTId SWFchi_GTIo SWFchi_GTId SWFchip_GTIo SWFchip_GTId)

esttab firstbothd* firstbothe* firstbothf* using "Results/Revision JEBO/Table IV_firststageB_full.tex", label title("First stage IV results") mtitles("Attacks index" "Attacks index" "Victims index" "Victims index" "Bombings index" "Bombings index") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps scalars("ll Log likelihood") obslast addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by dyad.") ///
stats (F_GTIo F_GTId df_GTIo df_GTId SWF_GTIo SWF_GTId SWFdf_GTIo SWFdf_GTId SWFp_GTIo SWFp_GTId SWFchi_GTIo SWFchi_GTId SWFchip_GTIo SWFchip_GTId)




label variable GTI_o "GTI o"
label variable GTI_d "GTI d"

/*
. ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_
> lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst sa
> vefprefix(firstboth) // same results: good!!!!!!
(dropped 45 singleton observations)
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstbothG~o | ivreg2       GTI_o          11  First-stage regression: GTI_o
firstbothG~d | ivreg2       GTI_d          11  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .1090725   .0012314    88.57   0.000     .1066589     .111486
  govfrac2020_o |   .8002715   .0296808    26.96   0.000      .742098    .8584451
      GTI_d_lag |   .0043208   .0014225     3.04   0.002     .0015328    .0071089
  govfrac2020_d |   .0150639   .0250327     0.60   0.547    -.0339994    .0641273
    GDPpc_or_ln |  -.5754646   .0332758   -17.29   0.000    -.6406842    -.510245
  GDPpc_dest_ln |   .0024532   .0329338     0.07   0.941    -.0620962    .0670025
  PolInstab3y_o |   .5736646   .0161534    35.51   0.000     .5420045    .6053248
  PolInstab3y_d |   .0069798   .0132838     0.53   0.599     -.019056    .0330156
WarOccurrence_o |   1.202211    .030014    40.06   0.000     1.143385    1.261038
WarOccurrence_d |    .035713   .0263121     1.36   0.175    -.0158579    .0872839
     Network_ln |   .0068141   .0018988     3.59   0.000     .0030925    .0105356
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  2203.77
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2880.05
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0033009    .001365     2.42   0.016     .0006256    .0059762
  govfrac2020_o |   .0152631   .0242497     0.63   0.529    -.0322656    .0627918
      GTI_d_lag |   .1037854   .0012626    82.20   0.000     .1013106    .1062601
  govfrac2020_d |   .4057364   .0268828    15.09   0.000      .353047    .4584258
    GDPpc_or_ln |   .0394167   .0276784     1.42   0.154    -.0148322    .0936657
  GDPpc_dest_ln |  -.6048366   .0389948   -15.51   0.000    -.6812653   -.5284079
  PolInstab3y_o |   .0150739   .0119396     1.26   0.207    -.0083273    .0384751
  PolInstab3y_d |   .4556392   .0178464    25.53   0.000     .4206608    .4906175
WarOccurrence_o |   .0225867   .0222199     1.02   0.309    -.0209636     .066137
WarOccurrence_d |   1.035103   .0338287    30.60   0.000     .9687993    1.101406
     Network_ln |   .0037706   .0017708     2.13   0.033     .0002998    .0072414
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  1724.68
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2263.13
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  4, 13302)  P-val | SW Chi-sq(  3) P-val | SW F(  3, 13302)
GTI_o        |    2203.77    0.0000 |     8642.14   0.0000 |     2880.05
GTI_d        |    1724.68    0.0000 |     6790.95   0.0000 |     2263.13

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                    5% maximal IV relative bias    16.85
                                   10% maximal IV relative bias    10.27
                                   20% maximal IV relative bias     6.71
                                   30% maximal IV relative bias     5.34
                                   10% maximal IV size             24.58
                                   15% maximal IV size             13.96
                                   20% maximal IV size             10.26
                                   25% maximal IV size              8.31
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(3)=1839.21  P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                   10180.99
Kleibergen-Paap Wald rk F statistic                              1560.85

Stock-Yogo weak ID test critical values for K1=2 and L1=4:
                                    5% maximal IV relative bias    11.04
                                   10% maximal IV relative bias     7.56
                                   20% maximal IV relative bias     5.57
                                   30% maximal IV relative bias     4.73
                                   10% maximal IV size             16.87
                                   15% maximal IV size              9.93
                                   20% maximal IV size              7.54
                                   25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(4,13302)=     6.00     P-val=0.0001
Anderson-Rubin Wald test           Chi-sq(4)=     24.01     P-val=0.0001
Stock-Wright LM S statistic        Chi-sq(4)=     24.46     P-val=0.0001

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =         11
Number of excluded instruments       L1 =          4

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    77.42
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =   0.0094
Total (uncentered) SS   =  170701.4477                Uncentered R2 =   0.0094
Residual SS             =  169096.7373                Root MSE      =    .7119

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0121152   .0062827     1.93   0.054    -.0001998    .0244302
          GTI_d |  -.0359705    .008426    -4.27   0.000    -.0524867   -.0194542
    GDPpc_or_ln |   .0136359   .0202155     0.67   0.500    -.0259894    .0532612
  GDPpc_dest_ln |   .1436143   .0216888     6.62   0.000     .1011011    .1861275
  PolInstab3y_o |   .0049762   .0087505     0.57   0.570     -.012176    .0221285
  PolInstab3y_d |    .033694   .0081636     4.13   0.000     .0176923    .0496958
WarOccurrence_o |   .0640726   .0168127     3.81   0.000     .0311174    .0970278
WarOccurrence_d |   .0729378   .0184336     3.96   0.000     .0368053    .1090702
     Network_ln |   .0248434   .0010224    24.30   0.000     .0228393    .0268475
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):           1839.215
                                                   Chi-sq(3) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):              1.0e+04
                         (Kleibergen-Paap rk Wald F statistic):       1560.846
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         2.475
                                                   Chi-sq(2) P-val =    0.2901
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

. est sto TIVb

. estadd scalar idstat1 = `e(idstat)'

added scalar:
            e(idstat1) =  1839.2146

. estadd scalar iddf1 = `e(iddf)'

added scalar:
              e(iddf1) =  3

. estadd scalar idp1 = `e(idp)'

added scalar:
               e(idp1) =  0

. estadd scalar cdf1 = `e(cdf)'

added scalar:
               e(cdf1) =  10180.992

. estadd scalar widstat1 = `e(widstat)'

added scalar:
           e(widstat1) =  1560.8459

. estadd scalar j1 = `e(j)'

added scalar:
                 e(j1) =  2.4749189

. estadd scalar jdf1 = `e(jdf)'

added scalar:
               e(jdf1) =  2

. estadd scalar jp1 = `e(jp)'

added scalar:
                e(jp1) =  .29012034

. 
. * Same for parsimoneous model
. ivreghdfe MigrationRateWithoutNeg_ln (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2
> 020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst savefprefix(fi
> rstboth) // same results: good!!!!!!
(dropped 45 singleton observations)
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstbothG~o | ivreg2       GTI_o           4  First-stage regression: GTI_o
firstbothG~d | ivreg2       GTI_d           4  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
-------------------------------------------------------------------------------
              |               Robust
        GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
--------------+----------------------------------------------------------------
    GTI_o_lag |   .1104043   .0012769    86.46   0.000     .1079016     .112907
govfrac2020_o |   .9113672   .0325549    27.99   0.000     .8475605    .9751739
    GTI_d_lag |   .0051258   .0015025     3.41   0.001     .0021809    .0080707
govfrac2020_d |   .0169955   .0263986     0.64   0.520    -.0347451     .068736
-------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  2098.21
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2747.05
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
-------------------------------------------------------------------------------
              |               Robust
        GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
--------------+----------------------------------------------------------------
    GTI_o_lag |   .0037393   .0014162     2.64   0.008     .0009637     .006515
govfrac2020_o |   .0129462   .0250687     0.52   0.606    -.0361879    .0620802
    GTI_d_lag |    .105275   .0012757    82.52   0.000     .1027746    .1077755
govfrac2020_d |   .4719645   .0283525    16.65   0.000     .4163944    .5275347
-------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  1736.63
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2279.68
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  4, 13302)  P-val | SW Chi-sq(  3) P-val | SW F(  3, 13302)
GTI_o        |    2098.21    0.0000 |     8242.88   0.0000 |     2747.05
GTI_d        |    1736.63    0.0000 |     6840.49   0.0000 |     2279.68

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                    5% maximal IV relative bias    16.85
                                   10% maximal IV relative bias    10.27
                                   20% maximal IV relative bias     6.71
                                   30% maximal IV relative bias     5.34
                                   10% maximal IV size             24.58
                                   15% maximal IV size             13.96
                                   20% maximal IV size             10.26
                                   25% maximal IV size              8.31
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(3)=1956.81  P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                   10224.80
Kleibergen-Paap Wald rk F statistic                              1558.44

Stock-Yogo weak ID test critical values for K1=2 and L1=4:
                                    5% maximal IV relative bias    11.04
                                   10% maximal IV relative bias     7.56
                                   20% maximal IV relative bias     5.57
                                   30% maximal IV relative bias     4.73
                                   10% maximal IV size             16.87
                                   15% maximal IV size              9.93
                                   20% maximal IV size              7.54
                                   25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(4,13302)=     5.26     P-val=0.0003
Anderson-Rubin Wald test           Chi-sq(4)=     21.04     P-val=0.0003
Stock-Wright LM S statistic        Chi-sq(4)=     20.88     P-val=0.0003

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          2
Number of endogenous regressors      K1 =          2
Number of instruments                L  =          4
Number of excluded instruments       L1 =          4

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  2, 13302) =     9.20
                                                      Prob > F      =   0.0001
Total (centered) SS     =  170701.4477                Centered R2   =  -0.0019
Total (uncentered) SS   =  170701.4477                Uncentered R2 =  -0.0019
Residual SS             =  171023.5824                Root MSE      =     .716

------------------------------------------------------------------------------
             |               Robust
Migr~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       GTI_o |   .0149914   .0061565     2.44   0.015     .0029237    .0270591
       GTI_d |  -.0292532   .0083374    -3.51   0.000    -.0455957   -.0129107
------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):           1956.808
                                                   Chi-sq(3) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):              1.0e+04
                         (Kleibergen-Paap rk Wald F statistic):       1558.440
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         3.309
                                                   Chi-sq(2) P-val =    0.1912
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Excluded instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

. est sto TIVa

. estadd scalar idstat1 = `e(idstat)'

added scalar:
            e(idstat1) =  1956.8085

. estadd scalar iddf1 = `e(iddf)'

added scalar:
              e(iddf1) =  3

. estadd scalar idp1 = `e(idp)'

added scalar:
               e(idp1) =  0

. estadd scalar cdf1 = `e(cdf)'

added scalar:
               e(cdf1) =  10224.8

. estadd scalar widstat1 = `e(widstat)'

added scalar:
           e(widstat1) =  1558.4405

. estadd scalar j1 = `e(j)'

added scalar:
                 e(j1) =  3.3085812

. estadd scalar jdf1 = `e(jdf)'

added scalar:
               e(jdf1) =  2

. estadd scalar jp1 = `e(jp)'

added scalar:
                e(jp1) =  .19122767

. rename GTI_o GTIooriginal

. rename GTI_d GTIdoriginal

. 
. * Terror Occurrence
. rename AttackOccurrence_o GTI_o

. rename AttackOccurrence_d GTI_d

. ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_
> lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst sa
> vefprefix(firstboth) // same results: good!!!!!!
(dropped 45 singleton observations)
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstbothG~o | ivreg2       GTI_o          11  First-stage regression: GTI_o
firstbothG~d | ivreg2       GTI_d          11  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0141146   .0002933    48.13   0.000     .0135398    .0146894
  govfrac2020_o |   .0724234   .0050933    14.22   0.000     .0624406    .0824062
      GTI_d_lag |   .0008791   .0002775     3.17   0.002     .0003352    .0014231
  govfrac2020_d |   .0007324   .0051708     0.14   0.887    -.0094022     .010867
    GDPpc_or_ln |  -.1249867   .0068815   -18.16   0.000    -.1384742   -.1114991
  GDPpc_dest_ln |    .000713   .0066525     0.11   0.915    -.0123257    .0137516
  PolInstab3y_o |   .0688079   .0027808    24.74   0.000     .0633577    .0742581
  PolInstab3y_d |   .0019582   .0027449     0.71   0.476    -.0034216    .0073381
WarOccurrence_o |   .0231604   .0036841     6.29   0.000     .0159397     .030381
WarOccurrence_d |   .0058516   .0051667     1.13   0.257     -.004275    .0159781
     Network_ln |   .0007473   .0003992     1.87   0.061    -.0000352    .0015297
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =   658.45
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =   842.50
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0004181   .0002829     1.48   0.139    -.0001363    .0009725
  govfrac2020_o |   .0032849   .0053616     0.61   0.540    -.0072237    .0137935
      GTI_d_lag |   .0131002   .0003082    42.50   0.000     .0124961    .0137044
  govfrac2020_d |  -.0017855    .005348    -0.33   0.738    -.0122675    .0086965
    GDPpc_or_ln |    .007821   .0060821     1.29   0.198    -.0040997    .0197417
  GDPpc_dest_ln |  -.1962845   .0081824   -23.99   0.000    -.2123218   -.1802471
  PolInstab3y_o |   .0009732   .0027264     0.36   0.721    -.0043705    .0063169
  PolInstab3y_d |   .0540657   .0030262    17.87   0.000     .0481345    .0599969
WarOccurrence_o |   .0055763   .0046721     1.19   0.233    -.0035809    .0147334
WarOccurrence_d |   .0029414   .0044011     0.67   0.504    -.0056847    .0115675
     Network_ln |   .0010021   .0003985     2.51   0.012      .000221    .0017831
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =   459.67
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =   596.77
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  4, 13302)  P-val | SW Chi-sq(  3) P-val | SW F(  3, 13302)
GTI_o        |     658.45    0.0000 |     2528.09   0.0000 |      842.50
GTI_d        |     459.67    0.0000 |     1790.72   0.0000 |      596.77

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                    5% maximal IV relative bias    16.85
                                   10% maximal IV relative bias    10.27
                                   20% maximal IV relative bias     6.71
                                   30% maximal IV relative bias     5.34
                                   10% maximal IV size             24.58
                                   15% maximal IV size             13.96
                                   20% maximal IV size             10.26
                                   25% maximal IV size              8.31
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(3)=854.47   P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                    2848.33
Kleibergen-Paap Wald rk F statistic                               440.52

Stock-Yogo weak ID test critical values for K1=2 and L1=4:
                                    5% maximal IV relative bias    11.04
                                   10% maximal IV relative bias     7.56
                                   20% maximal IV relative bias     5.57
                                   30% maximal IV relative bias     4.73
                                   10% maximal IV size             16.87
                                   15% maximal IV size              9.93
                                   20% maximal IV size              7.54
                                   25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(4,13302)=     6.00     P-val=0.0001
Anderson-Rubin Wald test           Chi-sq(4)=     24.01     P-val=0.0001
Stock-Wright LM S statistic        Chi-sq(4)=     24.46     P-val=0.0001

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =         11
Number of excluded instruments       L1 =          4

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    76.47
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =  -0.0035
Total (uncentered) SS   =  170701.4477                Uncentered R2 =  -0.0035
Residual SS             =   171305.617                Root MSE      =    .7166

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0903197   .0502666     1.80   0.072      -.00821    .1888494
          GTI_d |  -.2851581   .0684106    -4.17   0.000    -.4192526   -.1510636
    GDPpc_or_ln |   .0187062   .0206448     0.91   0.365    -.0217605    .0591729
  GDPpc_dest_ln |   .1097897   .0249532     4.40   0.000     .0608779    .1587015
  PolInstab3y_o |   .0054877   .0087215     0.63   0.529    -.0116078    .0225831
  PolInstab3y_d |   .0325122   .0080982     4.01   0.000     .0166386    .0483857
WarOccurrence_o |   .0775921   .0150591     5.15   0.000     .0480741      .10711
WarOccurrence_d |    .035636   .0169251     2.11   0.035     .0024604    .0688116
     Network_ln |   .0249982   .0010348    24.16   0.000     .0229698    .0270267
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):            854.472
                                                   Chi-sq(3) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):             2848.328
                         (Kleibergen-Paap rk Wald F statistic):        440.521
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         5.012
                                                   Chi-sq(2) P-val =    0.0816
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

. est sto TIVc

. estadd scalar idstat1 = `e(idstat)'

added scalar:
            e(idstat1) =  854.47155

. estadd scalar iddf1 = `e(iddf)'

added scalar:
              e(iddf1) =  3

. estadd scalar idp1 = `e(idp)'

added scalar:
               e(idp1) =  6.64e-185

. estadd scalar cdf1 = `e(cdf)'

added scalar:
               e(cdf1) =  2848.3282

. estadd scalar widstat1 = `e(widstat)'

added scalar:
           e(widstat1) =  440.5206

. estadd scalar j1 = `e(j)'

added scalar:
                 e(j1) =  5.0116847

. estadd scalar jdf1 = `e(jdf)'

added scalar:
               e(jdf1) =  2

. estadd scalar jp1 = `e(jp)'

added scalar:
                e(jp1) =  .08160683

. rename GTI_o AttackOccurrence_o

. rename GTI_d AttackOccurrence_d

. 
. * Attacks index
. rename AttacksIndex_o GTI_o

. rename AttacksIndex_d GTI_d

. ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_
> lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst sa
> vefprefix(firstboth) // same results: good!!!!!!
(dropped 45 singleton observations)
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstbothG~o | ivreg2       GTI_o          11  First-stage regression: GTI_o
firstbothG~d | ivreg2       GTI_d          11  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .1030266   .0011216    91.86   0.000     .1008283    .1052249
  govfrac2020_o |   .8885925   .0284224    31.26   0.000     .8328855    .9442995
      GTI_d_lag |   .0037227   .0013476     2.76   0.006     .0010813     .006364
  govfrac2020_d |   .0195065   .0234664     0.83   0.406    -.0264871       .0655
    GDPpc_or_ln |  -.3846961   .0277769   -13.85   0.000     -.439138   -.3302541
  GDPpc_dest_ln |   .0217857   .0316011     0.69   0.491    -.0401515    .0837229
  PolInstab3y_o |   .5553992   .0150772    36.84   0.000     .5258483      .58495
  PolInstab3y_d |   .0056933   .0122004     0.47   0.641    -.0182192    .0296058
WarOccurrence_o |   1.041309   .0281736    36.96   0.000     .9860898    1.096528
WarOccurrence_d |   .0231193   .0241548     0.96   0.339    -.0242235    .0704621
     Network_ln |   .0070771   .0017174     4.12   0.000     .0037111    .0104431
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  2453.24
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  3229.36
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0029388   .0013166     2.23   0.026     .0003583    .0055193
  govfrac2020_o |   .0194779   .0229623     0.85   0.396    -.0255276    .0644833
      GTI_d_lag |   .0997415   .0011374    87.70   0.000     .0975123    .1019707
  govfrac2020_d |   .5176285   .0250877    20.63   0.000     .4684574    .5667996
    GDPpc_or_ln |   .0446371   .0271996     1.64   0.101    -.0086733    .0979476
  GDPpc_dest_ln |  -.3496545   .0332462   -10.52   0.000     -.414816    -.284493
  PolInstab3y_o |   .0131108   .0110778     1.18   0.237    -.0086014     .034823
  PolInstab3y_d |   .4303366   .0161496    26.65   0.000     .3986839    .4619892
WarOccurrence_o |   .0188818   .0207539     0.91   0.363    -.0217953    .0595589
WarOccurrence_d |   .8690186   .0316396    27.47   0.000     .8070059    .9310313
     Network_ln |    .006182   .0016384     3.77   0.000     .0029707    .0093932
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  2010.49
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2654.58
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  4, 13302)  P-val | SW Chi-sq(  3) P-val | SW F(  3, 13302)
GTI_o        |    2453.24    0.0000 |     9690.33   0.0000 |     3229.36
GTI_d        |    2010.49    0.0000 |     7965.59   0.0000 |     2654.58

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                    5% maximal IV relative bias    16.85
                                   10% maximal IV relative bias    10.27
                                   20% maximal IV relative bias     6.71
                                   30% maximal IV relative bias     5.34
                                   10% maximal IV size             24.58
                                   15% maximal IV size             13.96
                                   20% maximal IV size             10.26
                                   25% maximal IV size              8.31
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(3)=2147.31  P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                   11444.84
Kleibergen-Paap Wald rk F statistic                              1814.45

Stock-Yogo weak ID test critical values for K1=2 and L1=4:
                                    5% maximal IV relative bias    11.04
                                   10% maximal IV relative bias     7.56
                                   20% maximal IV relative bias     5.57
                                   30% maximal IV relative bias     4.73
                                   10% maximal IV size             16.87
                                   15% maximal IV size              9.93
                                   20% maximal IV size              7.54
                                   25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(4,13302)=     6.00     P-val=0.0001
Anderson-Rubin Wald test           Chi-sq(4)=     24.01     P-val=0.0001
Stock-Wright LM S statistic        Chi-sq(4)=     24.46     P-val=0.0001

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =         11
Number of excluded instruments       L1 =          4

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    77.55
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =   0.0101
Total (uncentered) SS   =  170701.4477                Uncentered R2 =   0.0101
Residual SS             =  168975.7329                Root MSE      =    .7117

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0129107   .0065296     1.98   0.048     .0001119    .0257096
          GTI_d |  -.0369757   .0086494    -4.27   0.000    -.0539296   -.0200217
    GDPpc_or_ln |   .0118924   .0202038     0.59   0.556    -.0277099    .0514948
  GDPpc_dest_ln |   .1520195     .02134     7.12   0.000       .11019     .193849
  PolInstab3y_o |   .0046734   .0087521     0.53   0.593    -.0124821    .0218288
  PolInstab3y_d |   .0332473    .008099     4.11   0.000     .0173721    .0491224
WarOccurrence_o |   .0649525   .0164751     3.94   0.000      .032659     .097246
WarOccurrence_d |   .0681478   .0179939     3.79   0.000     .0328772    .1034184
     Network_ln |   .0249292   .0010256    24.31   0.000     .0229188    .0269397
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):           2147.308
                                                   Chi-sq(3) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):              1.1e+04
                         (Kleibergen-Paap rk Wald F statistic):       1814.445
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         1.994
                                                   Chi-sq(2) P-val =    0.3690
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

. est sto TIVd

. estadd scalar idstat1 = `e(idstat)'

added scalar:
            e(idstat1) =  2147.308

. estadd scalar iddf1 = `e(iddf)'

added scalar:
              e(iddf1) =  3

. estadd scalar idp1 = `e(idp)'

added scalar:
               e(idp1) =  0

. estadd scalar cdf1 = `e(cdf)'

added scalar:
               e(cdf1) =  11444.843

. estadd scalar widstat1 = `e(widstat)'

added scalar:
           e(widstat1) =  1814.445

. estadd scalar j1 = `e(j)'

added scalar:
                 e(j1) =  1.9938577

. estadd scalar jdf1 = `e(jdf)'

added scalar:
               e(jdf1) =  2

. estadd scalar jp1 = `e(jp)'

added scalar:
                e(jp1) =  .36901099

. rename GTI_o AttacksIndex_o

. rename GTI_d AttacksIndex_d

. 
. * Victims
. rename VictimsIndex_o GTI_o

. rename VictimsIndex_d GTI_d

. ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_
> lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst sa
> vefprefix(firstboth) // same results: good!!!!!!
(dropped 45 singleton observations)
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstbothG~o | ivreg2       GTI_o          11  First-stage regression: GTI_o
firstbothG~d | ivreg2       GTI_d          11  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .1082038   .0012344    87.66   0.000     .1057845    .1106231
  govfrac2020_o |   .8399929   .0310593    27.04   0.000     .7791175    .9008682
      GTI_d_lag |   .0033072   .0014815     2.23   0.026     .0004036    .0062109
  govfrac2020_d |   .0215325   .0266937     0.81   0.420    -.0307863    .0738514
    GDPpc_or_ln |  -.4343722   .0344539   -12.61   0.000    -.5019008   -.3668436
  GDPpc_dest_ln |  -.0218284   .0349208    -0.63   0.532    -.0902722    .0466154
  PolInstab3y_o |   .5072536   .0172195    29.46   0.000     .4735038    .5410034
  PolInstab3y_d |   .0031363   .0142552     0.22   0.826    -.0248034     .031076
WarOccurrence_o |   1.227128   .0304349    40.32   0.000     1.167476    1.286779
WarOccurrence_d |   .0430119   .0274685     1.57   0.117    -.0108255    .0968493
     Network_ln |   .0084235   .0019286     4.37   0.000     .0046435    .0122034
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  2140.77
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2811.51
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0029016   .0013791     2.10   0.035     .0001986    .0056045
  govfrac2020_o |   .0104471   .0260716     0.40   0.689    -.0406525    .0615467
      GTI_d_lag |   .1020655    .001259    81.07   0.000     .0995979    .1045332
  govfrac2020_d |     .50164   .0277453    18.08   0.000     .4472601    .5560199
    GDPpc_or_ln |   .0377758    .029012     1.30   0.193    -.0190869    .0946385
  GDPpc_dest_ln |  -.3086934   .0392494    -7.86   0.000    -.3856211   -.2317656
  PolInstab3y_o |   .0135819   .0128452     1.06   0.290    -.0115942    .0387581
  PolInstab3y_d |   .3653717   .0187343    19.50   0.000      .328653    .4020905
WarOccurrence_o |    .026641   .0230865     1.15   0.249    -.0186079    .0718899
WarOccurrence_d |   1.018064   .0337599    30.16   0.000     .9518955    1.084232
     Network_ln |   .0000247   .0017918     0.01   0.989    -.0034873    .0035366
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  1691.50
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2225.47
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  4, 13302)  P-val | SW Chi-sq(  3) P-val | SW F(  3, 13302)
GTI_o        |    2140.77    0.0000 |     8436.49   0.0000 |     2811.51
GTI_d        |    1691.50    0.0000 |     6677.95   0.0000 |     2225.47

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                    5% maximal IV relative bias    16.85
                                   10% maximal IV relative bias    10.27
                                   20% maximal IV relative bias     6.71
                                   30% maximal IV relative bias     5.34
                                   10% maximal IV size             24.58
                                   15% maximal IV size             13.96
                                   20% maximal IV size             10.26
                                   25% maximal IV size              8.31
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(3)=1826.11  P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                    8699.32
Kleibergen-Paap Wald rk F statistic                              1544.98

Stock-Yogo weak ID test critical values for K1=2 and L1=4:
                                    5% maximal IV relative bias    11.04
                                   10% maximal IV relative bias     7.56
                                   20% maximal IV relative bias     5.57
                                   30% maximal IV relative bias     4.73
                                   10% maximal IV size             16.87
                                   15% maximal IV size              9.93
                                   20% maximal IV size              7.54
                                   25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(4,13302)=     6.00     P-val=0.0001
Anderson-Rubin Wald test           Chi-sq(4)=     24.01     P-val=0.0001
Stock-Wright LM S statistic        Chi-sq(4)=     24.46     P-val=0.0001

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =         11
Number of excluded instruments       L1 =          4

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    77.51
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =   0.0089
Total (uncentered) SS   =  170701.4477                Uncentered R2 =   0.0089
Residual SS             =  169188.2948                Root MSE      =    .7121

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |   .0121251   .0062878     1.93   0.054       -.0002    .0244502
          GTI_d |  -.0361835   .0084739    -4.27   0.000    -.0527935   -.0195735
    GDPpc_or_ln |   .0118949   .0201623     0.59   0.555    -.0276261    .0514158
  GDPpc_dest_ln |   .1543653   .0212736     7.26   0.000      .112666    .1960646
  PolInstab3y_o |   .0057147   .0085693     0.67   0.505    -.0110823    .0225118
  PolInstab3y_d |   .0305888   .0078392     3.90   0.000     .0152229    .0459548
WarOccurrence_o |   .0638588   .0168773     3.78   0.000     .0307769    .0969407
WarOccurrence_d |   .0725949   .0184024     3.94   0.000     .0365235    .1086663
     Network_ln |   .0246909   .0010178    24.26   0.000     .0226959     .026686
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):           1826.106
                                                   Chi-sq(3) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):             8699.316
                         (Kleibergen-Paap rk Wald F statistic):       1544.984
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         2.164
                                                   Chi-sq(2) P-val =    0.3390
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

. est sto TIVe

. estadd scalar idstat1 = `e(idstat)'

added scalar:
            e(idstat1) =  1826.1064

. estadd scalar iddf1 = `e(iddf)'

added scalar:
              e(iddf1) =  3

. estadd scalar idp1 = `e(idp)'

added scalar:
               e(idp1) =  0

. estadd scalar cdf1 = `e(cdf)'

added scalar:
               e(cdf1) =  8699.3156

. estadd scalar widstat1 = `e(widstat)'

added scalar:
           e(widstat1) =  1544.9842

. estadd scalar j1 = `e(j)'

added scalar:
                 e(j1) =  2.1637799

. estadd scalar jdf1 = `e(jdf)'

added scalar:
               e(jdf1) =  2

. estadd scalar jp1 = `e(jp)'

added scalar:
                e(jp1) =  .33895431

. rename GTI_o VictimsIndex_o

. rename GTI_d VictimsIndex_d

. 
. * Bombings
. rename BombingIndex_o GTI_o

. rename BombingIndex_d GTI_d

. ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_
> lag govfrac2020_d), robust absorb(FE_PPML_od FE_PPML_y) first cluster(FE_PPML_od) savefirst sa
> vefprefix(firstboth) // same results: good!!!!!!
(dropped 45 singleton observations)
(MWFE estimator converged in 7 iterations)

Stored estimation results
-------------------------
----------------------------------------------------------------------------
        name | command      depvar       npar  title 
-------------+--------------------------------------------------------------
firstbothG~o | ivreg2       GTI_o          11  First-stage regression: GTI_o
firstbothG~d | ivreg2       GTI_d          11  First-stage regression: GTI_d
----------------------------------------------------------------------------

First-stage regressions
-----------------------


First-stage regression of GTI_o:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_o |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0961466   .0011411    84.26   0.000     .0939101    .0983831
  govfrac2020_o |   .8954113   .0300012    29.85   0.000     .8366097    .9542128
      GTI_d_lag |   .0022058   .0013904     1.59   0.113    -.0005193     .004931
  govfrac2020_d |   .0313132   .0246626     1.27   0.204    -.0170247    .0796511
    GDPpc_or_ln |  -.1234337   .0239358    -5.16   0.000    -.1703472   -.0765202
  GDPpc_dest_ln |   .0276962   .0331266     0.84   0.403    -.0372309    .0926234
  PolInstab3y_o |   .4762381   .0147045    32.39   0.000     .4474177    .5050584
  PolInstab3y_d |   .0067034   .0127119     0.53   0.598    -.0182114    .0316183
WarOccurrence_o |    .974436   .0306011    31.84   0.000     .9144587    1.034413
WarOccurrence_d |     .02073   .0244529     0.85   0.397     -.027197    .0686571
     Network_ln |   .0069542   .0017169     4.05   0.000     .0035892    .0103192
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  2154.95
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2839.75
  Prob > F      =   0.0000


First-stage regression of GTI_d:

Statistics robust to heteroskedasticity and clustering on FE_PPML_od
Number of obs =                 333686
Number of clusters (FE_PPML_od) =  13303
---------------------------------------------------------------------------------
                |               Robust
          GTI_d |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |   .0030022   .0013447     2.23   0.026     .0003667    .0056377
  govfrac2020_o |   .0183939   .0242104     0.76   0.447    -.0290578    .0658457
      GTI_d_lag |   .0937508    .001133    82.74   0.000     .0915302    .0959715
  govfrac2020_d |   .6138127    .025924    23.68   0.000     .5630024     .664623
    GDPpc_or_ln |   .0394485   .0287525     1.37   0.170    -.0169055    .0958025
  GDPpc_dest_ln |     .01448   .0292599     0.49   0.621    -.0428684    .0718285
  PolInstab3y_o |   .0147528   .0116276     1.27   0.205     -.008037    .0375425
  PolInstab3y_d |   .3552518   .0150936    23.54   0.000     .3256688    .3848348
WarOccurrence_o |    .015319   .0216287     0.71   0.479    -.0270728    .0577107
WarOccurrence_d |   .7468815   .0316283    23.61   0.000     .6848911     .808872
     Network_ln |   .0040154   .0015848     2.53   0.011     .0009092    .0071216
---------------------------------------------------------------------------------
F test of excluded instruments:
  F(  4, 13302) =  1867.71
  Prob > F      =   0.0000
Sanderson-Windmeijer multivariate F test of excluded instruments:
  F(  3, 13302) =  2469.31
  Prob > F      =   0.0000



Summary results for first-stage regressions
-------------------------------------------

                                           (Underid)            (Weak id)
Variable     | F(  4, 13302)  P-val | SW Chi-sq(  3) P-val | SW F(  3, 13302)
GTI_o        |    2154.95    0.0000 |     8521.22   0.0000 |     2839.75
GTI_d        |    1867.71    0.0000 |     7409.64   0.0000 |     2469.31

NB: first-stage test statistics cluster-robust

Stock-Yogo weak ID F test critical values for single endogenous regressor:
                                    5% maximal IV relative bias    16.85
                                   10% maximal IV relative bias    10.27
                                   20% maximal IV relative bias     6.71
                                   30% maximal IV relative bias     5.34
                                   10% maximal IV size             24.58
                                   15% maximal IV size             13.96
                                   20% maximal IV size             10.26
                                   25% maximal IV size              8.31
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for i.i.d. errors only.

Underidentification test
Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)
Ha: matrix has rank=K1 (identified)
Kleibergen-Paap rk LM statistic          Chi-sq(3)=2125.80  P-val=0.0000

Weak identification test
Ho: equation is weakly identified
Cragg-Donald Wald F statistic                                    9867.48
Kleibergen-Paap Wald rk F statistic                              1652.15

Stock-Yogo weak ID test critical values for K1=2 and L1=4:
                                    5% maximal IV relative bias    11.04
                                   10% maximal IV relative bias     7.56
                                   20% maximal IV relative bias     5.57
                                   30% maximal IV relative bias     4.73
                                   10% maximal IV size             16.87
                                   15% maximal IV size              9.93
                                   20% maximal IV size              7.54
                                   25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.

Weak-instrument-robust inference
Tests of joint significance of endogenous regressors B1 in main equation
Ho: B1=0 and orthogonality conditions are valid
Anderson-Rubin Wald test           F(4,13302)=     6.00     P-val=0.0001
Anderson-Rubin Wald test           Chi-sq(4)=     24.01     P-val=0.0001
Stock-Wright LM S statistic        Chi-sq(4)=     24.46     P-val=0.0001

NB: Underidentification, weak identification and weak-identification-robust
    test statistics cluster-robust

Number of clusters             N_clust  =      13303
Number of observations               N  =     333686
Number of regressors                 K  =          9
Number of endogenous regressors      K1 =          2
Number of instruments                L  =         11
Number of excluded instruments       L1 =          4

IV (2SLS) estimation
--------------------

Estimates efficient for homoskedasticity only
Statistics robust to heteroskedasticity and clustering on FE_PPML_od

Number of clusters (FE_PPML_od) =  13303              Number of obs =   333686
                                                      F(  9, 13302) =    77.55
                                                      Prob > F      =   0.0000
Total (centered) SS     =  170701.4477                Centered R2   =   0.0097
Total (uncentered) SS   =  170701.4477                Uncentered R2 =   0.0097
Residual SS             =  169051.1734                Root MSE      =    .7118

---------------------------------------------------------------------------------
                |               Robust
Migrati~tNeg_ln |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |    .013944   .0069199     2.02   0.044     .0003801     .027508
          GTI_d |  -.0385368   .0090264    -4.27   0.000    -.0562299   -.0208437
    GDPpc_or_ln |   .0085437   .0202464     0.42   0.673     -.031142    .0482295
  GDPpc_dest_ln |    .165218    .021206     7.79   0.000     .1236513    .2067847
  PolInstab3y_o |   .0052698   .0086025     0.61   0.540    -.0115922    .0221319
  PolInstab3y_d |   .0310203   .0078697     3.94   0.000     .0155945     .046446
WarOccurrence_o |   .0646236   .0164545     3.93   0.000     .0323705    .0968768
WarOccurrence_d |   .0649523   .0177644     3.66   0.000     .0301316     .099773
     Network_ln |   .0248515   .0010226    24.30   0.000     .0228472    .0268559
---------------------------------------------------------------------------------
Underidentification test (Kleibergen-Paap rk LM statistic):           2125.801
                                                   Chi-sq(3) P-val =    0.0000
------------------------------------------------------------------------------
Weak identification test (Cragg-Donald Wald F statistic):             9867.482
                         (Kleibergen-Paap rk Wald F statistic):       1652.147
Stock-Yogo weak ID test critical values:  5% maximal IV relative bias    11.04
                                         10% maximal IV relative bias     7.56
                                         20% maximal IV relative bias     5.57
                                         30% maximal IV relative bias     4.73
                                         10% maximal IV size             16.87
                                         15% maximal IV size              9.93
                                         20% maximal IV size              7.54
                                         25% maximal IV size              6.28
Source: Stock-Yogo (2005).  Reproduced by permission.
NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors.
------------------------------------------------------------------------------
Hansen J statistic (overidentification test of all instruments):         1.773
                                                   Chi-sq(2) P-val =    0.4121
------------------------------------------------------------------------------
Instrumented:         GTI_o GTI_d
Included instruments: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d
                      WarOccurrence_o WarOccurrence_d Network_ln
Excluded instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Partialled-out:       _cons
                      nb: total SS, model F and R2s are after partialling-out;
                          any small-sample adjustments include partialled-out
                          variables in regressor count K
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     13303       13303           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

. est sto TIVf

. rename GTI_o BombingIndex_o

. rename GTI_d BombingIndex_d

. estadd scalar idstat1 = `e(idstat)'

added scalar:
            e(idstat1) =  2125.8007

. estadd scalar iddf1 = `e(iddf)'

added scalar:
              e(iddf1) =  3

. estadd scalar idp1 = `e(idp)'

added scalar:
               e(idp1) =  0

. estadd scalar cdf1 = `e(cdf)'

added scalar:
               e(cdf1) =  9867.4821

. estadd scalar widstat1 = `e(widstat)'

added scalar:
           e(widstat1) =  1652.1468

. estadd scalar j1 = `e(j)'

added scalar:
                 e(j1) =  1.7729869

. estadd scalar jdf1 = `e(jdf)'

added scalar:
               e(jdf1) =  2

. estadd scalar jp1 = `e(jp)'

added scalar:
                e(jp1) =  .41209827

. rename GTIooriginal GTI_o

. rename GTIdoriginal GTI_d

. 
. label variable GTI_o "Terror o"

. label variable GTI_d "Terror d"

. 
. esttab  TIVa TIVb TIVc TIVd TIVe TIVf using "Results/Revision JEBO/Table IV.tex", label title(
> "Impact of terrorist attacks on global bilateral migration rates - IV") /// 
> mtitles("Parsimonious" "Benchmark" "Terror occurrence" "Attacks index" "Victims index" "Bombin
> gs index") nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers ///
> t(2) b(3) nogaps scalars("ll Log likelihood") obslast ///
> addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote signi
> ficance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robu
> st to heteroskedasticity and clustered by dyad.") ///
> stats(idstat1 iddf1 idp1 cdf1 widstat1 j1 jdf1 jp1, labels("KP LM stat" "Chi-sq(X)" "p-val" "C
> D Wald F" "KP Wald F" "Hansen J" "Chi-sq(X)" "p-val"))
(output written to Results/Revision JEBO/Table IV.tex)

. 
. label variable GTI_o "GTI o"

. label variable GTI_d "GTI d"

*/



*********************************************************************************************************
************************************** Relaxing validity of IVs *****************************************
*********************************************************************************************************
// ___________________________________________________________________________
***  "Plausibly Exogenous" estimation developed by Conley et al. (2012):
*** IV estimation under flexible (plausibly exogenous) conditions
// ___________________________________________________________________________

* To identify a prior for gamma, include the instruments in the baseline regression:
ppmlhdfe MigrationRateWithoutNeg GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) d // Effects become slightly less significant but survive!!! 
/*

HDFE PPML regression                              No. of obs      =    323,954
Absorbing 2 HDFE groups                           Residual df     =     12,450
Statistics robust to heteroskedasticity           Wald chi2(13)   =     190.43
Deviance             =   7142.40985               Prob > chi2     =     0.0000
Log pseudolikelihood = -15211.75226               Pseudo R2       =     0.6230

Number of clusters (FE_PPML_od)=    12,451
                           (Std. Err. adjusted for 12,451 clusters in FE_PPML_od)
---------------------------------------------------------------------------------
                |               Robust
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |  -.0085438   .0071509    -1.19   0.232    -.0225593    .0054717 --> take this upper CI value
  govfrac2020_o |   .0710714   .1223592     0.58   0.561    -.1687482    .3108909 --> take this upper CI value
      GTI_d_lag |   .0057324   .0092481     0.62   0.535    -.0123936    .0238583 --> take this upper CI value
  govfrac2020_d |  -.1542864   .1529771    -1.01   0.313    -.4541159    .1455432 --> take this upper CI value
          GTI_o |   .0282908   .0168589     1.68   0.093    -.0047521    .0613337
          GTI_d |  -.0149067    .018868    -0.79   0.429    -.0518873    .0220739
    GDPpc_or_ln |  -.1157605   .0960407    -1.21   0.228    -.3039969    .0724758
  GDPpc_dest_ln |   .5335826   .1595072     3.35   0.001     .2209543    .8462109
  PolInstab3y_o |  -.0165338   .0744924    -0.22   0.824    -.1625362    .1294687
  PolInstab3y_d |   .0454076   .1068706     0.42   0.671    -.1640548    .2548701
WarOccurrence_o |   .5482207   .1279219     4.29   0.000     .2974983     .798943
WarOccurrence_d |  -.0969075    .208322    -0.47   0.642    -.5052111     .311396
     Network_ln |   .3048498   .0382427     7.97   0.000     .2298956    .3798041
          _cons |   -7.92509   1.576391    -5.03   0.000    -11.01476    -4.83542
---------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     12451       12451           0    *|
   FE_PPML_y |        42           0          42     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation
*/


* Union of confidence intervals approach
plausexog uci MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
gmin(0 0 0 0) gmax(0.0054717 0.3108909 0.0238583 0.1455432) grid(2) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) 
*est sto TPEb 
/*
Estimating Conely et al.'s uci method
Exogenous variables: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d WarOccurrence_o WarOccurren
> ce_d Network_ln
Endogenous variables: GTI_o GTI_d
Instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d


Conley et al (2012)'s UCI results                     Number of obs =      333731
------------------------------------------------------------------------------
Variable    Lower Bound     Upper Bound
------------------------------------------------------------------------------
GDPpc_or_ln 	-.0521481      -.00528019 --> so statistically significant since zero not included
GDPpc_dest_ln	 .14806881      .20049543 --> so statistically significant since zero not included
PolInstab3y_o	 .19965947      .3296369 --> so statistically significant since zero not included
PolInstab3y_d	 .00465495      .31149111 --> so statistically significant since zero not included
WarOccurrence_o	 .46882707      .77001211 --> so statistically significant since zero not included
WarOccurrence_d	-.01202285      .86494063 
Network_ln  	 .11177325      .12711784 --> so statistically significant since zero not included
GTI_o       	-.25879018     -.16119436 --> so statistically significant since zero not included, but negatively!!!
GTI_d       	-.27260218      .02204275 --> insignificant since includes zero
_cons         -14.354312     -13.508755
------------------------------------------------------------------------------

Note: plotting not possible!
Graphing with UCI only supported with 1 plausibly exogenous variable
*/



* Do the same but now considering the estimated coefficient rather than the upper value of the 95% confidence interval
plausexog uci MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
gmin(0 0 0 0) gmax(-.0085438  .0710714 .0057324 -.1542864) grid(2) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) 
/*
Estimating Conely et al.'s uci method
Exogenous variables: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d WarOccurrence_o WarOccurren
> ce_d Network_ln
Endogenous variables: GTI_o GTI_d
Instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d


Conley et al (2012)'s UCI results                     Number of obs =      333731
------------------------------------------------------------------------------
Variable    Lower Bound     Upper Bound
------------------------------------------------------------------------------
GDPpc_or_ln 	-.04566732      -.01579129
GDPpc_dest_ln	.16619773      .20048105
PolInstab3y_o	.09791504      .23896249
PolInstab3y_d	-.004589       .10645715
WarOccurrence_o	.18840406    .54270212
WarOccurrence_d	-.00980437   .24350459
Network_ln  	.10783568       .11615806
GTI_o       	-.18071626      -.06362897 --> so statistically significant since zero not included, but negative!!
GTI_d       	-.06132694      .02037015 --> insignificant since includes zero
_cons       	-14.567165      -14.113028
------------------------------------------------------------------------------
*/

* Do the same but now adding fixed effects (it seems the absorb option doesn't work appropriately):
*** Try with year fixed effects first (od fixed effects are too many apparently)
plausexog uci MigrationRateWithoutNeg_ln $controlsOD i.FE_PPML_y (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
gmin(0 0 0 0) gmax(0.0054717 0.3108909 0.0238583 0.1455432) grid(2) level(.95) robust cluster(FE_PPML_od) 

*** Then check whether this is the same as adding the absorb option
plausexog uci MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
gmin(0 0 0 0) gmax(0.0054717 0.3108909 0.0238583 0.1455432) grid(2) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_y)

*** Now checking if the results are still the same if we don't put any absorb option at all (so means no FEs are included at all:
plausexog uci MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
gmin(0 0 0 0) gmax(0.0054717 0.3108909 0.0238583 0.1455432) grid(2) level(.95) robust cluster(FE_PPML_od) 
* INDEED!!! so it means this abosrb option doesn't work at all...
* Hence have to try and manually add the FEs but that won't work probably since too many

plausexog uci MigrationRateWithoutNeg_ln $controlsOD i.FE_PPML_od i.FE_PPML_y (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
gmin(0 0 0 0) gmax(0.0054717 0.3108909 0.0238583 0.1455432) grid(2) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
* Error messag: numlist in operator invalid



* Prepare the alternative approach: local to zero (LTZ) estimation
* Redo the estimation of the baseline with the instruments added, but now to get bootstrapped standard errors on gamma
bootstrap, reps(100) seed(1): ppmlhdfe MigrationRateWithoutNeg GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) //vce(cluster FE_PPML_od) d

/*
Bootstrap replications (100)
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5 
..................................................    50
..................................................   100

HDFE PPML regression                              No. of obs      =    323,954
Absorbing 2 HDFE groups                           Residual df     =    311,449
                                                  Wald chi2(13)   =     335.01
Deviance             =   7142.40985               Prob > chi2     =     0.0000
Log pseudolikelihood = -15211.75226               Pseudo R2       =     0.6230
---------------------------------------------------------------------------------
                |   Observed   Bootstrap                         Normal-based
MigrationR~tNeg |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      GTI_o_lag |  -.0085438   .0034733    -2.46   0.014    -.0153513   -.0017363 --> take bootstrapped se for LTZ approach
  govfrac2020_o |   .0710714   .0539351     1.32   0.188    -.0346395    .1767823 --> take bootstrapped se
      GTI_d_lag |   .0057324   .0039072     1.47   0.142    -.0019255    .0133903 --> take bootstrapped se
  govfrac2020_d |  -.1542864   .0662953    -2.33   0.020    -.2842227   -.0243501 --> take bootstrapped se
          GTI_o |   .0282908   .0092212     3.07   0.002     .0102175     .046364
          GTI_d |  -.0149067   .0109077    -1.37   0.172    -.0362854     .006472
    GDPpc_or_ln |  -.1157605   .0506747    -2.28   0.022    -.2150811   -.0164399
  GDPpc_dest_ln |   .5335826   .0793479     6.72   0.000     .3780636    .6891016
  PolInstab3y_o |  -.0165338   .0460494    -0.36   0.720    -.1067889    .0737214
  PolInstab3y_d |   .0454076   .0690811     0.66   0.511    -.0899888    .1808041
WarOccurrence_o |   .5482207   .0786181     6.97   0.000     .3941319    .7023094
WarOccurrence_d |  -.0969075   .0893847    -1.08   0.278    -.2720982    .0782832
     Network_ln |   .3048498   .0301865    10.10   0.000     .2456853    .3640144
          _cons |   -7.92509   .8522677    -9.30   0.000    -9.595504   -6.254676
---------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
  FE_PPML_od |     12451           0       12451     |
   FE_PPML_y |        42           1          41     |
-----------------------------------------------------+
*/



* Run local to zero (LTZ) estimation from Conley et al but using simulation-based method which works for arbitrary distributions
*    (here uniform with mean zero and standard deviation )
plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
distribution(uniform, 0, 0.01, 0, 0.1, 0, 0.01, 0, 0.1) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
/*
Endogenous variables: GTI_o GTI_d
Instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d
Simulating 5000 iterations.  This may take a moment.

Conley et al (2012)'s LTZ results (Non-Gaussian)      Number of obs =      333731
------------------------------------------------------------------------------
Variable    Lower Bound     Upper Bound
------------------------------------------------------------------------------
GTI_o       -.2888269       -.17695135 -->  negative significant
GTI_d       -.09794041      .01389978
GDPpc_or_ln -.02616022      -.00421267
GDPpc_dest_ln.15591752      .17651432
PolInstab3y_o.22183029      .33962352
PolInstab3y_d.02937356      .14120563
WarOccurrence_o.52110887    .83911825
WarOccurrence_d.0240444     .35125659
Network_ln  .11370262       .12062692
_cons       -14.23284       -13.938305
------------------------------------------------------------------------------
*/

plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
distribution(uniform, 0, 0, 0, 0, 0.01, 0.1, 0.01, 0.1) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
// --> Both negative significant effect

plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
distribution(normal, 0, 0.01, 0, 0.1, 0, 0.01, 0, 0.1) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
// --> Both insig

plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
distribution(normal, 0, 0, 0, 0, 0.01, 0.1, 0.01, 0.1) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
// --> GTI_o neg sig, GTI_d insig



* Run local to zero (LTZ) estimation from Conley et al
plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
mu(0 0 0 0) omega(.0034733 .0539351 .0039072 .0662953) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
/*
Estimating Conely et al.'s ltz method
Exogenous variables: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d WarOccurrence_o WarOccurren
> ce_d Network_ln
Endogenous variables: GTI_o GTI_d
Instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d


Conley et al. (2012)'s LTZ results                    Number of obs =    333731
---------------------------------------------------------------------------------
                |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |  -.1725912   .6888123    -0.25   0.802    -1.522639    1.177456 --> insig
          GTI_d |    .014631   .7302255     0.02   0.984    -1.416585    1.445847 --> insig
    GDPpc_or_ln |  -.0192993   .1152464    -0.17   0.867     -.245178    .2065795
  GDPpc_dest_ln |   .1702999   .0979387     1.74   0.082    -.0216563    .3622562
  PolInstab3y_o |   .2156905   .6935078     0.31   0.756     -1.14356    1.574941
  PolInstab3y_d |    .024253   .6741975     0.04   0.971     -1.29715    1.345656
WarOccurrence_o |   .5076683   1.936223     0.26   0.793    -3.287259    4.302595
WarOccurrence_d |   .0176426   2.102287     0.01   0.993    -4.102765     4.13805
     Network_ln |   .1126608   .0374909     3.01   0.003       .03918    .1861416
          _cons |  -14.30215   1.488156    -9.61   0.000    -17.21888   -11.38542
---------------------------------------------------------------------------------
*/

* Same but using non-bootstrapped standard errors instead:
plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
mu(0 0 0 0) omega(.0071509 .1223592 .0092481 .1529771) level(.95) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
/*
Estimating Conely et al.'s ltz method
Exogenous variables: GDPpc_or_ln GDPpc_dest_ln PolInstab3y_o PolInstab3y_d WarOccurrence_o WarOccurren
> ce_d Network_ln
Endogenous variables: GTI_o GTI_d
Instruments: GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d


Conley et al. (2012)'s LTZ results                    Number of obs =    333731
---------------------------------------------------------------------------------
                |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
          GTI_o |  -.1725912   .9883992    -0.17   0.861    -2.109818    1.764636 --> stays insig
          GTI_d |    .014631   1.123359     0.01   0.990    -2.187111    2.216373 --> stays insig
    GDPpc_or_ln |  -.0192993   .1665267    -0.12   0.908    -.3456857    .3070872
  GDPpc_dest_ln |   .1702999   .1458455     1.17   0.243    -.1155521     .456152
  PolInstab3y_o |   .2156905   .9957415     0.22   0.829    -1.735927    2.167308
  PolInstab3y_d |    .024253    1.03621     0.02   0.981    -2.006681    2.055187
WarOccurrence_o |   .5076683   2.778288     0.18   0.855    -4.937676    5.953013
WarOccurrence_d |   .0176426   3.234277     0.01   0.996    -6.321424    6.356709
     Network_ln |   .1126608   .0558595     2.02   0.044     .0031781    .2221435
          _cons |  -14.30215   2.222542    -6.44   0.000    -18.65825   -9.946043
---------------------------------------------------------------------------------
*/


* Run local to zero (LTZ) estimation and graph output as per Conley et al.
*** Note: I don't know how the graphmu and graphomega stuff should be determined, so these results aren't good (yet)
plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
mu(0 0 0 0) omega(.0034733 .0539351 .0039072 .0662953) level(.95) vce(cluster FE_PPML_od) graph(GTI_d ) ///
graphdelta(0 0.02 0.04 0.06 0.08 0.1) graphmu(0 0.002 0.004 0.006 0.008 0.01) graphomega(0 .001 .002 .003 .004 .005)

plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
mu(0 0 0 0) omega(.0034733 .0539351 .0039072 .0662953) level(.95) vce(cluster FE_PPML_od) graph(GTI_o ) ///
graphdelta(0 0.02 0.04 0.06 0.08 0.1) graphmu(0 0.002 0.004 0.006 0.008 0.01) graphomega(0 .001 .002 .003 .004 .005)

/*Trying some more things. The below doesn't work:
plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
mu(0 0 0 0) omega(.0034733 .0539351 .0039072 .0662953) level(.95) vce(cluster FE_PPML_od) graph(GTI_o ) ///
graphdelta(0 0.02 0.04 0.06 0.08 0.1) graphmu(0 0 0 0 0 0) graphomega(.0034733 .0034733 .0034733 .0034733 .0034733 .0034733)

plausexog ltz MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), ///
mu(0 0 0 0) omega(.0034733 .0539351 .0039072 .0662953) level(.95) vce(cluster FE_PPML_od) graph(GTI_o ) ///
graphdelta(0 0.02 0.04 0.06 0.08 0.1) graphmu(0 0.002 0.004 0.006 0.008 0.01) graphomega(0 .01 .02 .03 .04 .05)

*/

//_________________________________________________________________________________________

*** Trying out other approaches
imperfectiv MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d) 
* Yet gives error message when we keep our two endogenous variables (can only handle one)


sivreg MigrationRateWithoutNeg_ln GTI_o GTI_d $controlsOD, endog(GTI_o GTI_d) exog($controlsOD GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d) adaptive 
* Option absorb again not allowed!
* But even when leaving this out: error message stating "Only one endogenous regressor is allowed"

kinkyreg MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), endog( 0.1 .) range(-0.75 0.75) small inference(GTI_o GTI_d)
* This  needs to be done for one IV at a time, which works here, but this is without accounting for FEs

kinkyreg MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), endog(. 0.1) range(-0.75 0.75) small inference(GTI_o GTI_d) robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y)
* Options absorb, robust and cluster not allowed so useless!










********************************************************************************
************************* Further disagregation corridors ***********************
*Redefining the treshold for South and North on the basis of HighIncome is the same 
*as on the basis of Upper middle income (see the dofile "WDI cleaning - JEBO revision" for why)
*In short: the tresholds define the upper limit, not the bottom one, of an income category
********************************************************************************

******************************** THE ORIGINAL AS REPORTED BUT ADDING IV ************************************************
*Redefining the treshold for South and North on the basis of UpperMiddleIncome instead of HighIncome
* South - South
preserve
keep if GNIpc_o <= UpperMiddleIncome_o & GNIpc_d <= UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TUMI3a
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TUMI4a 
restore 

* South - North (S-N) 
preserve
keep if GNIpc_o <= UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
*drop if iso3d=="USA"
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TUMI3b
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TUMI4b
restore

* North - North (N-N) 
preserve
keep if GNIpc_o > UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
*drop if iso3o=="USA"
*drop if iso3d=="USA"
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TUMI3c
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TUMI4c
*Test without US
drop if iso3o=="USA"
drop if iso3d=="USA"
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od) // Same results
restore

// Now output in one table ppml and IV results
esttab TUMI3a TUMI3b TUMI3c TUMI4a TUMI4b TUMI4c using "Results/Revision JEBO/Table UMI.tex", label title("Corridors sub-samples") mtitles("South-South" "South-North" "North-North" "South-South" "South-North" "North-North") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.")



******************************** Do the same but using GTI_diff  ************************************************
*Replacing GTI_o and GTI_d by the difference in them (for IV requires also taking the difference for the exog vars)
gen GTI_diff = GTI_d - GTI_o
gen GTI_diff_lag = GTI_d_lag - GTI_o_lag
gen govfrac2020_diff = govfrac2020_d - govfrac2020_o

* South - South
preserve
keep if GNIpc_o <= UpperMiddleIncome_o & GNIpc_d <= UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TUMIdiffa
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TUMIdiffb
restore 

* South - North (S-N) 
preserve
keep if GNIpc_o <= UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
*drop if iso3d=="USA"
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TUMIdiffc
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TUMIdiffd
restore

* North - North (N-N) 
preserve
keep if GNIpc_o > UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TUMIdiffe
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TUMIdifff
restore

// Now output in one table ppml and IV results
esttab TUMIdiffa TUMIdiffb TUMIdiffc TUMIdiffd TUMIdiffe TUMIdifff using "Results/Revision JEBO/Table UMI GTI_diff.tex", label title("Corridors sub-samples") mtitles("South-South" "South-North" "North-North" "South-South" "South-North" "North-North") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.")


********************************************************************************
*Redefining the treshold for South and North on the basis of LowerMiddleIncome (as it was mistakenly reported in the paper) instead of UpperMiddleIncome
/*
* South - South
preserve
keep if GNIpc_o <= LowerMiddleIncome_o & GNIpc_d <= LowerMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TLMI3a
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TLMI4a 
restore 

* South - North (S-N) 
preserve
keep if GNIpc_o <= LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
*drop if iso3d=="USA"
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TLMI3b
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TLMI4b
restore

* North - North (N-N) 
preserve
keep if GNIpc_o > LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
pmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto TLMI3c
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto TLMI4c
restore

esttab TLMI3a TLMI3b TLMI3c using "Results/Revision JEBO/Table LMI3.tex", label title("Corridors sub-samples") mtitles("South-South" "South-North" "North-North") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.")

esttab TLMI4a TLMI4b TLMI4c using "Results/Revision JEBO/Table LMI4.tex", label title("Corridors sub-samples - IV approach") mtitles("South-South" "South-North" "North-North") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.") // APPENDIX
*/

********************************************************************************
*Completely tairing S-N apart (from lower to higher income) 
/*
* LI to LMI
preserve
keep if GNIpc_o <= LowIncome_o & GNIpc_d > LowIncome_d & GNIpc_d <= LowerMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3a
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4a 
restore 

* LI to UMI
preserve
keep if GNIpc_o <= LowIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_d <= UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3b
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4b
restore

* LI to HI
preserve
keep if GNIpc_o <= LowIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3c
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4c
restore

* LMI to UMI
preserve
keep if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_d <= UpperMiddleIncome_d & GNIpc_d <= UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3d
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4d
restore 

* LMI to HI
preserve
keep if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3e
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4e
restore

* UMI to HI
preserve
keep if GNIpc_o > LowerMiddleIncome_o & GNIpc_o <= UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3f
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4f
restore

* LI to MI (combining LMI and UMI)
preserve
keep if GNIpc_o > LowIncome_o & GNIpc_d > LowIncome_d & GNIpc_d < UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3g
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4g
restore

esttab Tsep3a Tsep3b Tsep3c Tsep3d Tsep3e Tsep3f Tsep3g using "Results/Revision JEBO/Table SEP3.tex", label title("Corridors sub-samples") mtitles("LI to LMI" "LI to UMI" "LI to HI" "LMI to UMI" "LMI to HI" "UMI to HI" "LI to MI") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.")
// So the odd result concerning a positive impact from GTI_d is found only for LMI to HI --> Need to further break down HI... into OECD and non-OECD...

esttab TLMI4a TLMI4b TLMI4c Tsep4d Tsep4e Tsep4f Tsep4g using "Results/Revision JEBO/Table SEP4.tex", label title("Corridors sub-samples - IV approach") mtitles("LI to LMI" "LI to UMI" "LI to HI" "LMI to UMI" "LMI to HI" "UMI to HI" "LI to MI") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.") // APPENDIX
// Luckily disappears with IV though!
*/
********************************************************************************
*Further splitting up HI in OECD and nonOECD

gen oecd = 0
replace oecd = 1 if destination=="Australia"
replace oecd = 1 if destination=="Austria"
replace oecd = 1 if destination=="Belgium"
replace oecd = 1 if destination=="Canada"
replace oecd = 1 if destination=="Chile"
replace oecd = 1 if destination=="Colombia"
replace oecd = 1 if destination=="Costa Rica"
replace oecd = 1 if destination=="Czech Republic"
replace oecd = 1 if destination=="Denmark"
replace oecd = 1 if destination=="Estonia"
replace oecd = 1 if destination=="Finland"
replace oecd = 1 if destination=="France"
replace oecd = 1 if destination=="Germany"
replace oecd = 1 if destination=="Greece"
replace oecd = 1 if destination=="Hungary"
replace oecd = 1 if destination=="Iceland"
replace oecd = 1 if destination=="Ireland"
replace oecd = 1 if destination=="Israel"
replace oecd = 1 if destination=="Italy"
replace oecd = 1 if destination=="Japan"
replace oecd = 1 if destination=="Korea"
replace oecd = 1 if destination=="Latvia"
replace oecd = 1 if destination=="Lithuania"
replace oecd = 1 if destination=="Luxembourg"
replace oecd = 1 if destination=="Mexico"
replace oecd = 1 if destination=="Netherlands"
replace oecd = 1 if destination=="New Zealand"
replace oecd = 1 if destination=="Norway"
replace oecd = 1 if destination=="Poland"
replace oecd = 1 if destination=="Portugal"
replace oecd = 1 if destination=="Slovakia"
replace oecd = 1 if destination=="Slovenia"
replace oecd = 1 if destination=="Spain"
replace oecd = 1 if destination=="Sweden"
replace oecd = 1 if destination=="Switzerland"
replace oecd = 1 if destination=="Turkey"
replace oecd = 1 if destination=="United Kingdom"
replace oecd = 1 if destination=="United States"

* LI to HI OECD
preserve
keep if GNIpc_o <= LowIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==1
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3h
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4h
restore

* LMI to HI OECD
preserve
keep if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==1
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3i
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4i
restore

* UMI to HI OECD
preserve
keep if GNIpc_o > LowerMiddleIncome_o & GNIpc_o <= UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==1
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3j
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4j
restore

* LI to HI nonOECD
preserve
keep if GNIpc_o <= LowIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.  & oecd==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3k
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4k
restore

* LMI to HI nonOECD
preserve
keep if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3l
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4l
restore

* UMI to HI nonOECD
preserve
keep if GNIpc_o > LowerMiddleIncome_o & GNIpc_o <= UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==0
ppmlhdfe MigrationRateWithoutNeg GTI_o GTI_d $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsep3m
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_o GTI_d = GTI_o_lag govfrac2020_o GTI_d_lag govfrac2020_d), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsep4m
restore


esttab Tsep3h Tsep3i Tsep3j Tsep3k Tsep3l Tsep3m using "Results/Revision JEBO/Table SEPII3.tex", label title("Corridors sub-samples") mtitles("LI to HIoecd" "LMI to HIoecd" "UMI to HIoecd" "LI to HInoecd" "LMI to HInoecd" "UMI to HInoecd") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.")
// So the pos sig effect for GTI_d is driven by the corridor LMI to HI oecd

esttab Tsep4h Tsep4i Tsep4j Tsep4k Tsep4l Tsep4m using "Results/Revision JEBO/Table SEPII4.tex", label title("Corridors sub-samples - IV approach") mtitles("LI to HIoecd" "LMI to HIoecd" "UMI to HIoecd" "LI to HInoecd" "LMI to HInoecd" "UMI to HInoecd") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.") // APPENDIX
// The neg sig effect disappears with IV though (only some GTI_o s remain marginally positively significant)


/*
**************************** Same but for GTI_diff **************************
*Further splitting up HI in OECD and nonOECD
* LI to HI OECD
preserve
keep if GNIpc_o <= LowIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==1
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsepdiff3a
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsepdiff4a
restore

* LMI to HI OECD
preserve
keep if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==1
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsepdiff3b
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsepdiff4b
restore

* UMI to HI OECD
preserve
keep if GNIpc_o > LowerMiddleIncome_o & GNIpc_o <= UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==1
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsepdiff3c
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsepdiff4c
restore

* LI to HI nonOECD
preserve
keep if GNIpc_o <= LowIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=.  & oecd==0
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsepdiff3d
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsepdiff4d
restore

* LMI to HI nonOECD
preserve
keep if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o & GNIpc_d > LowerMiddleIncome_d & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==0
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsepdiff3e
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsepdiff4e
restore

* UMI to HI nonOECD
preserve
keep if GNIpc_o > LowerMiddleIncome_o & GNIpc_o <= UpperMiddleIncome_o & GNIpc_d > UpperMiddleIncome_d & GNIpc_o!=. & GNIpc_d!=. & oecd==0
ppmlhdfe MigrationRateWithoutNeg GTI_diff $controlsOD, absorb(FE_PPML_od FE_PPML_y) cluster(FE_PPML_od)
est sto Tsepdiff3f
keep if e(sample)
ivreghdfe MigrationRateWithoutNeg_ln $controlsOD (GTI_diff = GTI_diff_lag govfrac2020_diff), robust cluster(FE_PPML_od) absorb(FE_PPML_od FE_PPML_y) first // same results: good!!!!!!
est sto Tsepdiff4f
restore


esttab Tsepdiff3a Tsepdiff3b Tsepdiff3c Tsepdiff3d Tsepdiff3e Tsepdiff3f using "Results/Revision JEBO/Table SEP GTI_diff PPML.tex", label title("Corridors sub-samples") mtitles("LI to HIoecd" "LMI to HIoecd" "UMI to HIoecd" "LI to HInoecd" "LMI to HInoecd" "UMI to HInoecd") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.")
// So the pos sig effect for GTI_d is driven by the corridor LMI to HI oecd

esttab Tsepdiff4a Tsepdiff4b Tsepdiff4c Tsepdiff4d Tsepdiff4e Tsepdiff4f  using "Results/Revision JEBO/Table SEP GTI_diff IV.tex", label title("Corridors sub-samples - IV approach") mtitles("LI to HIoecd" "LMI to HIoecd" "UMI to HIoecd" "LI to HInoecd" "LMI to HInoecd" "UMI to HInoecd") ///
nodepvars replace star(* 0.10 ** 0.05 *** 0.01) nonumbers t(2) b(3) nogaps obslast scalars("ll Log likelihood") addnotes("\textit{t} statistics in parentheses. \sym{*}, \sym{**}, and \sym{***}, denote significance at the 90, 95, and 99 percent confidence level, respectively. Standard errors are robust to heteroskedasticity and clustered by country pair.") // APPENDIX
// The neg sig effect disappears with IV though (only some GTI_o s remain marginally positively significant)
*/


*** Compute average GTI in the various categories of countries of origin and destination by income level:
sum GTI_o if GNIpc_o <= LowIncome_o // LI
sum GTI_o if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o // LMI
sum GTI_o if GNIpc_o > LowerMiddleIncome_o & GNIpc_o <= UpperMiddleIncome_o // UMI
sum GTI_o if GNIpc_o > UpperMiddleIncome_o & oecd==1 // HI and OECD
sum GTI_o if GNIpc_o > UpperMiddleIncome_o & oecd==0 // HI and nonOECD

/* DOESN'T REALLY SHOW ANYTHING INTERESTING
. sum GTI_o if GNIpc_o <= LowIncome_o // LI

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTI_o |    219,888     3.19063    2.533479          0   8.854758

. sum GTI_o if GNIpc_o > LowIncome_o & GNIpc_o <= LowerMiddleIncome_o // LMI

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTI_o |     83,630    3.993727    2.488918          0   9.505838

. sum GTI_o if GNIpc_o > LowerMiddleIncome_o & GNIpc_o <= UpperMiddleIncome_o // U
> MI

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTI_o |     53,441    3.385007    2.385187          0         10

. sum GTI_o if GNIpc_o > UpperMiddleIncome_o & oecd==1 // HI and OECD

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTI_o |     30,279    3.042443    2.143273          0   9.034956

. sum GTI_o if GNIpc_o > UpperMiddleIncome_o & oecd==0 // HI and nonOECD

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       GTI_o |     69,201    3.603658    2.018705          0   9.034956
*/

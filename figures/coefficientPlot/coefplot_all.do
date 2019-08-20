*===============================================================================
*************************** Coefficient Plots ***********************************
*
* Summary: 		perpares data set and code for coefficient plots, see more notes in 
*				section "GRAPHS"
* 
*
* Main Output: 	graph that plots all coefficients (all.pdf)
*
* Author: 		Simona Sartor and Pietro Biroli
*
* Date: 		August 2019

* TODO:         Saving the matrix Ppooled, Pgirl, and Pboy and then reading them again is not necessary
*               Do all the calculations directly in THP_analysis.do in matrix form
*
*===============================================================================




/* set maindir
global maindir "Z:\Simona\RA Pietro\"
global maindir "/mnt/data/Dropbox/SavingBrains/4_Data"
global maindir "/Users/pbirol/Dropbox/SavingBrains/4_Data/"
cd "${maindir}/figures/coefficientPlot/"
*/

// ----------------------------------------------------------------------------

// IMPORT AND APPEND DATA SET // 

foreach var in pooled girl boy {

import delimited "P`var'.txt", clear

drop v4

gen level="`var'"

drop if inlist(v1, "motherhealthindex", "fatherfinancial", /// 
"relation_traj", "grandmothers", "socialsupport")

rename (v1 rand) (regressor pValue)
	
save "`var'.dta", replace

}

clear

foreach var in pooled girl boy{

append using "`var'.dta"

}

save "coefplot.dta", replace

// -----------------------------------------------------------------------------


// PREPARE DATA SET //

use "coefplot.dta", clear


gen levelN=1 if level=="pooled"
replace levelN=2 if level=="girl"
replace levelN=3 if level=="boy"

order levelN beta pValue 

gen type=.

replace type=1 if regressor=="depindex_7y"
replace type=2 if inlist(regressor, "motherfinancial","parentmoney" /// 
,"parenttime","parentstyle","fertility_vars")
replace type=3 if type==.

gen     regOrder = 1  if regressor == "depindex_7y"
replace regOrder = 2  if regressor == "motherfinancial"
replace regOrder = 3  if regressor == "parentmoney"
replace regOrder = 4  if regressor == "parenttime"
replace regOrder = 5  if regressor == "parentstyle"
replace regOrder = 6  if regressor == "fertility_vars"
replace regOrder = 7  if regressor == "healthindex"
replace regOrder = 8  if regressor == "cognindex"
replace regOrder = 9  if regressor == "emoindex"
replace regOrder = 10 if regressor == "childmort"

sort type regOrder levelN 

gen order=_n

// -----------------------------------------------------------------------------


// CALCULATING CONFIDENCE INTERVALS //

* CI_i = beta +/- t_i * se, for i ={90,95}

* se = beta/t

* t is calculated from p-value


gen t=. // generate variable containing t-statistic which is backed out from p-value


*** back out t-statistic from p-value for each sample

replace t=invttail(584, pValue/2) if level=="pooled"

replace t=invttail(296, pValue/2)  if level=="girl"

replace t=invttail(287, pValue/2) if level=="boy"


gen se=. // generate variable for standard error
replace se= beta/t


foreach h in 0 5{

gen max9`h'=. // generating variable for upper bound of CI (90% & 95%)
gen min9`h'=. // generating variable for lower bound of CI (90% & 95%)

}

*** backing out the t-statistic for the 90 and 95 percentile for each sample

foreach h in max min{

	replace `h'95=invttail(584, 0.025) if level=="pooled"
	replace `h'90=invttail(584, 0.05) if level=="pooled"



	replace `h'95=invttail(296, 0.025) if level=="girl"
	replace `h'90=invttail(296, 0.05) if level=="girl"



	replace `h'95=invttail(287, 0.025) if level=="boy"
	replace `h'90=invttail(287, 0.05) if level=="boy"

}


*** final upper and lower bounds ***

foreach h in 0 5{

gen max9`h'b=.
gen min9`h'b=.

} 

* upper bound
foreach h in 5 0{

	replace max9`h'b=beta+se*max9`h' 

}

*lower bound
foreach h in 5 0{

	replace min9`h'b=beta-se*min9`h'
                  
}

order regressor pV min*90*b max*90*b min*95*b max*95*b  beta se  

sort order
save "final.dta", replace

// -----------------------------------------------------------------------------


// GRAPHS //

* - 	confidence intervals: 90% (with capped line) and 95% 
*		(continuous, fading out line)



*** matrices for coefplot ***

use "final.dta", clear

set scheme plotplainblind

graph set window fontface "Segoe UI Light"

keep beta m*b levelN regressor order

order beta m*b levelN regressor order

sort order

forval j=1/3{


mkmat beta-levelN if levelN==`j', matrix(A`j') 

matrix A`j'2=A`j''

mat list A`j'2

 }

coefplot matrix(A12[1,])   (matrix(A22[1,])) (matrix(A32[1,])), ci((2 3) (4 5)) xline(0, lwidth(medium) lcolor(gray) lpattern(solid)) ///
xscale(range(-0.5 0.75)) ///
ylabel(, labsize(vsmall) nogrid) /// 
xlabel(-0.5(0.25)0.75, labsize(vsmall)) xtitle("Effect size in standard deviations of the control group", size(vsmall)) /// 
coeflabels( r1="Depression Severity" ///
             r2="Mother's Financial Empowerment"  /// 
             r3="Parental Investment (monetary)" ///
             r4="Parental Investment (time-intensive)" /// 
             r5="Parenting Style" ///
             r6="Fertility" ///
             r7="Physical Development" ///
             r8="Cognitive Development" ///
             r9="Socio-emotional Development"  /// 
            r10="Sibling Survival Index" ///
           ) ///
 msize(vsmall) headings(r1= "{bf:Mother{c 39}s Mental Health}" r2="{bf:Mother{c 39}s Decision-Making}" r7= "{bf:Child Outcomes}" , labsize(vsmall)) /// 
 ciopts(recast(rcap rspike) lwidth(medium thin)) graphreg(color(gs16)) aspectratio(1.2) ///
 legend(order(3 "Full Sample" 6 "Female" 9 "Male") ring(0) bmargin(small) position(1) size(vsmall) rows(3) ) ///

graph play pink_change.grec 

graph save "coefplot_all.gph", replace

cd .. //save the pdf in the ${maindir}/figures/ folder
graph export "coefplot_all.pdf", replace


cd coefficientPlot
capture rm coefplot.dta
capture rm final.dta
capture rm pooled.dta
capture rm boy.dta
capture rm girl.dta
capture rm pooled.dta

// END //

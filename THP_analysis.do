//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
  * Thinking Healthy Program -- Saving Brains
  * This file takes the clean data (from THP_cleandata.do)
  *           and runs the analysis for the paper
  * By: Victoria Baranov and Pietro Biroli
  * Date: August 11, 2019

  * commands needed:
  *    pstar           (from https://github.com/PrincetonBPL/ado-gallery)
  *    leebounds       (from https://github.com/PrincetonBPL/ado-gallery)
  *    randcmd         (from A Young's website http://personal.lse.ac.uk/YoungA/)
  *    stepdownB       (adapted from https://github.com/PrincetonBPL/ado-gallery)
  *    stepdownrancmd  (adapted from https://github.com/PrincetonBPL/ado-gallery)
  *
  *    ssc install mat2txt
  *    ssc install xtgraph
  *    ssc install kdens
  *    ssc install coefplot
  *    ssc install blindschemes
  *    ssc install estout

  *    search grc1leg   (from http://www.stata.com/users/vwiggins/grc1leg/grc1leg.ado)
  *    search leebounds (from https://www.stata-journal.com/article.html?article=st0364)
  *    search ivqte     (net install st0203, from(http://www.stata-journal.com/software/sj10-3)
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
{
clear all
set matsize 10000
set more off
capture log close

noisily display "Start: $S_DATE $S_TIME"
scalar ts = clock("$S_DATE $S_TIME", "DMYhms")

/* main dir has been set in 00_readme.do; if not, run this part
global maindir "/mnt/data/Dropbox/SavingBrains/zz_AER_data_code/"
global tablefile "${maindir}/tables/"
global figurefile "${maindir}/figures/"
*/


cd "$maindir"

log using "$maindir/logfiles/THP_analysis $S_DATE.smcl", replace
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Settings
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

global sig          = "star(* 0.10 ** 0.05 *** 0.01)"
global iterations   = 1000    // 1000 is suggested for stepdownrandcmd: does RI and the permutation for stepdown, very slow!
global qtereps      = ${iterations}
local factordomains    0    //Factor scores instead of Anderson index
if `factordomains' {
	local factor _factor
}
}
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Switches
*	NOTE: To not run a part of the results
*		  set code 0 instead of 1
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local sumstattables       1
     local balance_tables            1   // creates Table 1 and Appendix Tables A1 and A2
     local dep_nondep                1   // creates Table 5 and 7
		 local sumtab_by_index           1
     local sr_diffs_bysmpl           1
     local correlation_tables        1

local analysis           1
     local depression_trajectory     1   // creates Table 2 and 3
     local main_tables               1   // creates Table 4, 6, and 9
		 local main_attrition_ipw        1   // creates Table 8
     local itt_figure                1   // creates Figure 2
     local sensitivity_controls      1
     local within_index_tables       1
     local het_tables                1
     local dd_tables                 1
     local attrition_bygender        1
     local misc                      1
     local magnitude                 1
     local gender_gaps               1
     local sci_byfertility           1

local make_graphs        1
     local dep_trends                1   // creates Figure 3
     local qte_graphs                1
     local density_graphs            1


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Clear the output folders
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cd "${tablefile}"
shell rm *.tex
*shell erase *.tex // for windows users

cd "${figurefile}"
shell rm *.pdf
shell rm *.gph
*shell erase *.pdf // for windows users
*shell erase *.gph // for windows users

cd "${maindir}"
*

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Global varlists
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
do ${maindir}THP_globalvars.do
/*
{
*baseline characteristics which will get demeaned and interacted with T in the
*programs_clean section of code
global X_control_vars "age_baseline age_baseline_sq employed_mo_baseline mo_emp  grandmother_baseline MIL wealth_baseline edu_lvl_mo_1 edu_lvl_mo_2 edu_lvl_mo_3  edu_mo_baseline edu_fa_baseline kids_no  first_child  hamd_baseline  mspss_baseline doi0"

*controls for the diff-in-diff specifications (because we don't have baseline characteristics for the non-depressed)
global controls_dd "edu_lvl_mo_7y_1 edu_lvl_mo_7y_2 edu_lvl_mo_7y_3 edu_lvl_mo_7y_4 edu_mo edu_fa c_first_child no_kids_baseline age age_sq   month_int month_int_sq "

*all design-based controls
global controls_design = "month_int month_int_sq doi0 doi0Xtreat intervr_1-intervr_9"

*interaction controls
global X_controls ""
foreach var in $X_control_vars doi0 {
	global X_controls = "$X_controls `var'Xtreat `var' "
	}

*full baseline chars interacted with T (generated in programs_clean) + design controls
global controls_baseline = "$X_controls  $controls_design "


//global majorgrouping =  "motherdecisions childoutcomes mediators"
global motherdecisions = "motherfinancial parentmoney parenttime parentstyle fertility_vars"
global childoutcomes = "healthindex cognindex emoindex  childmort"
global mediators= "motherhealthindex fatherfinancial relation_traj grandmothers socialsupport"
global infancy =  "parentinputs_infancy infantdev"
global allindices = "$motherdecisions $childoutcomes $mediators"
global motherdecisions_7y = "motherfinancial_7y parentmoney parenttime parentstyle fertility_vars"
global scales = "schoolqual_pca fsiq spence sdq_sum home"

global parenting        "parentmoney parenttime parentstyle"
global childdevelopment "cognindex healthindex emoindex"
global depression_allvars=	"depindex_7y depindex_1y depindex_6m"

}
*/

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	 SUMMARY & BALANCE TABLES
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if `sumstattables' ==1 {
noisily display "------------------SUMMARY TABLES------------------"
//////////////////////////////
//  T1: Balance/Attrition   //
//////////////////////////////
if `balance_tables' ==1 {
no di "balance_tables"
use "$maindir/dataClean/THP_clean.dta", clear

global baseline_balance "age_baseline mo_ht mo_bmi edu_mo_baseline mo_emp employed_mo_baseline kids_no first_child gender_4sum femshare hamd_baseline bdq_baseline gaf_baseline mspss_baseline var29  MIL maternalgma   edu_fa_baseline employed_fa_baseline occupation_fa_baseline  ses_bl_flipped wealth_baseline_4sum"

tempfile THP_balance
save `THP_balance', replace

clear
eststo clear
estimates drop _all
set obs 10
gen x = 1
gen y = 1

qui eststo col1: reg x y
qui eststo col2: reg x y
qui eststo col3: reg x y
qui eststo col4: reg x y
qui eststo col5: reg x y
qui eststo col6: reg x y
qui eststo col7: reg x y
qui eststo col8: reg x y
*qui eststo col9: reg x y
*qui eststo col10: reg x y

local varcount = 1
local count = 1
*local countse = `count'+ 1
local varlabels ""
local statnames ""


*local _gender "_girls"
*local _gender "_boys"

if "`_gender'"=="_girls" | "`_gender'"=="_boys" {
	global baseline_balance "age_baseline mo_ht mo_bmi edu_mo_baseline  mo_emp employed_mo_baseline kids_no   first_child  femshare hamd_baseline bdq_baseline gaf_baseline mspss_baseline var29  MIL maternalgma   edu_fa_baseline employed_fa_baseline occupation_fa_baseline  ses_bl_flipped wealth_baseline_4sum  "
}

foreach var in  $baseline_balance {
	qui use `THP_balance', clear

	if "`_gender'"=="_girls" {
	keep if girl==1
	}

	if "`_gender'"=="_boys" {
	keep if girl==0
	}

	*** COLUMN 1-2: BASELINE CONTROL MEAN ***
	qui sum `var' if ~Group  & THP_sample==1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col1
	local sd = "(" + string(r(sd), "%9.1f")+ ")"
	estadd local thisstat`count' = "`sd'": col2

	*** COLUMN 3-4: BASELINE TREATMENT EFFECT ***
	qui reg `var' Group if THP_sample==1
	pstar Group, prec(2) pnopar sestar
	estadd local thisstat`count' = "`r(bstar)'": col3
	*estadd local thisstat`count' = "`r(sestar)'": col4
	estadd local thisstat`count' = "`r(pstar)'": col4

	*** COLUMN 5-6: BASELINE TREATMENT EFFECT ***
	qui reg `var' Group  if attrit!=.
	pstar Group, prec(2) pnopar sestar
	estadd local thisstat`count' = "`r(bstar)'": col5
	*estadd local thisstat`count' = "`r(sestar)'": col4
	estadd local thisstat`count' = "`r(pstar)'": col6

	*** COLUMN 7-8: ENDLINE TREATMENT EFFECT ***
	qui reg `var' Group if ~attrit
	pstar Group, prec(2) pnopar sestar
	estadd local thisstat`count' = "`r(bstar)'": col7
	*estadd local thisstat`count' = "`r(sestar)'": col9
	estadd local thisstat`count' = "`r(pstar)'": col8

	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'"   "
	local statnames "`statnames' thisstat`count'"
	local count = `count' + 1
	*local countse = `count' + 1
	local ++varcount
}

foreach var in attrit2  {
	*** COLUMN 1-2: ENDLINE CONTROL MEAN ***
	qui sum `var' if ~Group   & THP_sample==1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col1
	local sd = "(" + string(r(sd), "%9.1f")+ ")"
	estadd local thisstat`count' = "`sd'": col2

	*** COLUMN 3-4: ENDLINE TREATMENT EFFECT ***
	qui reg `var' Group if THP_sample==1, cl(uc)
	pstar Group, prec(2) pnopar pstar
	estadd local thisstat`count' = "`r(bstar)'": col3
	*estadd local thisstat`count' = "`r(sestar)'": col4
	estadd local thisstat`count' = "`r(pstar)'": col4
	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'"   "
	local statnames "`statnames' thisstat`count'"
	local count = `count' + 1
	*local countse = `count' + 1
	local ++varcount
	}

foreach var in attrit  {
	*** COLUMN 1-2: ENDLINE CONTROL MEAN ***
	qui sum `var' if ~Group  & attrit!=.
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col1
	local sd = "(" + string(r(sd), "%9.1f")+ ")"
	estadd local thisstat`count' = "`sd'": col2

	*** COLUMN 5-6: ENDLINE TREATMENT EFFECT ***
	qui reg `var' Group  if attrit!=.
	pstar Group, prec(2) pnopar pstar
	estadd local thisstat`count' = "`r(bstar)'": col5
	*estadd local thisstat`count' = "`r(sestar)'": col4
	estadd local thisstat`count' = "`r(pstar)'": col6
	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'"   "
	local statnames "`statnames' thisstat`count'"
	local count = `count' + 1
	*local countse = `count' + 1
	local ++varcount

}

*** ADD SUR ROW ***
local suestcount = 1
local suest1 "suest "
local suest2 "suest "
local suest3 "suest "

foreach var in $baseline_balance attrit2  {

*** STORE FOR SUEST ***
	qui reg `var' Group if THP_sample==1
	estimates store model1_`suestcount'
	local suest1 "`suest1' model1_`suestcount'"
	}
	local ++suestcount


foreach var in $baseline_balance attrit  {

	qui reg `var' Group if attrit!=.
	estimates store model2_`suestcount'
	local suest2 "`suest2' model2_`suestcount'"
	}
	local ++suestcount

foreach var in $baseline_balance {
	qui reg `var' Group if ~attrit
	estimates store model3_`suestcount'
	local suest3 "`suest3' model3_`suestcount'"

	local ++suestcount
}

`suest1'
test Group
local testp = r(p)
pstar, p(`testp')  pnopar
local testp "`r(pstar)'"
estadd local testp "`testp'": col4
noisily di "P-value joint test (starting sample) = `r(pstar)'"

`suest2'
test Group
local testp = r(p)
pstar, p(`testp')  pnopar
local testp "`r(pstar)'"
estadd local testp "`testp'": col6
noisily di "P-value joint test (starting sample) = `r(pstar)'"

`suest3'
test Group
local testp = r(p)
pstar, p(`testp')  pnopar
local testp "`r(pstar)'"
estadd local testp "`testp'": col8
noisily di "P-value joint test (analysis sample) = `r(pstar)'"


local statnames "`statnames' testp "
local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" "

esttab col* using "$tablefile/baseline_balance`_gender'.tex", cells(none) f booktabs nonotes compress replace alignment(S) mgroups("\specialcell{Baseline Sample \\ N=903}" "\specialcell{1-year Sample \\ N=704}" "\specialcell{7-year Sample \\ N=585}", pattern(1 0 0 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) stats(`statnames', labels(`varlabels')) mtitle("\specialcell{Control\\ Mean}" "(st.dev.)" "\specialcell{T-C\\ Diff}" "\emph{p}-val" "\specialcell{T-C \\Diff}"  "\emph{p}-val" "\specialcell{T-C \\Diff}"  "\emph{p}-val")



***ATTRITORS

clear
eststo clear
estimates drop _all
set obs 10
gen x = 1
gen y = 1

qui eststo col1: reg x y
qui eststo col2: reg x y
qui eststo col3: reg x y
qui eststo col4: reg x y
qui eststo col5: reg x y
qui eststo col6: reg x y
qui eststo col7: reg x y
qui eststo col8: reg x y

local varcount = 1
local count = 1
local varlabels ""
local statnames ""

foreach var in  $baseline_balance abortion stillbirth childdeath motherdeath refused moved {
	qui use `THP_balance', clear

	if ("`var'" != "abortion" & "`var'" != "stillbirth" & "`var'" != "childdeath" & "`var'" != "motherdeath" & "`var'" != "refused" & "`var'" != "moved") {
	*** COLUMN 1-2: BASELINE CONTROL MEAN ***
	qui sum `var' if attrit2==0  & THP_sample==1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col1

	qui sum `var' if attrit2==1  & THP_sample==1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col2

	*** COLUMN 3-4: BASELINE TREATMENT EFFECT ***
	qui reg `var' attrit2 if THP_sample==1
	pstar attrit2, prec(2) pnopar pstar
	estadd local thisstat`count' = "`r(bstar)'": col3
	*estadd local thisstat`count' = "`r(sestar)'": col4
	estadd local thisstat`count' = "`r(pstar)'": col4
	}
	*** COLUMN 5-6: BASELINE CONTROL MEAN ***
	qui sum `var' if Group==1  & attrit2==1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col5

	qui sum `var' if Group==0 & attrit2==1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col6

	*** COLUMN 7-8: BASELINE TREATMENT EFFECT ***
	qui reg `var' Group  if attrit2==1.
	pstar Group, prec(2) pnopar pstar
	estadd local thisstat`count' = "`r(bstar)'": col7
	*estadd local thisstat`count' = "`r(sestar)'": col4
	estadd local thisstat`count' = "`r(pstar)'": col8

	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'"   "
	local statnames "`statnames' thisstat`count'"
	local count = `count' + 1
	local ++varcount
}

*** ADD SUR ROW ***
local suestcount = 1
local suest1 "suest "
local suest2 "suest "
local suest3 "suest "

foreach var in $baseline_balance stillbirth childdeath motherdeath refused moved {

*** STORE FOR SUEST ***
	qui reg `var' Group if attrit2==1
	estimates store model1_`suestcount'
	local suest1 "`suest1' model1_`suestcount'"
	}
	local ++suestcount

`suest1'
test Group
local testp = r(p)
pstar, p(`testp')  pnopar
local testp "`r(pstar)'"
estadd local testp "`testp'": col8
noisily di "P-value joint test (starting sample) = `r(pstar)'"


local statnames "`statnames' testp "
local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" "

esttab col* using "$tablefile/attrition_balance.tex", cells(none) f booktabs nonotes compress replace alignment(S) mgroups("\specialcell{Characteristics of attritors \\ N=903} " "\specialcell{Attritor characteristics \\ by treatment arm \\ N=318}" , pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) stats(`statnames', labels(`varlabels')) mtitle("\specialcell{In sample\\ Mean \\ N=585}" "\specialcell{Attritor\\ Mean \\ N=318}" "\specialcell{Diff}" "\emph{p}-val" "\specialcell{T \\ Mean \\ N=174}"   "\specialcell{C \\ mean \\ N=144}" "Diff" "\emph{p}-val")

*********************************
***Balance tables by child gender
*********************************
use "$maindir/dataClean/THP_clean.dta", clear

global baseline_balance_bygender "age_baseline mo_ht mo_bmi edu_mo_baseline  mo_emp employed_mo_baseline kids_no   first_child  femshare hamd_baseline bdq_baseline gaf_baseline mspss_baseline var29  MIL maternalgma   edu_fa_baseline employed_fa_baseline occupation_fa_baseline  ses_bl_flipped wealth_baseline_4sum  "

tempfile THP_balance
save `THP_balance', replace

clear
eststo clear
estimates drop _all
set obs 10
gen x = 1
gen y = 1

qui eststo col1: reg x y
qui eststo col2: reg x y
qui eststo col3: reg x y
qui eststo col4: reg x y
qui eststo col5: reg x y
qui eststo col6: reg x y
qui eststo col7: reg x y
qui eststo col8: reg x y

local varcount = 1
local count = 1
local varlabels ""
local statnames ""

foreach var in  $baseline_balance_bygender  {
	qui use `THP_balance', clear

	*** COLUMN 1-2: BASELINE CONTROL MEAN ***
	qui sum `var' if ~Group  & THP_sample==1 & girl==1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col1
	local sd = "(" + string(r(sd), "%9.1f")+ ")"
	estadd local thisstat`count' = "`sd'": col2

	*** COLUMN 3-4: BASELINE TREATMENT EFFECT ***
	qui reg `var' Group if THP_sample==1 & girl==1
	pstar Group, prec(2) pnopar sestar
	estadd local thisstat`count' = "`r(bstar)'": col3
	estadd local thisstat`count' = "`r(pstar)'": col4

	*** COLUMN 5-6: BASELINE CONTROL MEAN ***
	qui sum `var' if ~Group  & THP_sample==1 & girl==0
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col5
	local sd = "(" + string(r(sd), "%9.1f")+ ")"
	estadd local thisstat`count' = "`sd'": col6

	*** COLUMN 7-8: BASELINE TREATMENT EFFECT ***
	qui reg `var' Group if THP_sample==1 & girl==0
	pstar Group, prec(2) pnopar sestar
	estadd local thisstat`count' = "`r(bstar)'": col7
	estadd local thisstat`count' = "`r(pstar)'": col8

	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'"   "
	local statnames "`statnames' thisstat`count'"
	local count = `count' + 1
	local ++varcount
}

*** ADD SUR ROW ***
local suestcount = 1
local suest1 "suest "
local suest2 "suest "

foreach var in $baseline_balance attrit2  {

*** STORE FOR SUEST ***
	qui reg `var' Group if THP_sample==1 & girl==1
	estimates store model1_`suestcount'
	local suest1 "`suest1' model1_`suestcount'"

	qui reg `var' Group if THP_sample==1 & girl==0
	estimates store model2_`suestcount'
	local suest2 "`suest2' model2_`suestcount'"
	}
	local ++suestcount


`suest1'
test Group
local testp = r(p)
pstar, p(`testp')  pnopar
local testp "`r(pstar)'"
estadd local testp "`testp'": col4
noisily di "P-value joint test (starting sample) = `r(pstar)'"

`suest2'
test Group
local testp = r(p)
pstar, p(`testp')  pnopar
local testp "`r(pstar)'"
estadd local testp "`testp'": col8
noisily di "P-value joint test (starting sample) = `r(pstar)'"

local statnames "`statnames' testp "
local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" "

esttab col* using "$tablefile/baseline_balance_bygender.tex", cells(none) f booktabs nonotes compress replace alignment(S) mgroups("\specialcell{Baseline Sample - Girls \\ N=384} " "\specialcell{Baseline Sample - Girls \\ N=377} ", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) stats(`statnames', labels(`varlabels')) mtitle("\specialcell{Control\\ Mean}" "(st.dev.)" "\specialcell{T-C\\ Diff}" "\emph{p}-val" "\specialcell{Control\\ Mean}" "(st.dev.)"  "\specialcell{T-C \\Diff}"  "\emph{p}-val")


} // end if `balance_tables'
//////////////////////////////
// Summary Statistics Table //
//////////////////////////////
if `sumtab_by_index' == 1 {
use "$maindir/dataClean/THP_clean.dta", clear

foreach v in $allindices $depression_allvars {
	foreach var in $`v' {
		label variable `var' `"\hspace{0.25cm} `: variable label `var''"'
		}
	}

foreach v in $allindices $depression_allvars {
	label variable `v' `"\textbf{`: variable label `v''\textsuperscript{a}}"'
	}

global sumstats1 = ""
foreach var in $motherdecisions {
	global sumstats1 = "$sumstats1 `var' $`var'"
	}

global sumstats2 " "
foreach var in $childoutcomes  {
	global sumstats2 = "$sumstats2 `var' $`var'"
	}

global sumstats3 " "
foreach var in $mediators  {
	global sumstats3 = "$sumstats3 `var' $`var'"
	}

global sumstats4 " "
foreach var in $depression_allvars  {
	global sumstats4 = "$sumstats4 `var' $`var'"
	}



gen x = 1
gen y = 1
forvalues num = 1/4 {
	eststo clear

	qui eststo col1: reg x y
	qui eststo col2: reg x y
	qui eststo col3: reg x y
	qui eststo col4: reg x y
	qui eststo col5: reg x y
	qui eststo col6: reg x y

	local varcount = 1
	local count = 1
	local varlabels ""
	local statnames ""

	foreach var of global sumstats`num' {
		replace `var' = . if three_groups==.
		local endvar `var'
		local bevar `var'

		*** COLUMN 1: MEAN ***
		qui sum `endvar', detail
		local mean = string(r(mean), "%9.2f")
		estadd local thisstat`count' = "`mean'": col1
		*estadd local thisspace`count' = " ": col1

		*** COLUMN 2: SD ***
		qui sum `endvar', detail
		local sd = string(r(sd), "%9.1f")
		estadd local thisstat`count' = "`sd'": col2
		*estadd local thisspace`count' = " ": col2

		*** COLUMN 3: MEDIAN ***
		qui sum `endvar', detail
		local med = string(r(p50), "%9.1f")
		estadd local thisstat`count' = "`med'": col3
		*estadd local thisspace`count' = " ": col3

		*** COLUMN 4: MIN  ***
		qui sum `endvar', detail
		local min = string(r(min), "%9.1f")
		estadd local thisstat`count' = "`min'": col4
		*estadd local thisspace`count' = " ": col4

		*** COLUMN 5: MAX ***
		qui sum `endvar', detail
		local max = string(r(max), "%9.1f")
		estadd local thisstat`count' = "`max'": col5
		*estadd local thisspace`count' = " ": col5

		*** COLUMN 6: OBSERVATIONS ***
		cap sum `bevar', detail
		if _rc == 0 local n2 = string(r(N), "%9.0f")
		else local n2 = string(0, "%9.0f")
		estadd local thisstat`count' = "`n2'": col6
		*estadd local thisspace`count' = " ": col6

		*** LABELS ***
		local thisvarlabel: variable label `endvar'
		local varlabels "`varlabels' "`thisvarlabel'" "
		local statnames "`statnames' thisstat`count' "
		local ++count
	} // end foreach var

	esttab col* using "$tablefile/c_sumstats`num'.tex", cells(none) booktabs nonotes compress replace alignment(ccccccc) mtitle("Mean" "SD" "Median" "Min." "Max." "\specialcell{Total\\Obs}")  stats(`statnames', labels(`varlabels') ) nonum
} // end forvalues num
use "$maindir/dataClean/THP_clean.dta", clear

} // end if `sumtab_by_index'

////////////////////////////////
//  Depressed/Non Depressed   //
////////////////////////////////
if `dep_nondep' == 1 {
use "$maindir/dataClean/THP_clean.dta", clear

global mothergap "depindex_7y motherfinancial_7y parentmoney parenttime parentstyle no_kids_postt"

tempfile THP_clean
save `THP_clean', replace

foreach vargroup in mothergap childoutcomes {
	clear
	eststo clear
	estimates drop _all
	set obs 10
	gen x = 1
	gen y = 1

	qui eststo col1: reg x y
	qui eststo col2: reg x y
	qui eststo col3: reg x y
	qui eststo col4: reg x y

	local varcount = 1
	local count = 1
	local countse = `count'+ 1
	local varlabels ""
	local statnames ""

	foreach var in   $`vargroup' {
		qui use `THP_clean', clear
		keep if three_groups!=2

		*** COLUMN 1:  T-C  ***
		qui reg `var' dep_sample
		pstar dep_sample, prec(2)  pnopar pstar
		estadd local thisstat`count' = "`r(bstar)'": col1
		estadd local thisstat`countse' = "`r(sestar)'": col1

		*** COLUMN 2:  BY GENDER  ***
		qui reg `var' dep_sample   if girl==1
		pstar dep_sample, prec(2)  pnopar pstar
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2

		*** COLUMN 3: Boys  ***
		qui reg `var' dep_sample  if girl==0
		pstar dep_sample, prec(2)  pnopar pstar
		estadd local thisstat`count' = "`r(bstar)'": col3
		estadd local thisstat`countse' = "`r(sestar)'": col3

		*** COLUMN 4: interaction with girl  ***
		gen dep_sampleXgirl=dep_sample*girl
		qui reg `var' dep_sample dep_sampleXgirl girl
		pstar dep_sampleXgirl, prec(2) pstar pnopar
		estadd local thisstat`count' = "`r(pstar)'": col4

		*** ITERATE ***
				local thisvarlabel: variable label `var'
				local varlabels "`varlabels' "`thisvarlabel'" " " "
				local statnames "`statnames' thisstat`count' thisstat`countse'"
				local count = `count' + 2
				local countse = `count' + 1
				local ++varcount
		}
		esttab col* using "$tablefile/c_dep_nondep_`vargroup'.tex", cells(none) f booktabs nonotes compress replace alignment(S)  mgroups("\specialcell{Depressed controls $-$ Non-Depressed}"  , pattern(1  0 0  0  ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle(      "Pooled"       "Girls" "Boys" "p-value") stats(`statnames', labels(`varlabels'))
	}
} // end if `dep_nondep'

///////////////////////////////////////////
//  SR Diffs in TE by Attrition Sample   //
///////////////////////////////////////////
if `sr_diffs_bysmpl' == 1 {
noisily display "sr_diffs_bysmpl"
global sr_mentalhealth "depressed_6m depressed_1y hamd_6m hamd_1y bdq_6m bdq_1y gaf_6m gaf_1y mspss_6m mspss_1y"

		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		qui eststo col4: reg x y
		qui eststo col5: reg x y

		local varcount = 1
		local count = 1
 		local varlabels ""
		local statnames ""

		foreach var in $sr_mentalhealth  {
			qui use "$maindir/dataClean/THP_clean.dta", clear

			*** COLUMN 1: All data ***
			qui reg `var' Group
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1

			*** COLUMN 2:  7-yr sample ***
			qui reg `var' Group if ~attrit
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col2

			*** COLUMN 3:  Diffs  ***
			qui reg `var' Group
			local beta1 = _b[Group]
			qui reg `var' Group if ~attrit
			local beta2 = _b[Group]
			local diff = `beta1' - `beta2'
			local diff_s = string(`diff', "%9.2f")
			estadd local thisstat`count' = "`diff_s'": col3

			*** COLUMN 4:  sd***
			sum `var'
			local b_sd= abs(`diff'/r(sd)*100)
			local sd = string(`b_sd', "%9.0f")+"\%"
			estadd local thisstat`count' = "`sd'": col4

			*** COLUMN 5:  interacted with attrition ***
			gen GroupXattrit2=Group*attrit2
			qui reg `var' Group GroupXattrit2 attrit2
			pstar GroupXattrit2, prec(2) pnopar
			estadd local thisstat`count' = "`r(pstar)'": col5

			*** ITERATE ***
			local thisvarlabel: variable label `var'
			local varlabels "`varlabels' "`thisvarlabel'" "
			local statnames "`statnames' thisstat`count' "
			local count = `count' + 2
			local ++varcount
		}

		foreach var in mspss gaf {
			gen `var'_6m_flipped = -`var'_6m
			gen `var'_1y_flipped = -`var'_1y
		}

		global sr_mentalhealth_flipped_6m "depressed_6m  hamd_6m  bdq_6m  mspss_6m_flipped  gaf_6m_flipped "
		global sr_mentalhealth_flipped_1y  " depressed_1y  hamd_1y  bdq_1y  mspss_1y_flipped  gaf_1y_flipped"
		sureg ($sr_mentalhealth_flipped_6m = treat##attrit2)
		test 1.treat#1.attrit2
		local testp = r(p)
		pstar, p(`testp')  pnopar
		local testp "`r(pstar)'"
		estadd local testp_6m "`testp'": col5

		sureg ($sr_mentalhealth_flipped_1y = treat##attrit2)
		test 1.treat#1.attrit2
		local testp = r(p)
		pstar, p(`testp')  pnopar
		local testp "`r(pstar)'"
		estadd local testp_1y "`testp'": col5

		local statnames "`statnames' testp_6m testp_1y "
		local varlabels "`varlabels' "\midrule Joint test at 6m (\emph{p}-value)" "Joint test at 1y (\emph{p}-value) " "

		esttab col* using "$tablefile/c_treatmenteffect_diffs_byattrition.tex", cells(none) booktabs nonotes compress replace alignment(SSSSS) mgroups("\specialcell{Coefficient on Treat \\ ($\beta$ / (s.e.))}" "Difference between samples", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("\specialcell{Full \\ sample}" "\specialcell{7-yr \\ followup \\ sample}" "\specialcell{ Raw Diff. }" "\specialcell{ Diff. in \\ st.devs. }" "\specialcell{ \emph{p}-value }") stats(`statnames', labels(`varlabels'))

} // end if `sr_diffs_bysmpl'
////////////////////////
// Correlation Tables //
////////////////////////
if `correlation_tables'  {
noisily display "correlation_tables"
use "${maindir}/dataClean/THP_clean.dta", clear

global intermediates "play_mo_1y play_fa_1y diarhea_1y_flip  exclusivebf_6m ari_1y_flip"
global baseline_demo "girl c_age_int wealth_baseline edu_mo edu_fa  age age_sq no_kids_baseline grandmother_baseline"
global depression_vars "depressed depindex_0"

foreach thisvargroup in parenting childdevelopment {
	local count = 1
	eststo clear
	foreach var in $`thisvargroup'  {
		eststo: reg `var' $baseline_demo i.interviewer, cl(uc) , if treat==0
		eststo: reg `var' $baseline_demo $depression_vars i.interviewer, cl(uc) , if treat==0
		eststo: reg `var' $baseline_demo $depression_vars $intermediates i.interviewer, cl(uc) , if treat==0
		local var`count'label: variable label `var'
		local count = `count' + 1
		} // end of foreach var
	esttab using "${tablefile}/correlates_index_`thisvargroup'`factor'.tex",  cells("b(fmt(%8.2f)star)" "se(fmt(%8.2f)par)") stats(N r2, fmt(0 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") labels(`"Observations"' `"\(R^{2}\)"')) replace booktabs label nonotes compress alignment(SSSSSSSSS) collabels(none)  keep($baseline_demo $depression_vars $intermediates) mgroups("`var1label'" "`var2label'" "`var3label'", pattern(1 0 0 1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nomtitles star(* 0.10 ** 0.05 *** 0.01)
} // end of foreach thisvargroup
} // end if correlation_tables

} // end if sumstattables

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	ANALYSIS - REGRESSIONS & QTE
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if `analysis' == 1 {
use "$maindir/dataClean/THP_clean.dta", clear
noisily display "------------------ANALYSIS------------------"
/////////////////////////
// Depression Results  //
/////////////////////////
if `depression_trajectory' == 1{
noisily display "depression_trajectory"
use "$maindir/dataClean/THP_clean.dta", clear


la var recover_never 	"Never recovered\tnote{a}"
la var recover_perm 	"Recovered permanently\tnote{a}"

global depression_mainvars "depressed_6m depindex_6m depressed_1y depindex_1y depressed depindex_7y recover_perm recover_never"

foreach var in depressed_6m depressed_1y depressed {
 la var `var' "Depressed"
 }
foreach var in depindex_6m depindex_1y depindex_7y {
 la var `var' "Depression severity"
 }
foreach var in mspss_6m mspss_1y mspss_tot {
 la var `var' "Perceived social support"
 }

la var depressed_6m `" \multicolumn{10}{l}{\emph{At the 6-month followup}}\\ \hspace{0.15cm}`: variable label depressed_6m ' "'
la var depressed_1y `" \multicolumn{10}{l}{\emph{At the 1-year followup}}\\ \hspace{0.15cm}`: variable label depressed_1y ' "'
la var depressed `" \multicolumn{10}{l}{\emph{At the 7-year followup}}\\ \hspace{0.15cm}`: variable label depressed ' "'

la var recover_perm `" \multicolumn{10}{l}{\emph{Recovery trajectory}}\\ \hspace{0.15cm}`: variable label recover_perm ' "'

foreach v in depindex_6m mspss_6m  depindex_1y mspss_1y  depindex_7y mspss_tot recover_never {
	label variable `v' `"\hspace{0.15cm}`: variable label `v' ' "'
	}

tempfile THP_within
save `THP_within', replace

foreach thisvargroup in depression_mainvars {
	local varlabels ""
	local statnames ""

		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		qui eststo col4: reg x y
		qui eststo col5: reg x y
		qui eststo col6: reg x y
		qui eststo col7: reg x y
		qui eststo col8: reg x y
		qui eststo col9: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
		local varlabels ""
		local statnames ""

		*** STEP DOWN ***
		use `THP_within', clear

		foreach var in $`thisvargroup' {
			qui use `THP_within', clear

				*** COLUMN 1: CONTROL MEAN ***
				qui sum `var' if control & ~attrit
				local mean = string(r(mean), "%9.2f")
				estadd local thisstat`count' = "`mean'": col1
				local sd = "(" + string(r(sd), "%9.2f")+ ")"
				estadd local thisstat`countse' = "`sd'": col1

				*** COLUMN 2: No controls ***
				qui reg `var' Group $controls_design  if ~attrit , cluster(uc)
				pstar Group, prec(2) pstar
				estadd local thisstat`count' = "`r(bstar)'": col2
				estadd local thisstat`countse' = "`r(sestar)'": col2

				*** COLUMN 3:  All controls ***
				qui reg `var' Group $controls_baseline  if ~attrit , cluster(uc)
				pstar Group, prec(2) pstar
				estadd local thisstat`count' = "`r(bstar)'": col3
				estadd local thisstat`countse' = "`r(sestar)'": col3

				*** COLUMN 4: FWER P-VALUE ***
				randcmd ((Group) reg `var' Group $controls_baseline  if ~attrit , cluster(uc)), treatvars(Group) reps(${iterations})
				mat define A=e(RCoef)
				scalar p = A[1,6]
				local pRI = string(p, "%9.3f")
				estadd local thisstat`count' = "`pRI'": col4

				*** COLUMN 5: CONTROL MEAN GIRL ***
				qui sum `var' if control & ~attrit & girl==1
				local mean = string(r(mean), "%9.2f")
				estadd local thisstat`count' = "`mean'": col5

				*** COLUMN 6: CONTROL MEAN BOY ***
				qui sum `var' if control & ~attrit & girl==0
				local mean = string(r(mean), "%9.2f")
				estadd local thisstat`count' = "`mean'": col6

				*** COLUMN 7: Girls ***
				qui reg `var' Group $controls_baseline  if ~attrit & girl, cluster(uc)
				pstar Group, prec(2) pstar
				estadd local thisstat`count' = "`r(bstar)'": col7
				estadd local thisstat`countse' = "`r(sestar)'": col7

				*** COLUMN 8: Boys ***
				qui reg `var' Group $controls_baseline  if ~attrit & ~girl, cluster(uc)
				pstar Group, prec(2) pstar
				estadd local thisstat`count' = "`r(bstar)'": col8
				estadd local thisstat`countse' = "`r(sestar)'": col8

				*** COLUMN 9: Gender diff ***
				// run the regression without cluster (suest doesn't work otherwise)
				qui reg `var' Group $controls_baseline  if ~attrit  & girl
				estimates store beta_girls
				qui reg `var' Group $controls_baseline  if ~attrit  & ~girl
				estimates store beta_boys
				// test the difference clustering the s.e.
				suest beta_girls beta_boys, cluster(uc)
				test [beta_girls_mean]Group = [beta_boys_mean]Group
				local testp = r(p)
				pstar, prec(3) p(`testp')  pnopar
				estadd local thisstat`count' = "`r(pstar)'": col9


				*** ITERATE ***
				local thisvarlabel: variable label `var'
				local varlabels "`varlabels' "`thisvarlabel'" " " "
				local statnames "`statnames' thisstat`count' thisstat`countse'"
				local count = `count' + 2
				local countse = `count' + 1
				local ++varcount
			} // end foreach var

			esttab col* using "$tablefile/depression_mainvars.tex", cells(none) f booktabs nonotes compress replace alignment(SSSSSS)  mtitle("\specialcell{Control \\ group \\ mean}" "\specialcell{ \\ $\beta$ \\ (s.e.)}" "\specialcell{Adjusted \\ $\beta$ \\ (s.e.)}" "\specialcell{RI \\ \emph{p}-value}"     "\specialcell{Girl\\ control \\ mean}" "\specialcell{Boy\\ control \\ mean}" "\specialcell{  $\beta^{Girl}$ \\ (s.e.)}" "\specialcell{ $\beta^{Boy}$ \\ (s.e.)}" "\specialcell{$\beta^{Girl}=$ \\ $\beta^{Boy}$ \\ \emph{p}-value}" ) stats(`statnames', labels(`varlabels')) mgroups("Full sample" "By child gender", pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

} // end foreach thisvargroup
} // end if `depression_trajectory'

//////////////////
// Main Results //
//////////////////
if `main_tables' == 1{
noisily display "main_tables"
use "$maindir/dataClean/THP_clean.dta", clear

foreach thisvargroup in  motherdecisions childoutcomes mediators motherdecisions_7y{
	local varlabels ""
	local statnames ""
		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		qui eststo col4: reg x y
		qui eststo col5: reg x y
		qui eststo col6: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
 		local varlabels ""
		local statnames ""

		*** STEP DOWN ***
		use "$maindir/dataClean/THP_clean.dta", clear

		cap mat drop A2
		stepdownrandcmd reg ($`thisvargroup') treat month_int month_int_sq intervr_1-intervr_9   if ~attrit & sample==1, options(cluster(uc)) iter($iterations) txcontrols($X_control_vars) rcluster(uc)
		mat A2 = r(p)

		foreach var in  $`thisvargroup' {
			qui use "$maindir/dataClean/THP_clean.dta", clear

			*** COLUMN 1:  No controls ***
			reg `var' Group $controls_design if ~attrit , cluster(uc)
			pstar Group, prec(2) pstar
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2:  All controls ***
			qui reg `var' Group $controls_baseline  if ~attrit , cluster(uc)
			pstar Group, prec(2) pstar
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2

			*** COLUMN 3: FWER P-VALUE ***
			local thisp1 = A2[1,`varcount']
			pstar, p(`thisp1') pnopar prec(3)
			estadd local thisstat`count' = "`r(pstar)'": col3

			*** COLUMN 4: Girls All controls ***
			qui reg `var' Group $controls_baseline  if ~attrit  & girl, cluster(uc)
			pstar Group, prec(2) pstar
			estadd local thisstat`count' = "`r(bstar)'": col4
			estadd local thisstat`countse' = "`r(sestar)'": col4

			*** COLUMN 5: Boys All controls ***
			qui reg `var' Group $controls_baseline  if ~attrit  & ~girl, cluster(uc)
			pstar Group, prec(2) pstar
			estadd local thisstat`count' = "`r(bstar)'": col5
			estadd local thisstat`countse' = "`r(sestar)'": col5

			*** COLUMN 6: Gender diff ***
			qui reg `var' Group $controls_baseline  if ~attrit  & girl
			estimates store beta_girls
			qui reg `var' Group $controls_baseline  if ~attrit  & ~girl
			estimates store beta_boys
			suest beta_girls beta_boys, cluster(uc)
			test [beta_girls_mean]Group = [beta_boys_mean]Group
			local testp = r(p)
			pstar, prec(3) p(`testp')  pnopar
			estadd local thisstat`count' = "`r(pstar)'": col6

			*** ITERATE ***
			local thisvarlabel: variable label `var'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}

		local statnames "`statnames' "
		local varlabels "`varlabels' "

		esttab col* using "$tablefile/c_main_`thisvargroup'`factor'.tex", cells(none) f booktabs nonotes compress replace alignment(SSSS) mgroups("Coefficient on Treat - Full Sample"  "By child gender", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("\specialcell{  \\ $\beta$ / (s.e.)}" "\specialcell{ Adjusted \\ $\beta$ / (s.e.)}" "\specialcell{FWER \\ \emph{p}-val \\ spec (2)}" "\specialcell{  $\beta^{Girl}$ \\ (s.e.)}" "\specialcell{ $\beta^{Boy}$ \\ (s.e.)}" "\specialcell{$\beta^{Girl}=$ \\ $\beta^{Boy}$ \\ \emph{p}-value}") stats(`statnames', labels(`varlabels'))


}
}


//////////////////
// ITT Figure   //
//////////////////
if `itt_figure' == 1{
noisily display "Generate Treatment Effects (pooled and by gender) with RI p-values for the main Figure of coefficients"
use "$maindir/dataClean/THP_clean.dta", clear

* create matrix where to store beta and pval
local bases depindex_7y $motherdecisions $childoutcomes $mediators
local nbases : word count `bases'
foreach sample in pooled girl boy{
	matrix P`sample' = J(`nbases',2,.)
	matrix rowname P`sample' = `bases'
	matrix colname P`sample' = beta rand-pval
}

local iter=1
foreach var of varlist depindex_7y $motherdecisions $childoutcomes $mediators{ //

	*** RANDOMIZATION INFERENCE ***

	**** pooled
	*coeff
	qui reg `var' Group $controls_baseline  if ~attrit , cluster(uc)
	matrix Ppooled[`iter',1] = _b[Group]
	scalar beta_pooled_`var' = _b[Group]

		*pval
	cap mat drop Apooled
	randcmd ((Group) reg `var' Group $controls_baseline  if ~attrit , cluster(uc)), treatvars(Group) reps($iterations)
	mat define Apooled=e(RCoef)
	matrix Ppooled[`iter',2] = Apooled[1,6]
	scalar p_pooled_`var' = Apooled[1,6]

	***** girl
	*coeff
	qui reg `var' Group $controls_baseline  if ~attrit  & girl==1, cluster(uc)
	matrix Pgirl[`iter',1] = _b[Group]
	scalar beta_girl_`var' = _b[Group]
		*pval
	cap mat drop Agirl
	randcmd ((Group) reg `var' Group $controls_baseline  if ~attrit & girl==1, cluster(uc)), treatvars(Group) reps($iterations)
	mat define Agirl=e(RCoef)
	matrix Pgirl[`iter',2] = Agirl[1,6]
	scalar p_girl_`var' = Agirl[1,6]

	***** boy
	*coeff
	qui reg `var' Group $controls_baseline  if ~attrit  & girl==0, cluster(uc)
	matrix Pboy[`iter',1] = _b[Group]
	scalar beta_boy_`var' = _b[Group]

	*pval
	cap mat drop Aboy
	randcmd ((Group) reg `var' Group $controls_baseline  if ~attrit & girl==0, cluster(uc)), treatvars(Group) reps($iterations)
	mat define Aboy=e(RCoef)
	matrix Pboy[`iter',2] = Aboy[1,6]
	scalar p_boy_`var' = Aboy[1,6]

	local ++iter
	}

*save the matrices
cd figures/coefficientPlot/
foreach sample in pooled girl boy{
	matrix list P`sample'
	mat2txt , matrix(P`sample') saving(P`sample') replace
}

scalar list

do ${maindir}/figures/coefficientPlot/coefplot_all.do

cd "${maindir}"
} // END IF ITT_FIGURE


/////////////////////////
// Control sensitivity //
/////////////////////////
if `sensitivity_controls' == 1{
noisily display "sensitivity_controls"
use "$maindir/dataClean/THP_clean.dta", clear

** NOTE: This has the be ran twice: once with the flag for factor, and once without (anderson index)

if ("`factordomains'" == "1") global allindices = "parentmoney parenttime parentstyle healthindex cognindex emoindex"

	local varlabels ""
	local statnames ""
		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		qui eststo col4: reg x y
		*qui eststo col5: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
 		local varlabels ""
		local statnames ""

		*** STEP DOWN ***
		use "$maindir/dataClean/THP_clean.dta", clear

		foreach var in depindex_1y depindex_7y motherfinancial_7y $allindices {
			qui use "$maindir/dataClean/THP_clean.dta", clear

			*** COLUMN 1:  No controls ***
			qui reg `var' Group  if ~attrit , cluster(uc)
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2: Interviewer FEs ***
			qui reg `var' Group $controls_design  if ~attrit , cluster(uc)
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2

			*** COLUMN 3: Individual Controls ***
			qui reg `var' Group $X_control_vars $controls_design if ~attrit , cluster(uc)
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3

			*** COLUMN 4: Individual Controls ***
			qui reg `var' Group $controls_baseline if ~attrit , cluster(uc)
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col4
			estadd local thisstat`countse' = "`r(sestar)'": col4

			*** ITERATE ***
			local thisvarlabel: variable label `var'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}

		local statnames "`statnames' "
		local varlabels "`varlabels' "

		esttab col* using "$tablefile/c_control_sensitivity`factor'.tex", cells(none) f booktabs nonotes compress replace alignment(SSSS) mgroups("Coefficient on Treat ($\beta$ / (s.e.))" , pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("\specialcell{No \\ controls}" "\specialcell{Interviewer \\ FEs}" "\specialcell{+ Individual \\ controls}" "\specialcell{+ Ind. $\times$ T \\ controls}"  ) stats(`statnames', labels(`varlabels'))

} //end if `sensitivity_controls'

/////////////////////////
// Within Index Tables //
/////////////////////////
if `within_index_tables' == 1{
noisily display "within_index_tables"
use "$maindir/dataClean/THP_clean.dta", clear

global dep_support "depindex_6m depindex_1y depindex_7y motherfinancial parentmoney parenttime parentstyle fertility_vars motherfinancial_7y healthindex cognindex emoindex childmort fatherfinancial motherhealthindex grandmothers socialsupport relation_traj parentinputs_infancy infantdev home schoolqual_pca"
foreach v in $allindices $infancy fsiq sdq_sum spence home motherfinancial_7y $dep_support {
	label variable `v' `"\hspace{-0.05cm}\textbf{`: variable label `v' '}"'
}
foreach vgroup in $allindices $infancy schoolqual_pca $dep_support {
	foreach v in $`vgroup' {
	label variable `v' `"\hspace{0.15cm}`: variable label `v' ' "'
	}
}
tempfile THP_within
save `THP_within', replace

foreach thisvargroup in  $dep_support {
	noisily display "...Within-table `thisvargroup': $S_TIME"

	local varlabels ""
	local statnames ""

		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		qui eststo col4: reg x y
		qui eststo col5: reg x y
		qui eststo col6: reg x y
		qui eststo col7: reg x y
		qui eststo col8: reg x y
		qui eststo col9: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
		local varlabels ""
		local statnames ""

		*** STEP DOWN ***
		use `THP_within', clear

		cap mat drop A2
		stepdownB reg ($`thisvargroup') treat month_int month_int_sq intervr_1-intervr_9   if ~attrit & sample==1, options(cluster(uc)) iter($iterations) txcontrols($X_control_vars) rcluster(uc)
		mat A2 = r(p)
		reg `thisvargroup' treat  $controls_baseline if ~attrit & sample==1, cl(uc)
		pstar treat, prec(2)
		mat A2 = [`r(pstar)',A2]

		foreach var in `thisvargroup' $`thisvargroup' {
			qui use `THP_within', clear

				*** COLUMN 1: CONTROL MEAN ***

				qui sum `var' if control & ~attrit
				local mean = string(r(mean), "%9.2f")
				estadd local thisstat`count' = "`mean'": col1
				local sd = "(" + string(r(sd), "%9.2f")+ ")"
				estadd local thisstat`countse' = "`sd'": col1

				*** COLUMN 2: No controls ***
				qui reg `var' Group $controls_design  if ~attrit , cluster(uc)
				pstar Group, prec(2)
				estadd local thisstat`count' = "`r(bstar)'": col2
				estadd local thisstat`countse' = "`r(sestar)'": col2

				*** COLUMN 3:  All controls ***
				qui reg `var' Group $controls_baseline  if ~attrit , cluster(uc)
				pstar Group, prec(2)
				estadd local thisstat`count' = "`r(bstar)'": col3
				estadd local thisstat`countse' = "`r(sestar)'": col3

				*** COLUMN 4: FWER P-VALUE ***
				local thisp1 = A2[1,`varcount']
				pstar, p(`thisp1') pnopar pstar prec(2)
				estadd local thisstat`count' = "`r(pstar)'": col4

				*** COLUMN 5: CONTROL MEAN GIRL ***
				qui sum `var' if control & ~attrit & girl==1
				local mean = string(r(mean), "%9.2f")
				estadd local thisstat`count' = "`mean'": col5

				*** COLUMN 6: CONTROL MEAN BOY ***
				qui sum `var' if control & ~attrit & girl==0
				local mean = string(r(mean), "%9.2f")
				estadd local thisstat`count' = "`mean'": col6

				*** COLUMN 7: Girls All controls ***
				gen GroupXgirl=Group*girl
				gen GroupXnogirl=Group-GroupXgirl
				qui reg `var' GroupXgirl GroupXnogirl girl $controls_baseline  if ~attrit , cluster(uc)
				pstar GroupXgirl, prec(2)
				estadd local thisstat`count' = "`r(bstar)'": col7
				estadd local thisstat`countse' = "`r(sestar)'": col7

				*** COLUMN 8: Vulnerable All controls ***
				*qui reg `var' Group  $controls_baseline  if ~attrit & girl==0, cluster(uc)
				pstar GroupXnogirl, prec(2)
				estadd local thisstat`count' = "`r(bstar)'": col8
				estadd local thisstat`countse' = "`r(sestar)'": col8

				*** COLUMN 9: Gender diff ***
				qui reg `var' Group girl GroupXgirl $controls_baseline  if ~attrit  , cluster(uc)
				pstar GroupXgirl, prec(2) pnopar
				estadd local thisstat`count' = "`r(pstar)'": col9

				*** ITERATE ***
				local thisvarlabel: variable label `var'
				local varlabels "`varlabels' "`thisvarlabel'" " " "
				local statnames "`statnames' thisstat`count' thisstat`countse'"
				local count = `count' + 2
				local countse = `count' + 1
				local ++varcount
			}

			esttab col* using "$tablefile/c_within_`thisvargroup'.tex", cells(none) f booktabs nonotes compress replace alignment(SSSSSS)  mtitle("\specialcell{Control \\ mean}" "\specialcell{No controls \\ $\beta$ \\ (s.e.)}" "\specialcell{All controls \\ $\beta$ \\ (s.e.)}" "\specialcell{FWER\\p-value}"     "\specialcell{Girl\\ control \\ mean}" "\specialcell{Boy\\ control \\ mean}" "\specialcell{  $\beta^{Girl}$ \\ (s.e.)}" "\specialcell{ $\beta^{Boy}$ \\ (s.e.)}" "\specialcell{$\beta^{Girl}=$ \\ $\beta^{Boy}$ \\ p-value}" ) stats(`statnames', labels(`varlabels')) mgroups("Full sample" "By child gender", pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

}
}

///////////////////////////
// Heterogeneous Effects //
///////////////////////////
if `het_tables' ==1 {
noisily display "het_tables"
use "$maindir/dataClean/THP_clean.dta", clear


global het1  = "edu_mo_baseline young first_child wealth_baseline grandmother_baseline"

gen young=age_baseline<27 if age_baseline!=.
gen more_edu = edu_mo_baseline>=9 if edu_mo_baseline!=.
egen mspss_z = std(mspss_baseline)

la var wealth_baseline       "Wealth index"
la var famstruct_baseline    "Living w/ extended fam."
la var grandmother_baseline  "Grandmother present"
la var edu_parents           "Parents' avg educ"
la var girl                  "Girl index child"
la var age_baseline          "Mother's age"
la var young                 "Younger mother (age $<$ 27)"
la var more_edu              "Mother went to high school"
la var depindex_0            "Depression severity (z-score)"
la var first_child           "First child"
la var mspss_z               "Perceived social support (z-score)"

foreach var2 in $het1 {
	cap drop treatX`var2'
	gen treatX`var2' = treat*`var2'
	local i_label:  var label `var2'
	la var 	treatX`var2'  "Treat $\times$ \\ `i_label' "
	}


tempfile THP_het
save `THP_het', replace

global deptrajectory = "depindex_6m depindex_1y depindex_7y"
global specificoutcomes = "depressed empowered home schoolqual_pca zhaz fsiq"
global majorgrouping2 = "deptrajectory motherdecisions childoutcomes specificoutcomes"

foreach hetgroup in het1 {
	global het_effects "$`hetgroup'"
	no: di "$het_effects"
	foreach thisvargroup in $majorgrouping2  {
	local varlabels ""
	local statnames ""
	local hetcount = 1

		foreach interact in $het_effects {

		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
		local varlabels ""
		local statnames ""

		foreach var in  $`thisvargroup' {
			qui use `THP_het', clear

			local thisvarname "`var'"
			local interaction "treatX`interact'"
			local thiscontrol "i.interviewer month_int month_int_sq "
			local interact_label: var label `interact'
			local interaction_label: var label `interaction'

			*** COLUMN 1: Treatment Effect ***
			qui reg `thisvarname' Group `interact' `interaction' `thiscontrol' if ~attrit, cluster(uc)
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2: Interactation Effect ***
			pstar `interaction', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2

			*** COLUMN 3: Interactant Effect ***
			pstar `interact', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3

			*** ITERATE ***
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
			}
		noisily di "`hetcount' == `interact'"

		if `hetcount' > 1  {
		noisily di "Appending"
		esttab col* using "$tablefile/c_`thisvargroup'_`hetgroup'`factor'.tex", cells(none) f $sig  plain nomtitles nonumbers nonotes compress append  stats(`statnames', labels(`varlabels') ) mgroups("\textbf{Baseline characteristic: `interact_label' }" , pattern(1 0 0 ) prefix(\multicolumn{@span}{l}{) suffix(}) span ) //erepeat(\cmidrule(lr){@span})
		}
		if `hetcount' == 1 {
		noisily di "First"
		esttab col* using "$tablefile/c_`thisvargroup'_`hetgroup'`factor'.tex", cells(none) f $sig plain  nonotes compress replace  stats(`statnames', labels(`varlabels') ) nomtitles nonumbers mgroups("\textbf{Baseline characteristic: `interact_label' }" , pattern(1 0 0 ) prefix(\multicolumn{@span}{l}{) suffix(}) span  ) // erepeat(\cmidrule(lr){@span})
		}
		local hetcount = `hetcount'+1
		}
	} // end foreach thisvargroup in $majorgrouping2
} // end foreach hetgroup


} // end if het_tables

//////////////////////////////
// Difference-in-difference //
//////////////////////////////
if `dd_tables' ==1 {
noisily display "dd_tables"
use "$maindir/dataClean/THP_clean.dta", clear

la var depXtreat "Treat $\times$ \\ Prenatally \\ Depressed"
la var dep_sample " Prenatally \\ Depressed "

foreach var in $allindices {
	replace `var'=. if sample==2
	}

tempfile THP_dd
save `THP_dd', replace

* All indices, without LHW FEs
	local varlabels ""
	local statnames ""
		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		*qui eststo col4: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
		local varlabels ""
		local statnames ""

		foreach var in depindex_7y motherfinancial_7y $motherdecisions $childoutcomes  {
			qui use `THP_dd', clear

			local thisvarname "`var'"
			local interact "dep_sample"
			local interaction "depXtreat"
			local thiscontrol "$controls_dd i.interviewer"
			local interact_label: var label `interact'
			local interaction_label: var label `interaction'

			*** COLUMN 1: Treatment Effect ***
			qui reg `thisvarname' treat `interact' `interaction' `thiscontrol', cluster(uc)
			pstar treat, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2: Interactation Effect ***
			pstar `interaction', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2

			*** COLUMN 3: Interactant Effect ***
			pstar `interact', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3

			*** ITERATE ***
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}
		esttab col* using "$tablefile/c_dd_allindices`factor'.tex", cells(none) f booktabs nonotes compress replace alignment(SSSc)  mtitle("Treat" "\specialcell{`interaction_label'}" "\specialcell{`interact_label'}"  "N" ) stats(`statnames', labels(`varlabels') ) mgroups("Coefficient on" , pattern(1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

*With LHW FEs
	local varlabels ""
	local statnames ""
		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
		local varlabels ""
		local statnames ""

		foreach var in depindex_7y motherfinancial_7y $motherdecisions $childoutcomes  {
			qui use `THP_dd', clear

			local thisvarname "`var'"
			local interact "dep_sample"
			local interaction "depXtreat"
			local thiscontrol "$controls_dd lhw_* i.interviewer"
			local interact_label: var label `interact'
			local interaction_label: var label `interaction'

			*** COLUMN 1: Treatment Effect ***
			qui reg `thisvarname' treat `interact' `interaction' `thiscontrol', cluster(uc)
			pstar treat, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2: Interactation Effect ***
			pstar `interaction', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2

			*** COLUMN 3: Interactant Effect ***
			pstar `interact', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3

			*** ITERATE ***
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}
		esttab col* using "$tablefile/c_dd_allindices_lhwFE`factor'.tex", cells(none) f booktabs nonotes compress replace alignment(SSSc)  mtitle("Treat" "\specialcell{`interaction_label'}" "\specialcell{`interact_label'}"  "N" ) stats(`statnames', labels(`varlabels') ) mgroups("Coefficient on" , pattern(1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

* --------------------------------------------
* Depression outcomes
* --------------------------------------------
use `THP_dd', clear
gen dep1213=1-notdep1213
la var dep1213 "MDE in previous 2yrs"
sum scid_tot
replace scid_tot=(r(max)-scid_tot)/10
la var scid_tot "Depressive symptoms (\%)"
replace impaired=1-impaired
la var impaired "Symptoms impair"

global mother_mh "depressed scid_tot impaired dep1213 "

foreach v in mother_mh {
	label variable `v' `"\hspace{-0.05cm}\textbf{`: variable label `v' '}"'
}
foreach v in $mother_mh  {
	label variable `v' `"\hspace{0.2cm}`: variable label `v' ' "'
	}


label variable mspss_tot `"\hspace{-0.05cm}`: variable label mspss_tot '\tnote{a} "'

save `THP_dd', replace

*Without LHW FEs
	local varlabels ""
	local statnames ""
		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
		local varlabels ""
		local statnames ""

		foreach var in  mother_mh $mother_mh mspss_tot   {
			qui use `THP_dd', clear

			local thisvarname "`var'"
			local interact "dep_sample"
			local interaction "depXtreat"
			local thiscontrol "$controls_dd i.interviewer"
			local interact_label: var label `interact'
			local interaction_label: var label `interaction'

			*** COLUMN 1: Treatment Effect ***
			qui reg `thisvarname' treat `interact' `interaction' `thiscontrol', cluster(uc)
			pstar treat, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2: Interactation Effect ***
			pstar `interaction', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2

			*** COLUMN 3: Interactant Effect ***
			pstar `interact', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3

			*** ITERATE ***
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}
		esttab col* using "${tablefile}/sci_dd`factor'.tex", cells(none) f booktabs nonotes compress replace alignment(SSSc)  mtitle("Treat" "\specialcell{`interaction_label'}" "\specialcell{`interact_label'}"  "N" ) stats(`statnames', labels(`varlabels') ) mgroups("Coefficient on" , pattern(1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

*With LHW FEs
	local varlabels ""
	local statnames ""
		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
		local varlabels ""
		local statnames ""

		foreach var in  mother_mh $mother_mh mspss_tot {
			qui use `THP_dd', clear

			local thisvarname "`var'"
			local interact "dep_sample"
			local interaction "depXtreat"
			local thiscontrol "$controls_dd lhw_* i.interviewer"
			local interact_label: var label `interact'
			local interaction_label: var label `interaction'

			*** COLUMN 1: Treatment Effect ***
			qui reg `thisvarname' treat `interact' `interaction' `thiscontrol', cluster(uc)
			pstar treat, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2: Interactation Effect ***
			pstar `interaction', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2

			*** COLUMN 3: Interactant Effect ***
			pstar `interact', prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3

			*** ITERATE ***
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}
		esttab col* using "${tablefile}/sci_dd_lhwFE`factor'.tex", cells(none) f booktabs nonotes compress replace alignment(SSSc)  mtitle("Treat" "\specialcell{`interaction_label'}" "\specialcell{`interact_label'}"  "N" ) stats(`statnames', labels(`varlabels') ) mgroups("Coefficient on" , pattern(1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

} // end of dd_tables

//////////////////////////////////////
// Main Results - IPW for Attrition //
//////////////////////////////////////
if `main_attrition_ipw' == 1{
use "$maindir/dataClean/THP_clean.dta", clear

global attritionvars "depindex_7y depressed recover_never recover_perm  motherfinancial_7y $motherdecisions $childoutcomes grandmother mspss_tot"

foreach var in $attritionvars {
	replace `var'=. if sample!=1
	}

la var 	depression_traj_all "Depression trajectory"
la var mspss_tot "Perceived social support (7y)"

tempfile THP_attrition
save `THP_attrition', replace

noisily display "main_attrition_ipw"
	local varlabels ""
	local statnames ""

		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
 		local varlabels ""
		local statnames ""

		foreach var in $attritionvars {
			qui use `THP_attrition', clear

			*** COLUMN 1:  No controls ***
			qui reg `var' Group $controls_baseline  if ~attrit , cluster(uc)
			pstar Group, prec(2) pstar
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2:  All controls ***
			qui reg `var' Group $controls_baseline  if ~attrit [pw=1/p_hat] , cluster(uc)
			pstar Group, prec(2) pstar
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2


			*** COLUMN 3: LEE BOUND THP SAMPLE ***
			leebounds `var' treat if sample!=3 & attrit2!=., cie
			local cilower = "[" + string(e(cilower), "%9.2f") + "$\,$ , $\,$" + string(e(ciupper), "%9.2f") + "]"
			estadd local thisstat`count' = "`cilower'": col3


			*** ITERATE ***
			local thisvarlabel: variable label `var'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}
		esttab col* using "$tablefile/c_ipw_main_allindices`factor'.tex", cells(none) booktabs nonotes compress replace alignment(SSc) mgroups("Treatment Effect $\beta$ / (s.e.)" "\specialcell{Attrition Bounds}", pattern(1 0 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("\specialcell{Unweighted}"  "\specialcell{ IPW}" " 95\% CI" ) stats(`statnames', labels(`varlabels'))
} // end of if main_attrition_ipw

/////////////////////////
// Attrition by gender //
/////////////////////////
if `attrition_bygender' == 1{
noisily display "attrition_bygender"
use "$maindir/dataClean/THP_clean.dta", clear

global attritionvars "depindex_7y depressed recover_never recover_perm  motherfinancial_7y $motherdecisions $childoutcomes grandmother mspss_tot"

foreach var in $attritionvars  {
	replace `var'=. if sample!=1
	}

la var 	depression_traj_all "Depression trajectory"
la var mspss_tot "Perceived social support (7y)"

/*
this fills in the gender of the child so that the numbers of boys and girl match what was
reported in Rahman as number of girl/boys at birth (these numbers are from registries)
-- 223/463 in T and 226/440 in C were boys.
*/

drop if three_groups ==1
gen girl_filled=girl
gen girl_miss=1 if girl==.
sort girl_miss Group
replace girl_filled = 1 if (_n<= 33 | _n>=106) & girl==.
replace girl_filled = 0 if girl_filled==.
replace girl = girl_filled
bys Group: tab girl

tempfile THP_attrition
save `THP_attrition', replace

	local varlabels ""
	local statnames ""

		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		qui eststo col4: reg x y
		qui eststo col5: reg x y
		qui eststo col6: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
 		local varlabels ""
		local statnames ""

		foreach var in $attritionvars {
			qui use `THP_attrition', clear

			*** COLUMN 1:  No controls ***
			qui reg `var' Group  $controls_design if ~attrit & girl == 1, cluster(uc)
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2: LEE BOUND LOWER ***
			leebounds `var' treat if  sample!=3 & girl == 1, cie
			local cilower = string(e(cilower), "%9.2f")
			estadd local thisstat`count' = "`cilower'": col2

			*** COLUMN 3: LEE BOUND UPPER ***
			local ciupper = string(e(ciupper), "%9.2f")
			estadd local thisstat`count' = "`ciupper'": col3


			*** COLUMN 4:  No controls ***
			qui reg `var' Group $controls_design   if ~attrit & girl == 0, cluster(uc)
			pstar Group, prec(2)
			estadd local thisstat`count' = "`r(bstar)'": col4
			estadd local thisstat`countse' = "`r(sestar)'": col4

			*** COLUMN 5: LEE BOUND THP SAMPLE ***
			leebounds `var' treat if  sample!=3 &  girl == 0, cie
			local cilower = string(e(cilower), "%9.2f")
			estadd local thisstat`count' = "`cilower'": col5

			*** COLUMN 6: LEE BOUND UPPER ***
			local ciupper = string(e(ciupper), "%9.2f")
			estadd local thisstat`count' = "`ciupper'": col6

			*** ITERATE ***
			local thisvarlabel: variable label `var'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}
		esttab col* using "$tablefile/c_attrition_bygender.tex", cells(none) booktabs nonotes compress replace alignment(SSSS) mgroups("Girls" "Boys", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("\specialcell{Unadjusted \\ $\beta$/(s.e.)}"  "95\% CI" "" "\specialcell{Unadjusted \\ $\beta$/(s.e.)}" "95\% CI" "") stats(`statnames', labels(`varlabels'))
} // end if `attrition_bygender'



////////////////////////////////
// Magnitude comparison table //
////////////////////////////////
if `magnitude' == 1{
use "$maindir/dataClean/THP_clean.dta", clear

la var 	depression_traj_all "Depression trajectory"
la var mspss_tot "Perceived social support (7y)"

// set to missing if not all the items are asked to the non-depressed mothers
foreach var in depression_traj_all motherfinancial fertility_vars childmort fatherfinancial relation_traj motherhealthindex grandmothers{
	replace `var'=. if sample!=1
	}


tempfile THP_magnitude
save `THP_magnitude', replace

noisily display "magnitude"
	local varlabels ""
	local statnames ""

		clear
		eststo clear
		estimates drop _all
		set obs 10
		gen x = 1
		gen y = 1

		qui eststo col1: reg x y
		qui eststo col2: reg x y
		qui eststo col3: reg x y
		qui eststo col4: reg x y

		local varcount = 1
		local count = 1
		local countse = `count'+ 1
 		local varlabels ""
		local statnames ""

		foreach var in depindex_7y depression_traj_all mspss_tot motherfinancial_7y motherfinancial parentmoney parenttime parentstyle fertility_vars healthindex cognindex emoindex childmort no_kids_postt motherhealthindex fatherfinancial relation_traj grandmothers {
			qui use `THP_magnitude', clear
			di "*********************** Running for variable `var'"

			*** COLUMN 1:  No controls ***
			qui reg `var' Group $controls_baseline  if ~attrit , cluster(uc)
			pstar Group, prec(2) pstar
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1

			*** COLUMN 2:  Depression gap ***
			qui sum `var'
			//run only for the indices that are there also for non-depressed
			if r(N)>585{
			qui reg `var' dep_sample if three_groups!=2
			pstar dep_sample, prec(2)  pstar
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2
			}

			*** COLUMN 3: Gender gap ***
			qui reg `var' girl if sample==1 & treat==0
			pstar girl, prec(2)  pstar
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3

			*** COLUMN 4: MDE ***
			qui reg `var' Group $controls_baseline  if ~attrit , cluster(uc)
			local MDE: display %9.2f  _se[Group]*2.8
			estadd local thisstat`count' = "`MDE'": col4

			*** ITERATE ***
			local thisvarlabel: variable label `var'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount
		}
		esttab col* using "$tablefile/c_magnitude`factor'.tex", cells(none) booktabs nonotes compress replace alignment(SSc) ///
		            ///mgroups("Treatment Effect $\beta$ / (s.e.)" "\specialcell{Lee Bounds 95\% CI}" "MDE", pattern(1 0 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
			    mtitle("Treatment Effect $\beta$" "Depression Gap" "Gender gap (boy-girl)" "MDE") ///
			    stats(`statnames', labels(`varlabels'))
}

//////////////////////////
// Misc Appendix Tables //
//////////////////////////
if `misc'==1{
** Parenting and child development
global parentcontrol "parentmoney parenttime parentstyle motherfinancial fertility_vars"
la var parentmoney "Monetary investment"
la var parenttime "Time investment"
global controls_plus "$controls_dd intervr_1-intervr_9 girl##c.c_age_int "
eststo clear
foreach outcomevar in healthindex cognindex emoindex {
	eststo: reg `outcomevar' $parentcontrol             $controls_plus , cl(uc), if sample==1
	eststo: reg `outcomevar' $parentcontrol dep_sample  $controls_plus, cl(uc)
	}
esttab using "$tablefile/c_parenting_childdev`factor'.tex", cells("b(fmt(%8.2f)star)" "se(fmt(%8.2f)par)") stats(N r2, fmt(0 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") labels(`"Observations"' `"\(R^{2}\)"')) replace booktabs label nonotes compress alignment(SSSSSSSSS) collabels(none)  keep($parentcontrol dep_sample) nomtitles star(* 0.10 ** 0.05 *** 0.01)	mgroups("Physical development" "Cognitive development" "Socioemotional development", pattern(1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

* depression trajectories and outcomes  // not used in the paper
la var depressed "Depressed (7y)"
la var dep_sample "Depressed (baseline)"
la var depindex_0 "Dep. severity (baseline)"
eststo clear
foreach outcomevar in $motherdecisions $childoutcomes  {
	eststo: reg `outcomevar'  depressed  dep_sample   $controls_plus , vce(cluster uc), if  three_groups!=2
	}

esttab using "$tablefile/c_depression_baseline_7y_outcomes.tex", b(%9.2f) se(%9.2f) booktabs nonotes label compress replace f keep( depressed dep_sample )    mgroups( "Mother's decision-making" "Child outcomes", pattern(1 0 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) star(* 0.10 ** 0.05 *** 0.01) 	 mtitle("\specialcell{Mother's \\ empowerment }" "\specialcell{Parenting \\ Time }" "\specialcell{Parenting \\ Money }"   "\specialcell{Parenting \\ Style }" "\specialcell{Fertility}"  "\specialcell{Physical \\ Development }" "\specialcell{Cognitive \\ Development }" "\specialcell{Socio-emotional \\ Development }" "\specialcell{Child \\ survival }") noobs

eststo clear
eststo: reg mo_emp depindex_0 , cl(uc)
eststo: reg empowered_6m depressed_6m depindex_0 girl , cl(uc), if treat==0
eststo: reg var611 depressed_1y depindex_0 girl , cl(uc), if treat==0

eststo: reg empowered depressed  dep_sample girl  i.interviewer, vce(cluster uc), if  three_groups!=2
eststo: reg empowered depressed  dep_sample   i.interviewer, vce(cluster uc), if  three_groups!=2 & girl==1
eststo: reg empowered depressed  dep_sample   i.interviewer, vce(cluster uc), if  three_groups!=2 & girl==0
eststo: reg empowered depressed  depressed_1y  girl  i.interviewer, vce(cluster uc), if  three_groups!=2
eststo: reg empowered depressed  depressed_1y    i.interviewer, vce(cluster uc), if  three_groups!=2 & girl==1
eststo: reg empowered depressed  depressed_1y    i.interviewer, vce(cluster uc), if  three_groups!=2 & girl==0


esttab using "$tablefile/c_dep_empowered.tex", b(%9.2f) se(%9.2f) booktabs nonotes label compress replace f keep( depressed depressed_1y depressed_6m dep_sample depindex_0  girl) order(depressed depressed_1y depressed_6m dep_sample depindex_0  girl)    mgroups("\specialcell{Empowered \\ before 7y }" "Empowered at 7y followup", pattern(1 0 0 1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) star(* 0.10 ** 0.05 *** 0.01) 	 mtitle("\specialcell{at \\ baseline }" "\specialcell{at \\ 6m }" "\specialcell{at \\ 1y }" "\specialcell{All}" "\specialcell{Girls}" "\specialcell{Boys}"   "\specialcell{All}" "\specialcell{Girls}" "\specialcell{Boys}" )
} // end if misc
/////////////////////////////////////////
//         Gender gaps                 //
/////////////////////////////////////////
if `gender_gaps' == 1{
use "$maindir/dataClean/THP_clean.dta", clear


** GENDER GAPS **
eststo clear
foreach group in $motherdecisions $childoutcomes {
	foreach var in `group' {
	eststo: reg `var' girl if sample==1 & treat==0
	}
	}
no: esttab , keep(girl)	b(%9.2f) se(%9.2f) star(* 0.10 ** 0.05 *** 0.01)


eststo clear
foreach group in $motherdecisions $childoutcomes {
	foreach var in `group' {
	eststo: reg `var' girl if sample==3
	}
	}
no: esttab , keep(girl)	b(%9.2f) se(%9.2f) star(* 0.10 ** 0.05 *** 0.01)

foreach group in $motherdecisions $childoutcomes {
	eststo clear
	foreach within in $`group' {
		foreach var in `within' {
		eststo: reg `var' girl if sample==1 & treat==0
		}

	}
	no: esttab , keep(girl)	b(%9.2f) se(%9.2f) star(* 0.10 ** 0.05 *** 0.01)
	}

} // end if gender_gaps

/////////////////////////////////////////
// Controling for subsequent fertility //
/////////////////////////////////////////
if `sci_byfertility' == 1{
noisily display "sci_byfertility"
use "${maindir}/dataClean/THP_clean.dta", clear

gen recent = age_kid1<2
gen vrecent = age_kid1<1
la var recent "Birth within 2y"
la var vrecent "Birth within 1y"
la var notlast "Index not last child"
foreach var2 in recent vrecent notlast {
	cap drop treatX`var2'
	gen treatX`var2' = treat*`var2'
	local i_label:  var label `var2'
	la var 	treatX`var2'  "Treat $\times$ `i_label' "
	}

eststo clear
eststo: reg depressed treat $controls_design , cl(uc), if sample==1
eststo: reg depressed treat treatXrecent recent $controls_design , cl(uc), if sample==1
sum recent if sample==1
estadd scalar cm=r(mean)
eststo: reg depressed treat treatXvrecent vrecent $controls_design , cl(uc), if sample==1
sum vrecent if sample==1
estadd scalar cm=r(mean)
eststo: reg depressed treat treatXnotlast notlast $controls_design , cl(uc), if sample==1
sum notlast if sample==1
estadd scalar cm=r(mean)

esttab using "${tablefile}/sci_byfertility.tex", b(a2) se(a2) $sig f booktabs nonotes compress replace keep(treat treatXrecent treatXvrecent treatXnotlast recent vrecent notlast) mgroups("MDE at 7-year followup", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nomtitle noobs label stats(N r2 cm, fmt(0 2 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}" "\multicolumn{1}{S}{@}") labels(`"Observations"' `"R$^2$"' `"Mean of interactant"'))

} // end if sci_byfertility

} // end if analysis


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	GRAPHS
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if `make_graphs' == 1 {
noisily display "make_graphs"

// set scheme s2color
set scheme plotplainblind

////////////////////////////////
// DEPRESSIONS TRAJECTORIES	  //
////////////////////////////////
if `dep_trends' ==1 {
noisily display "dep_trends"
use "$maindir/dataClean/THP_clean.dta", clear

keep if newid!=.
rename depressed_6m dep2006
rename depressed_1y dep2007
gen dep2005=sample==1
cap drop dep2013
rename depressed 	dep2013
keep newid dep2005 dep2006 dep2007 dep2013  treat  girl sample

reshape long dep  , i(newid) j(year)
tsset newid year

la define treatvar 1 "Treated" 0 "Control"
la values treat treatvar

la define valuel 2006 "6-month" 2007 "1-year" 2013 "7-year"
la values year valuel


gen time=1 if year==2005
replace time=2 if year==2006
replace time=3 if year==2007
replace time=4 if year==2013
tsset newid time

replace treat=3 if sample!=1

label var dep "Share depressed"
label var time " "
label define treat 0 "Control" 1 "Treatment" 3 "Non-depressed"
label values treat treat

xtgraph dep, gr(treat) offset(.1)
graph play   ${figurefile}/xtgraph_change.grec
graph export "${figurefile}/dep_trends.pdf", replace

/* Another way of doing the same graph
tab year, gen(year_)
la var year_1 "6-month  followup"
la var year_2 "1-year   followup"
la var year_3 "7-year   followup"
eststo clear
eststo control : reg dep year_*   if treat==0		, noc
eststo treated : reg dep year_*   if treat==1		, noc

coefplot (control ,  label(Control) levels(95)  msize(*1.45))  (treated , label(Treated) levels(90) msymbol(D) msize(*1.45))  ,   ///
		vertical ///
		 ciopts(recast(rcap)   lcolor(gs10) )     ///
		ylabel(, format(%9.1f )  angle(0))  mlabel format(%9.2f) mlabposition(3) mlabgap(*2)  ///
		grid(between glcolor(orange) glpattern(dash)) ///
		coeflabels( , wrap(8) notick labcolor(orange) labsize(medsmall) labgap(2)) ///
		graphregion(color(white)) bgcolor(white)   plotregion(lcolor(black)) ///
		legend(order(2  "Control" 4 "Treated" 1 "95% CI" ) rows(1)  symxsize(3) region(color(white)) )

graph export "$maindir/figures/dep_trends_coeff.pdf", replace
*/

} // end if dep_trajectory

////////////////////////////////
// QUANTILE TREATMENT EFFECTS //
////////////////////////////////
if `qte_graphs' ==1 {
use "${maindir}/dataClean/THP_clean.dta", clear
noisily display "qte_graphs"
la var cognindex 	"Cognitive development"
la var healthindex 	"Physical development"
la var emoindex 	"Socio-emotional dev."

la var parentstyle	"Parenting style"
la var parenttime	"Time investment"
la var parentmoney	"Monetary investment"

global childdevelopment "healthindex cognindex emoindex"
global parenting 		"parentmoney parenttime parentstyle"

tempfile bootresults
local count = 0
foreach thisvargroup in parenting childdevelopment {

		foreach var in $`thisvargroup' {
			bootstrap  , reps($qtereps) cluster(uc) saving(`bootresults', replace) seed(100): ivqte `var' (treat=treat) if sample==1, c(month_int month_int_sq) d(interviewer) q(.01(.01).99)
			local label : variable label `var'
			preserve
			use `bootresults', clear
			gen id = _n
			forvalues n = 1/99{
				egen fifth_q_`n'= pctile(_b_Quantile_`n') , p(2.5)
				egen nintyfifth_q_`n'= pctile(_b_Quantile_`n') , p(97.5)
				egen _b_`n'=mean(_b_Quantile_`n')
				}
			drop _b_Quantile_*
			reshape long _b_ fifth_q_ nintyfifth_q_, i(id) j(qt)
			gen Percentile = qt // /20*100
			egen ATE= mean(_b_)


			twoway (lpoly _b_  Percentile , lcolor(navy) lwidth(medthick) lpattern(solid)) (lpoly fifth_q_ Percentile , lcolor(blue) lpattern(dash)) (lpoly nintyfifth_q_ Percentile , lcolor(blue) lpattern(dash)) (lpoly ATE Percentile if Percentile>=5 & Percentile<=95, lcolor(red) lpattern(dash_dot)),  saving("${figurefile}/qte_`var'.gph", replace) xtitle(Percentile) title(`label') legend(on order(1 "QTE" 2 "95% CI" 4 "ATE") cols(3))  yline(0, lpattern(solid) lcolor(black))  ysc(r(-1.5 1.5)) nodraw sch(s2mono) graphr(fcolor(white) lcolor(white)) ylabel(, format(%9.1f)  angle(0))
			restore
			}

		local graphs ""
		foreach var in $`thisvargroup' {
			local graphs "`graphs' "${figurefile}/qte_`var'.gph""
			}
		if `count' == 1 {
		grc1leg `graphs', sch(s2mono) graphr(fcolor(white) lcolor(white)) ycomm xcomm iscale(*.95) cols(3) xsize(6.5) ysize(4)  legendfrom("${figurefile}/qte_cognindex.gph")
		graph export "${figurefile}/qte_`thisvargroup'`factor'.pdf", replace
		}
		else {
		grc1leg `graphs', sch(s2mono) graphr(fcolor(white) lcolor(white)) ycomm xcomm iscale(*.95) cols(3) xsize(6.5) legendfrom("${figurefile}/qte_parenttime.gph")
		graph export "${figurefile}/qte_`thisvargroup'`factor'.pdf", replace
		}
		local count = `count'+1
} // end foreach thisvargroup
} // end if qte_graphs

////////////////////
// DENSITY GRAPHS //
////////////////////
if `density_graphs' == 1 {
noisily display "density_graphs"

local outcome_list0 "hamd_6m hamd_1y"
foreach var of local outcome_list0 {
	local label : variable label `var'
	twoway (hist hamd_baseline, fcolor(gs15) lcolor(gs15) gap(0) ) (hist `var', fcolor(none) lcolor(ltkhaki) gap(0) ) (kdensity `var' if three_groups==2, lcolor(blue) lwidth(thick) lpattern(solid) ) (kdensity `var' if three_groups==3, lcolor(red) lwidth(thick) lpattern(dash) ) (kdensity hamd_baseline if three_groups==2, lcolor(blue) lwidth(thin) lpattern(solid) ) (kdensity hamd_baseline if three_groups==3, lcolor(red) lwidth(thin) lpattern(dash) )   , ytitle(Density) xtitle("") title(`label') legend(on order( 2 "All Groups" 3 "Treatment" 4 "Control" 1 "Baseline (All)" 5 "Baseline (T)" 6 "Baseline (C)") cols(3))  graphr(fcolor(white) lcolor(white))
	cd "${figurefile}"
	graph save density_`var' , replace
	graph export density_`var'.pdf, replace
	}

local outcome_list1 "c_wt_6m c_wt_1y c_ht_6m c_ht_1y"
foreach var of local outcome_list1 {
	local label : variable label `var'
	twoway (hist `var',  fcolor(none) lcolor(ltkhaki) gap(0) ) (kdensity `var' if three_groups==2, lcolor(blue) lwidth(thick)  lpattern(solid) ) (kdensity `var' if three_groups==3, lcolor(red) lwidth(thick)  lpattern(dash) ), ytitle(Density) xtitle("") title(`label') legend(on order(1 "All Groups" 2 "Treatment" 3 "Control") cols(3))  graphr(fcolor(white) lcolor(white))
	cd "${figurefile}"
	graph save density_`var' , replace

	}

local outcome_list2 "fsiq stroop c_wt c_ht spence sdq_sum home PPI"
foreach var of local outcome_list2 {
	local label : variable label `var'
	twoway (hist `var',  fcolor(none) lcolor(ltkhaki) gap(0) ) (kdensity `var' if three_groups==2, lcolor(blue) lwidth(thick) lpattern(solid) ) (kdensity `var' if three_groups==3, lcolor(red) lwidth(thick) lpattern(dash) ) (kdensity `var' if three_groups==1, lcolor(green) lwidth(med) lpattern(dash_dot) ) , ytitle(Density) xtitle("") title(`label') legend(on order(1 "All Groups" 2 "Treatment" 3 "Control" 4 "Prenatally non-depressed") cols(2))   graphr(fcolor(white) lcolor(white))
	cd "${figurefile}"
	graph save density_`var' , replace
	}

	grc1leg ${figurefile}/density_fsiq.gph ${figurefile}/density_stroop.gph, title("Cognitive Development (Age 7)") legendfrom("${figurefile}/density_fsiq.gph") graphr(fcolor(white) lcolor(white))
	graph export ${figurefile}/density_cognitive.pdf, replace

	grc1leg  ${figurefile}/density_c_wt.gph ${figurefile}/density_c_ht.gph, title("Physical Development (Age 7)") legendfrom("${figurefile}/density_c_wt.gph") graphr(fcolor(white) lcolor(white))
	graph export ${figurefile}/density_growth_7y.pdf, replace

	grc1leg  ${figurefile}/density_c_wt_6m.gph ${figurefile}/density_c_ht_6m.gph, title("Physical Development (6 months)") legendfrom("${figurefile}/density_c_wt_6m.gph") graphr(fcolor(white) lcolor(white))
	graph export ${figurefile}/density_growth_6m.pdf, replace

	grc1leg  ${figurefile}/density_c_wt_1y.gph ${figurefile}/density_c_ht_1y.gph, title("Physical Development (12 months)") legendfrom("${figurefile}/density_c_wt_1y.gph") graphr(fcolor(white) lcolor(white))
	graph export ${figurefile}/density_growth_1y.pdf, replace

	grc1leg ${figurefile}/density_spence.gph ${figurefile}/density_sdq_sum.gph, title("Socio-emotional Development (Age 7)") legendfrom("${figurefile}/density_spence.gph") graphr(fcolor(white) lcolor(white))
	graph export ${figurefile}/density_emoindex.pdf, replace

	grc1leg ${figurefile}/density_home.gph ${figurefile}/density_PPI.gph, title("Parenting and Home Environment (Age 7)") legendfrom("${figurefile}/density_home.gph")  graphr(fcolor(white) lcolor(white))
	graph export ${figurefile}/density_parenting.pdf, replace
} // end if density_graphs

} // end if make_graphs





noisily display "End: $S_DATE $S_TIME"
scalar te = clock("$S_DATE $S_TIME", "DMYhms")
no: di "Runtime: " (te-ts)/(60*60*1000)  " hours with $iterations iterations in FWER adjustment"

/*
*to test if all indices jointly are significant for girls
egen childindex = weightave($childdevelopment), normby(control)
egen childindex2 = weightave(cognindex emoindex healthindex), normby(control)
reg childindex Group $controls_baseline  if ~attrit  & girl, cluster(uc)
reg childindex2 Group $controls_baseline  if ~attrit & girl, cluster(uc)
*/

log close

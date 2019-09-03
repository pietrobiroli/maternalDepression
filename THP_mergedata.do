//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
  * Thinking Healthy Program -- Saving Brains
  * This file merges the raw data
  * By: Victoria Baranov and Pietro Biroli
  * Date: July 20, 2019
  
  *in:  /dataRaw/SBQ with Ages Merged_Dep_Non-Dep_remaining_cases_29092014.dta
  *     /dataRaw/SB_newid_mo_9.dta
  *     /dataRaw/complete_THP_roster_with_UCs&LHW.dta
  *     /dataRaw/rct_atif_chris_cost_var_labelled_8208(c).dta
  *     /dataRaw/WHO BMI Height/who_cutoffs.dta

  *out: /dataClean/THP_merge.dta
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
{ // setup
clear all
set matsize 10000
set more off
capture log close

noisily display "Start: $S_DATE $S_TIME"
scalar ts = clock("$S_DATE $S_TIME", "DMYhms")

/* main dir has been set in 00_readme.do; if not, run this part
global maindir "/mnt/data/Dropbox/SavingBrains/zz_AER_data_code/"
*/

//clean the data folder
capture rm "${maindir}/dataRaw/THP_merge.dta"
cd "${maindir}"
log using "${maindir}/logfiles/THP_merge_$S_DATE.smcl", replace
} //end setup
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	MERGE all the raw data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
noisily display "------------------MERGE------------------"
use "${maindir}/dataRaw/SBQ with Ages Merged_Dep_Non-Dep_remaining_cases_29092014.dta", clear

****
**** SB data, add interview dates and treatment status for LTFU sample 
****
merge 1:1 newid mo_1 using "${maindir}/dataRaw/SB_newid_mo_9.dta", update replace gen(_merge1) //interview dates, LTFU treat
drop _merge1 
drop if newid==. & mo_1 ==570 //clear duplicate
order newid mo_1 mo_2 mo_5 mo_6a mo_8 mo_9
rename mo_2 	interviewer
rename mo_6a 	uc
rename mo_9 	date
iis uc
gen attrit = newid==.
replace attrit = . if three_groups==1
replace treat = 1 if status_con_inv == 2
replace treat = 0 if status_con_inv == 1
gen dep_sample = (three_groups != 1)
tab interviewer, gen(intervr_)

****
**** add the LTFU women, LHW and roster info from SB followup
****
gen id= mo_1
replace id = 2527.5 if id==2527 & mo_275==1 //replace duplicate (status: nondepressed) ids. id 2527 does match with the roster
merge 1:1 id using  "${maindir}/dataRaw/complete_THP_roster_with_UCs&LHW.dta", gen(_m2)
encode lhw_name, gen(lhw) //current LHW at 7y, not baseline
tab lhw, gen(lhw_) missing
gen     sample = 1 if attrit == 0
replace sample = 2 if attrit == 1
replace sample = 3 if attrit == . 
drop sex
drop if _m2==2 //drop women from roster who weren't in the dataset

****
**** THP Original Data
****
merge 1:1 id using "${maindir}/dataRaw/rct_atif_chris_cost_var_labelled_8208(c).dta", gen(_m3)
replace sample= 2 if _m3==2
la var sample "1=SB; 2=THP; 3=Nondep"

replace treat = 1 if arm==1
replace treat = 0 if arm==0
gen Group = treat==1
rename sex sex_thp

****
**** interview dates
****
gen date_int = date(date, "DMY")
la var date_int "Date of interview"
format %td date_int
la var date_int "Interview date"
gen month_int=month(date_int)
replace month_int=13 if month_int==1 //so it is in line with actual timing

*scrambled the month number protect to identity of participants 
*(XXX is a number, it has been hidden in the public code)
replace month_int=month_int-XXX        // ***SCRAMBLE*** //
la var month_int "Month of interview"
tab month_int, gen(month_)
gen month_int_sq=month_int^2

gen date_int_0 = var5
la var date_int_0 "Interview date (baseline)"
gen month_int_0=month(date_int_0)
la var month_int_0 "Month of interview (baseline)"

sum date_int_0
gen doi0= date_int_0-r(min)-XXX        // ***SCRAMBLE*** //
gen doi0_sq=doi0^2

drop age         //mother's age variables
gen age = mo_5   //at 7-yr 
sum age
replace age=r(mean) if age==. & three_groups!=. //5 missing (from nondep)
gen age_sq = age^2
gen age_baseline = mo_age

save "${maindir}/dataRaw/THP_merge.dta", replace
log close

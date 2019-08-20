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
global tablefile "$maindir/tables/"
global figurefile "$maindir/figures/"
*/

//clean the data folder
capture rm "${maindir}/dataRaw/THP_merge.dta"

cd "${maindir}"

log using "${maindir}/logfiles/THP_merge_$S_DATE.smcl", replace
} //end setup

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Global varlists
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
global controls_design = "month_int month_int_sq doi0 doi0Xtreat intervr_1-intervr_9"
global X_control_vars "age_baseline age_baseline_sq employed_mo_baseline mo_emp  grandmother_baseline MIL wealth_baseline edu_lvl_mo_1 edu_lvl_mo_2 edu_lvl_mo_3  edu_mo_baseline edu_fa_baseline kids_no  first_child  hamd_baseline  mspss_baseline doi0"
}

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	MERGE all the raw data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

noisily display "------------------MERGE------------------"
///////////////////
//  MERGE DATA   //
///////////////////
{
use "${maindir}/dataRaw/SBQ with Ages Merged_Dep_Non-Dep_remaining_cases_29092014.dta", clear

****
**** interview dates and treatment status for LTFU sample 
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
gen treat2 = 1- treat //for sum stats tables
gen dep_sample = (three_groups != 1)
gen Group = treat==1
tab interviewer, gen(intervr_)

****
**** add the LTFU women, LHW and roster info from SB followup (not original data sample)
****
gen id= mo_1
replace id = 2527.5 if id==2527 & mo_275==1 //replace on of the duplicates (status: nondepressed) ids. id 2527 does match with the roster
merge 1:1 id using  "${maindir}/dataRaw/complete_THP_roster_with_UCs&LHW.dta", gen(_m2)
encode lhw_name, gen(lhw) //current LHW at 7y, not baseline
rename lhw_name lhwname
gen lhw2=lhw
tab lhw2, gen(lhw_) missing
replace lhw2=99 if lhw==.	

gen     sample = 1 if attrit == 0
replace sample = 2 if attrit == 1
replace sample = 3 if attrit == . 

drop sex
drop if _m2==2 //drop women from roster who weren't in the dataset

****
**** THP Original Data
****

merge 1:1 id using "${maindir}/dataRaw/rct_atif_chris_cost_var_labelled_8208(c).dta", gen(_m3)
gen dep_b4_preg = var12a > 7 & var12a!=.
replace sample= 2 if _m3==2
la var sample "1=SB; 2=THP; 3=Nondep"
replace uc=UC if sample==1

replace treat=arm if sample==2 & treat==.
rename sex sex_thp

gen flag_trt=treat!=arm if sample!=3
gen treat_sb=treat

replace treat = 1 if arm==1
replace treat = 0 if arm==0
replace Group = treat==1


****
**** interview dates
****
gen date_int = date(date, "DMY")
la var date_int "Date of interview"
format %td date_int
la var date_int "Interview date"
gen month_int=month(date_int)
replace month_int=13 if month_int==1 //so it is in line with actual timing
replace month_int=month_int-5        //scrambe the month number to make it harder to identify participants based on interview date
la var month_int "Month of interview"
tab month_int, gen(month_)
gen month_int_sq=month_int^2

gen date_int_0 = var5
la var date_int_0 "Interview date (baseline)"
gen month_int_0=month(date_int_0)
la var month_int_0 "Month of interview (baseline)"

sum date_int_0
gen doi0= date_int_0-r(min)-5        //scrambe the month number to make it harder to identify participants based on interview date
gen doi0_sq=doi0^2


drop age                // supposedly the age of the child but it is wrong, see below c_age_int
gen age = mo_5			//mother's age variables
sum age
gen age_miss= age==.
replace age=r(mean) if age==. & three_groups!=. //5 missing (from nondep)
gen age_sq = age^2
gen age_baseline = mo_age
gen age_group_baseline = ceil(age_baseline/5)
gen age_group = ceil(age/5)

gen days_since_start = date_int -19479 //19479 is interview start date in stata days

save "${maindir}/dataRaw/THP_merge.dta", replace
}


log close

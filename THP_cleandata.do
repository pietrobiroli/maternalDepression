//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
  * Thinking Healthy Program -- Saving Brains
  * This file starts from the merged data and cleans it for the analysis
  * By: Victoria Baranov and Pietro Biroli
  * Date: August 11, 2019
  
  *in:  /dataRaw/THP_merge.dta

  *out: /dataClean/THP_clean.dta
  *     /dataClean/THP_clean.csv

  * commands needed:
  *    _gweightave (From Haushofer 2013)
  *
  * ssc install mat2txt 
  * ssc install xtgraph
  * search zanthro (from https://www.stata-journal.com/article.html?article=dm0004_1)

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
capture rm "${maindir}/dataClean/THP_clean.dta"

cd "${maindir}"

log using "${maindir}/logfiles/THP_clean_$S_DATE.smcl", replace
} //end setup

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Global varlists
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
do ${maindir}THP_globalvars.do 
/*
global controls_design = "month_int month_int_sq doi0 doi0Xtreat intervr_1-intervr_9"
global X_control_vars "age_baseline age_baseline_sq employed_mo_baseline mo_emp  grandmother_baseline MIL wealth_baseline edu_lvl_mo_1 edu_lvl_mo_2 edu_lvl_mo_3  edu_mo_baseline edu_fa_baseline kids_no  first_child  hamd_baseline  mspss_baseline doi0"
*/
}

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	CLEAN, GENERATE	
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
use "${maindir}/dataRaw/THP_merge.dta", clear

noisily display "------------------CLEAN------------------"
///////////////////
//  CLEAN DATA   //
///////////////////
{
**** 
**** household structure, mother demographics, parity
**** 
gen famstruct = (mo_11>0)
rename mo_12	marital_status
rename mo_13	grandmother
rename mo_16 	adults_inhouse

rename mo_17	kids_boys
rename mo_18	kids_girls
replace kids_girls=0 if kids_boys<. & kids_girls==. //one missing for girls but not for boys
gen kids_total = kids_boys+kids_girls
gen kids_fem_share = kids_girls / (kids_girls + kids_boys)
gen no_kids = mo_41		//number of kids
gen no_kids_recent = 0
forvalues i=2/8 {
	replace no_kids_recent = no_kids_recent + 1 if mo_4`i' < 7
	}
gen avg_age_kids_recent = 0
if no_kids_recent >0 {
	forvalues i=2/8 {
		replace avg_age_kids_recent = avg_age_kids_recent + mo_4`i' if mo_4`i' < 7
		}
	}
replace avg_age_kids_recent = avg_age_kids_recent/no_kids_recent
gen no_kids_baseline = no_kids - no_kids_recent
la var avg_age_kids_recent "Avg. age of kids born in last 7yrs"
la var no_kids_recent "No. kids born to mother in last 7yrs"
la var no_kids_baseline "No. kids born to mother at baseline"
gen c_first_child=(no_kids_baseline==1) if no_kids_baseline<.
la var c_first_child "Index child is the first one (7yrs)"
gen c_last_child = (no_kids_recent==0) if no_kids_recent<.
la var c_last_child "Index child is the last one (7yrs)"
rename mo_50 	no_kids_dead
rename mo_54	no_kids_miscarry
tab kids_no, gen(kids_no_)
tab no_kids_baseline, gen(no_kids_baseline_)
tab kidscat, gen(kidscat_)

rename mo_39	edu_mo 		//education
rename mo_40	edu_fa
sum edu_fa
replace edu_fa = r(mean) if edu_fa==. //just 3 missing
rename mo_edu	edu_mo_baseline
rename fa_edu 	edu_fa_baseline
gen edu_parents = (edu_mo_baseline+edu_fa_baseline)/2

gen edu_mo_any2= edu_mo==0 if edu_mo!=.
gen edu_fa_any2= edu_fa==0 if edu_fa!=.

foreach v in fa mo {
	gen edu_lvl_`v'_7y=0 if edu_`v'==0   &  edu_`v'!=.
	replace edu_lvl_`v'_7y=1 if edu_`v'>0 & edu_`v'<7  &  edu_`v'!=.
	replace edu_lvl_`v'_7y=2 if edu_`v'>6 & edu_`v'<11  &  edu_`v'!=. 
	replace edu_lvl_`v'_7y=3 if edu_`v'>10  &  edu_`v'!=.
	tab edu_lvl_`v'_7y, gen(edu_lvl_`v'_7y_)
	}


**** 
**** economic outcomes
**** 
rename mo_21	employed_fa
rename mo_22	occupation_fa
rename mo_23	income_fa	
rename mo_24	worktravel_fa
rename mo_25	employed_mo
rename mo_26	occupation_mo
rename mo_27	income_mo
rename mo_29	income_hh
rename mo_482	ses_lhw_rating
*replace mo_75= mo_75/100  //100s of PKR (roughly USD)
gen income = income_mo + income_fa
replace income = income_mo if income == .
replace income = income_fa if income == .
replace income_hh = income if income_hh == 2 & income != .
gen ln_income = ln(income_hh) if income_hh != 2 //basically zero income
gen ln_inc_percap = ln(income_hh/adults_inhouse) if income_hh != 2
gen enough_basic = mo_70==1 if mo_70!=2
gen enough_food = mo_71==1 if mo_71<2

**** 
**** mother mental health outcomes
**** 
rename mo_36	genhealth
rename mo_37 	days_unwell
gen mspss_tot = mo_170 + mo_171 + mo_172 + mo_173 + mo_174 + mo_175 + mo_176 + mo_177 + mo_178 + mo_179 + mo_180 + mo_181
gen depressed = (mo_89 ==3) if mo_89!=.
gen recover_perm = (recover_trend_full == 1)
gen recover_relapse = (recover_trend_full == 2)
gen recover_late = (recover_trend_full ==3)
gen recover_never = (recover_trend_full ==4)
gen year_on_A = substr(mo_90,-4,.)
gen year_off_A = substr(mo_92,-4,.)
gen year_on_B = substr(mo_93,-4,.)
gen year_off_B = substr(mo_95,-4,.)
gen year_on_C = substr(mo_96,-4,.)
gen year_off_C = substr(mo_98,-4,.)
destring year_on_A year_off_A year_on_B year_off_B year_on_C year_off_C, replace
replace year_on_A = 2008 if year_on_A<2008 & year_off_A >2007
replace year_off_A = . if year_on_A<2008
replace year_on_A = . if year_on_A<2008
replace year_on_B = 2008 if year_on_B<2008 & year_off_B >2007
replace year_off_B = . if year_on_B<2008
replace year_on_B = . if year_on_B<2008
replace year_on_C = 2008 if year_on_C<2008 & year_off_C >2007
replace year_off_C = . if year_on_C<2008
replace year_on_C = . if year_on_C<2008
gen dep_A = (year_on_A!=.) //same as mo_165
gen dep_B = (year_on_B!=.) //same as mo_166 
gen dep_C = (year_on_C!=.) //same as mo_167
gen dur_A = year_off_A-year_on_A + 1
replace dur_A = 0 if dur_A==.
gen dur_B = year_off_B-year_on_B + 1
replace dur_B = 0 if dur_B==.
gen dur_C = year_off_C-year_on_C + 1 
replace dur_C = 0 if dur_C==.
gen dur_tot =  dur_A + dur_B + dur_C
gen dep_tot = dep_A + dep_B + dep_C
replace dur_tot = 2*dep_tot if dur_tot<dep_tot //this interviewer swapped the on/off for 2 cases
gen dep_tot2 = dep_tot+1 if depressed ==1  //& (year_off_A==. | year_off_A<2013) & (year_off_B==. | year_off_B<2013)  & (year_off_C==. | year_off_C<2013) -- not necessary since interview date well after offset dates, except one case
replace dep_tot2 = 0 if dep_tot2==.
gen dep_ever = dep_tot >0 if attrit!=1
gen dep_ever_recall = dep_ever
replace dep_ever = 1 if depressed ==1 
gen date_on_A = date(subinstr(mo_90,"00/","01/",.),"DMY")
gen date_off_A = date(subinstr(mo_92,"00/","01/",.),"DMY")
gen date_on_B = date(subinstr(mo_93,"00/","01/",.),"DMY")
gen date_off_B = date(subinstr(mo_95,"00/","01/",.),"DMY")
gen date_on_C = date(subinstr(mo_96,"00/","01/",.),"DMY")
gen date_off_C = date(subinstr(mo_98,"00/","01/",.),"DMY")
gen dur_A2 = (date_off_A-date_on_A)/365 if dep_A ==1
replace dur_A2=0.5 if dur_A2==0
replace dur_A2 = 0 if dur_A2 ==.
gen dur_B2 = (date_off_B-date_on_B)/365 if dep_B ==1
replace dur_B2=0.5 if dur_B2==0
replace dur_B2 = 0 if dur_B2 ==.
gen dur_C2 = (date_off_C-date_on_C)/365 if dep_C ==1
replace dur_C2=0.5 if dur_C2==0
replace dur_C2 = 0 if dur_C2 ==.
replace dur_A2 = -dur_A2 if dur_A2<0
replace dur_B2 = -dur_B2 if dur_B2<0
gen dur_tot_exact = dur_A2+dur_B2+dur_C2
forvalues year = 2008/2013 {
	gen dep`year' = ( year_on_A <= `year' & year _off_A >= `year' & year_on_A!=.) | ( year_on_B <= `year' & year _off_B >= `year' & year_on_B!=.) | ( year_on_C <= `year' & year _off_C >= `year' & year_on_C!=.)
	replace dep`year'=. if attrit==1
	}
replace dep2013= 1 if depressed==1

****
**** child outcomes
****
rename mo_8 	c_sex
rename mo_483 	c_wt
rename mo_484 	c_ht
replace c_ht = 2.54*c_ht //reported in inches, converting to cm
gen w4h = c_wt/c_ht
rename var387 	c_wt_6m
rename var388 	c_ht_6m
rename var595 	c_wt_1y
rename var596 	c_ht_1y
gen girl = c_sex==2 if c_sex!=.
replace girl= 1 if sex_thp==2 //& girl==.  //replace missing gender of attritors 
replace girl= 0 if sex_thp==1
gen girlXtreat= girl*treat

*child age (age_child was wrong not age_int, can see from other dataset)
rename age_int c_age_int
la var c_age_int "Child age at interview"

gen c_age_days = c_age_int*365.25
gen c_age_start = c_age_days- days_since_start
replace c_age_start= c_age_start/365.25
la var c_age_start "Child Age at start of SB interviews"
drop days_since_start c_age_days
gen g4a=ch_9/(c_age_int-5)
la var g4a "Grade-for-age"

****
**** from baseline,6m,1y     
****
rename var212 	date_baseline
rename hamd_0	hamd_baseline
rename bdq_0	bdq_baseline
rename mspss_0 	mspss_baseline
rename var197	ses_baseline
rename var51 	income_fa_baseline
rename fam_inc	income_hh_baseline  //9==DK
gen ln_inc_baseline = ln(income_hh_baseline)
gen inc_miss_baseline = ln_inc_baseline<6  //DK
rename var215	genhealth_6m
rename var218 	depressed_6m
rename var239 	hamd_6m 
rename var240	bdq_6m
rename var241	gaf_6m
rename var254	mspss_6m
rename var256	ses_6m
rename var421	depressed_1y
rename var442 	hamd_1y
rename var443	bdq_1y
rename var444	gaf_1y
rename var457	mspss_1y
rename var468 	ses_1y
rename var607	play_mo_1y
rename var608	play_fa_1y

gen bf_only_6m =  var392 ==1 if var392!=.
gen diarhea_6m =  var389 > 0 if var389!=.
gen ari_6m = var390>0 if var390 !=.
gen bf_1y = var600!=.
gen bf_stop = var601
replace bf_stop = 13 if bf_stop==.
gen diarhea_1y = var597 >0 if var597 !=.
gen ari_1y = var598 >0 if var598!=.

gen grandmother_baseline = (var30>0) if var30!=.
gen employed_fa_baseline = var49 if var49 !=9
replace var198 = . if var198==9
gen occupation_fa_baseline = 1 if var50 == 2
replace occupation_fa_baseline = 0 if var50 == 1
gen famstruct_baseline = var29
replace occupation_fa = 0 if occupation_fa!= 2
replace occupation_fa = 1 if occupation_fa == 2
replace mo_76 = . if mo_76==2
gen grandmother_6m = (var265 >0 ) if var265!=.
gen grandmother_1y = (var473 >0 ) if var473!=.
replace play_fa_1y = . if play_fa_1y == 5
gen ltfu_moved = (status_thp_remain=="MOVED/SHIFTED") if attrit==1
gen first_child=kids_no==0 if kids_no!=.
replace first_child=no_kids_baseline==1 if kids_no==. & no_kids_baseline!=. //nondep
gen nograndma_baseline = 1-grandmother_baseline
replace mo_ht = mo_ht/100

gen employed_mo_baseline= var42==1 if var42!=.
la var employed_mo_baseline "Mother usually works"

gen edu_fa_any = edu_fa_baseline>0 if edu_fa_baseline!=.
gen edu_mo_any = edu_mo_baseline>0 if edu_mo_baseline!=.

foreach v in fa mo {
	gen edu_lvl_`v'=0 if edu_`v'_baseline==0   &  edu_`v'_baseline!=.
	replace edu_lvl_`v'=1 if edu_`v'_baseline>0 & edu_`v'_baseline<7  &  edu_`v'_baseline!=.
	replace edu_lvl_`v'=2 if edu_`v'_baseline>6 & edu_`v'_baseline<11  &  edu_`v'_baseline!=.
	replace edu_lvl_`v'=3 if edu_`v'_baseline>10  &  edu_`v'_baseline!=.
	tab edu_lvl_`v', gen(edu_lvl_`v'_)
	}
****
**** PCA wealth index (baseline)
****
gen nodebt= var198==0 if var198!=.
gen ses_bl_flipped= 5-ses_baseline
tab ses_baseline, gen(ses_baseline_)

gen	electricity	=	var161
gen	radio	=	var162
gen	tv	=	var163
gen	fridge	=	var164
gen	bicycle	=	var165
gen	motorcycle	=	var166
gen	aircon	=	var167
gen	washingmachine	=	var168
gen	waterpump	=	var169
gen	cartruck	=	var170
gen	pipedwater	=	var172+var173+var174
replace pipedwater=1 if pipedwater==2
gen wellwithpump=pipedwater+var175
gen wellwater=pipedwater+var175+var176

gen	flushtoilet	=	var183
gen anylatrine = var183 + var182 + var184 +var185
gen	brickwalls	=	var188
gen	enoughfoodmoney	=	var199
gen metalroof=var191+var192+var193
gen bestroof=var192+var193

foreach var in wellwithpump wellwater metalroof bestroof {
	replace `var'=1 if `var'==2 
	}
gen ses1=ses_baseline<5
gen ses2=ses_baseline<4
gen ses3=ses_baseline<3 

global assets "electricity radio tv fridge bicycle motorcycle aircon washingmachine waterpump cartruck pipedwater flushtoilet brickwalls wellwithpump wellwater metalroof bestroof anylatrine enoughfoodmoney" 
pca  $assets  ses1 ses2 ses3 // ses_bl_flipped // ln_inc_baseline -- 70% DK
predict wealth_baseline
la var wealth_baseline "Wealth Index"

foreach var in age_baseline hamd_baseline bdq_baseline mspss_baseline {
	gen `var'_sq = `var'*`var'
	}
	
gen depXtreat = treat*dep_sample
gen no_kids_baseline_estimate = no_kids - no_kids_recent
sum no_kids_baseline_estimate kids_no //kids_no only for THP

*vars for attrition bounds controls
gen rich_baseline = (ses_baseline <= 3) if ses_baseline!=.
gen mspss_high_baseline = (mspss_baseline>45) if mspss_baseline!=. 

*pca electricity radio tv fridge bicycle motorcycle aircon washingmachine waterpump cartruck pipedwater flushtoilet brickwalls enoughfoodmoney // ses_bl_flipped ln_inc_baseline -- 70% DK
pca $assets
predict wealth_baseline_4sum
rename var202 gaf_baseline 
replace uc=UC if uc==.

*gender of child at birth (not in data, but reported in THP paper)
*impute missings so that treat/control at baseline match THP
*on for ttest in baseline balance
gen gender_4sum = girl
sort treat gender_4sum
replace gender_4sum=0 if _n>=524 & _n<=557
replace gender_4sum=1 if _n>=558 & _n<=590
replace gender_4sum=0 if _n>=1129 & _n<=1166
replace gender_4sum=1 if _n>=1167 & _n<=1203
la var gender_4sum "Index child is female"

gen THP_sample= (_m3==2 | _m3==3) 
gen attrit2= attrit
replace attrit2= 1 if attrit==. & THP_sample==1
replace treat=1 if treat==. & arm ==1
replace treat=0 if treat==. & arm==0
replace Group=treat
gen rich_bl=ses_bl_flipped>0 if ses_bl_flipped !=.

gen MIL=var30==2 if var30!=.
gen maternalgma=var30==1 if var30!=.

gen abortion = var415==1 if var415!=.
gen stillbirth = var415==2 if var415!=.
gen childdeath = (var415>2 & var415<8) if var415!=.
gen motherdeath= var415==8 | var415==9 if var415!=.
gen refused		=var415==10 			if var415!=.
gen moved 		= var415==11  if var415!=.

replace childdeath=1 if status_thp_remain=="CHILD DEATH"
replace childdeath=1 if status_thp_remain=="CHILD WITH DISABILITY"
replace motherdeath=1 if status_thp_remain=="MOTHER DEATH"
replace moved=1 if status_thp_remain=="MOVED/SHIFTED"
}

//////////////
// ANTHRO   //
//////////////
{
**** stunting and wasting (merge WHO cutoffs by gender and age (months)
gen month = round(c_age_int*12)
merge m:1 month using "${maindir}/dataRaw/WHO BMI Height/who_cutoffs.dta", gen(_merge2)
keep if _merge2!=2 //drop months not found in our sample
drop _merge2

gen stunted = c_ht<sd2_height_girls if girl==1 & c_ht!=.
replace stunted = c_ht<sd2_height_boys if girl==0 & c_ht!=.

gen bmi2 = c_wt/((c_ht/100)^2)  //bmi variable in data isn't the same
gen thin = bmi2<sd2_bmi_girls if girl==1 & bmi2!=.
replace thin = bmi2<sd2_bmi_boys if girl==0 & bmi2!=.

drop zwaz zhaz //redo w-4-a and h-4-a
egen zwaz=zanthro(c_wt,wa,WHO), xvar(month) gender(girl) gencode(male=0, female=1) ageunit(month)
egen zhaz=zanthro(c_ht,ha,WHO), xvar(month) gender(girl) gencode(male=0, female=1) ageunit(month)
egen zbmi2=zanthro(bmi2,ba,WHO), xvar(month) gender(girl) gencode(male=0, female=1) ageunit(month)

la var zbmi2 "BMI-for-age (z)"


}
////////////////////////
//  UC & X Controls   //
////////////////////////
{
*interaction controls
foreach var in $X_control_vars doi0 {
	cap drop `var'Xtreat
	sum `var' if sample==1
	gen `var'Xtreat= (`var'-r(mean))*treat
	}

*uc-level controls
global for_uc_controls "mo_ht  grandmother_baseline wealth_baseline  hamd_baseline"
foreach var in $for_uc_controls {
	cap drop uc_`var'*
	bysort uc: egen uc_`var'= mean(`var')
	bysort uc: egen uc_`var'_max = max(uc_`var')
	replace uc_`var'= uc_`var'_max if three_groups==1
	}
}
/////////////////
//  FERTILITY  //
/////////////////
{

*baseline
rename var21	kids_girls_baseline
rename var22	kids_boys_baseline
gen boy_baseline = (kids_boys_baseline>0) if kids_boys_baseline<.
label var boy_baseline "At least one boy at baseline"
gen kids_total_baseline = kids_boys_baseline+kids_girls_baseline
label var kids_total_baseline "Sum of num of boys and girl at baseline"
gen kids_fem_share_baseline = kids_girls_baseline / kids_total_baseline
gen kids_fem_share_baseline_imp =  kids_fem_share_baseline
replace kids_fem_share_baseline_imp = 0.5 if kids_total_baseline==0

sum kids_no kids_*baseline
gen  kids_no_baseline= kids_no
label var kids_no_baseline "Number of kids at baseline"
rename kids_u7 kids_u7_baseline
label var kids_u7 "Kids under age 7 at baseline"

rename var24 child_dead_baseline
label var child_dead_baseline "Number of children died for any cause"
rename var25 child_dead_over5_baseline
rename var26 child_dead_under5_baseline
rename var27 child_dead_under1_baseline
rename var28 child_dead_miscar_baseline
gen child_dead_total_baseline = child_dead_over5_baseline+child_dead_under5_baseline+child_dead_under1_baseline if child_dead_baseline<. //+child_dead_miscar_baseline

gen parity = kids_no_baseline + child_dead_over5_baseline + child_dead_under5_baseline + child_dead_under1_baseline
label var parity "Parity (considering child death, but not miscarriages)"

gen flag1_kids_baseline = (kids_no_baseline!=kids_total_baseline) if kids_no_baseline<.
label var flag1_kids_baseline "The total number of kids at baseline is not the sum of boys and girls"
gen flag2_kids_baseline = (kids_no_baseline<kids_u7_baseline)
label var flag2_kids_baseline "The total number of kids at baseline is smaller than total number of kids under 7"
gen flag3_child_dead_baseline = (child_dead_baseline<child_dead_total_baseline)
label var flag3_child_dead_baseline  "The total number of child deaths at baseline is smaller than sum for different ages (prob due to miscarriages)"

* 6 months
rename var267 pregnant_6m 
label var pregnant_6m "Pregnant at 6m"

* 12 months
rename var474 pregnant_12m
label var pregnant_12m "Pregnant at 1y"
mvdecode pregnant*, mv(9)

gen pregnant_ever_12m = pregnant_12m
replace pregnant_ever_12m = 1 if pregnant_6m==1 

*7 year followup
replace mo_44 = 17 if mo_44==718 //there's one outlier

*gen no_kids = mo_41		//number of kids ("how many living children do you have?")
label var no_kids "Number of kids (7y followup)"
gen no_kids_postt = 0 if no_kids<.
label var no_kids_postt "Number of kids post-treatment (7y followup)"
gen no_kids_check = 1 if no_kids<. //sum up all of the kids reported in the fertility table, start from 1 because index child is not reported in the table
label var no_kids_check "Number of kids reported in fertility table (7y followup)"
forvalues i=2/8 {
	local j = `i'-1
	gen age_kid`j' = mo_4`i'
	gen temp = age_kid`j'*365.25
	gen birthday_kid`j' = date_int - temp
	format birthday* %td 
	lab var birthday_kid`j' "kid `j' birthday (approx)"
	capture drop temp
 
	replace no_kids_check = no_kids_check + 1 if mo_4`i' < .
	replace no_kids_postt = no_kids_postt + 1 if mo_4`i' < c_age_int //7
	}
gen flag_no_kids = no_kids_check - no_kids
replace flag_no_kids = . if no_kids>7 //there are only 7 slots in the fertility table, so the difference could make sense if total number of kids is 8 or more
label var flag_no_kids "# kids in fertility table - total number of kids reported"

gen avg_age_kids_postt = 0
if no_kids_postt >0 {
	forvalues i=2/8 {
		replace avg_age_kids_postt = avg_age_kids_postt + mo_4`i' if mo_4`i' < c_age_int
		}
	}
replace avg_age_kids_postt = avg_age_kids_postt/no_kids_postt
gen no_kids_baseline2 = no_kids - no_kids_postt
la var no_kids_baseline2 "Num kids - num kids born in last 7 years (7y followup)"

tab no_kids_baseline2 kids_no_baseline
gen flag_kids_baseline=(kids_no_baseline != no_kids_baseline -1) if attrit==0
label var flag_kids_baseline "Num of kids before index child doesn't match baseline and 7 year follow up"

*gen c_first_child=(no_kids_baseline2==1) if no_kids_baseline2<.
la var c_first_child "Index child is the first one (7yrs)"
*gen c_last_child = (no_kids_postt==0) if no_kids_postt<.
la var c_last_child "Index child is the last one (7yrs)"

la var avg_age_kids_postt "Avg. age of kids born in last 7yrs"
la var no_kids_postt "\# kids born past 7yrs"

rename mo_49	ideal_no_kids 
la var ideal_no_kids "Ideal \# kids (7y)"
mvdecode ideal_no_kids, mv(99=.d)
*rename mo_50 	no_kids_dead
rename mo_51 	no_kids_over5_dead
rename mo_52 	no_kids_1_5_dead
rename mo_53 	no_kids_less1_dead
*rename mo_54	no_kids_miscarry

gen kids_0 = no_kids_baseline - 1
replace kids_0 = 4 if no_kids_baseline>4 & no_kids_baseline !=.

foreach var in kids_0 {
    tab `var', gen(`var'_)
}

cap drop femshare
gen femshare = kids_fem_share_baseline_imp
gen	kids_boys_inhouse = kids_boys //in house
gen	kids_girls_inhouse = kids_girls
replace kids_girls_inhouse=0 if kids_boys_inhouse<. & kids_girls_inhouse==. 
gen kids_fem_share_inhouse = kids_girls_inhouse / (kids_girls_inhouse + kids_boys_inhouse)


la var kids_fem_share_inhouse "\% of kids female "
la var kids_fem_share_baseline_imp  "\% of kids \\ female \\ (at baseline)"
la var femshare  "\% of kids \\ female \\ (at baseline)"
la var kids_fem_share_baseline  "\% of kids female (at baseline)"

la var kids_girls_inhouse "Number of girls"
la var kids_boys_inhouse "Number of boys"
*la var kids_total_inhouse "Total \# of kids"

la var no_kids_miscarry   "\# of miscarriages"
la var no_kids_less1_dead  "\# died $<$1 year of age"
la var no_kids_1_5_dead  "\# died btw 1 \& 5 years old"
la var no_kids_over5_dead  "\# died $>$ 5 years old"
la var no_kids_dead   "\# died total"
*la var no_kids_postt "\# surviving births since treatment"

la var child_dead_under5_baseline "\# died $<$5 years old "  //asked differently at baseline
la var child_dead_under1_baseline "\# died $<$1 year of age"

gen change_girls= kids_girls_inhouse-kids_girls_baseline
gen change_boys = kids_boys_inhouse-kids_boys_baseline
gen change_tot = change_girls+change_boys
la var change_girls "$\Delta$ girls"
la var change_boys "$\Delta$ boys"
la var change_tot  "$\Delta$ total kids"

gen notlast=1-c_last_child
la var notlast "Index not last child"

gen c_dead_past7 = no_kids_dead - child_dead_baseline
gen c_dead_past7_v2 = (no_kids_less1_dead + no_kids_1_5_dead + no_kids_over5_dead) - child_dead_total_baseline

egen cdead0= rowtotal(child_dead_over5_baseline child_dead_under5_baseline child_dead_under1_baseline child_dead_miscar_baseline)
egen cdead7=rowtotal(no_kids_less1_dead  no_kids_1_5_dead no_kids_over5_dead no_kids_miscarry)

gen c_dead_past7_v3 = cdead7 - cdead0 if sample==1

gen c_dead= c_dead_past7
replace c_dead = c_dead_past7_v3 if c_dead_past7<0 
replace c_dead = c_dead_past7_v2 if c_dead<0  //6 cases no report less than 0 (less than 1%)
replace c_dead = 0 if c_dead<0
gen births=no_kids_postt+c_dead
la var births "Total pregnancies since baseline"

gen kids_boy_share=1-kids_fem_share
la var kids_boy_share 		"Share of boys"


}
/////////////////////////
//  IPW FOR ATTRITION  //
/////////////////////////
{
gen nonattrit = 1 - attrit2
logit nonattrit $X_control_vars if treat==1
predict p_hat1  if e(sample)
logit nonattrit $X_control_vars if treat==0
predict p_hat0  if e(sample)
gen p_hat = p_hat1
replace p_hat = p_hat0 if p_hat==.
}

////////////////
//  INDICES   //
////////////////
{
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*   CLEAN ALL VARIABLES FOR INDICES      */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
*~~~~~~~~~~~ child-related indices
{
*parenting quality
gen play_mo = mo_358>0 if mo_358!=.
gen play_fa = mo_359>0 if mo_359!=.
gen babysitter = mo_360
gen discussed = var609>0 if var609!=.
replace mo_358 = mo_358/4
replace mo_359 = mo_359/4


*Infant inputs
gen exclusivebf_6m = var392==1 if var392!=.
gen anybf_6m = (var392!=3) if var392!=.

foreach var in diarhea_6m diarhea_1y ari_6m ari_1y {
	sum `var'
	gen `var'_flip = r(max)-`var'
	}


*other vars
destring ch_432 ch_437, replace
egen peg_time2= rowmin(ch_432 ch_437)
gen peg_time = ch_432 if ch_431==0
replace peg_time = ch_437 if ch_436 == 0 //dominant hand

*replace peg_time = ch_432 if ch_436 == 0
*replace peg_time = ch_437 if ch_431 == 0 //nondominant hand

factor ch_432 ch_436 ch_438 ch_439
predict motor_f
replace peg_time = motor_f // factor of both times and drops, not placed

*replace peg_time = ch_432 + ch_437  // average of both hands
*destring peg_time, replace

gen urdu=ch_2+ch_3+ch_4
gen math=ch_5+ch_6+ch_7+ch_8

replace ch_13 = 29 if ch_13==296 // typo
gen attendance = ch_14/ch_13
replace attendance = 1 if attendance>1 & attendance!=. //1 case

gen private_sch = mo_283>0 if mo_283<3
gen expect_sch = mo_294
gen class_size = ch_10

gen health_probs = mo_491 + mo_490 + mo_485 + mo_488
replace health_probs = 1 if health_probs>0 & health_probs!=.


* other interaction variables
gen grandmaXtreat = grandmother_baseline*treat
gen tot_edu = edu_mo+edu_fa
replace tot_edu = tot_edu <12 if tot_edu!=.
gen toteduXtreat = tot_edu*treat


* flip signs for variables to be all positive
gen control = (treat==0) if sample==1
gen motor = -peg_time //flip signs for health issues (so more positive is good)
gen motor2 = peg_time
gen mo_491_2 = 1-mo_491
gen mo_490_2 = 1-mo_490
gen mo_485_2 = 1-mo_485
gen mo_488_2 = 1-mo_488 
gen class_size_2 = -class_size
gen sdq_sum_2=-sdq_sum
gen spence_2=-spence
gen mspss2 = -mspss_baseline

/* construct child develompent scores using Item Response Theory

*----- Cognitive -----*
replace ch_3 = . if ch_3 == 6
replace ch_261 =. if ch_261 ==.5

local urdu      ch_2-ch_4
local math      ch_5-ch_8
local iqblock   ch_48-ch_65
	*the items ch_68 to 71 all have values equal to 1, so I drop them
local iqinfo    ch_72-ch_96
local iqmatrix  ch_99-ch_124
local iqpicmem  ch_129-ch_163
local iqsimil1  ch_167-ch_171
local iqpiccon  ch_192-ch_218
local iqzoo     ch_228-ch_247
local iqobjass  ch_250-ch_262
local iqrecvocab ch_317-ch_347
local iqpicname ch_350-ch_373
local dccs      ch_376-ch_381 ch_383-ch_388 ch_390-ch_401
local stroop    ch_403-ch_418
	//very few obs
local iqcompr   ch_293-ch_314 
local iqvocab   ch_265-ch_287
local iqsimil2  ch_172-ch_189


* IQ
irt grm `iqblock' `iqinfo' `iqmatrix' `iqpicmem' `iqsimil1' `iqpiccon' `iqzoo' `iqobjass' `iqrecvocab' `iqpicname'
predict IQ_irt if e(sample)


* grades
irt grm `urdu' `math'
predict Grade_irt if e(sample)

*stroop
irt grm `stroop'     
predict Stroop_irt if e(sample)


*Emotional index
irt grm mo_192-mo_216 mo_235-mo_272
predict EMO_irt if e(sample)

egen temp = std(EMO_irt) //standardize 0-1
replace EMO_irt = temp
drop temp

reg EMO_irt Group $controls_baseline  if ~attrit, cluster(uc)


*----- Socio emotional -----*
* SDQ
irt grm mo_192-mo_216
predict SDQ_irt if e(sample)

*Spence
irt grm mo_235-mo_272
predict Spence_irt if e(sample)

*Emotional index
irt grm mo_192-mo_216 mo_235-mo_272
predict EMO_irt if e(sample)

egen temp = std(EMO_irt) //standardize 0-1
replace EMO_irt = temp
drop temp

reg EMO_irt Group $controls_baseline  if ~attrit, cluster(uc)
*/

*PPI
gen PPI_neg = 0 // these are negative practices (pos practices are 364 366 367 368 372 374 375 376 380 382 383 384 387)
foreach i in 362 363 365 369 370 371 373 377 378 379 381 385 386 388 389 390 391 392 393 {
	replace PPI_neg = PPI_neg+mo_`i'
	}

gen PPI_pos = 0 // (pos practices are 364 366 367 368 372 374 375 376 380 382 383 384 387)  367 375 383 -- too harsh?
foreach i in 364 366  368 372 374  376 380 382 383 384 387 {
	replace PPI_pos = PPI_pos+mo_`i'
	}	

sum PPI_neg	
gen PPI = (r(max)-PPI_neg)	//PPI_pos +  to keep or not pos?
replace mo_394=PPI


****PPI - new
gen PPI_harsh = 0
foreach i in 363 371 379 365 373 381 369 377 385 390 391 {
	replace PPI_harsh = PPI_harsh+mo_`i'
	}
sum PPI_harsh
replace PPI_harsh = r(max)-PPI_harsh
	
gen PPI_harsh4age = 0
foreach i in 367 375 383  {
	replace PPI_harsh4age = PPI_harsh4age +mo_`i'
	}
sum PPI_harsh4age
replace PPI_harsh4age = r(max)-PPI_harsh4age

gen PPI_inconsistent = 0
foreach i in  386 387 388 389 392 393  {
	replace PPI_inconsistent = PPI_inconsistent +mo_`i'
	}
sum PPI_inconsistent
replace PPI_inconsistent = r(max)-PPI_inconsistent

gen PPI_appropriate = 0
foreach i in 364 372 380 366 374 382 367 376 384   {
	replace PPI_appropriate = PPI_appropriate +mo_`i'
	}
	
replace PPI = PPI_harsh +PPI_harsh4age + PPI_inconsistent + PPI_appropriate 	

replace ch_22=1 if ch_22==60 & ch_23==1 //coding error, 1 case
gen classroom=ch_22+ch_23+ch_24
gen schoolqual= ch_27 + ch_28+ ch_29+ ch_30+ ch_31+ ch_32+ ch_33+ ch_34+ ch_35

gen not_stunted = 1-stunted
gen not_thin = 1-thin
la var not_stunted  "Not stunted (height $>-$ 2SD)"
la var not_thin		"Not thin (BMI $>-$ 2SD)"
sum sdq_pro
replace sdq_pro = r(max)-sdq_pro  //so that more positive is bad, like the rest of SDQ


gen lteachers	= log(ch_16+1)
gen lteachers_extra = ch_17>0 if ch_17!=.
gen lrooms 		= log(ch_25)
gen rooms_share = ch_26/ch_25
replace rooms_share	= 1 if rooms_share>1 & rooms_share!=.
factor schoolqual lteachers lrooms rooms_share class_size classroom
predict schoolqual_f
la var schoolqual_f "School quality"

replace ch_19=. if ch_19==99 //1 case --no variation
replace ch_36=1 if ch_36==13 //coding error, 1 case

*global schoolqual_pca "classroom ch_27 ch_28 ch_29 ch_30 ch_31 ch_32 ch_33 ch_34 ch_35 ch_36 lteachers lrooms class_size"
*factor $schoolqual_pca
pca  $schoolqual_pca
predict schoolqual_pca

la var schoolqual_pca "School quality"
la var ch_36 "Has toilets for girls"
la var classroom "Classroom amenities"
la var lteachers "Total teachers (ln)"
la var lrooms   "Total rooms (ln)"
la var class_size "Class size"

egen home_obs = rowtotal(mo_299-mo_304 mo_310 mo_311 mo_317 mo_318 mo_319)
la var home_obs "Positive parenting (interviewer obs.)"

}
*~~~~~~~~~~~ mother-related indices
{
*	____________________________________
* 	Marital satisfaction & Relationships
*	------------------------------------
replace mo_184 = 1 - mo_184
gen maritalscale = mo_182 + mo_183 +mo_184 +mo_186 +mo_187 +mo_188 //mo_185 empowerment
gen nonviolent = 1 -mo_189
gen relationship_husb =mo_190
gen relationship_inlaw = mo_191

gen maritalscale_1y = var610 + var612 + var613 +var614
gen relationship_husb_1y =var616
gen relationship_inlaw_1y = var617
gen nonviolent_1y = 1 -var615

*	___________
* 	Empowerment
*	-----------
gen empowered = mo_28  //gets money and controls spending

gen empowered_6m = var266	//empowered as above
gen empowered_1y = var611   //pocket money

la var empowered_6m "Mother controls spending (6m)" 
* Income & Wealth	----------- INCOME/WEALTH MEASURES ----------
*	_______
* 	General
*	-------
gen basicneeds = mo_70 ==1  if mo_70!=.
gen enoughfood = mo_71 ==1 if mo_71!=.
gen ses = 5- ses_lhw_rating  
gen nodebt_7y= 1-mo_76
gen nonmanual_mo = occupation_mo >1 if occupation_mo!=.
gen nonmanual_fa = occupation_fa==0 if occupation_fa !=.

*	______
* 	Income
*	------			
replace income_mo = 0 if income_mo==. & three_groups!=. //unemployed mothers
replace income_mo = . if income_mo==2  //2 == IDK

replace income_hh=. if income_hh==2
gen income_hh_full = income_hh
replace income_hh = income_hh-income_mo

replace income_fa = 0 if income_fa==. & (marital_status == 2 | marital_status == 3)
replace income_fa=. if income_fa==2

gen employed_fa_6m = var285
gen employed_fa_1y = var493

replace employed_fa_6m = 1 if (employed_fa_6m == 9 | employed_fa_6m==.) & employed_fa_1y==1
replace employed_fa_1y = 1 if (employed_fa_1y == 9 | employed_fa_1y==.) & employed_fa_6m==1
replace employed_fa_6m = 1 if employed_fa_6m ==9
replace employed_fa_1y = 1 if employed_fa_1y ==9

gen income_fa_6m = var287
replace income_fa_6m = 0 if employed_fa_6m ==0
replace income_fa_6m = . if income_fa_6m == 9 //DK
gen income_fa_1y = var495
replace income_fa_1y = 0 if employed_fa_1y ==0
replace income_fa_1y = . if income_fa_1y == 9


gen knows_inc_6m = (income_fa_6m!=.) if three_groups!=.
gen knows_inc_1y = (income_fa_1y!=.) if three_groups!=.
gen knows_inc_7y = (income_fa!=.) if three_groups!=.

replace income_fa_6m= income_fa_1y if income_fa_6m==.
replace income_fa_1y= income_fa_6m if income_fa_1y==.

replace ses_6m = 5-ses_6m
replace ses_1y = 5-ses_1y

*	____________
* 	Expenditures
*	------------
gen expend_food = mo_72 if mo_72 != 2
gen expend_med = mo_74  if mo_74 != 2
replace expend_med = mo_73*4 if expend_med==. & mo_73!=2
gen expend_educ = mo_75 if mo_75!=2
gen expend_tot= expend_food+expend_med+expend_educ

foreach var of varlist expend_food expend_med expend_educ expend_tot income_hh income_mo income_fa income_fa_6m income_fa_1y income_fa_baseline {
	gen ln_`var' = ln( `var' + 10)
	egen `var'_99 = pctile(`var'), p(99)
	replace `var' = `var'_99 if `var'>`var'_99 & `var'!=.
	drop `var'_99
	replace `var' = `var'/100	

	}
*	______
* 	Assets	
*	------
gen pipedwater_7y = mo_55 ==1 if mo_55!=.
gen flushtoilet_7y = mo_61  ==1  if mo_61!=.
gen gasstove_7y = mo_63 ==1  if mo_63!=.
gen transport_7y = 1 if mo_69 == 1  
replace transport_7y = 2 if mo_67==1  
replace transport_7y = 3 if mo_65==1 
replace transport_7y = 4 if mo_66==1 
replace transport_7y = 5 if mo_68==1 
*	_______________
* 	Physical health	
*	---------------
gen notunwell = mo_30 ==0  if mo_30!=. // see mo_31 for network!
replace days_unwell =30 if days_unwell>30 & days_unwell!=. // (mo_37)
gen days_healthy = 30- days_unwell
replace genhealth =5-genhealth  //flip so positive is better

gen days_forgonework = mo_32
replace days_forgonework = 0 if mo_32==. & three_groups!=.
gen days_forgonepaid = mo_32
replace days_forgonepaid = 0 if mo_34==1
replace days_forgonepaid = 0 if mo_34==. & three_groups!=.
gen paid_notforgone = 180-days_forgonepaid

gen mo_wt_6m = var214
la var mo_wt_6m "Weight (kg) (6m)"
*	_______________
* 	Mental health
*	---------------
gen notdepressed = 1- depressed
replace dur_tot_exact = -dur_tot_exact
gen notdep_ever_recall = 1- dep_ever_recall

gen scid_tot = 0   //could be up to 86 (imparement)
replace mo_86 = 1 if mo_86 ==. & three_groups!=. //was not answered for not depressed (missing for those who answered 'no' to above), so leave mark no
forvalues x = 77/85 {
	gen scid_`x' = (3-mo_`x')/2   
	replace scid_tot = scid_tot +scid_`x'
}
gen impaired = (3-mo_86)/2 if mo_86!=.

gen notdep = 1-depressed
gen notdep2011 = 1-dep2011
gen notdep2012 = 1-dep2012
gen notdep2013 = 1-dep2013
gen dur_notdep=notdep2011+notdep2012+notdep2013
gen notdep1213=1-(dep2013+dep2012-depressed)
replace notdep1213 = 0 if notdep1213<0 //one case dep'd in both 12 and 13

gen gaf_6m_2 = 90-gaf_6m
gen gaf_1y_2 = 90-gaf_1y
la var gaf_6m_2 "GAF general functioning (6m)"
la var gaf_1y_2 "GAF general functioning (1y)"
la var nodebt_7y "No debt"

gen scid_tot_2 = 	10-scid_tot	
gen impaired_2 =	1-impaired	
gen	notdep1213_2 = 	1-notdep1213
la var scid_tot_2 "\# Depression symptoms present (7y)"
la var impaired_2 "Symptoms cause impairement (7y)"
la var notdep1213_2 "Depressed in previous 2 years (7y)"

}

/*~~~~~~~~~~~~~~~~~~~~~~~*/
/*  GENERATE INDICES     */
/*~~~~~~~~~~~~~~~~~~~~~~~*/
* 							------------------------------------
* 							childdev & parenting-related indices
* 							------------------------------------
{
/* globals defined in the separate file THP_globalvars.do
global parenting "parentstyle parenttime parentmoney"
global childdevelopment "cognindex healthindex emoindex"


global parentstyle  " PPI_harsh PPI_harsh4age PPI_inconsistent   home_res home_mat home_emo " 
global parenttime   " home_enrich home_f_comp home_f_inter mo_358  mo_360 " 
global parentmoney	"home_learn home_env ln_expend_educ expect_sch private_sch  schoolqual_pca " 

global cognindex = "vci vsi fri wmi psi urdu math stroop g4a"  
global healthindex = "zhaz zbmi2 not_stunted  motor mo_491_2 mo_490_2 mo_485_2 mo_488_2"  
global emoindex = " sdq_emo  sdq_cond sdq_hyper sdq_peer sdq_pro panic separation injury_fear social_phobia obc gad "  

* subscales for appendix
global home  		" home_res home_mat home_emo home_learn home_enrich home_f_comp home_f_inter home_env home_obs"
global spence 		" panic separation injury_fear social_phobia obc gad"
global sdq_sum 		" sdq_emo  sdq_cond sdq_hyper sdq_peer sdq_pro"
global fsiq   		" vci vsi fri wmi psi"
*/

foreach thisvar in $parenting $childdevelopment {
	egen `thisvar' = weightave($`thisvar'), normby(control)
	sum `thisvar' if control==1
	replace `thisvar' = (`thisvar'-r(mean))/r(sd)
	factor $`thisvar'
	predict `thisvar'_f
} //end foreach thisvar

}
* 							------------------------------------
* 								  mother-related indices
* 							------------------------------------
{ 
/* globals defined in the separate file THP_globalvars.do
global parentinputs_infancy "exclusivebf_6m anybf_6m play_mo_1y play_fa_1y var599 discussed var618 var619 var620 var621"
global infantdev_6m 		"HAZ_6 WAZ_6    diarhea_6m_flip ari_6m_flip" // c_wt_6m c_ht_6m
global infantdev_1y 		"HAZ_12 WAZ_12   diarhea_1y_flip ari_1y_flip" 
global infantdev = 			"$infantdev_6m $infantdev_1y"
global depindex_0 = 		"hamd_baseline bdq_baseline"
global depindex_6m = 		"depressed_6m hamd_6m bdq_6m  gaf_6m_2"
global depindex_1y = 		"depressed_1y hamd_1y bdq_1y  gaf_1y_2"
global depindex_7y = 		"depressed scid_tot_2 impaired_2 notdep1213_2"

global depression_traj=		"depressed_6m depressed_1y depressed"
global depression_allvars=	"depindex_7y depindex_1y depindex_6m"
global depression_traj_all=	"$depindex_7y $depindex_1y $depindex_6m"

global motherfinancial 		"empowered_6m var611 empowered mo_185 employed_mo  income_mo "   
global motherfinancial_7y 	"empowered mo_185 employed_mo  income_mo "   
global mother_mh			"notdep scid_tot impaired notdep1213 "    

global motherhealthindex	"notunwell genhealth days_healthy mo_wt_6m var416" //paid_notforgone
global relationshipindex 	"maritalscale relationship_husb nonviolent relationship_inlaw" 
global relationshipindex_1y "maritalscale_1y relationship_husb_1y nonviolent_1y relationship_inlaw_1y"
global relation_traj	 	$relationshipindex $relationshipindex_1y 	 

global grandmothers			"grandmother grandmother_1y grandmother_6m"
global socialsupport		"mspss_6m mspss_1y mspss_tot"
global fertility_vars 		"ideal_no_kids  no_kids_postt pregnant_12m notlast"  // births pregnant_6m

global childmort 	  		"kids_boy_share no_kids_less1_dead no_kids_1_5_dead no_kids_over5_dead"

global fatherfinancial 		"ln_income_fa ln_income_fa_1y ln_income_fa_6m"
global ses_trajectory		"ses ses_1y ses_6m"
global incomeindex 			"basicneeds enoughfood nodebt_7y income_hh ses ses_6m ses_1y"
global expend_tot			"expend_food expend_med expend_educ"

global allotherindex ///
            incomeindex motherhealthindex motherfinancial fatherfinancial  ///
			relationshipindex relationshipindex_1y relation_traj grandmothers ///
			fertility_vars childmort depindex_0 depindex_6m depindex_1y depindex_7y mother_mh depression_traj depression_traj_all ///
			infantdev_6m infantdev_1y parentinputs_infancy infantdev motherfinancial_7y socialsupport
*/

foreach var in $allotherindex {
	egen `var' = weightave($`var') , normby(control)
	qui sum `var' if control==1
	replace `var' = (`var'-r(mean))/r(sd)
	factor $`var'
	predict `var'_f 
	}

replace childmort=-childmort
replace fertility_vars=-fertility_vars
replace emoindex=-emoindex

}
}

run "${maindir}/THP_label_variables.do"

global all2keep  ///
treat *Xtreat control dep_sample three_groups sample  lhw_*  p_hat ///
month_int month_int_sq doi0 doi0Xtreat intervr_1-intervr_9 interviewer ///
girl gender_4sum femshare age_baseline age_baseline_sq employed_mo_baseline mo_emp grandmother_baseline MIL wealth_baseline edu_lvl_mo_1 edu_lvl_mo_2 edu_lvl_mo_3 edu_mo_baseline edu_fa_baseline kids_no first_child hamd_baseline mspss_baseline doi0 ///
famstruct_baseline edu_parents depindex_0 first_child /// mspss_z 
electricity radio tv fridge bicycle motorcycle aircon washingmachine waterpump cartruck pipedwater flushtoilet brickwalls wellwithpump wellwater metalroof bestroof anylatrine enoughfoodmoney ///
mo_ht grandmother_baseline wealth_baseline hamd_baseline ///
ch_27 ch_28 ch_29 ch_30 ch_31 ch_32 ch_33 ch_34 ch_35 ///
classroom ch_36 lteachers lrooms class_size ///
edu_lvl_mo_7y_1 edu_lvl_mo_7y_2 edu_lvl_mo_7y_3 edu_lvl_mo_7y_4 edu_mo edu_fa c_first_child no_kids_baseline age age_sq   month_int month_int_sq ///
parentstyle parenttime parentmoney ///
cognindex healthindex emoindex ///
c_age_int newid ///
PPI_harsh PPI_harsh4age PPI_inconsistent home_res home_mat home_emo ///
home_enrich home_f_comp home_f_inter mo_358 mo_360 ///
home_learn home_env ln_expend_educ expect_sch private_sch schoolqual_pca ///
vci vsi fri wmi psi urdu math stroop g4a PPI ///
mo_bmi zhaz zbmi2 not_stunted motor mo_491_2 mo_490_2 mo_485_2 mo_488_2 ///
sdq_emo sdq_cond sdq_hyper sdq_peer sdq_pro panic separation injury_fear social_phobia obc gad ///
home_res home_mat home_emo home_learn home_enrich home_f_comp home_f_inter home_env home_obs ///
panic separation injury_fear social_phobia obc gad ///
sdq_emo sdq_cond sdq_hyper sdq_peer sdq_pro ///
vci vsi fri wmi psi ///
exclusivebf_6m anybf_6m play_mo_1y play_fa_1y var599 discussed var618 var619 var620 var621 ///
HAZ_6 WAZ_6 diarhea_6m_flip ari_6m_flip c_wt* c_ht* ///
HAZ_12 WAZ_12 diarhea_1y_flip ari_1y_flip ///
hamd_baseline bdq_baseline ///
depressed_6m hamd_6m bdq_6m gaf_6m_2 ///
depressed_1y hamd_1y bdq_1y gaf_1y_2 ///
depressed scid_tot_2 impaired_2 notdep1213_2 ///
depressed_6m depressed_1y depressed ///
depindex_7y depindex_1y depindex_6m ///
empowered_6m var611 empowered mo_185 employed_mo income_mo ///
empowered mo_185 employed_mo income_mo ///
notdep scid_tot impaired notdep1213 ///
notunwell genhealth days_healthy mo_wt_6m var416 /// paid_notforgone ///
maritalscale relationship_husb nonviolent relationship_inlaw ///
maritalscale_1y relationship_husb_1y nonviolent_1y relationship_inlaw_1y ///
grandmother grandmother_1y grandmother_6m ///
mspss_6m mspss_1y mspss_tot ///
ideal_no_kids no_kids_postt pregnant_12m notlast /// births pregnant_6m ///
kids_boy_share no_kids_less1_dead no_kids_1_5_dead no_kids_over5_dead ///
ln_income_fa ln_income_fa_1y ln_income_fa_6m ///
ses ses_1y ses_6m ///
basicneeds enoughfood nodebt_7y income_hh ses ses_6m ses_1y ///
expend_food expend_med expend_educ ///
Group THP_sample attrit* uc ///
age_baseline mo_ht mo_bmi edu_mo_baseline mo_emp employed_mo_baseline kids_no  first_child gender_4sum femshare hamd_baseline bdq_baseline gaf_baseline mspss_baseline var29 MIL maternalgma  edu_fa_baseline employed_fa_baseline occupation_fa_baseline ses_bl_flipped wealth_baseline_4sum ///
abortion stillbirth childdeath motherdeath refused moved ///
fsiq sdq_sum spence home motherfinancial_7y edu_lvl_mo_7y_1 ///
notdepressed notdep-notdep1213_2 recover_never recover_perm ///
parentstyle-socialsupport_f ///
age_kid1 ///

keep $all2keep 

save "${maindir}/dataClean/THP_clean.dta", replace
export delimited using "${maindir}/dataClean/THP_clean.csv", replace
}

log close

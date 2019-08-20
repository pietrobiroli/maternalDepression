*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Global varlists
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*~~~~~~~~~~~~*
*  CONTROLS  *
*~~~~~~~~~~~~*

*baseline characteristics which will get demeaned and interacted with T in the 
*programs_clean section of code
global X_control_vars       "age_baseline age_baseline_sq employed_mo_baseline mo_emp  grandmother_baseline MIL wealth_baseline edu_lvl_mo_1 edu_lvl_mo_2 edu_lvl_mo_3  edu_mo_baseline edu_fa_baseline kids_no  first_child  hamd_baseline  mspss_baseline doi0"

*controls for the diff-in-diff specifications (because we don't have baseline characteristics for the non-depressed)
global controls_dd          "edu_lvl_mo_7y_1 edu_lvl_mo_7y_2 edu_lvl_mo_7y_3 edu_lvl_mo_7y_4 edu_mo edu_fa c_first_child no_kids_baseline age age_sq   month_int month_int_sq "

*all design-based controls
global controls_design =    "month_int month_int_sq doi0 doi0Xtreat intervr_1-intervr_9"

*interaction controls
global X_controls ""
foreach var in $X_control_vars doi0 {
	global X_controls = "$X_controls `var'Xtreat `var' "
	}

*full baseline chars interacted with T (generated in programs_clean) + design controls
global controls_baseline =  "$X_controls  $controls_design "  


*~~~~~~~~~~~*
*  INDICES  *
*~~~~~~~~~~~*

global motherdecisions =    "motherfinancial parentmoney parenttime parentstyle fertility_vars"
global motherdecisions_7y = "motherfinancial_7y parentmoney parenttime parentstyle fertility_vars"
global childoutcomes =      "healthindex cognindex emoindex  childmort"
global mediators=           "motherhealthindex fatherfinancial relation_traj grandmothers socialsupport"
global allindices =         "$motherdecisions $childoutcomes $mediators"

global infancy =            "parentinputs_infancy infantdev"
global scales =             "schoolqual_pca fsiq spence sdq_sum home"

* 							------------------------------------
* 							childdev & parenting-related indices
* 							------------------------------------
{
global parenting            "parentmoney parenttime parentstyle"
global childdevelopment     "cognindex healthindex emoindex"

global parentstyle          "PPI_harsh PPI_harsh4age PPI_inconsistent   home_res home_mat home_emo " 
global parenttime           "home_enrich home_f_comp home_f_inter mo_358  mo_360 " 
global parentmoney          "home_learn home_env ln_expend_educ expect_sch private_sch  schoolqual_pca " 

global cognindex =          "vci vsi fri wmi psi urdu math stroop g4a"  
global healthindex =        "zhaz zbmi2 not_stunted  motor mo_491_2 mo_490_2 mo_485_2 mo_488_2"  
global emoindex =           "sdq_emo  sdq_cond sdq_hyper sdq_peer sdq_pro panic separation injury_fear social_phobia obc gad "  

* subscales for appendix
global home                 "home_res home_mat home_emo home_learn home_enrich home_f_comp home_f_inter home_env home_obs"
global spence               "panic separation injury_fear social_phobia obc gad"
global sdq_sum              "sdq_emo  sdq_cond sdq_hyper sdq_peer sdq_pro"
global fsiq                 "vci vsi fri wmi psi"
global schoolqual_pca       "classroom ch_27 ch_28 ch_29 ch_30 ch_31 ch_32 ch_33 ch_34 ch_35 ch_36 lteachers lrooms class_size"

}
* 							------------------------------------
* 								  mother-related indices
* 							------------------------------------
{ 
global parentinputs_infancy "exclusivebf_6m anybf_6m play_mo_1y play_fa_1y var599 discussed var618 var619 var620 var621"
global infantdev_6m         "HAZ_6 WAZ_6    diarhea_6m_flip ari_6m_flip" // c_wt_6m c_ht_6m
global infantdev_1y         "HAZ_12 WAZ_12   diarhea_1y_flip ari_1y_flip" 
global infantdev =          "$infantdev_6m $infantdev_1y"
global depindex_0 =         "hamd_baseline bdq_baseline"
global depindex_6m =        "depressed_6m hamd_6m bdq_6m  gaf_6m_2"
global depindex_1y =        "depressed_1y hamd_1y bdq_1y  gaf_1y_2"
global depindex_7y =        "depressed scid_tot_2 impaired_2 notdep1213_2"

global depression_traj=     "depressed_6m depressed_1y depressed"
global depression_allvars=  "depindex_7y depindex_1y depindex_6m"
global depression_traj_all= "$depindex_7y $depindex_1y $depindex_6m"

global motherfinancial      "empowered_6m var611 empowered mo_185 employed_mo  income_mo "   
global motherfinancial_7y   "empowered mo_185 employed_mo  income_mo "   
global mother_mh            "notdep scid_tot impaired notdep1213 "    

global motherhealthindex    "notunwell genhealth days_healthy mo_wt_6m var416" //paid_notforgone
global relationshipindex    "maritalscale relationship_husb nonviolent relationship_inlaw" 
global relationshipindex_1y "maritalscale_1y relationship_husb_1y nonviolent_1y relationship_inlaw_1y"
global relation_traj         $relationshipindex $relationshipindex_1y 	 

global grandmothers         "grandmother grandmother_1y grandmother_6m"
global socialsupport        "mspss_6m mspss_1y mspss_tot"
global fertility_vars       "ideal_no_kids  no_kids_postt pregnant_12m notlast"  // births pregnant_6m
global childmort            "kids_boy_share no_kids_less1_dead no_kids_1_5_dead no_kids_over5_dead"

global fatherfinancial      "ln_income_fa ln_income_fa_1y ln_income_fa_6m"
global ses_trajectory       "ses ses_1y ses_6m"
global incomeindex          "basicneeds enoughfood nodebt_7y income_hh ses ses_6m ses_1y"
global expend_tot           "expend_food expend_med expend_educ"

global allotherindex ///
            incomeindex motherhealthindex motherfinancial fatherfinancial  ///
			relationshipindex relationshipindex_1y relation_traj grandmothers ///
			fertility_vars childmort depindex_0 depindex_6m depindex_1y depindex_7y mother_mh depression_traj depression_traj_all ///
			infantdev_6m infantdev_1y parentinputs_infancy infantdev motherfinancial_7y socialsupport
}

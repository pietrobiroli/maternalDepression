*! version 2.0.0 5December 2018
program randcmd, eclass
	version 13.1
	syntax anything , treatvars(string) [calc1(string) calc2(string) calc3(string) calc4(string) calc5(string) calc6(string) calc7(string) calc8(string) calc9(string) calc10(string) calc11(string) calc12(string) calc13(string) calc14(string) calc15(string) calc16(string) calc17(string) calc18(string) calc19(string) calc20(string) reps(integer 1000) strata(string) groupvar(string) seed(integer 1) saving(string) sample]
	tempname b bb bbb f ff fff T ResB ResSE ResF list cols RCoef REqn ResCoef ResEqn cov
	tempvar U Order M n

preserve

	local oldseed = "`c(seed)'"

*Extracting list of treatment variables and post-treatment calculations, establishing sample (treatvars ~= .), checking treatvars do not vary within groupvar
	unab treatvars: `treatvars'
	local calc = 0
	forvalues k = 1/20 {
		if ("`calc`k''" ~= "") local calc = `k'
		}
	foreach var in `treatvars' {
		quietly drop if `var' == .
		}
	local error = 0
	if ("`groupvar'" ~= "") {
		foreach var in `treatvars' {
			quietly egen `M' = sd(`var'), by(`groupvar')
			quietly sum `M'
			if (r(mean) ~= 0) {
				display as error "`var' varies within `groupvar'.  Base treatment variables should not vary within treatment groupings."
				local error = 1
				}
			quietly drop `M'
			}
		}
	if (`error' == 1) exit


*Baseline estimating equations
	gettoken a anything: anything, match(match)
	gettoken testvars eqn: a, match(match)
	unab testvars: `testvars'
	local cols = wordcount("`testvars'")

*In case of bootstrap with user set seed
	local tempseed = "`c(seed)'"
	`eqn'
	set seed `tempseed' 
	matrix `b' = J(`cols',2,.)
	local i = 0
	local length = 0
	foreach var in `testvars' {
		local i = `i' + 1
		matrix `b'[`i',1] = _b[`var'], _se[`var']
		local length = max(`length',length("`var'"))
		}
	if ("`sample'" ~= "") keep if e(sample)
	test `testvars'
	local df = r(df)
	if (r(df_r) ~= .) local ftype = "r(F)"
	if (r(df_r) == .) local ftype = "r(chi2)"
	matrix `f' = `ftype'

	display " "

*Displaying treatment variables so that user can confirm that programme has correctly identified treatment variables and interaction equations
	display "Treatment variables determined directly by randomization: `treatvars'.", _newline
	display "Post-randomization treatment based calculations:  `calc'."
	forvalues k = 1/`calc' {
		display "  `k':   `calc`k''"
		}
	display " "
	display "Tested treatment based variables: `testvars'."
	display " "

*Preparing variables and matrices to be used in randomization analysis
	set seed `seed' 
	if ("`groupvar'" ~= "") {
		egen `M' = group(`groupvar')
		quietly sum `M'
		local N = r(max)
		quietly bysort `M': gen `n' = _n
		sort `n' `strata' `M'
		quietly generate `Order' = _n
		}
	if ("`groupvar'" == "") {
		local N = _N
		quietly generate `Order' = _n	
		sort `strata' `Order'
		}
	quietly generate double `U' = .
	mata `list' = J(1,0,"")
	foreach var in `treatvars' {
		mata `list' = `list', "`var'"
		}
	mata `T' = st_data((1,`N'),`list'); `ResB' = J(`reps',`cols',.); `ResSE' = J(`reps',`cols',.); `ResF' = J(`reps',1,.)

display " "
display "Running `reps' randomization iterations:"

*Randomization iterations
	forvalues count = 1/`reps' {
		if (ceil(`count'/10)*10 == `count') display "`count'", _continue

*Randomizing direct treatment and recalculating treatment based variables
		if ("`groupvar'" == "") {
			quietly sort `strata' `Order'
			quietly replace `U' = uniform()
			quietly sort `strata' `U'
			mata st_store(.,`list',`T')
			}
		if ("`groupvar'" ~= "") {
			quietly sort `n' `strata' `Order'  
			quietly replace `U' = uniform() if _n <= `N'
			quietly sort `strata' `U' in 1/`N'
			mata st_store((1,`N'),`list',`T')
			quietly sort `M' `n'
			foreach var in `treatvars' {
				quietly replace `var' = `var'[_n-1] if `n' > 1
				}
			}						
		forvalues k = 1/`calc' {
			quietly `calc`k''
			}

*Estimating equations
		local tempseed = "`c(seed)'"
		capture `eqn'
		set seed `tempseed'
		if (_rc == 0) {
			matrix `bb' = J(`cols',2,.)
			local i = 0
			foreach var in `testvars' {
				local i = `i' + 1
				capture matrix `bb'[`i',1] = _b[`var'], _se[`var']
				}
			mata `bbb' = st_matrix("`bb'"); `ResB'[`count',1...] = `bbb'[1...,1]'; `ResSE'[`count',1...] =  `bbb'[1...,2]'
			capture test `testvars'
			if (_rc == 0 & r(df) == `df') mata `ResF'[`count',1] = ``ftype''
			}
		}
display, _newline

*Calculating p-values
	mata `b' = st_matrix("`b'"); `f' = st_matrix("`f'"); `ResCoef' = J(`cols',6,.); `ResEqn' = J(1,6,.)
	forvalues c = 1/`cols' {
		mata `bb' = (`ResB'[1...,`c']:~=.); `bb' = `bb':*(`ResSE'[1...,`c']:~=.); `bb' = `bb':*(`ResSE'[1...,`c']:~=0)
		mata `ff' = select(`ResB'[1...,`c'],`bb'); `ff' = (abs(`ff'):>abs(`b'[`c',1])*1.000001), (abs(`ff'):>abs(`b'[`c',1])*.999999); `ff' = colsum(`ff'), rows(`ff')
		mata `ResCoef'[`c',1..3] = `ff'[1,1]/(`ff'[1,3]+1), (`ff'[1,2]+1)/(`ff'[1,3]+1), `ff'[1,3]
		mata `ff' = select(`ResB'[1...,`c']:/`ResSE'[1...,`c'],`bb'); `ff' = (abs(`ff'):>abs(`b'[`c',1]/`b'[`c',2])*1.000001), (abs(`ff'):>abs(`b'[`c',1]/`b'[`c',2])*.999999); `ff' = colsum(`ff'), rows(`ff')
		mata `ResCoef'[`c',4..6] = `ff'[1,1]/(`ff'[1,3]+1), (`ff'[1,2]+1)/(`ff'[1,3]+1), `ff'[1,3]
		}
	mata `bb' = (`ResF'[1...,1]:~=.)
	forvalues c = 1/`cols' {
		mata `bb' = `bb':*(`ResB'[1...,`c']:~=.); `bb' = `bb':*(`ResSE'[1...,`c']:~=.); `bb' = `bb':*(`ResSE'[1...,`c']:~=0)
		}
	mata `ff' = select(`ResB',`bb'); `cov' = `ff':-mean(`ff'); `cov' = `cov''*`cov'/rows(`cov'); `cov' = invsym(`cov')
	mata `ff' = rowsum(`ff'*`cov':*`ff'); `fff' = `b'[1...,1]'*`cov'*`b'[1...,1]
	mata `ff' = (`ff':>`fff'*1.000001), (`ff':>`fff'*.999999); `ff' = colsum(`ff'), rows(`ff')
	mata `ResEqn'[1,1..3] = `ff'[1,1]/(`ff'[1,3]+1), (`ff'[1,2]+1)/(`ff'[1,3]+1), `ff'[1,3]
	mata `ff' = select(`ResF'[1...,1],`bb'); `ff' = (`ff':>`f'[1,1]*1.000001), (`ff':>`f'[1,1]*.999999); `ff' = colsum(`ff'), rows(`ff')
	mata `ResEqn'[1,4..6] = `ff'[1,1]/(`ff'[1,3]+1), (`ff'[1,2]+1)/(`ff'[1,3]+1), `ff'[1,3]
	mata `bb' = uniform(rows(`ResCoef'),1); `ResCoef' = `ResCoef'[1...,1..2], `ResCoef'[1...,1]+`bb':*(`ResCoef'[1...,2]-`ResCoef'[1...,1]), `ResCoef'[1...,4..5], `ResCoef'[1...,4]+`bb':*(`ResCoef'[1...,5]-`ResCoef'[1...,4]), `ResCoef'[1...,6]
	mata `bb' = uniform(1,1); `ResEqn' = `ResEqn'[1...,1..2], `ResEqn'[1...,1]+`bb':*(`ResEqn'[1...,2]-`ResEqn'[1...,1]), `ResEqn'[1...,4..5], `ResEqn'[1...,4]+`bb':*(`ResEqn'[1...,5]-`ResEqn'[1...,4]), `ResEqn'[1...,6]
	mata st_matrix("`ResCoef'",`ResCoef'); st_matrix("`ResEqn'",`ResEqn')

*Displaying results
local length = max(`length',length("  joint test  "))
local a1 = `length' + 6
forvalues k = 2/7 {
	local a`k' = `a1' + 13*(`k'-1)
	}
local aa1 = `a1' - 4
local aa2 = floor(`length'/2)-1
local aa3 = `a2' - 3
local aa5 = `a5' - 3

display as text " "
if (`cols' > 1) display "Randomization p-values for individual treatment effects and joint test of significance:", _newline
if (`cols' == 1) display "Randomization p-values:", _newline
display as text _col(`aa3') %15s  "randomization-c" _col(`aa5') "randomization-t" 
display as text _col(`aa2') %8s "treatment" _col(`a1') %8s "minimum" _col(`a2') %8s "maximum" _col(`a3') %10s "randomized" _col(`a4') %8s "minimum" _col(`a5') %8s "maximum" _col(`a6') %10s "randomized" _col(`a7') %10s "successful"
display as text _col(`aa2') %8s "effect" _col(`a1') %8s "p-value" _col(`a2') %8s "p_value" _col(`a3') %8s "p-value" _col(`a4') %8s "p-value" _col(`a5') %8s "p-value" _col(`a6') %8s "p-value" _col(`a7') %10s "iterations"
display as text "{hline `aa1'}{c +}{hline 90}"
	local i = 0
	foreach var in `testvars' {
		local i = `i' + 1
		display as text _col(2) %-`length's "`var'" _col(`aa1') " {c |}" , _continue
		display as result _col(`a1') %7.6g `ResCoef'[`i',1] _col(`a2') %7.6g `ResCoef'[`i',2] _col(`a3') %7.6g `ResCoef'[`i',3] _col(`a4') %7.6g `ResCoef'[`i',4] _col(`a5') %7.6g `ResCoef'[`i',5] _col(`a6') %7.6g `ResCoef'[`i',6] _col(`a7') %7.6g `ResCoef'[`i',7]  
		}
	if (`cols' > 1) {
		display as text _col(2) %-`length's "`var'" _col(`aa1') " {c |}" 
		display as text _col(2) %-`length's "  joint test  " _col(`aa1') " {c |}" , _continue
		display as result _col(`a1') %7.6g `ResEqn'[1,1] _col(`a2') %7.6g `ResEqn'[1,2] _col(`a3') %7.6g `ResEqn'[1,3] _col(`a4') %7.6g `ResEqn'[1,4] _col(`a5') %7.6g `ResEqn'[1,5] _col(`a6') %7.6g `ResEqn'[1,6] _col(`a7') %7.6g `ResEqn'[1,7]  
		}
display as text "{hline `aa1'}{c BT}{hline 90}", _newline

*ereturn matrices
matrix colnames `ResCoef' = "min-c pvalue" "max-c pvalue" "rand-c pvalue" "min-t pvalue" "max-t pvalue" "rand-t pvalue" "iterations"
matrix colnames `ResEqn' = "min-c pvalue" "max-c pvalue" "rand-c pvalue" "min-t pvalue" "max-t pvalue" "rand-t pvalue" "iterations"
matrix rownames `ResCoef' = `testvars'
matrix rownames `ResEqn' = "joint test"

ereturn matrix RCoef = `ResCoef', copy
ereturn matrix REqn = `ResEqn', copy

set seed `oldseed'

*Saving, if user requested
if ("`saving'" ~= "") {
	quietly drop _all
	quietly set obs `reps'
	forvalues i = 1/`cols' {
		quietly generate double ResB`i' = .
		}
	forvalues i = 1/`cols' {
		quietly generate double ResSE`i' = .
		}
	quietly generate double ResF = .
	mata st_store(.,.,(`ResB', `ResSE', `ResF'))
	save `saving'
	}

restore

end


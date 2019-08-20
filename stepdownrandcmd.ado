*! version 2.0.2  30july2019
* Started from stepdown.ado file from https://github.com/PrincetonBPL/ado-gallery
*       use the non-parametric pvalue created by the randcmd (from A Young's website http://personal.lse.ac.uk/YoungA/)
*       in a separate loop, perform the stepdown procedure
*       included option to make controls demeaned and interacted with treatments


*stepdownrandcmd reg (hap1 sat1) treat spillover if ~purecontrol, options(r cluster(village)) iter(100) txcontrols(educ_baseline) rcluster(village)
capture program drop stepdownrandcmd
program define stepdownrandcmd, rclass
	gettoken cmd 0 : 0
	gettoken depvars 0 : 0, parse("(") match(par)
	syntax varlist [if] [in] [aweight], ITER(integer) [OPTions(string)] [TYPE(string)] [CONTROLstems(string)] [TXCONTROLS(varlist)] [RCLUSTER(varlist)]
	gettoken treat varlist : varlist

	local weights "[`weight' `exp']"

	dis""
	dis "cmd: `cmd'; depvars: `depvars'; treat: `treat'; varlist: `varlist'; weights: `weights'; options: `options'; iter: `iter'; controlstems: `controlstems'; txcontrols: `txcontrols'; rcluster: `rcluster'"
	dis""

if "`iter'" == "" {
	local iter 100
	dis""
	dis "Number of iterations not specified; `iter' assumed."
	dis""
	}

if "`rcluster'" == "" {
	dis""
	dis "Randomization group not specificied; iid across all observations assumed."
	dis""
	tempvar cluster 
	gen `cluster' = _n
	}

	
if "`type'" == "" {
	local type "fwer"
	dis""
	dis "FWER or FDR not specified; default to FWER."
	dis""
	}

* set seed 1073741823 //the seed is set in the mainfile

quietly {
* generate variables to store actual and simulated t-stats/p-vals
local counter = 1
tempvar varname tstat act_pval tstatsim pvalsim pvals

gen str20 `varname' = ""
gen float `tstat' = .
gen float `act_pval' = .
gen float `tstatsim' = .
gen float `pvalsim' = .
gen float `pvals' = .

foreach x of varlist `depvars' {

	local controlvars ""
    if "`controlstems'"~="" {
		foreach stem in `controlstems' {
			local controlvars "`controlvars' `x'`stem'"
		}
	}
	
	local txcontrolvars ""
    if "`txcontrols'"~="" {
		foreach txvar in `txcontrols' {
			cap drop `txvar'Xtreat
			sum `txvar' `if'
			gen `txvar'Xtreat= (`txvar'-r(mean))*`treat'
			local txcontrolvars "`txcontrolvars' `txvar'Xtreat `txvar'"
		}
	}
	 
	dis "`cmd' `x' `treat' `varlist' `txcontrolvars' `controlvars' `if' `in' `weights', `options'"
		 `cmd' `x' `treat' `varlist' `txcontrolvars' `controlvars' `if' `in' `weights', `options'
		 
	randcmd ((`treat') `cmd' `x' `treat' `varlist' `controlvars' `txcontrolvars' `if' `in' `weights', `options'), treatvars(`treat') reps(`iter')
	
	mat define A=e(RCoef)
    replace `act_pval' = A[1,6] in `counter'

    replace `varname' = "`x'" in `counter'
    local `x'_ct_0 = 0
    local counter = `counter' + 1
}


sum treat
local cutoff = `r(mean)'

local numvars = `counter' - 1
dis "numvars: `numvars'"

* sort the p-vals by the actual (observed) p-vals (this will reorder some of the obs, but that shouldn't matter)
tempvar porder
gen `porder' = _n in 1/`numvars'
gsort `act_pval'

* generate the variable that will contain the simulated (placebo) treatments
tempvar simtreatment simtreatment_uni simtreatment_cluster ind
gen byte `simtreatment' = .
gen float `simtreatment_uni' = .
gen `ind' = .
local count = 1
} //quietly


* run 10,000 iterations of the simulation, record results in p-val storage counters
while `count' <= `iter' {
	if mod(`count',25)==0{
	dis "`count'/`iter'"
	}
quietly {
	* in this section we assign the placebo treatments and run regressions using the placebo treatments
	replace `simtreatment_uni' = uniform()
	*assign the same randomization value to all of the obs in rcluster
	if "`rcluster'" != "" {
		sort `rcluster', stable
		by `rcluster': replace `ind'=1 if _n==1
		replace `simtreatment_uni' = . if `ind' != 1
		sum `simtreatment_uni', d
		local cutoff = r(p50)
		bysort `rcluster': replace `simtreatment_uni' = `simtreatment_uni'[1] 
	}
	replace `simtreatment' = (`simtreatment_uni'<=`cutoff')
	replace `tstatsim' = .
	replace `pvalsim' = .
	foreach lhsvar of numlist 1/`numvars' {
	    local depvar = `varname'[`lhsvar']
		local controlvars ""
    	if "`controlstems'"~="" {
			foreach x in `controlstems' {
				local controlvars "`controlvars' `depvar'`x'"
			}
		}
		local txcontrolvars ""
		if "`txcontrols'"~="" {
		foreach txvar in `txcontrols' {
			cap drop `txvar'Xsimtreat
			sum `txvar' `if'
			gen `txvar'Xsimtreat= (`txvar'-r(mean))*`simtreatment'
			local txcontrolvars "`txcontrolvars' `txvar'Xsimtreat `txvar'"
		}
	}
	
		randcmd ((`simtreatment') `cmd' `depvar' `simtreatment' `varlist' `controlvars' `txcontrolvars' `if' `in' `weights', `options'), treatvars(`simtreatment') reps(`iter') 
		mat define A=e(RCoef)
		
		scalar p = A[1,6]
		replace `pvalsim' = p in `lhsvar'

    }
	* in this section we perform the "step down" procedure that replaces simulated p-vals with the minimum of the set of simulated p-vals associated with outcomes that had actual p-vals greater than or equal to the one being replaced.  For each outcome, we keep count of how many times the ultimate simulated p-val is less than the actual observed p-val.
    	
	local countdown `numvars'
    while `countdown' >= 1 {
        replace `pvalsim' = min(`pvalsim',`pvalsim'[_n+1]) in `countdown'
        local depvar = `varname'[`countdown']
        if `pvalsim'[`countdown'] <= `act_pval'[`countdown'] {
            local `depvar'_ct_0 = ``depvar'_ct_0' + 1
            dis "Counter `depvar': ``depvar'_ct_0'"
            }
        local countdown = `countdown' - 1
	}
    local count = `count' + 1
	} // quietly
} // iterations

quietly {
foreach lhsvar of numlist 1/`numvars' {
	local thisdepvar =`varname'[`lhsvar']
    replace `pvals' = max(round(``thisdepvar'_ct_0'/`iter',.00001), `pvals'[`lhsvar'-1]) in `lhsvar'
    }

tempname pvalmatrix ordermatrix combmatrix finalmatrix
mkmat `pvals', matrix(`pvalmatrix')
matrix `pvalmatrix' = `pvalmatrix'[1..`numvars',1]'

mkmat `porder', matrix(`ordermatrix')
matrix `ordermatrix' = `ordermatrix'[1..`numvars',1]'
mat def `combmatrix' = (`ordermatrix' \ `pvalmatrix')'
mata : st_matrix("`combmatrix'", sort(st_matrix("`combmatrix'"), 1))
matrix `finalmatrix' = `combmatrix'[1..`numvars',2]'

*return matrix pvalordered = `pvalmatrix'
*return matrix order = `ordermatrix'
return matrix p = `finalmatrix'

cap drop `tstatsim' `pvalsim' `simtreatment'*  *Xsimtreat
} //quietly

end
exit

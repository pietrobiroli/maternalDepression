{smcl}
{* *! version 1.0.0 15December2015}{...}
{cmd: help randcmd}
{hline}

{title:Title}

{phang} {hi:randcmd} {hline 2} Randomization inference based p-values. {p_end}
 
{title:Syntax}

{phang} {cmd:randcmd} ({opth (varlist)} stata estimation command), {opth treatvars(varlist)} [{cmd:,} {it:options}] {p_end}

{title:Options}

    {opth strata(varlist)}            variables identifying randomization strata.
    {opth groupvar(varlist)}          variables identifying treatment groups.
    {opth seed(#)}                    set random-number seed to #, default is 1.
    {opth saving(filename, replace)}  save results to filename (replace to overwrite).
    {opth reps(#)}                    number of attempted randomization iterations, default is 1000.
    {opt sample}                     restrict rerandomization to the sample of the estimating equation.
    {opth calc1(string)}              execute stata command after each treatment rerandomization.
	...
    {opth calc20(string)}             execute stata command after each treatment rerandomization.


{p} {opth (varlist)} must appear as right-hand side variables in the stata estimation command.  
{opt treatvars} indicates the base treatment variables that are rerandomized on each iteration, and is not optional. 
{opt treatvars} cannot vary within groups identified by {opt groupvar}.  Observations for which any of {opt treatvars} are missing are dropped.  
If {opt sample} is specified, {opt treatvars} are rerandomized across observations in the estimating equation; otherwise, {opt treatvars} are rerandomized across their non-missing observations.
To update treatment measures that involve interactions with participant characteristics (see below), up to twenty post-treatment calculations are allowed and are executed in numerical order.  
If the user does not provide a random number seed, the seed is set to 1 (to ensure replicability, provided the data have not been reordered, on subsequent runs).  
The seed is restored to its pre-program value on termination.

{title:Description}

{phang} {cmd:randcmd} computes randomization-c and randomization-t p-values for individual treatment effects and the joint significance of all treatment effects in an estimating equation.
The p-value, in each case, is calculated under the null hypothesis that all treatment effects are zero for all participants.  
Randomization-t p-values are more robust to deviations from the exact null of zero effects for all participants.  For details, see:

{pmore} Young, Alwyn. 
{browse "http://personal.lse.ac.uk/YoungA/ChannellingFisherQJE.pdf": {it:Channelling Fisher: Randomization Tests and the Statistical Insignificance of Seemingly Significant Experimental Results.}}  
Quarterly Journal of Economics, forthcoming.
{p_end}

{phang} {cmd:randcmd} begins by reporting the conventional estimation results and p-values for the stata command specified by the user.  
The stata command must return estimated coefficients and standard errors for each variable listed in {opth (varlist)} for the estimating equation.  
Otherwise, all estimation options associated with any stata command are allowed.  
{cmd:randcmd} then rerandomizes {opt treatvars}, following any strata and grouping specified by the user, performs optional calc1 ... calc20 (see examples below), and then reruns the stata estimation command.  
Conventional coefficient estimates and standard errors, as well as joint test Wald/F statistics, are stored for each iteration and saved if requested by the user.  
Randomization p-values for individual and joint tests of treatment effects are only based upon iterations that produce an estimated coefficient and non-zero standard error for the treatment measures involved.  
The number of such iterations is reported.
{p_end}

{title:Examples}

{p} Example 1: Basic estimating equation, with sample restrictions and command options.

{phang} randcmd ((treatment) areg outcome treatment covariates [if] [in] [weights], absorb(absorb) cluster(cluster)), treatvars(treatment)

{phang} Comment: Estimating equation can be restricted to subsets of participants (e.g. age > 25), but treatment is rerandomized across the entire experimental population (treatment ~= . in the data file) unless {opt sample} is specified. 

{p} Example 2: Treatment variables include interactions with participant characteristics which are not part of treatment and have to be recalculated after treatment is rerandomized.

{phang} randcmd ((treatment treatage) xtreg outcome treatment treatage covariates [if] [in] , re cluster(cluster)), treatvars(treatment) calc1(replace treatage = treatment*age)

{phang} Comment: Calculations could also be coded as calc1(drop treatage) calc2(generate treatage = treatment*age), but use of replace, where appropriate, is simpler.

{p} Example 3: Interactions between treatment measures can be coded with calc or without.

{phang} randcmd ((treat1 treat2 treat12) probit outcome treat1 treat2 treat12 covariates [if] [in], robust asis), treatvars(treat1 treat2) calc1(replace treat12 = treat1*treat2)

{phang} randcmd ((treat1 treat2 treat12) probit outcome treat1 treat2 treat12 covariates [if] [in], robust asis), treatvars(treat1 treat2 treat12)

{phang} Comment: Since treat12 is the product of randomized treatment variables, and does not involve interaction with non-randomized participant characteristics, 
reallocating pairs of (treat1,treat2) to participants and then calculating treat12 is equivalent to reallocating triplets of (treat1,treat2,treat12) across participants.

{p} Example 4: Treatment is stratified and applied in groups.

{phang} randcmd ((treat1 treat2) areg outcome treat1 treat2 covariates [if] [in] [weights], absorb(village) cluster(village)), treatvars(treat1 treat2) strata(strata) groupvar(village)

{phang} Comment: treat1 and treat2 cannot vary within groupvar.  The pair (treat1, treat2) applied to each village is rerandomized across villages (within strata). 

{p} Example 5: Variables appearing in {opt treatvars} do not have to appear in {opth (varlist)} in the estimating equation.  Consider the case where results are analysed using dif-in-dif, with post denoting the post-treatment period.

{phang} randcmd ((treatpost) reg outcome treatpost treat post, cluster(village))), treatvars(treat) groupvar(village) calc1(replace treatpost = treat*post)

{phang} Comment: The coefficients on variable treat are used to determine average differences in the pre-treatment period, but the treatment effects are actually measured by treatpost.  
I am interested in testing the hypothesis that treatment has no effect on post-treatment outcomes 1 and 2, so only treatpost is listed in {opth (varlist)}.  

{p} Example 6: Estimating treatment p-values for stata commands which produce multiple coefficients for each right-hand side variable requires a careful listing of desired treatment variables in {opth (varlist)}.

{phang} randcmd ((treat select:treat) heckman outcome treat covariates, select(treat covariates othercovariates) twostep), treatvars(treat) 

{phang} randcmd ((3:treat 7:treat) mlogit outcome037 treat covariates, baseoutcome(0)), treatvars(treat) {p_end}

{phang} Comment: In the heckman estimating equation I identify that I am interested in the significance of the treat variable in both the outcome and selection equations.  
In the mlogit estimating equation I have a dependent variable that takes on three values (0,3,7). 
I specify that 0 is the base outcome (treat coefficient automatically set to 0) and calculate p-values for the treat coefficients for outcomes 3 and 7.  
A simple rule of thumb is to observe how stata names the coefficient estimates when reporting results and use those names in {opth (varlist)}.

{title:Reported results}

{phang} In comparing potential outcomes, randomization inference always produces "ties", as the original experimental outcome (at a minimum) must be considered a tie with itself (see paper referenced above).  
P-values are uniformly distributed between minimum and maximum values determined by these ties.  
{cmd:randcmd} reports these minimum and maximum values and a "final" randomized p-value based upon a random draw from the uniform distribution. 
The practical relevance of the experiment's tie with itself can be reduced by increasing the number of iterations, 
but if the experiment allows for only a small number of potential outcomes the width of the min-max interval will not systematically fall with the number of iterations.  {p_end}

{phang} {cmd:randcmd} stores the following matrices in {cmd:e()}: {p_end}

{cmd:e(RCoef)}   Randomization-c and randomization-t p-values for individual coefficients.
{cmd:e(REqn)}    Randomization-c and randomization-t p-values for the joint-test of the significance of treatment measures in each equation.

{title:Author}
	
{phang} Alwyn Young, London School of Economics, a.young@lse.ac.uk. {p_end}


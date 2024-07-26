
clear all
set more off 
cap log close
pause on 
timer on 1

/*******************************************************************************
Title: RCT Session - EconThaki
Author: Germán D. Orbegozo
Date Created: July 20th, 2024
*******************************************************************************/

/*
Description:

This do file opens the database from:

Fafchamps, M., McKenzie, D., Quinn, S., & Woodruff, C. (2014). Microenterprise 
growth and the flypaper effect: Evidence from a randomized experiment in Ghana. 
Journal of Development Economics, 106, 211-226.

It explores, cleans the database, and runs regressions.
*/

********************************************************************************
**# Set Directory paths and macros
********************************************************************************

if c(username) == "germanorbegozo" { //Add your username here
 	global dropbox = "/Users/germanorbegozo/Library/CloudStorage/Dropbox/"	
}		
else if c(username) == "" { //Add your username here
 	global dropbox = ""	// Add your path here
}	

// Globals
global main   "$dropbox/Temporal/Personal/Voluntariado/EconThaki Latam/Sesion1_RCT"
global data   "$main/Data"
global output "$main/Output"

// Directory
cd "$main"


********************************************************************************
**# Data exploration
********************************************************************************

// Load dataset
use "${main}/Data/ReplicationDataGhanaJDE.dta", clear

// Explore data
describe sheno wave groupnum assigntreat cashtreat equiptreat realfinalprof
mdesc sheno wave groupnum assigntreat cashtreat equiptreat realfinalprof

// Understand level of data
codebook sheno
tab wave
isid sheno wave

// Order data
order sheno wave groupnum assigntreat cashtreat equiptreat realfinalprof
sort groupnum sheno wave 
browse 

// Look at treatment variable
foreach var in assigntreat cashtreat equiptreat {
	display "*** `var' ***"
	tab `var'
}

// Look at summary stats of the outcomes
des realfinalprof
sum realfinalprof


********************************************************************************
**# Table 1: Sample
********************************************************************************
/*
1.	Produce a well-organized descriptive statistics table for Wave 2 that includes: (i) the number of households, (ii) the number of units of randomization, (iii) the sample mean and standard error of the real final profit in the control group, and (iv) the same sample mean and standard error in the treatment group. The table should have one row per country and five columns, including the country name.  
*/

// Do a matrix to store the results
matrix define mat_ghana = J(2,4,.)
matlist mat_ghana

// Get number of households
count if wave == 2
scalar households = r(N)

// Get number of units of randomization / strata
des groupnum
codebook groupnum
preserve 
	keep if wave == 2
	collapse wave , by(groupnum)
	egen N_groupnum = count(groupnum) 
	sum N_groupnum
	scalar units = r(mean)
restore 

// Get sample mean and standard error of the real final profit in the control group
qui sum realfinalprofit if wave == 2 & assigntreat  == 0
scalar mean_control = r(mean)
scalar se_control = r(sd)/sqrt(r(N))
display "Control group: mean = " mean_control " and se = " se_control

// Get sample mean and standard error of the real final profit in the treatment group
qui sum realfinalprofit if wave == 2 & assigntreat  == 1
scalar mean_treatment = r(mean)
scalar se_treatment = r(sd)/sqrt(r(N))
display "Treatment group: mean = " mean_treatment " and se = " se_treatment

// Comapre means
bysort assigntreat: tabstat realfinalprofit if wave == 2 ,stat(mean semean) 
reg realfinalprofit assigntreat if wave == 2 

// Do a matrix to store the results
matrix mat_ghana[1,1] = households
matrix mat_ghana[1,2] = units
matrix mat_ghana[1,3] = mean_control
matrix mat_ghana[1,4] = mean_treatment
matrix mat_ghana[2,3] = se_control
matrix mat_ghana[2,4] = se_treatment
matlist mat_ghana

// Table for correlations
matrix rownames mat_ghana = "Ghana" "SE"
matlist mat_ghana

local file = "Table_1"
#delimit;
	frmttable using "${main}/Output/`file'", 
	tex frag 						
	statmat(mat_ghana) 
	substat(0) 
	coljust() 										
	annotate() 
	asymbol(x) 															
	ctitles("Country" "Households" "Units of Randomization" 						
	"Control Mean/SE" "Treatment Mean/SE") 										
	varlabels 
	sdec(0,0,3) 
	replace;
#delimit cr

local tex "$main/Output/`file'.tex"
local tex2 "$main/Output/`file'_2.tex"

filefilter "`tex'" "`tex2'" , replace 											///
from("\BSbegin{center}") to("")

filefilter "`tex2'" "`tex'" , replace 											///
from("\BS\BS\n\BSend{center}") to("")

erase "`tex2'"

 
 
********************************************************************************
**# Table 2: Verifying Randomization
********************************************************************************

/*
2.	Verify the randomization as done in Table 2 of the paper. Specifically, interpret the p-values of the F-statistics in the first row.
*/

local varlist = "realfinalprofit fem highcapture highcapital male_male male_mixed female_female female_mixed  finalsales  inventories  hourslastweek totalK useasusu businesshome married educ_years digitspan akanspeaker gaspeaker age firmage everloan business_taxnumber"

des `varlist'
sum `varlist'

foreach lhs of varlist `varlist' {

	// OLS estimation without strata controls
	display
	display "*** `lhs' ***"
	des `lhs' 
	reg `lhs' control cashtreat equiptreat if wave==2, noconstant robust
	test cashtreat==equiptreat==control
	
}
 
reg realfinalprofit control cashtreat equiptreat if wave==2, noconstant robust

sum realfinalprofit if control==1 & wave==2
sum realfinalprofit if cashtreat==1 & wave==2 
sum realfinalprofit if equiptreat==1 & wave==2


********************************************************************************
**# Table 3: Main treatment effects.
********************************************************************************

/*
3. Reproduce the coefficient and standard error estimates from columns 1-6 of Table 3 in the paper, and export the results to a well-formatted table in LaTeX.
*/

// Recall what are the variables
des realfinalprofit atreatcash atreatequip 

// See statistics
sum realfinalprofit atreatcash atreatequip 


// Column 1: OLS with strata dummies and clustering
reghdfe realfinalprofit atreatcash atreatequip wave2-wave6 , abs(groupnum) cluster(sheno)
estimates store col1


// Column 2: OLS with strata dummies and clustering and trimming
tab trimgroup
reghdfe realfinalprofit atreatcash atreatequip wave2-wave6 if trimgroup!=1, abs(groupnum) cluster(sheno) 
estimates store col2

// Column 3: Fixed effects with all rounds
xtset sheno wave
xtreg realfinalprof atreatcash atreatequip wave2-wave6, fe cluster(sheno)

reghdfe realfinalprof atreatcash atreatequip wave2-wave6, abs(sheno) cluster(sheno)
estimates store col3

// Column 4: Fixed effects with all rounds and trimming
xtreg realfinalprof atreatcash atreatequip wave2-wave6 if trimgroup!=1, fe cluster(sheno)
estimates store col4


// Column 5: Divide by gender
reghdfe realfinalprof atreatcashfemale atreatequipfemale atreatcashmale atreatequipmale wave2-wave6 wave2_female-wave6_female, abs(groupnum) cluster(sheno)
estimates store col5


// Column 6: 
reghdfe realfinalprof atreatcashfemale atreatequipfemale atreatcashmale atreatequipmale wave2-wave6 wave2_female-wave6_female if trimgroup!=1, abs(groupnum) cluster(sheno)
estimates store col6


// Create Table
# delimit ;

local file Table_3_version1 ;

esttab 	col1 col2 col3 col4 col5 col6
		using "${main}/Output/`file'",   						
		keep(atreatcash atreatequip 
			atreatcashfemale atreatequipfemale 
			atreatcashmale atreatequipmale _cons)
		order(atreatcash atreatequip 
			atreatcashfemale atreatequipfemale 
			atreatcashmale atreatequipmale _cons)
		b(%12.2f)		  	
		se(%12.2f)	
		starlevels(* .10 ** .05 *** .01)
		mtitles("OLS" "OLS" 
				"FE" "FE"
				"OLS" "OLS")
		/*nomtitles
		mgroups("Trusts Group A Less Than B", 
			pattern(1 0 0 0)                  
			prefix(\multicolumn{@span}{c}{) suffix(})   
			span erepeat(\cmidrule(lr){@span}))         
			alignment(D{.}{.}{-1}) // nonumber //page(dcolumn)	*/	
		varlab(atreatcash "Cash treatment"
			atreatequip "In-kind treatment"
			atreatcashfemale "Cash treatment*female"
			atreatequipfemale "In-kind treatment*female"
			atreatcashmale "Cash treatment*male"
			atreatequipmale "In-kind treatment*male"
			   _cons "Constant")
		/*refcat(1.risk_more " \multicolumn{4}{l}{\textbf{Panel A: Blame Variable: Higher Covid Risk}} \\ \hline ", nolabel) */
		stats(N , 
			labels("Obs.")	
			fmt("%12.0f")) 
		booktabs
		nonotes
		noobs	
		/*nonum*/
		replace ;

# delimit cr

	
********************************************************************************
**# Table 3: Main treatment effects + test statistics
********************************************************************************

/*
4.	Reproduce the coefficient and standard error estimates from columns 1-6 of Table 3 in the paper, add the test statistics at the bottom of the table, and export the results to a well-formatted table in LaTeX.
*/


// Column 1: OLS with strata dummies and clustering
reghdfe realfinalprofit atreatcash atreatequip wave2-wave6 , abs(groupnum) cluster(sheno)

	// Store estimates
	estimates store col1
	count if e(sample)==1
	estadd local obs = r(N)

	// Hypothesis test
	test atreatcash=atreatequip
	estadd scalar pval = r(p)


// Column 2: OLS with strata dummies and clustering and trimming
tab trimgroup
reghdfe realfinalprofit atreatcash atreatequip wave2-wave6 if trimgroup!=1, abs(groupnum) cluster(sheno) 

	// Store estimates
	estimates store col2
	count if e(sample)==1
	estadd local obs = r(N)

	// Hypothesis test
	test atreatcash=atreatequip
	estadd scalar pval = r(p)


// Column 3: Fixed effects with all rounds
xtset sheno wave
xtreg realfinalprof atreatcash atreatequip wave2-wave6, fe cluster(sheno)

reghdfe realfinalprof atreatcash atreatequip wave2-wave6, abs(sheno) cluster(sheno)

	// Store estimates
	estimates store col3
	count if e(sample)==1
	estadd local obs = r(N)

	// Hypothesis test
	test atreatcash=atreatequip
	estadd scalar pval = r(p)


// Column 4: Fixed effects with all rounds and trimming
xtreg realfinalprof atreatcash atreatequip wave2-wave6 if trimgroup!=1, fe cluster(sheno)

	// Store estimates
	estimates store col4
	count if e(sample)==1
	estadd local obs = r(N)

	// Hypothesis test
	test atreatcash=atreatequip
	estadd scalar pval = r(p)


// Column 5: Divide by gender
reghdfe realfinalprof atreatcashfemale atreatequipfemale atreatcashmale atreatequipmale wave2-wave6 wave2_female-wave6_female, abs(groupnum) cluster(sheno)


	// Store estimates
	estimates store col5
	count if e(sample)==1
	estadd local obs = r(N)

	// Hypothesis test
	test atreatcashfemale=atreatequipfemale
	estadd scalar pval_1 = r(p)

	test atreatcashmale=atreatequipmale
	estadd scalar pval_2 = r(p)

	test atreatcashmale=atreatcashfemale
	estadd scalar pval_3 = r(p)

	test atreatequipmale=atreatequipfemale	
	estadd scalar pval_4 = r(p)


// Column 6: 
reghdfe realfinalprof atreatcashfemale atreatequipfemale atreatcashmale atreatequipmale wave2-wave6 wave2_female-wave6_female if trimgroup!=1, abs(groupnum) cluster(sheno)

	// Store estimates
	estimates store col6
	count if e(sample)==1
	estadd local obs = r(N)

	// Hypothesis test
	test atreatcashfemale=atreatequipfemale
	estadd scalar pval_1 = r(p)

	test atreatcashmale=atreatequipmale
	estadd scalar pval_2 = r(p)

	test atreatcashmale=atreatcashfemale
	estadd scalar pval_3 = r(p)

	test atreatequipmale=atreatequipfemale	
	estadd scalar pval_4 = r(p)


// Create Table
# delimit ;

local file Table_3_version2 ;

esttab 	col1 col2 col3 col4 col5 col6
		using "${main}/Output/`file'",   						
		keep(atreatcash atreatequip 
			atreatcashfemale atreatequipfemale 
			atreatcashmale atreatequipmale _cons)
		order(atreatcash atreatequip 
			atreatcashfemale atreatequipfemale 
			atreatcashmale atreatequipmale _cons)
		b(%12.2f)		  	
		se(%12.2f)	
		starlevels(* .10 ** .05 *** .01)
		mtitles("OLS" "OLS" 
				"FE" "FE"
				"OLS" "OLS")
		/*nomtitles
		mgroups("Trusts Group A Less Than B", 
			pattern(1 0 0 0)                  
			prefix(\multicolumn{@span}{c}{) suffix(})   
			span erepeat(\cmidrule(lr){@span}))         
			alignment(D{.}{.}{-1}) // nonumber //page(dcolumn)	*/	
		varlab(atreatcash "Cash treatment"
			atreatequip "In-kind treatment"
			atreatcashfemale "Cash treatment*female"
			atreatequipfemale "In-kind treatment*female"
			atreatcashmale "Cash treatment*male"
			atreatequipmale "In-kind treatment*male"
			   _cons "Constant")
		/*refcat(1.risk_more " \multicolumn{4}{l}{\textbf{Panel A: Blame Variable: Higher Covid Risk}} \\ \hline ", nolabel) */
		stats(obs pval
			pval_1 pval_2 pval_3 pval_4, 
			labels("Obs." 
			"P.val Cash=In-kind"
			"P.val Cash=In-kind for females"
			"P.val Cash=In-kind for males"
			"P.val Cash male=cash Female"
			"P.val  In-kind male=in-kind female")	
			fmt("%12.0f" "%12.3f" "%12.3f" "%12.3f" "%12.3f" "%12.3f")) 
		booktabs
		nonotes
		noobs	
		/*nonum*/
		replace ;

# delimit cr




* ------------------------------------------------------------------------------
* MAIN DOFILE
* Sesión: RDD
* Name: Rony Rodrigo Maximiliano
*
* 1. Paths
* 2. Global Settings for style
* 3. Programs
* 
* ------------------------------------------------------------------------------ 

* ------------------------------------------------------------------------------ 
* 0. Sets
* ------------------------------------------------------------------------------ 
  clear all
  version 18
  capture log close _all
 
* ------------------------------------------------------------------------------ 
* 1. Paths
* ------------------------------------------------------------------------------ 

* Rony
  if (inlist("`c(username)'", "ifyou","maximiliano", "wb559559") & "`c(hostname)'" == "RRMax") {
  	global main  "C:/Users/ifyou/Documents/GitHub/econ-thaki-talleres"
  }
  
* Other User
  else if ("${main}" == "") {
    display "Ingrese la carpeta principal de su proyecto apuntando a /root/ y use barras diagonales" _request(main)
  }
  
* Build folders if they do not exists (for rep purporses)  
  local folders = "data dofiles outputs"
  foreach f in `folders' {
    mata : st_numscalar("OK", direxists("${main}/`f'"))
    if scalar(OK)==1 {
      display "All good!"
    }
    else if scalar(OK)==0 {
      display "Making folder: `f'"
      mkdir "${main}/`f'"
      mkdir "${main}/`f'/RDD"
      
      if "`f'" == "outputs" {
        mkdir "${main}/`f'/RDD/tabs"
        mkdir "${main}/`f'/RDD/figs"
      }
    }
  }

* Continue with the folders
  global data       "${main}/data"
  global code       "${main}/code"
  global outputs    "${main}/outputs"
  
* ------------------------------------------------------------------------------ 
* 2. Global settings
* ------------------------------------------------------------------------------ 
  global style  "label nolines fragment nomtitle nonumbers noobs nodep collabels(none) booktabs b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)" 
  global style2 "label nolines nogaps fragment nomtitle nonumbers nodep collabels(none) booktabs b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)"
  global style3	"label nolines nogaps fragment nomtitle nonumbers nodep collabels(none) booktabs b(3) star(* 0.10 ** 0.05 *** 0.01)" 
  global style4 "label nolines nogaps fragment nomtitle nonumbers nodep collabels(none) booktabs b(4) se(4)"
  global stylet "label nolines fragment nomtitle nonumbers noobs nodep collabels(none) booktabs b(3) t(5) star(* 0.10 ** 0.05 *** 0.01)" 
  global stylel "label fragment nomtitle nonumbers noobs nodep collabels(none) booktabs b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)" 

* ------------------------------------------------------------------------------     
* 3. Programs
* ------------------------------------------------------------------------------ 
  
* Switch to install programs    
  local install = 0  
  
  
  local programs = "reghdfe estout coefplot schemepack"
  if (`install'==1) { 
    foreach p in `programs' {
      ssc install `p'
    }
  }
  
* ------------------------------------------------------------------------------ 
* Exercises
* ------------------------------------------------------------------------------
  use "${data}/ozier_jhr_rep_data_v1_1.dta", clear 
    
  * ----------------------------------------------------------------------------
  // Exercise 1
  * ----------------------------------------------------------------------------
  local absvalue = 0.8
 
  // Panel A
  estpost sum age_at_klps2_approximate female fathers_education mothers_education         ///
    if has_score_2016 == 1
    
  esttab using                    ///
    "${outputs}/RDD/tabs/ex1.tex",   ///
    replace  ${style}             ///
    cells("mean(fmt(%9.2fc)) sd(par fmt(%9.2fc)) count(fmt(%9.0gc))")     ///
    prehead(`"\begin{tabular}{@{}l*{3}{r}}"'                          ///
          `"\toprule \toprule"'                                       ///
          `"                 &      & Standard  & Sample \\"'         ///
          `" Characteristic  & Mean & Deviation & Size   \\"'         ///       
          `"  & (1)  & (2) & (3) \\ "'                                /// 
          `"\toprule"'                                                ///
          `"\multicolumn{4}{@{}l}{\textbf{Panel A: Respondent Characteristics among Those with KCPE Scores}} \\"')                                 

  // Panel B
  estpost sum kcpe_self_or_matched_recent max_grade_complete attending_school_klps2       ///
    anysecondary finishsecondary postsecondary if has_score_2016==1
  esttab using                    ///
    "${outputs}/RDD/tabs/ex1.tex",   ///
    append  ${style}              ///
    cells("mean(fmt(%9.2fc)) sd(par fmt(%9.2fc)) count(fmt(%9.0gc))")     ///
    prehead(`"\multicolumn{4}{@{}l}{\textbf{Panel B: First Stage: Education Characteristics}} \\"') ///

  // Panel C
  estpost sum vocabulary_standardized ravens_standardized ravens_plus_vocab_standardized  ///
    if has_score_2016==1 & abs(rkcpe)<`absvalue'
  esttab using                    ///
    "${outputs}/RDD/tabs/ex1.tex",   ///
    append  ${style}              ///
    cells("mean(fmt(%9.2fc)) sd(par fmt(%9.2fc)) count(fmt(%9.0gc))")     ///
    prehead(`"\multicolumn{4}{@{}l}{\textbf{Panel C: Cognitive Outcomes within 80-Point Bandwidth}} \\"') ///    
    
  // Panel D  
  estpost sum age_at_klps2_approximate attending_school_klps2 employed self_employed      ///
    if has_score_2016==1 & abs(rkcpe)<`absvalue' & female==0 & psdp_std98 > 5
  esttab using                    ///
    "${outputs}/RDD/tabs/ex1.tex",   ///
    append  ${style}              ///
    cells("mean(fmt(%9.2fc)) sd(par fmt(%9.2fc)) count(fmt(%9.0gc))")     ///
    prehead(`"\multicolumn{4}{@{}l}{\textbf{Panel D: Labor Market Outcomes for Older Men within 80-Point Bandwidth}} \\"') ///    
    
  // Panel E    
  estpost sum age_at_klps2_approximate pregnant_by_18                                     ///
    if (has_score_2016==1 & female==1 & age_at_klps2_approximate >= 18 & abs(rkcpe) < `absvalue')
  esttab using                    ///
    "${outputs}/RDD/tabs/ex1.tex",   ///
    append  ${style}              ///
    cells("mean(fmt(%9.2fc)) sd(par fmt(%9.2fc)) count(fmt(%9.0gc))")     ///
    prehead(`"\multicolumn{4}{@{}l}{\textbf{Panel E: Fertility within 80-Point Bandwidths}} \\"') ///
    postfoot(`"\bottomrule \bottomrule \end{tabular}"')             
    
  * ----------------------------------------------------------------------------
  // Exercise 2
  * ----------------------------------------------------------------------------    
  local absvalue = 0.8
  local outcome "finishsecondary"

  // Mejorando los labels
	lab var passrkcpe       "KCPE $\geq$ cutoff"
	lab var rkcpe           "KCPE centered at cutoff"
	lab var int_pass_rkcpe  "(KCPE $\geq$ cutoff) $\times$ KCPE"

  
  eststo clear
  eststo est1: reg `outcome' passrkcpe rkcpe int_pass_rkcpe if abs(rkcpe)<`absvalue', vce(cluster rkcpe)
  estadd local controls No
  test passrkcpe=0
  estadd scalar fstat = `r(F)'

  eststo est2: reg `outcome' passrkcpe rkcpe int_pass_rkcpe if abs(rkcpe)<`absvalue' & female==0, vce(cluster rkcpe)
  estadd local controls No
  test passrkcpe=0
  estadd scalar fstat = `r(F)'
  
  eststo este: reg `outcome' passrkcpe rkcpe int_pass_rkcpe if abs(rkcpe)<`absvalue' & female==1, vce(cluster rkcpe)
  estadd local controls No
  test passrkcpe=0
  estadd scalar fstat = `r(F)'
  
  esttab est* using "${outputs}/RDD/tabs/ex2.tex", replace ${style}  ///
    prehead(`"\begin{tabular}{@{}l*{3}{c}}"'     ///
          `"\toprule \toprule"'                  ///
          `"  &  Pooled & Male & Female \\"'     ///       
          `"  & (1)  & (2) & (3) \\ "'           /// 
          `"\toprule"')                          ///
    postfoot(`"\bottomrule \bottomrule \end{tabular}"')         ///
    stats(controls fstat N r2, ///
      label("Controls" "Discontinuity \(F\)-statistic" "Observations" "\(R^2\)" ) ///
      fmt(%9.4f %9.2f %9.0gc %9.2f))    
    
  * ----------------------------------------------------------------------------
  // Exercise 3
  * ----------------------------------------------------------------------------   
  // First, let's round the score to get better collapse
  gen roundedrkcpe   = round(rkcpe-0.0499999,0.1) // To round up (following Owen's description)
  gen roundedrkcpeP5 = roundedrkcpe+0.05          // This create a more evenly spaced values
   
  // Getting the mean scores per bin (I could collapse here as well)
  bys roundedrkcpe: egen binmeanoutcome = mean(ravens_plus_vocab_standardized)
  label var binmeanoutcome "10-point bins"

  // Main regression
  reg ravens_plus_vocab_standardized passrkcpe rkcpe int_pass_rkcpe ///
    if abs(rkcpe) < 0.8 , vce(cluster rkcpe)
    
  local coef  = _b[passrkcpe]
  local se 	  = _se[passrkcpe]
  mat A       = r(table)
  local ll 	  = A[5,1]
  local ul 	  = A[6,1]
  
  predict lfit, xb
  label var lfit "Piecewise linear prediction"
  
  // To get the CI, I use each point from 150 to 350, and estimate the CIs
  gen cil = .
  gen cih  =.

  // Left Side
  forvalues i=150(1)249 {
    lincom _cons+((`i'-250)/100)*rkcpe
    replace cih = r(estimate)+invttail(r(df),0.025)*r(se) if round(rkcpe-(`i'-250)/100,0.0001)==0
    replace cil = r(estimate)-invttail(r(df),0.025)*r(se) if round(rkcpe-(`i'-250)/100,0.0001)==0
  }
  
  // Right side
  forvalues i = 250(1)350 {
    lincom _cons+((`i'-250)/100)*rkcpe+((`i'-250)/100)*int_pass_rkcpe+passrkcpe
    replace cih = r(estimate)+invttail(r(df),0.025)*r(se) if round(rkcpe-(`i'-250)/100,0.0001)==0
    replace cil = r(estimate)-invttail(r(df),0.025)*r(se) if round(rkcpe-(`i'-250)/100,0.0001)==0
  }

  // Graph
  twoway ///
    /// Area
    (rarea cil cih rkcpe if rkcpe <  -0.0099 & abs(rkcpe) < 0.8, lw(none) color(gs8))  ///
    (rarea cil cih rkcpe if rkcpe >= -0.0001 & abs(rkcpe) < 0.8, lw(none) color(gs8))  ///
    /// Lines
    (line lfit rkcpe if rkcpe < 0  & abs(rkcpe) < 0.8, lc(black))               ///
    (line lfit rkcpe if rkcpe >= 0 & rkcpe<=1.5 & abs(rkcpe) < 0.8, lc(black))  ///  
    (scatter binmeanoutcome roundedrkcpeP5 if abs(rkcpe) < 0.8, msym(Oh) mc(black) msize(2)), ///
    xline(0) scheme(s1mono) xlabel(-1(0.25)1)                                   ///
    xtitle("KCPE score (normalized so that Cutoff = 0)")                        ///
    ytitle("Combined Cognitive Score")                                          ///
    subtitle("Coef: `=round(`coef',.001)' (`=round(`ll',.001)',`=round(`ul',.001)'), se: `=round(`se', .001)')", position(11)) ///
    legend(rows(1) order(3 1 5) label(1 "95% CI") size(small)) 

	graph export "${outputs}/RDD/figs/rdd1.png", as(png) replace	
	           
  // Using RDplot
  rdrobust ravens_plus_vocab_standardized rkcpe if abs(rkcpe)<0.8 & inrange(rkcpe,-1,1), ///
    c(0) p(1) kernel(uniform) h(0.8) vce(cluster rkcpe) b(10)  
  
	rdplot ravens_plus_vocab_standardized rkcpe if ///
    inrange(rkcpe,-1,1), c(0) p(1) kernel(uniform) h(.8) vce(cluster rkcpe)     ///
    binselect(es) b(10)                                                         ///
    graph_options(ytitle("Combined cognitive score")                            ///
    xtitle("KCPE score (normalized so that Cutoff = 0)")                        ///
    xlabel(-1(0.25)1) ylabel(-.5(.5)1, angle(horizontal))                       ///
    subtitle("Coef: `=round(`e(tau_cl)',.001)' (`=round(`e(ci_l_cl)',.001)',`=round(`e(ci_r_cl)',.001)'), se: `=round(`e(se_tau_cl)', .001)')", position(11)) ///
    legend(position(6)) scheme(s1mono)) ci(95) shade 
 
	graph export "${outputs}/RDD/figs/rdd2.png", as(png) replace	
	   
* ------------------------------------------------------------------------------ 
* End
* ------------------------------------------------------------------------------

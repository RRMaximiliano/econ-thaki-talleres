* ------------------------------------------------------------------------------
* MAIN DOFILE
* Sesión: DID
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
      mkdir "${main}/`f'/DID"
      
      if "`f'" == "outputs" {
        mkdir "${main}/`f'/DID/tabs"
        mkdir "${main}/`f'/DID/figs"
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
  use "${data}/stevenson_wolfers_210.dta", clear 
    
  * ----------------------------------------------------------------------------
  // Exercise 1
  * ----------------------------------------------------------------------------
  // 2x2 difference in differences
  gen ln_suiciderate_jag = log(suiciderate_jag)
  label var ln_suiciderate_jag "Log Computed as suicide/stpop*gendershare"
  label var unilateral "Unilateral Law Enacted"
  
  // Using only states that passed law in 1973 vs no
  gen insample = .
  replace insample = 1 if divyear == 1973 // Passed the law in 1973
  replace insample = 1 if divyear == 2000 // Never passed the law
  
  
  encode st, gen(state)
  eststo clear
  eststo est1: reghdfe ln_suiciderate_jag unilateral if insample == 1, abs(state year) vce(cluster state)
  estadd local se_fe "Yes"
  estadd local ye_fe "Yes"
  eststo est2: reghdfe ln_suiciderate_jag unilateral if insample == 1 & sex == 1, abs(state year) vce(cluster state)
  estadd local se_fe "Yes"
  estadd local ye_fe "Yes"  
  eststo est3: reghdfe ln_suiciderate_jag unilateral if insample == 1 & sex == 2, abs(state year) vce(cluster state)
  estadd local se_fe "Yes"
  estadd local ye_fe "Yes"  
  
  esttab est* using "${outputs}/DID/tabs/ex1.tex", replace ${style2}  ///
    prehead(`"\begin{tabular}{@{}l*{3}{c}}"'    ///
          `"\toprule \toprule"'                 ///
          `"  & All & Males & Females \\"'      ///       
          `"  & (1) & (2)   & (3)     \\ "'     /// 
          `"\toprule"')                         ///
    postfoot(`"\bottomrule \bottomrule \end{tabular}"')         ///
    stats(se_fe ye_fe N r2, ///
      label("State FEs" "Year FEs" "Observations" "\(R^2\)" ) ///
      fmt(%9.3f %9.3f %9.0gc %9.3f))    
  
  
  // Instead of the TWFE
  gen post  = (year >= 1973)
  gen treat = (divyear == 1973)
  
  label var post "Post"
  label var treat "Treatment"
  
  label define post 1"Post"
  labe values post post
  label define treat 1"Treatment"
  label values treat treat
  
  eststo clear 
  eststo est1: reg ln_suiciderate_jag i.post##i.treat if insample == 1, vce(cluster state)
  eststo est2: reg ln_suiciderate_jag i.post##i.treat if insample == 1 & sex == 1, vce(cluster state) 
  eststo est3: reg ln_suiciderate_jag i.post##i.treat if insample == 1 & sex == 2, vce(cluster state)  
  
  esttab est* using "${outputs}/DID/tabs/ex1b.tex", replace ${style2}  ///
    keep(1.post 1.treat 1.post#1.treat _cons)   ///
    prehead(`"\begin{tabular}{@{}l*{3}{c}}"'    ///
          `"\toprule \toprule"'                 ///
          `"  & All & Males & Females \\"'      ///       
          `"  & (1) & (2)   & (3)     \\ "'     /// 
          `"\toprule"')                         ///
    postfoot(`"\bottomrule \bottomrule \end{tabular}"')         ///
    stats(N r2, ///
      label("Observations" "\(R^2\)" ) ///
      fmt(%9.0gc %9.3f))    
    
  
  
  * ----------------------------------------------------------------------------
  // Exercise 2
  * ----------------------------------------------------------------------------  
  // Gen relevant vars
  gen tvars = (year - divyear)
  recode tvars (. = -1) (-1000/-6 = -6) (12/1000 = 12)
  char tvars[omit] -1 
  xi i.tvars, pref(_T)
  
  labvarch _T*, after(==) 
  labvarch _T*, pref("Years relative to reform: ")
    
  * Get vanilla DID estimates
  reghdfe ln_suiciderate_jag unilateral if sex == 2, abs(state year) vce(cluster state) 
  local fmtDD1: display %9.3f _b[unilateral]
  local fmtDD2: display %9.3f _b[unilateral] + 0.01
  local fmtSE1: display %9.3f _se[unilateral]

  eststo clear 
  eststo est1: reghdfe ln_suiciderate_jag _T*, abs(state year) vce(cluster state) nocons
  eststo est2: reghdfe ln_suiciderate_jag _T* if sex == 1, abs(state year) vce(cluster state) nocons  
  eststo est3: reghdfe ln_suiciderate_jag _T* if sex == 2, abs(state year) vce(cluster state) nocons  
  
  esttab est* using "${outputs}/DID/tabs/ex2.tex", replace ${style2}  ///
    prehead(`"\begin{tabular}{@{}l*{3}{c}}"'    ///
          `"\toprule \toprule"'                 ///
          `"  & All & Males & Females \\"'      ///       
          `"  & (1) & (2)   & (3)     \\ "'     /// 
          `"\toprule"')                         ///
    postfoot(`"\bottomrule \bottomrule \end{tabular}"')         ///
    stats(N r2, ///
      label("Observations" "\(R^2\)" ) ///
      fmt(%9.0gc %9.3f))       
  
  
  tempfile temp 
  save `temp'
  
  regsave using "${outputs}/DID/tabs/results", replace ci tstat pval 
  use "${outputs}/tabs/results", clear 
  
  encode var, gen(dvar)
  gen n = real(regexs(1)) if regexm(var,"([0-9]+)")
  replace n = n - 7
  insobs 1
  drop if var == "_cons"
  replace n = -1    if missing(n)
  replace coef = 0  if missing(coef)

  sort n 
  scatter coef ci* n, c(l l l) cmissing(y n n) msym(i i i) lcolor(gray gray gray)                               ///
    lpattern(solid dash dash) lwidth(thick medthick medthick) yline(0, lcolor(black)) xline(-1, lcolor(black) ) ///
    subtitle("Log suicides rate for women", size(small) j(left) pos(11)) ylabel( , nogrid angle(horizontal) labsize(small) ) ///
    xtitle("Years Relative to Divorce Reform", size(small)) xlabel(-5(5)10, labsize(small) )                    ///
    legend(off) graphregion(color(white)) ///
    yline(`fmtDD1', lcolor(red) lwidth(thick)) text(`fmtDD2' 2.6 "DD Coefficient = `fmtDD1' (s.e. = `fmtSE1')")
    
	graph export "${outputs}/DID/figs/event_study.png", as(png) replace	
  
    
  * ----------------------------------------------------------------------------
  // Exercise 3
  * ----------------------------------------------------------------------------      
  * Go back to dataset
  use `temp', clear 
    
  eststo clear
  eststo est1: reghdfe ln_suiciderate_jag unilateral, abs(state) vce(cluster state) nocons
  estadd local se_fe "Yes"
  estadd local ye_fe "No"
  eststo est2: reghdfe ln_suiciderate_jag unilateral, abs(year) vce(cluster state) nocons
  estadd local se_fe "No"
  estadd local ye_fe "Yes"
  eststo est3: reghdfe ln_suiciderate_jag unilateral, abs(state year) vce(cluster state) nocons
  estadd local se_fe "Yes"
  estadd local ye_fe "Yes"  
  eststo est4: reghdfe ln_suiciderate_jag unilateral if sex == 1, abs(state) vce(cluster state) nocons
  estadd local se_fe "Yes"
  estadd local ye_fe "No"
  eststo est5: reghdfe ln_suiciderate_jag unilateral if sex == 1, abs(year) vce(cluster state) nocons
  estadd local se_fe "No"
  estadd local ye_fe "Yes"
  eststo est6: reghdfe ln_suiciderate_jag unilateral if sex == 1, abs(state year) vce(cluster state) nocons
  estadd local se_fe "Yes"
  estadd local ye_fe "Yes"    
  eststo est7: reghdfe ln_suiciderate_jag unilateral if sex == 2, abs(state) vce(cluster state) nocons
  estadd local se_fe "Yes"
  estadd local ye_fe "No"
  eststo est8: reghdfe ln_suiciderate_jag unilateral if sex == 2, abs(year) vce(cluster state) nocons
  estadd local se_fe "No"
  estadd local ye_fe "Yes"
  eststo est9: reghdfe ln_suiciderate_jag unilateral if sex == 2, abs(state year) vce(cluster state) nocons
  estadd local se_fe "Yes"
  estadd local ye_fe "Yes"    
  
  esttab est* using "${outputs}/DID/tabs/ex3.tex", replace ${style2}  ///
    prehead(`"\begin{tabular}{@{}l*{9}{c}}"'    ///
          `"\toprule \toprule"'                 ///
          `"  & \multicolumn{3}{c}{All} & \multicolumn{3}{c}{Males} & \multicolumn{3}{c}{Females} \\"'      ///       
          `"  & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9)    \\ "'     /// 
          `"\toprule"')                         ///
    postfoot(`"\bottomrule \bottomrule \end{tabular}"')         ///
    stats(se_fe ye_fe N r2, ///
      label("State FEs" "Year FEs" "Observations" "\(R^2\)" ) ///
      fmt(%9.3f %9.3f %9.0gc %9.3f))  
      
    
* ------------------------------------------------------------------------------ 
* End
* ------------------------------------------------------------------------------

  
  
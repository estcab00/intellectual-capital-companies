clear all
set more off
global dir "D:\Users\u_sociales\Documents\Esteban\Intelectual"
global data "$dir/data"

/*** 1. Import the file and prepare the data ***/ 
import excel "$data/data.xlsx", firstrow

egen empresa_id = group(Nombre)

duplicates tag empresa_id Año, gen(dup)

tab dup

** Set data as panel data
xtset empresa_id Año

xtdescribe

/*** 2. Correlation matrix ***/ 
/* Create the correlation matrix */

pwcorr VAIC HCE SCE CCE RCE MTB SIZE DEBT, sig

/*** 3. Run the models and perform the Hausman test to decide which model to use ***/ 

*** 3.1 Estimate fixed effects models

* WG1
qui xtreg ROA VAIC SIZE DEBT, fe 
estimates store WG1A

* WG2
qui xtreg ROA HCE SCE CCE RCE SIZE DEBT, fe
estimates store WG2A

* WG3
qui xtreg MTB VAIC SIZE DEBT, fe 
estimates store WG3A

* WG4
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT, fe 
estimates store WG4A

* Regressions for QTOBIN, not running them
* R5  
qui xtreg QTOBIN VAIC SIZE DEBT, fe 
estimates store RE5A

* R6
qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT, fe
estimates store RE6A

*** 3.2 Estimate random effects models
* R1
qui xtreg ROA VAIC SIZE DEBT, re
estimates store RE1A

* R2
qui xtreg ROA HCE SCE CCE RCE SIZE DEBT, re
estimates store RE2A

* R3
qui xtreg MTB VAIC SIZE DEBT, re
estimates store RE3A

* R4
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT, re
estimates store RE4A

* R5  
qui xtreg QTOBIN VAIC SIZE DEBT, re 
estimates store RE5A

* R6
qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT, re
estimates store RE6A

*** 3.3 Perform the Hausman test to decide whether to use fixed or random effects models

hausman WG1A RE1A  
*Fail to reject H0: p>0.05
*Choose Random Effects

hausman WG2A RE2A
*Fail to reject H0: p>0.05
*Choose Random Effects

hausman WG3A RE3A
*Reject H0: p<0.05
*Choose Fixed Effects

hausman WG4A RE4A
*Reject H0: p<0.05
*Choose Fixed Effects

/*** 5. We test for autocorrelation using Wooldridge's test to choose between using xtreg or xtregar ***/ 

*ssc install xtserial
* Manually install xtserial

xtserial ROA VAIC SIZE DEBT, output
* Reject H0: p<0.05
* We use xtregar

xtserial ROA HCE SCE CCE RCE SIZE DEBT, output
* Reject H0: p<0.05
* We use xtregar

xtserial MTB VAIC SIZE DEBT, output
* Do not reject H0: P>0.05
* We use xtreg

xtserial MTB HCE SCE CCE RCE SIZE DEBT, output 
* Do not reject H0: P>0.05
* We use xtreg

/*** 6. Run the chosen models ***/ 

*** 6.1 Final regressions. Add robust standard errors using vce(robust) when necessary

* Model 1
qui xtregar ROA VAIC SIZE DEBT, re 
estimates store RE1A

* Model 2
qui xtregar ROA HCE SCE CCE RCE SIZE DEBT, re
estimates store RE2A

* Model 3
qui xtreg MTB VAIC SIZE DEBT, fe vce(robust)
estimates store RE3A

* Model 4
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT, fe vce(robust)
estimates store RE4A

* Model 5
qui xtreg QTOBIN VAIC SIZE DEBT, fe vce(robust)
estimates store REG5

* Model 6
qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT, re vce(robust)
estimates store REG6

** 6.2 We compile all results into a table
estimates table RE1A RE2A RE3A RE4A REG5 REG6,  ///
  stats(N r2_o r2_b r2_w sigma_u sigma_e rho) b(%7.4f) star  

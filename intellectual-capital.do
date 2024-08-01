clear all
set more off
cd .

/*** 1. Importamos el archivo y lo adecuamos ***/ 
import excel "data.xlsx", firstrow

egen empresa_id = group(Nombre)

duplicates tag empresa_id Año, gen(dup)

tab dup

** Lo ponemos como data tipo panel
xtset empresa_id Año

xtdescribe

/*** 2. Matriz de correlación ***/ 
/* Elaboramos la matriz de correlación */

pwcorr VAIC HCE SCE CCE RCE MTB SIZE DEBT, sig

/*** 3. Corremos los modelos y realizamos el test de Hausman, para decidir cual modelo utilizar ***/ 

*** 3.1 Estimamos los modelos de efectos fijos

* WG1
qui xtreg ROA VAIC SIZE DEBT , fe 
estimates store WG1A

* WG2
qui xtreg ROA HCE SCE CCE RCE SIZE DEBT , fe
estimates store WG2A

* WG3
qui xtreg MTB VAIC SIZE DEBT , fe 
estimates store WG3A

* WG4
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT , fe 
estimates store WG4A

* Regresiones para QTOBIN, no las corremos
// * R5  
// qui xtreg QTOBIN VAIC SIZE DEBT , fe 
// estimates store RE5A
//
// * R6
// qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT , fe
// estimates store RE6A


*** 3.2 Estimamos los modelos de efectos aleatorios
* R1
qui xtreg ROA VAIC SIZE DEBT , re
estimates store RE1A

* R2
qui xtreg ROA HCE SCE CCE RCE SIZE DEBT , re
estimates store RE2A

* R3
qui xtreg MTB VAIC SIZE DEBT , re
estimates store RE3A

* R4
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT, re
estimates store RE4A

* Regresiones para QTOBIN, no las corremos
// * R5  
// qui xtreg QTOBIN VAIC SIZE DEBT , re 
// estimates store RE5A
//
// * R6
// qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT , re
// estimates store RE6A


*** 3.3 Realizamos el test de Hausman para decidir si utilizamos el modelo de efectos fijos o aleatorios

hausman WG1A  RE1A  
*No se rechaza H0: p>0.05
*Escogemos Random Effects
 
hausman WG2A  RE2A
*No se rechaza H0: p>0.05
*Escogemos Random Effects

hausman WG3A  RE3A
*Se rechaza H0: p<0.05
*Escogemos Fixed Effects

hausman WG4A  RE4A
*Se rechaza H0: p<0.05
*Escogemos Fixed Effects


/*** 5. Testeamos autocorrelación usando Wooldridge para elegir si correr usando xtreg o xtregar ***/ 

xtserial ROA VAIC SIZE DEBT, output
* Se rechaza HO: p<0.05
* Usamos xtregar

xtserial ROA HCE SCE CCE RCE SIZE DEBT, output
* Se rechaza HO: p<0.05
* Usamos xtregar

xtserial MTB VAIC SIZE DEBT, output
* No se rechaza HO: P>0.05
* Usamos xtreg

xtserial MTB HCE SCE CCE RCE SIZE DEBT, output 
* No se rechaza HO: P>0.05
* Usamos xtreg

/*** 4. Corremos los modelos escogidos. Modelo 1 y 2: efectos aleatorios; Modelo 3 y 4: efectos fijos  ***/ 

*** 4.1 Regresiones finales. Agregamos errores estándares robustos usando vce(robust)

* Modelo 1
qui xtregar ROA VAIC SIZE DEBT , re 
// xttest0
estimates store RE1A

* Modelo 2
qui xtregar ROA HCE SCE CCE RCE SIZE DEBT , re
estimates store RE2A

* Modelo 3
qui xtreg MTB VAIC SIZE DEBT , fe vce(robust)
xttest3
estimates store RE3A

* Modelo 4
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT, fe vce(robust)
xttest3
estimates store RE4A

* Regresiones para QTOBIN, no las corremos
// * R5
// qui xtreg QTOBIN VAIC SIZE DEBT , fe vce(robust)
// estimates store REG5
//
// * R6
// qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT , re vce(robust)
// xttest0
// estimates store REG6

** 4.2 Colocamos todos los resultados en una tabla
estimates table RE1A RE2A RE3A RE4A  ,  ///
  stats(N r2_o r2_b r2_w sigma_u sigma_e rho) b(%7.4f) star  

/* MODELOS DESCARTADOS PRESENTADOS ORIGINALMENTE  
*** 5. Comparación de algunos modelos para datos panel para la regresión
*** WITHIN GROUPS con cluster por empresa

* WG1
xtreg ROA VAIC SIZE DEBT , fe vce(cluster empresa_id)
estimates store WG1

* WG2
xtreg ROA HCE SCE CCE RCE SIZE DEBT , fe vce(cluster empresa_id)
estimates store WG2

* WG3
xtreg QTOBIN VAIC SIZE DEBT , fe vce(cluster empresa_id)
estimates store WG3

* WG4
xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT , fe vce(cluster empresa_id)
estimates store WG4

* WG5
xtreg MTB VAIC SIZE DEBT , fe vce(cluster empresa_id)
estimates store WG5

* WG6
xtreg MTB HCE SCE CCE RCE SIZE DEBT , fe vce(cluster empresa_id)
estimates store WG6

** Table
estimates table WG1 WG2 WG3 WG4 WG5 WG6 ,  ///
  stats(N r2 r2_o r2_b r2_w sigma_u sigma_e rho) b(%7.4f) star
 
 
*** WITHIN GROUPS con errores robustos

* WG1
qui xtreg ROA VAIC SIZE DEBT , fe vce(robust)
estimates store WG1A

* WG2
qui xtreg ROA HCE SCE CCE RCE SIZE DEBT , fe vce(robust)
estimates store WG2A

* WG3
qui xtreg QTOBIN VAIC SIZE DEBT , fe vce(robust)
estimates store WG3A

* WG4
qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT , fe vce(robust)
estimates store WG4A

* WG5
qui xtreg MTB VAIC SIZE DEBT , fe vce(robust)
estimates store WG5A

* WG6
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT , fe vce(robust)
estimates store WG6A

** Table
estimates table WG1A WG2A WG3A WG4A WG5A WG6A ,  ///
  stats(N r2 r2_a r2_o r2_b r2_w sigma_u sigma_e rho) b(%7.4f) star  

  
*** RANDOM EFFECTS con cluster por empresa

* R1
qui xtreg ROA VAIC SIZE DEBT , re vce(cluster empresa_id)
estimates store RE1

* R2
qui xtreg ROA HCE SCE CCE RCE SIZE DEBT , re vce(cluster empresa_id)
estimates store RE2

* R3
qui xtreg QTOBIN VAIC SIZE DEBT , re vce(cluster empresa_id)
estimates store RE3

* R4
qui xtreg QTOBIN HCE SCE CCE RCE SIZE DEBT , re vce(cluster empresa_id)
estimates store RE4

* R5
qui xtreg MTB VAIC SIZE DEBT , re vce(cluster empresa_id)
estimates store RE5

* R6
qui xtreg MTB HCE SCE CCE RCE SIZE DEBT , re vce(cluster empresa_id)
estimates store RE6

** Table
estimates table RE1 RE2 RE3 RE4 RE5 RE6 ,  ///
  stats(N r2_o r2_b r2_w sigma_u sigma_e rho) b(%7.4f) star
  
*** PRAIS REGRESSION en panel fixed effects

* R1
qui xtregar ROA VAIC SIZE DEBT , fe 
estimates store PRAIS1


* R2
qui xtregar ROA HCE SCE CCE RCE SIZE DEBT , fe
estimates store PRAIS2

* R3
qui xtregar QTOBIN VAIC SIZE DEBT , fe
estimates store PRAIS3

* R4
qui xtregar QTOBIN HCE SCE CCE RCE SIZE DEBT , fe
estimates store PRAIS4

* R5
qui xtregar MTB VAIC SIZE DEBT , fe
estimates store PRAIS5

* R6
qui xtregar MTB HCE SCE CCE RCE SIZE DEBT , fe
estimates store PRAIS6

** Table
estimates table PRAIS1 PRAIS2 PRAIS3 PRAIS4 PRAIS5 PRAIS6 ,  ///
  stats(N r2_a F r2_o r2_b r2_w sigma_u sigma_e) b(%7.4f) star
  
*** POOLED OLS con dummies por año

* OLS1
qui regress ROA VAIC SIZE DEBT i.Año
estimates store OLS1
vif

* OLS2
qui regress ROA HCE SCE CCE RCE SIZE DEBT i.Año
estimates store OLS2
vif

* OLS3

qui regress QTOBIN VAIC SIZE DEBT i.Año
estimates store OLS3
vif

* OLS4
qui regress QTOBIN HCE SCE CCE RCE SIZE DEBT i.Año
estimates store OLS4
vif

* OLS5
qui regress MTB VAIC SIZE DEBT i.Año
estimates store OLS5
vif

* OLS6
qui regress MTB HCE SCE CCE RCE SIZE DEBT i.Año
estimates store OLS6
vif

** Table
estimates table OLS1 OLS2 OLS3 OLS4 OLS5 OLS6 ,  ///
  stats(N r2 r2_a F) b(%7.4f) drop(i.Año) star
  

*** POOLED OLS con dummies por año y errores robustos

* OLS1
qui regress ROA VAIC SIZE DEBT i.Año, vce(robust)
estimates store OLS1A
predict residuals, residuals
xtset empresa_id Año
xtreg residuals L.residuals, fe
drop residuals


* OLS2
qui regress ROA HCE SCE CCE RCE SIZE DEBT i.Año, vce(robust)
estimates store OLS2A
predict residuals, residuals
xtset empresa_id Año
xtreg residuals L.residuals, fe
drop residuals


* OLS3
qui regress QTOBIN VAIC SIZE DEBT i.Año, vce(robust)
estimates store OLS3A
predict residuals, residuals
xtset empresa_id Año
xtreg residuals L.residuals, fe
drop residuals

* OLS4
qui regress QTOBIN HCE SCE CCE RCE SIZE DEBT i.Año, vce(robust)
estimates store OLS4A
predict residuals, residuals
xtset empresa_id Año
xtreg residuals L.residuals, fe
drop residuals

* OLS5
qui regress MTB VAIC SIZE DEBT i.Año, vce(robust)
estimates store OLS5A
predict residuals, residuals
xtset empresa_id Año
xtreg residuals L.residuals, fe
drop residuals

* OLS6
qui regress MTB HCE SCE CCE RCE SIZE DEBT i.Año, vce(robust)
estimates store OLS6A
predict residuals, residuals
xtset empresa_id Año
xtreg residuals L.residuals, fe
drop residuals

** Table
estimates table OLS1A OLS2A OLS3A OLS4A OLS5A OLS6A ,  ///
  stats(N r2 r2_a F) b(%7.4f) drop(i.Año) star

  
*** POOLED OLS con dummies por año y cluster id

* OLS1
qui regress ROA VAIC SIZE DEBT i.Año, vce(cluster empresa_id)
estimates store OLS1B


* OLS2
qui regress ROA HCE SCE CCE RCE SIZE DEBT i.Año, vce(cluster empresa_id)
estimates store OLS2B

* OLS3

qui regress QTOBIN VAIC SIZE DEBT i.Año, vce(cluster empresa_id)
estimates store OLS3B

* OLS4
qui regress QTOBIN HCE SCE CCE RCE SIZE DEBT i.Año, vce(cluster empresa_id)
estimates store OLS4B

* OLS5
qui regress MTB VAIC SIZE DEBT i.Año, vce(cluster empresa_id)
estimates store OLS5B

* OLS6
qui regress MTB HCE SCE CCE RCE SIZE DEBT i.Año, vce(cluster empresa_id)
estimates store OLS6B

** Table
estimates table OLS1B OLS2B OLS3B OLS4B OLS5B OLS6B ,  ///
  stats(N r2 r2_a F) b(%7.4f) drop(i.Año) star
  
  
*** POOLED OLS 

* OLS1
qui regress ROA VAIC SIZE DEBT 
vif
estimates store OLS1B


* OLS2
qui regress ROA HCE SCE CCE RCE SIZE DEBT
vif 
estimates store OLS2B

* OLS3

qui regress QTOBIN VAIC SIZE DEBT
vif 
estimates store OLS3B

* OLS4
qui regress QTOBIN HCE SCE CCE RCE SIZE DEBT
vif
estimates store OLS4B

* OLS5
qui regress MTB VAIC SIZE DEBT
vif 
estimates store OLS5B

* OLS6
qui regress MTB HCE SCE CCE RCE SIZE DEBT
vif
estimates store OLS6B

** Table
estimates table OLS1B OLS2B OLS3B OLS4B OLS5B OLS6B ,  ///
  stats(N r2 r2_a F) b(%7.4f) drop(i.Año) star
  


*** LSDV

* LSDV1
qui regress ROA VAIC SIZE DEBT i.empresa_id, vce(robust)
estimates store LSDV1

* LSDV2
qui regress ROA HCE SCE CCE RCE SIZE DEBT i.empresa_id, vce(robust)
estimates store LSDV2

* LSDV3
qui regress QTOBIN VAIC SIZE DEBT i.empresa_id, vce(robust)
estimates store LSDV3

* LSDV4
qui regress QTOBIN HCE SCE CCE RCE SIZE DEBT i.empresa_id, vce(robust)
estimates store LSDV4

* LSDV5
qui regress MTB VAIC SIZE DEBT i.empresa_id, vce(robust)
estimates store LSDV5

* LSDV6
qui regress MTB HCE SCE CCE RCE SIZE DEBT i.empresa_id, vce(robust)
estimates store LSDV6

estimates table LSDV1 LSDV2 LSDV3 LSDV4 LSDV5 LSDV6 ,  ///
  stats(N r2 r2_a F) b(%7.4f) drop(i.empresa_id) star
  
  
*** PRAIS WINSTEN con transformación CORCHRANE-ORCUTT REGRESSION FINAL
qui prais ROA VAIC SIZE DEBT i.Año, corc robust nocons
estimates store PRAIS1A
predict residuals, residuals
regress residuals VAIC SIZE DEBT i.Año
estat hettest
drop residuals


qui prais ROA HCE SCE CCE RCE SIZE DEBT i.Año, corc robust nocons
estimates store PRAIS2A
predict residuals, residuals
regress residuals VAIC SIZE DEBT i.Año
estat hettest
drop residuals

qui prais QTOBIN VAIC SIZE DEBT i.Año, corc robust nocons
estimates store PRAIS3A
predict residuals, residuals
regress residuals VAIC SIZE DEBT i.Año
estat hettest
drop residuals

prais QTOBIN HCE SCE CCE RCE SIZE DEBT i.Año, corc robust nocons
estimates store PRAIS4A
predict residuals, residuals
regress residuals VAIC SIZE DEBT i.Año
estat hettest
drop residuals


qui prais MTB VAIC SIZE DEBT i.Año, corc robust nocons
estimates store PRAIS5A
predict residuals, residuals
regress residuals VAIC SIZE DEBT i.Año
estat hettest
drop residuals


qui prais MTB HCE SCE CCE RCE SIZE DEBT i.Año, corc robust nocons
estimates store PRAIS6A
predict residuals, residuals
regress residuals VAIC SIZE DEBT i.Año
estat hettest
drop residuals

** table
estimates table PRAIS1A PRAIS2A PRAIS3A PRAIS4A PRAIS5A PRAIS6A ,  
  stats(N r2 r2_a F dw dw_0 rho) b(%7.4f) drop(i.Año) star
  
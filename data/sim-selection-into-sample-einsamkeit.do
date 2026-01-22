clear 
set seed 45792346

set obs 2000 

// Geschlecht
gen frau = 0 
replace frau = runiform()<=.5
label var frau "Geschlecht"
label def Lfrau 0 "Mann" 1 "Frau", modify 
label val frau Lfrau 

// Bildung
gen bild_rand = runiform()
gen bildung = . 
replace bildung = cond(bild_rand < 0.3, 1, cond(bild_rand < 0.6, 2, 3)) if frau == 0
replace bildung = cond(bild_rand < 0.2, 1, cond(bild_rand < 0.5, 2, 3)) if frau == 1

label var bildung "Bildung"
label def Lbildung 1 "Niedrig" 2 "Mittel" 3 "Hoch", modify 
label val bildung Lbildung 

tab bildung, gen(bildung_)


// Einsamkeit 
cap drop einsam
#delim ;

gen einsam = 
30 + 
(-10*frau) +
(-10*bildung_2) +
(10*bildung_2*frau) +
(-20*bildung_3) +
(25*bildung_3*frau) +
rweibull(1,2)*5;
#delim cr
replace einsam = einsam^2 if einsam < 0
qui sum einsam, det 
replace einsam = einsam - r(min)
label var einsam "Einsamkeit (latente Ausprägungen)" 

tabstat einsam, by(frau)
table frau bildung, stat(mean einsam) nototal nformat(%8.1f)


/** Histogramme **/ 

cd "C:\GIT\MethodenEmpSoz\slides\images"
hist einsam, ytitle("Dichte")
graph export sim-histo-einsam.png, replace 

tw 	kdensity einsam if frau == 0, lwi(thick) ///
|| 	kdensity einsam if frau == 1, lwi(thick) lpat(shortdash) ///
|| , ytitle("Dichte") xtitle("Einsamkeit (latente Ausprägungen)") ///
 legend(order(1 "Männer" 2 "Frauen") ring(0) pos(1)) ylab( , nogrid) xlab(, nogrid)
graph export sim-histo-einsam-geschlecht.png, replace 

/**** Tabellen ******/

tab frau bildung,  row nofreq 
table frau bildung, stat(mean einsam) nototal nformat(%8.1f)



// Selektion in die netto1probe ohne unbeobachteten Faktor
cap drop teil 
gen teil = -0.5 + 0.4*frau + 0.3*bildung_2 + 0.4*bildung_3 + rweibull(2,1)
sum teil
replace teil =  ((teil) - r(min))/( r(max) - r(min) )
label var teil "Wahrscheinlichkeit einer Teilnahme"

kdensity teil, xline(0.5) ylab( , nogrid) xlab(, nogrid) ///
ytitle("Dichte") xtitle("Wahrscheinlichkeit einer Teilnahme") ///
title(" ") note(" ") 
graph export sim-histo-teilnahme.png, replace 

tw 	kdensity teil if frau == 0, lwi(thick) ///
|| 	kdensity teil if frau == 1, lwi(thick) lpat(shortdash) ///
|| , xline(0.5) ytitle("Dichte") xtitle("Wahrscheinlichkeit einer Teilnahme") ///
 legend(order(1 "Männer" 2 "Frauen") ring(0) pos(1)) ylab( , nogrid) xlab(, nogrid)
graph export sim-histo-teilnahme-geschlecht.png, replace 


cap drop netto1
gen netto1 = teil >= 0.5
label var netto1 "Teil der Stichprobe"
label def Lnetto 0 "Nein" 1 "Ja", modify
label val netto1 Lnetto

tab frau bildung,  row nofreq 
tab frau bildung if netto1 == 1,  row nofreq 

catplot frau bildung, title("Bruttostichprobe") percent(frau) ytitle("Relativer Anteil") blabel(bar, format(%8.1f)) ylabel(, nogrid)
graph export sim-bar-geschlecht-bildung-brutto.png, replace 

catplot frau bildung if netto1 == 1, title("Nettostichprobe") percent(frau) ytitle("Relativer Anteil") blabel(bar, format(%8.1f)) ylabel(, nogrid)
graph export sim-bar-geschlecht-bildung-netto1.png, replace 

qui sum einsam if frau == 0
local m = r(mean)
qui sum einsam if frau == 1 
local w = r(mean)
graph hbar einsam, over(frau) over(bildung) blabel(bar, format(%8.1f)) ytitle("Einsamkeit") ylabel(, nogrid) ///
yline(`m', lpat(solid)) yline(`w') 
graph export sim-bar-einsamkeit-geschlecht-bildung-brutto.png, replace 

table frau bildung , stat(mean einsam) nototal nformat(%8.1f)
table frau bildung if netto1 ==1, stat(mean einsam) nototal nformat(%8.1f)

tw kdensity einsam if frau == 0, lcol(ebblue) lwi(thick) lpat(solid) ///
|| kdensity einsam if frau == 0 & netto1 == 1, lcol(ebblue) lwi(thick) lpat(shortdash) ///
|| , ytitle("Dichte") xtitle("Einsamkeit (latente Ausprägungen)") title("Männer") ///
 legend(order(1 "Brutto" 2 "Netto") ring(0) pos(1)) ylab( , nogrid) xlab(, nogrid)
 graph export sim-histo-einsam-man.png, replace 

tw kdensity einsam if frau == 1, lcol(orange) lwi(thick) lpat(solid) ///
|| kdensity einsam if frau == 1 & netto1 == 1, lcol(orange) lwi(thick) lpat(shortdash) ///
|| , ytitle("Dichte") xtitle("Einsamkeit (latente Ausprägungen)") title("Frauen") ///
 legend(order(1 "Brutto" 2 "Netto") ring(0) pos(1)) ylab( , nogrid) xlab(, nogrid)
 graph export sim-histo-einsam-frau.png, replace  


qui sum einsam if frau == 0 & netto == 1
local m = r(mean)
qui sum einsam if frau == 1 & netto == 1
local w = r(mean)
graph hbar einsam if netto1 == 1, over(frau) over(bildung) blabel(bar, format(%8.1f)) ytitle("Einsamkeit") ylabel(, nogrid) ///
yline(`m', lpat(solid)) yline(`w') 
graph export sim-bar-einsamkeit-geschlecht-bildung-netto1.png, replace 



/*Gewichtung*/

tab frau bildung,  row nofreq 
tab frau bildung if netto1 == 1,  row nofreq 

table frau bildung, stat(mean einsam) nototal nformat(%8.1f)
table frau bildung if netto == 1, stat(mean einsam) nototal nformat(%8.1f)


// Selektion in die netto1probe mit unbeobachteten Faktor

cap drop antifem
gen antifem = 10 - 7*frau - 2*bildung_2 - 5*bildung_3 + rweibull(1,3)
label var antifem "Antifeministische Einstellungen (latente Ausprägungen)"
qui sum antifem, det 
hist antifem
graph export sim-hist-antifem.png, replace 

graph bar antifem, over(frau) over(bildung) ytitle("Antifeministische Einstellungen")
graph export sim-bar-antifem-gender-bildung.png, replace 

gen einsam2 = einsam - 1*antifem 

cap drop netto2 
gen netto2 = netto1 
 sum antifem, det 
replace netto2 = 0 if (netto1 == 1 & antifem > r(p75)) 


qui sum einsam2 if frau == 0 & netto2 == 1
local m = r(mean)
qui sum einsam2 if frau == 1 & netto2 == 1
local w = r(mean)
graph hbar einsam2 if netto2 == 1, over(frau) over(bildung) blabel(bar, format(%8.1f)) ytitle("Einsamkeit") ylabel(, nogrid) ///
yline(`m', lpat(solid)) yline(`w') 
graph export sim-bar-einsamkeit2-geschlecht-bildung-netto2.png, replace 

catplot frau bildung if netto2 == 1, title("Nettostichprobe (+ Antifem. Selektion)") percent(frau) ytitle("Relativer Anteil") blabel(bar, format(%8.1f)) ylabel(, nogrid)
graph export sim-bar-geschlecht-bildung-netto2.png, replace 

table frau bildung, stat(mean einsam) nototal nformat(%8.1f)
table frau bildung if netto2 == 1, stat(mean einsam) nototal nformat(%8.1f) 
table frau bildung if netto2 == 1, stat(mean einsam) nototal nformat(%8.1f) 



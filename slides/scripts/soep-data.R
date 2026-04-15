

c orgsoep 
use pl, clear 

/* Verteilungen der gewünschten Arbeitsstunden */ 
clonevar gewh = plb0241_h
label var gewh "Gewünschte Arbeitsstunden"
replace gewh = . if gewh < 0 
replace gewh = . if gewh > 98

// Categoriale Variante
cap drop cgewh 
egen cgewh = cut(gewh), at(0 10 20 30 40 50 60)
label var cgewh "Gewünschte Arbeitsstunden"

label def Lgewh ///
0 "bis 10h" ///
10 "bis 20h" ///
20 "bis 30h" ///
30 "bis 40h" ///
40 "bis 50h" ///
50 "über 50h" ///
, modify 

label val cgewh Lgewh 

// Geschlecht
gen frau = 0 if  pla0009_v2 == 1
replace frau = 1 if  pla0009_v2 == 2 

// Berufliche Belastung durch Arbeitsstunden 
clonevar belasth = plb0123
label var belasth "Berufliche Belastung durch Arbeitsstunden"
replace belasth = . if belasth < 0

// Bargraph für 2018
catplot cgewh if syear == 2018, vertical percent blabel(bar, format(%4.1f)) ytitle("relativer Anteil") ylab(, nogrid)
c graph  
graph export lehre-gew-arbeitsstunden-cat.pdf, replace 

// Darstellung als diskrete Verteilung
histogram gewh if syear == 2018, col(black) discrete ytitle("relativer Anteil") ylab(, nogrid) xlab(0(5)85, nogrid)
c graph  
graph export lehre-gew-arbeitsstunden-dis.pdf, replace 

// Darstellung als stetige Verteilung
tw kdensity gewh if syear == 2018, col(orange) lpat(solid) lwi(thick) ///
|| kdensity gewh if syear == 2018, bw(2) col(black) lpat(solid) lwi(thick) ///
|| kdensity gewh if syear == 2018, bw(5) col(ebblue) lpat(solid) lwi(thick) ///
|| ,  ytitle("Dichte") xtitle("Gewünschte Arbeitsstunden") ylab(, nogrid) xlab(0(5)85, nogrid) note(" ") title(" ") ///
  legend(order(1 "Minimal Smoothing" 2 "Medium Smoothing" 3 "Strong Smoothing") row(3) pos(1) ring(0)) ///
  xsize(10) ysize(7)

c graph  
graph export lehre-gew-arbeitsstunden-kdens.pdf, replace 


/*** Unterschiedliche Verteilungen **/


tw kdensity gewh if syear == 2018 & frau == 1 & gewh < 70, bw(3) lcol(orange) lwi(thick) ///
|| kdensity gewh if syear == 2018 & frau == 0 & gewh < 70, bw(3) lcol(ebblue) lwi(thick) lpat(shortdash) ///
|| ,  ytitle("Dichte") xtitle("Gewünschte Arbeitsstunden") ylab(, nogrid) xlab(0(5)70, nogrid) xscale(range(0 70)) ///
    note(" ") title(" ") ///
  legend(order(1 "Frauen" 2 "Männer") row(2) pos(1) ring(0)) ///
  xsize(10) ysize(7)

c graph  
graph export lehre-gew-arbeitsstunden-kdens-gender.pdf, replace 




preserve 
collapse (mean) mgewh = gewh (median) medgewh = gewh (sd) sdgewh = gewh, by(syear frau)

tw scatter mgewh syear if frau == 0, mcol(ebblue) msym(D) ///
|| scatter mgewh syear if frau == 1, mcol(orange) msym(O) ///
|| scatter mgewh syear if frau == 0 & inlist(syear, 1985, 2003, 2018), msym(i) mlab(mgewh) mlabcol(black) mlabformat(%4.1f) mlabpos(6) ///
|| scatter mgewh syear if frau == 1 & inlist(syear, 1985, 2003, 2018), msym(i) mlab(mgewh) mlabcol(black) mlabformat(%4.1f) mlabpos(6) ///
|| lpoly  mgewh syear if frau == 0, lcol(ebblue) ///
|| lpoly  mgewh syear if frau == 1, lcol(orange) ///
|| , ylab(25(5)40, nogrid) yscale(range(25 40)) xlab(1985(5)2015 2018, nogrid) ///
  legend(order(1 "Männer" 2 "Frauen") row(2) pos(4) ring(0)) ///
  ytitle("Gewünschte Arbeitsstunden (arith. Mittel)")

c graph 
graph export lehre-gew-arbeitsstunden-mean-change-gender.pdf, replace 

tw scatter sdgewh syear if frau == 0, mcol(ebblue) msym(D) ///
|| scatter sdgewh syear if frau == 1, mcol(orange) msym(O) ///
|| scatter sdgewh syear if frau == 0 & inlist(syear, 1985, 2003, 2018), msym(i) mlab(sdgewh) mlabcol(black) mlabformat(%4.1f) mlabpos(6) ///
|| scatter sdgewh syear if frau == 1 & inlist(syear, 1985, 2003, 2018), msym(i) mlab(sdgewh) mlabcol(black) mlabformat(%4.1f) mlabpos(6) ///
|| lpoly  sdgewh syear if frau == 0, lcol(ebblue) ///
|| lpoly  sdgewh syear if frau == 1, lcol(orange) ///
|| , ylab(, nogrid) xlab(1985(5)2015 2018, nogrid) ///
  legend(order(1 "Männer" 2 "Frauen") row(2) pos(4) ring(0)) ///
  ytitle("Gewünschte Arbeitsstunden (Standardabweichung)")

c graph 
graph export lehre-gew-arbeitsstunden-mean-change-gender.pdf, replace 


restore 

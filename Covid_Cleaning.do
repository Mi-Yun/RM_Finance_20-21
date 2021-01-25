clear all 

import excel "Covid_Death_cases"

rename A date 
rename B state
rename Q weekly_death  
gen key=_n 
drop if key==1
drop  D E G I J L M N O P 
drop if state=="HI"
drop if date=="01/22/2020" 
drop if date=="01/23/2020"
drop if date=="01/24/2020"
drop if date=="01/25/2020" 
drop if date=="01/26/2020"
drop if date=="01/27/2020" 
rename F new_cases 
rename H tot_death 
rename K new_death 
drop R
destring new_cases, replace
destring tot_death, replace 
destring new_death, replace 
destring weekly_death, replace 
encode date, generate(de)
encode C, generate(tot_cases_1)
drop key C

gen int every_7=mod(_n, 7 )==0
keep if every_7==1

gen key=_n
gen week=0
sort key
egen week_ind=group(date)
egen we=group(de)
replace week=5 if week_ind==3
replace week=6 if week_ind==11
replace week=7 if week_ind==17 
replace week=8 if week_ind==18
replace week=9 if we==2

replace week=10 if week_ind==10
replace week=11 if week_ind==19
replace week=12 if week_ind==20 
replace week=13 if week_ind==21
replace week=14 if we==6

replace week=15 if week_ind==22
replace week=16 if week_ind==23
replace week=17 if week_ind==24 
replace week=18 if week_ind==5
replace week=19 if we==13

replace week=20 if week_ind==25
replace week=21 if week_ind==26
replace week=22 if week_ind==1 
replace week=23 if week_ind==9
replace week=24 if we==27

replace week=25 if week_ind==28
replace week=26 if week_ind==29
replace week=27 if week_ind==7 
replace week=28 if week_ind==30
replace week=29 if we==31

replace week=30 if week_ind==32
replace week=31 if week_ind==4
replace week=32 if week_ind==12 
replace week=33 if week_ind==33
replace week=34 if we==34

replace week=35 if week_ind==35
replace week=36 if week_ind==8
replace week=37 if week_ind==36 
replace week=38 if week_ind==37
replace week=39 if we==38

replace week=40 if week_ind==15
replace week=41 if week_ind==44
replace week=42 if week_ind==39 
replace week=43 if week_ind==40
replace week=44 if we==14

replace week=45 if week_ind==16
replace week=46 if week_ind==41
replace week=47 if week_ind==42 
replace week=48 if week_ind==43

drop week_ind we every_7





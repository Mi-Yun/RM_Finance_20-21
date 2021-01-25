***Mi Yun-Kuo Spophie Friebe 
**Research Moduel finance 2020/2021
***Impacts of Covid 19 
***Regression part 

**data already merged 
clear all 
**import data
use "US_Covid_Compstat_Stock_weekly_1_final.dta"

duplicates tag gvkey state week year, generate (duplicates)
**Check  for duplicates

duplicates drop gvkey week fyearq, force 

drop count_gvkey
egen count_gvkey=count(gvkey), by (gvkey)
tab count_gvkey
drop if count_gvkey==0
**some comapanies have gaps in observation data 
**drop them if there is data for less than 70 weeks 
drop if count_gvkey<=70


replace weekly_death=0 if fyearq==2019
destring gvkey, generate (gvkeyid)
**check how many companies are left
unique gvkeyid, generate(sum_companies)

**generate the panel variable for weeks!
gen time_variable=0
replace time_variable=week if fyearq==2019
replace time_variable=week+52 if fyearq==2020
**check for duplicates as xtset not working with duplicates 
duplicates drop gvkeyid time_variable, force  
**check for duplicates as xtset not working with duplicates 

**due to the original covid data there are 59 negative observations 
**since mistake in original data drop them  
drop if weekly_death<0 
**drop the canada values!!
**british Columbia
drop if state=="BC" 
**Ontario
drop if state=="ON" 
*Alberta
drop if state=="AB"
**Quebec
drop if state=="QC"
**Puerto rico
drop if state=="PR"
**Saskatchewan Canada
drop if state=="SK"

**drop Hawai since no Covid data available
drop if state=="HI" 
**drop Virgin Island 
drop if state=="VI"
drop if state=="US"

** compensate for missing values (no death) in week 1-5 of 2020
replace weekly_death=0 if week<=5  

**drop values from dataset that are not used for Covid 
drop new_death tot_death new_cases tot_cases_1 key US_every_7 tot_cases US_new_cases US_new_death US_weekly_death US_tot_cases_1

encode state, generate(state_number)
rename _merge _merge_old
**add the total population of a state
merge m:1 state using "Inhabitants_final_final.dta", force
**death per population, later used as robustness check 
gen death_fraction=(weekly_death/popu)*100

rename _merge _merge2
**Add Covid US Data
merge m:1 week using "Covid_US_final_final.dta", force
rename _merge _merge_US_final
**account for week 1-5 that have zero cases
replace US_weekly_death=0 if week<=5

**Add the weekly case data
merge m:1 state week using "Weekly_Cases_summed.dta", force
destring weekly_cases, generate(weekly_cases_long)
drop weekly_cases 
rename weekly_cases_long weekly_cases
replace weekly_cases=0 if week<=4
replace weekly_cases=0 if fyearq==2019

**Merge other Household data 
rename _merge _merge1_1
merge m:1 state using "HouseholdFeatureData.dta", force 
gen popden = popu/landarea_km
label var popden "population density per sqr-km"

**generate variable for leverage-used later 
gen debt_to_assets=dlttq/atq

**generate industry dummy after Standard Industry Classification main groups (SIC)- later used
gen sic_dummy=0
destring sic, replace 
replace sic_dummy=1 if sic>=1000 & sic<=1499
**mining
replace sic_dummy=2 if sic>=1500 & sic<=1799
**construction
replace sic_dummy=3 if sic>=2000 & sic<=3999
**manufacturing
replace sic_dummy=4 if sic>=4000 & sic<=4999
**Trasport, Communication, Electric
replace sic_dummy=5 if sic>=5000 & sic<=5199
**Wholesale Trade
replace sic_dummy=6 if sic>=5200 & sic<=5999
**Retail Trade
replace sic_dummy=7 if sic>=6000 & sic<=6799
**finance, Insurance and real estate
replace sic_dummy=8 if sic>=7000 & sic<=8999
**services
replace sic_dummy=9 if sic>=9100 &sic<=9729
**Public Administration- no observation
replace sic_dummy=10 if sic_dummy==0
**Agriculture, Foresty, Fishing


**add the data on share of population over 65- later used
generate age=0
replace age=20.5 if state=="FL"
replace age=20.6 if state=="ME"
replace age=19.9 if state=="WV"
replace age=19.4 if state=="VT"
replace age=18.7 if state=="DE"
replace age=18.7 if state=="MT"
replace age=18.2 if state=="PA"
replace age=18.1 if state=="NH"
replace age=17.7 if state=="SC" 
replace age=17.6 if state=="OR"
replace age=17.5 if state=="AZ" 
replace age=17.5 if state=="NM"
replace age=17.2 if state=="CT" | state=="MI" | state=="RI" 
replace age=17.1 if state=="IA" | state=="OH"
replace age=17 if state=="AR" | state=="WI"
replace age=16.9 if state=="AL" | state=="MO"
replace age=16.6 if state=="SD"
replace age=16.5 if state=="MA" |state=="WY"
replace age=16.4 if state=="KY" |state=="NY" |state=="TN"
replace age=16.3 if state=="NC" 
replace age=16.1 if state=="NJ"
replace age=15.9 if state=="ID" | state=="KS" | state=="MN" | state=="MS"
replace age=15.8 if state=="IN"
replace age=15.7 if state=="NE" | state=="NV" | state=="OK"
replace age=15.6 if state=="IL"
replace age=15.4 if state=="LA" | state=="MD"| state=="VA" | state=="WA"
replace age=15.3 if state=="ND"
replace age=14.3 if state=="CA" 
replace age=14.2 if state=="CO"
replace age=13.9 if state=="GA" 
replace age=12.6 if state=="TX" 
replace age=11.8 if state=="AK"
replace age=11.1 if state=="UT"

**replace 2019 values for stay home order with zero, since no stay home order was in place 
gen dummy_stay_home=0
replace dummy_stay_home=1 if state=="FL" |state=="CA" |state=="NY" |state=="IL" | state=="TX" |state=="NJ" |state=="MA" |state=="PA" |state=="CO" 
gen dummy_stay_home1=0
replace dummy_stay_home1=1 if dummy_stay_home==1 & fyearq==2019
replace stay_home_order=0 if dummy_stay_home1==1


**update stay home order collected with new values till week 50 (so far till week 44)
replace stay_home_order=1 if state=="CA" | state=="TX" | state=="IL" | state=="CO" | state=="NY" & week>44 
replace stay_home_order=2 if state=="CA" & week>=47 & week<=50
replace stay_home_order=2 if state=="NY" & week>=47 & week<=50
replace stay_home_order=2 if state=="CO" & week>=37 & week<=50
replace stay_home_order=2 if state=="IL" & week>=48 & week<=50
replace stay_home_order=2 if state=="TX" & week>=46 & week<=50

**generate the polit variables, that is the state representation in the Senate in the 117 US Congress
**0 is Democratic 
**1 is Republican 
**2 is one Rebublican and one Democratic Senator 

gen polit=0 
replace polit=1 if state=="TX" 
replace polit=1 if state=="FL"

replace polit=1 if state=="OK" 
replace polit=1 if state=="KS"

replace polit=1 if state=="NE" 
replace polit=1 if state=="ID"

replace polit=1 if state=="UT" 
replace polit=1 if state=="IA"

replace polit=1 if state=="LA" 
replace polit=1 if state=="MO"

replace polit=1 if state=="AR" 
replace polit=1 if state=="MS"

replace polit=1 if state=="TN" 
replace polit=1 if state=="KY"

replace polit=1 if state=="IN" 
replace polit=1 if state=="AK"

replace polit=1 if state=="GA" 
replace polit=1 if state=="SC"

replace polit=1 if state=="NC" 


replace polit=2 if state=="MT"
replace polit=2 if state=="CO"


replace polit=2 if state=="WI"
replace polit=2 if state=="AL"


replace polit=2 if state=="OH"
replace polit=2 if state=="WV"


replace polit=2 if state=="PA"

**Also take 2 when one of the senators is independet (Maine Independent and Republican Vermont Independet and Democratic)
replace polit=2 if state=="ME"
replace polit=2 if state=="VT"


**generate polit variable with last election this november for the new senate representation starting in January 2021
gen polit_last=0 
**O for Democratic 
**1 Republican 
replace polit_last=1 if state=="TX" | state=="ID" |state=="WY" | state=="MT" | state=="SD" |state=="NE" | state=="KS" | state=="OK" | state=="IA"  | state=="LA" | state=="AR"
replace polit_last=1 if state=="MS" | state=="TN" | state=="AL" | state=="KY" | state=="ME" | state=="WV" | state=="NC" | state=="SC" 
replace polit_last=1 if state=="AK"
**for thoose who were no senate election this year take presidential election result of November 2020
replace polit_last=1 if state=="UT" | state=="ND" | state=="MO"  | state=="FL" | state=="IN" | state=="OH" 

**Polit variable only Republican or Democratic but not the states with mixed representation  
gen polit_check=0 if polit==0
replace polit_check=1 if polit==1

**generate the log values 
gen prcodavg_log=log(prcodavg) 
gen weekly_death_log=log(weekly_death) 
gen weekly_cases_log=log(weekly_cases)
gen US_weekly_death_log=log(US_weekly_death)
gen cash_log=log(chq)
gen revenue_log=log(revtq)
gen debt_to_assets_log=log(debt_to_assets)
gen assets_log=log(atq)
gen sales_log=log(saleq)

gen log_dummy=0
replace log_dummy=1 if prcodavg<=1

gen sales_dummy=0
replace sales_dummy=1 if saleq<1

gen assets_dummy=0
replace assets_dummy=1 if atq<1


**declare data to be panel data 
**bit unbalanced because of some little gaps in available company data 
xtset gvkeyid time_variable

**tables on descriptive statistics 
**Data description 
twoway hist prcodavg, percent
graph export Stock.png
twoway hist prcodavg_log, percent
graph export log_stock.png
twoway hist prcodavg_log if log_dummy==0, percent 
graph export log_stock_penny.png

twoway hist atq, percent 
graph export Asset.png
twoway hist chq, percent 
graph export Cash.png
twoway hist sic, percent 
graph export industry.png
twoway hist sic_dummy, percent 
graph export sic.png
twoway hist dlttq, percent 
graph export debt_long_term.png

twoway hist cash_log, percent 
graph export cash_log.png
twoway hist sales_log, percent 
graph export sales_log.png


**More descriptive statistics
eststo sumstat: quietly estpost sum prcodavg_log weekly_death sales_log assets_log debt_to_assets, detail 
esttab sumstat, cells ("mean p50 p25 p75 min max sd skewness kurtosis") nonumbers label 
esttab sumstat using desstat.png,  cells ("mean p50 p25 p75 min max sd skewness kurtosis") nonumbers label 
 
eststo sumstat1: quietly estpost sum prcodavg saleq atq, detail 
esttab sumstat1, cells ("mean p50 p25 p75 min max sd skewness kurtosis") nonumbers label 
esttab sumstat1 using desstat_1.tex,  cells ("mean p50 p25 p75 min max sd skewness kurtosis") nonumbers label  
 
ssc install estout 
**start with basic regressions 
**Covid on stock prices with index and logs 
reg prcodavg weekly_death, robust  
eststo 	Index_Index 
reg prcodavg_log weekly_death_log if log_dummy==0, robust
eststo Log_Log   
reg prcodavg_log weekly_death if log_dummy==0, robust 
eststo Log_index_our_baseline
esttab, se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
esttab using simple_regression_final.tex, se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 


**compare the first and the second wave!
**first wave till the end of june 
**second wave starting from mid October
plot US_weekly_death week if fyearq==2020
generate time_check=0 if fyearq==2020
replace time_check=1 if fyearq==2020 & week<=27 
replace time_check=2 if fyearq==2020 & week>=42


**Interaction terms to compare the results, 0 is weeks between
reg prcodavg c.weekly_death#i.time_check, robust
reg prcodavg_log c.weekly_death##1.time_check if log_dummy==0, robust
eststo compare_weeks_2
reg prcodavg_log c.weekly_death##2.time_check if log_dummy==0, robust
eststo compare_weeks_3
esttab, title("Regression unsing Interaction terms to compare the two waves")se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
esttab using compare_two_waves_final.tex, title("Regression unsing Interaction terms to compare the two waves")se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

**Checking for deaths instead of weeks 
reg prcodavg c.weekly_cases#i.time_check, robust
reg prcodavg_log c.weekly_cases##1.time_check if log_dummy==0, robust
eststo compare_weeks_2
reg prcodavg_log c.weekly_cases##2.time_check if log_dummy==0, robust
eststo compare_weeks_3
esttab, title("Regression unsing Interaction terms to compare the two waves")se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
esttab using compare_two_waves_cases.tex, title("Regression unsing Interaction terms to compare the two waves")se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 


**Checks for weeks
bysort week: reg prcodavg_log weekly_death if log_dummy==0, r

**Use this regressions in order to show in paper!
reg prcodavg_log weekly_death if log_dummy==0  & week==12, robust
eststo week_12
reg prcodavg_log weekly_death if log_dummy==0 & week==13, robust 
eststo week_13
reg prcodavg_log weekly_death if log_dummy==0  & week==14, robust 
eststo week_14
reg prcodavg_log weekly_death if log_dummy==0  & week==15, robust 
eststo week_15
reg prcodavg_log weekly_death if log_dummy==0  &  week==16, robust 
eststo week_16
reg prcodavg_log weekly_death if log_dummy==0  & week==17, robust 
eststo week_17
reg prcodavg_log weekly_death if log_dummy==0  & week==18, robust 
eststo week_18
reg prcodavg_log weekly_death if log_dummy==0  & week==19, robust 
eststo week_19
reg prcodavg_log weekly_death if log_dummy==0  & week==20, robust 
eststo week_20
reg prcodavg_log weekly_death if log_dummy==0  & week==21, robust 
eststo week_21
esttab, se mtitle 
esttab using week1_final.tex, title("Regression Week First Wave") se mtitle replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

**second weeks 

reg prcodavg_log weekly_death if log_dummy==0  & week==41, robust 
eststo week_41
reg prcodavg_log weekly_death if log_dummy==0  & week==42, robust 
eststo week_42
reg prcodavg_log weekly_death if log_dummy==0  & week==43, robust 
eststo week_43
reg prcodavg_log weekly_death if log_dummy==0  & week==44, robust 
eststo week_44
reg prcodavg_log weekly_death if log_dummy==0  & week==45, robust 
eststo week_45
reg prcodavg_log weekly_death if log_dummy==0  & week==46, robust 
eststo week_46
reg prcodavg_log weekly_death if log_dummy==0  & week==47, robust 
eststo week_47
reg prcodavg_log weekly_death if log_dummy==0  & week==48, robust 
eststo week_48
esttab, title("Regression Result Week") se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
esttab using week_2_final.tex,  title("Regression Week Second Wave") se mtitle replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

 

**impacts on industries using sic dummy created above 
**Interaction term displays the sensitivity of rising deaths in the respective industry
reg prcodavg_log c.weekly_death##1.sic_dummy, robust
eststo Mining
reg prcodavg_log c.weekly_death##2.sic_dummy, robust
eststo Construction
reg prcodavg_log c.weekly_death##3.sic_dummy, robust
eststo Manufacturing
reg prcodavg_log  c.weekly_death##4.sic_dummy, robust
eststo Transport_Communication
reg prcodavg_log  c.weekly_death##5.sic_dummy, robust
eststo Wholesale_trade
reg prcodavg_log  c.weekly_death##6.sic_dummy, robust
eststo Retail
reg prcodavg_log c.weekly_death##7.sic_dummy, robust
eststo Finance_Insurance
reg prcodavg_log  c.weekly_death##8.sic_dummy, robust
eststo Service
reg prcodavg_log c.weekly_death##10.sic_dummy, robust
eststo Agriculture_Fishing_Foresty
esttab, se mtitle label title("Impact on stock prices in different industries")
esttab using regression_industry_final_final.tex, se label mtitle title("Impact on stock prices in different industries") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear

**further clustering of Retail in order to explain the surprising result 
**compare to the aggregate of all other firms not just within retail 
**not used in paper!- since few observations 
gen retail_dummy=0 
replace retail_dummy=1 if sic==5400 | sic==5411
**grocery and Food
replace retail_dummy=2 if sic==5661 |sic==5651 
**Clothing 
replace retail_dummy=3 if sic==5810 |sic==5812
**Eating and drinking places
replace retail_dummy=4 if sic==5500 |sic==5531
**Auto supply 
replace retail_dummy=5 if sic==5734 | sic==5731
**Computer Parts -  no observations!!
replace retail_dummy=6 if sic==5200 | sic==5211 
**home Building materials 
reg prcodavg_log c.weekly_death##i.retail_dummy, robust
eststo reg_retail 
reg prcodavg_log c.weekly_death##i.retail_dummy if time_check==1, robust 
eststo regression_retail 
esttab, label
esttab using regression_retail_industry_final.tex, label se replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear

**same for Manufacturing 
gen manu_dummy=0
replace manu_dummy=1 if sic==3721 | sic==3724 | sic==3728 
**Aircraft 
replace manu_dummy=2 if sic==3651 | sic==3663 | sic==3669 | sic==3670 | sic==3678 | sic==3674 | sic==3571 | sic==3571 | sic==3570 | sic==3576
**Electronic, COmputers, TV and Radio, Semiconductors 
replace manu_dummy=3 if sic==3411 | sic==3444 | sic==3412 | sic==3310 | sic==3312 | sic==3220 
**metal steel amnd glass 
replace manu_dummy=4 if sic==2836 | sic==2834 | sic==2833 | sic==2835 | sic==2800 
**Chemicals and Pharmazeticals
replace manu_dummy=5 if sic==2100 | sic==2111
**tabacco and cigarrets 
replace manu_dummy=6 if sic==2000 | sic==2050 | sic==2024 | sic==2020 | sic==2080 | sic==2082 | sic==2052 | sic==2030 | sic==2033
*Food and alcohol 
reg prcodavg_log c.weekly_death##i.manu_dummy if log_dummy==0, robust 
eststo manu_reg_first
reg prcodavg_log c.weekly_death##i.manu_dummy if log_dummy==0 & time_check==1, robust 
esttab, se  
esttab using manu_regression_final.tex, se title("Impact on Manufacturing companies") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear


**state analysis
bysort state:reg prcodavg weekly_death, robust 

**14 states with more than 3000 observations
reg prcodavg_log weekly_death if state=="CA" & log_dummy==0, robust
eststo  california
reg prcodavg_log weekly_death if state=="CO" & log_dummy==0, robust 
eststo colorado
reg prcodavg_log weekly_death if state=="TX" & log_dummy==0, robust 
eststo texas
reg prcodavg_log weekly_death if state=="FL" & log_dummy==0, robust 
eststo florida
reg prcodavg_log weekly_death if state=="PA" & log_dummy==0, robust 
eststo pennsylvania
reg prcodavg_log weekly_death if state=="GA" & log_dummy==0, robust 
eststo georgia
reg prcodavg_log weekly_death if state=="IL" & log_dummy==0, robust 
eststo illinois
esttab, mtitle se 
esttab using regression_state_1_final.tex, mtitle se title("Impact on States(1)")replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

reg prcodavg_log weekly_death if state=="NY" & log_dummy==0, robust 
eststo new_york
reg prcodavg_log weekly_death if state=="CT" & log_dummy==0, robust 
eststo connecticut
reg prcodavg_log weekly_death if state=="MA" & log_dummy==0, robust 
eststo massachusetts
reg prcodavg_log weekly_death if state=="NC"  & log_dummy==0, robust 
eststo north_carolina
reg prcodavg_log weekly_death if state=="NJ" & log_dummy==0, robust 
eststo new_jersey
reg prcodavg_log weekly_death if state=="OH" & log_dummy==0, robust 
eststo ohio
reg prcodavg_log weekly_death if state=="VA" &  log_dummy==0, robust 
eststo virginia
esttab, mtitle
esttab using regression_state_2_final.tex, se mtitle title("Impact on States(2)") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

*Influence of political variable on stay home order
*Used in Paper 
reg stay_home_order polit_check, r
reg stay_home_order 1.polit_check, r

**IV with stay home order (policy variable)

ssc install ivreg2
ssc install ranktest

reg stay_home_order polit_check, rob 

**Used the paper before other independet variables are added

**Baseline case with stay home order 
reg prcodavg_log stay_home_order, robust 
reg prcodavg_log stay_home_order sic sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, r

**with polit_check 
ivreg2 prcodavg_log sic sales_log cash_log debt_to_assets (stay_home_order=polit_check) if log_dummy==0 &sales_dummy==0, first 
eststo Polit_main 
reg stay_home_order polit_check, r
reg sales_log polit_check, r
reg sic polit_check, r

**with polit_last 
ivreg2 prcodavg_log sic sales_log cash_log debt_to_assets (stay_home_order=polit_last) if log_dummy==0 &sales_dummy==0, first
eststo Polit_last_election  
**polit_check shows more influence 


**with uninsured percentage 
ivreg2 prcodavg_log sic sales_log cash_log debt_to_assets (stay_home_order=unisured_percent_2019) if log_dummy==0 &sales_dummy==0, first  
eststo Uninsured
reg stay_home_order unisured_percent_2019, r


**with share of HH with an member of 65 or older
gen HH_over_65_fraction=TotalHouseholdswithoneormorepeop/popu
ivreg2 prcodavg_log  sic sales_log cash_log debt_to_assets (stay_home_order=HH_over_65_fraction) if log_dummy==0 &sales_dummy==0, first 
eststo HH_over_65 
**weak instrument 

esttab, mtitle se 
esttab using IV_stay_home.tex,  mtitle se title("IV Regression Stay Home Order") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 


**Durbin Wu Hausmann Test to test all IVS
reg stay_home_order polit_check, robust 
predict residual_1, resid
reg prcodavg_log sic sales_log cash_log debt_to_assets stay_home_order residual_1, robust 
test residual_1 
**works 

**test polit-last 
reg stay_home_order polit_last, robust 
predict residual_2, resid
reg prcodavg_log  sic sales_log cash_log debt_to_assets stay_home_order residual_2, robust 
test residual_2 


**test for uninsured percentage 
reg stay_home_order unisured_percent_2019, r
predict res3_4, resid
reg prcodavg_log sic sales_log cash_log debt_to_assets stay_home_order res3_4, r
test res3_4
**Ols is not consistent



*******************************
****ADD other independent variables 
**This part is used in paper
cor prcodavg_log sales_log assets_log debt_to_assets cash_log 
reg prcodavg_log weekly_death if log_dummy==0, robust 
eststo basic_log
reg prcodavg_log weekly_death sic if log_dummy==0, robust
eststo basic_log_2
reg prcodavg_log weekly_death sic sales_log  if log_dummy==0 & sales_dummy==0, robust 
eststo basic_log_3
reg prcodavg_log weekly_death sic sales_log assets_log if log_dummy==0 & sales_dummy==0 & assets_dummy==0, robust
eststo basic_log_4
**add cash 
reg prcodavg_log weekly_death sic sales_log assets_log cash_log if log_dummy==0 & sales_dummy==0 &assets_dummy==0, robust
eststo basic_log_5
estat vif
**add leverage!
reg prcodavg_log weekly_death sic sales_log assets_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0 &assets_dummy==0, robust
eststo basic_log_6
estat vif
ovtest
**Vif high for assets hence drop assets for further analysis 
**without assets
reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, robust
eststo basic_log_7
estat vif
esttab, se 
esttab using further_regression_basic_log_final.tex, se title("Regression with more independent variables") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

*****************************************************************************
**IV Part for weekly death 


**to compare, so far baseline regression!
reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, robust 
eststo baseline

**IV with HH over 65 or age variable?
ivreg2 prcodavg_log sic sales_log cash_log debt_to_assets (weekly_death=HH_over_65_fraction) if log_dummy==0 &sales_dummy==0, first  
eststo Households_over_65

**IV with uninsured
ivreg2 prcodavg_log sic sales_log cash_log debt_to_assets (weekly_death=unisured_percent_2019) if log_dummy==0 &sales_dummy==0, first 
**coefficient increases
eststo Uninsured 

**Using population density
ivreg2 prcodavg_log sic sales_log cash_log debt_to_assets (weekly_death=popden) if log_dummy==0 &sales_dummy==0, first  


**with age share 
ivreg2 prcodavg_log sic sales_log cash_log debt_to_assets (weekly_death=age) if log_dummy==0 &sales_dummy==0, first  
**use HH share with one or two members instead 
eststo Age_Structure

esttab, mtitle se
esttab using IV_weekly_death_final.tex, se mtitle title("IV Regression Weekly Death") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

**test Population density 
reg weekly_death popden, r
**not significant 
predict res1_2, resid 
reg prcodavg_log weekly_death res1_2 sales_log sic cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, robust 
test res1_2
**Population density influence on ther variables 
reg sales_log popden, r
reg debt_to_assets popden, r 
**population density not good IV

**uninsured testing!
reg weekly_death unisured_percent_2019, r
predict res2_2, resid 
reg prcodavg_log weekly_death res2_2 sales_log sic cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, robust 
test res2_2
**works 

**test HH over 65 
reg weekly_death HH_over_65_fraction, r
predict res3_3, resid 
reg prcodavg_log weekly_death res3_3 sales_log sic cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, robust 
test res3_3

reg sales_log HH_over_65_fraction,r
reg cash_log HH_over_65_fraction, r
reg sic HH_over_65_fraction, r

reg sales_log unisured_percent_2019, r
reg debt_to_assets unisured_percent_2019, r
reg prcodavg_log unisured_percent_2019, r


********************************
***Add otherv independent variables when set as PANEL 

xtset gvkeyid time_variable 
**log setup as Panel Data 
xtreg prcodavg_log weekly_death if log_dummy==0, vce(robust)
eststo log_reg_panel
xtreg prcodavg_log weekly_death  if log_dummy==0, vce(robust)
eststo log_reg_panel_2
**Sic is time invariant, but depends for company i 
xtreg prcodavg_log weekly_death sales_log if log_dummy==0 & sales_dummy==0, vce(robust)
eststo log_reg_panel_3
xtreg prcodavg_log weekly_death sales_log cash_log if log_dummy==0 & sales_dummy==0, vce(robust)
eststo log_reg_panel_4
xtreg prcodavg_log weekly_death sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, vce(robust)
eststo log_reg_panel_5
esttab 
esttab using regression_log_panel_final.tex, se title("Panel Regression") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 


********************************
*******FIXED EFFECTS
**include company fixed effects to the last setup
xtreg prcodavg_log weekly_death sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, fe vce(robust)
eststo company_fixed_effect 
**time fixed effects(with weeks)
xtreg prcodavg_log weekly_death sales_log cash_log debt_to_assets i.time_variable if log_dummy==0 & sales_dummy==0, vce(robust)
 
**reghdfe does not cosider Panel- baseline setting 
reghdfe prcodavg_log weekly_death sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, absorb(time_variable gvkeyid) vce(robust)


**both fixed effects as Panel!
xtreg prcodavg_log weekly_death sales_log cash_log debt_to_assets i.time_variable if log_dummy==0 & sales_dummy==0, fe vce(robust)
eststo both_fixed_effects
esttab 
esttab using fixed_effects_final.tex, se title("Regression using fixed-effects")replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear  


*************ROBUSTNESS CHECKS***********
********USED in PAPER***********
**Robustness Check: death per inhabitants 
**for comparison 
reg prcodavg_log weekly_death  if log_dummy==0 , robust 
reg prcodavg_log death_fraction if log_dummy==0, robust
eststo OLS
xtreg prcodavg_log death_fraction if log_dummy==0, vce(robust) 
eststo Panel_1
 
reg prcodavg_log weekly_death sic if log_dummy==0, robust 
reg prcodavg_log death_fraction sic if log_dummy==0, robust 
eststo OLS_2
xtreg prcodavg_log death_fraction sic if log_dummy==0, vce(robust)
eststo Panel_2

reg prcodavg_log weekly_death sic sales_log if log_dummy==0 & sales_dummy==0, robust 
reg prcodavg_log death_fraction sic sales_log  if log_dummy==0 & sales_dummy==0 , robust 
eststo OLS_3
xtreg prcodavg_log death_fraction sic sales_log if log_dummy==0, vce(robust)
eststo Panel_3


reg prcodavg_log weekly_death sic sales_log cash_log if log_dummy==0 & sales_dummy==0 , robust 
reg prcodavg_log death_fraction sic sales_log cash_log if log_dummy==0 & sales_dummy==0, robust
eststo OLS_4
xtreg prcodavg_log death_fraction sic sales_log cash_log if log_dummy==0 & sales_dummy==0, vce(robust)
eststo Panel_4


reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0 , robust 
reg prcodavg_log death_fraction sic sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, robust 
eststo OLS_5
xtreg prcodavg_log death_fraction sic sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, vce(robust)
eststo Panel_5


esttab, se mtitle  
esttab using death_fraction_final_final.tex, mtitle se title("Robustness Check 1") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

**robustness check outlier
**one for company size 
**another for marketvalue 
tabstat mkvaltq, stats(p90) 
tabstat atq, stats(p90)

**test when largest 10% of companies are excluded
reg prcodavg_log weekly_death if atq<16428.9, robust 
eststo OLS
xtreg prcodavg_log weekly_death if atq<16428.9, vce(robust)
eststo Panel
reg prcodavg_log weekly_death, robust 

reg prcodavg_log weekly_death sic  if atq<16428.9, robust
eststo OLS_2
xtreg prcodavg_log weekly_death sic if atq<16428.9, vce(robust)
eststo Panel_2
reg prcodavg_log weekly_death sic, robust

reg prcodavg_log weekly_death sic sales_log if atq<16428.9, robust
eststo OLS_3
xtreg prcodavg_log weekly_death sic sales_log if atq<16428.9, vce(robust)
eststo Panel_3
reg prcodavg_log weekly_death sic sales_log, robust

reg prcodavg_log weekly_death sic sales_log cash_log if atq<16428.9, robust
eststo OLS_4
xtreg prcodavg_log weekly_death sic sales_log cash_log if atq<16428.9, vce(robust)
eststo Panel_4
reg prcodavg_log weekly_death sic sales_log cash_log,robust

reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets if atq<16428.9, robust
eststo OLS_5
xtreg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets if atq<16428.9, vce(robust)
eststo Panel_5
reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets, robust 
esttab 
esttab using rub_1_final.tex, se mtitle title("Robustness Check 2") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

**test when companies with the 10% highest marketvalue are excluded 
reg prcodavg_log weekly_death if mkvaltq<19100.34, robust 
eststo OLS
xtreg prcodavg_log weekly_death if mkvaltq<19100.34, vce(robust)
eststo Panel
reg prcodavg_log weekly_death, robust
 
reg prcodavg_log weekly_death sic  if mkvaltq<19100.34, robust
eststo OLS_2
xtreg prcodavg_log weekly_death sic if mkvaltq<19100.34, vce(robust)
eststo Panel_2
reg prcodavg_log weekly_death sic, robust

reg prcodavg_log weekly_death sic sales_log if mkvaltq<19100.34, robust
eststo OLS_3
xtreg prcodavg_log weekly_death sic sales_log if mkvaltq<19100.34, vce(robust)
eststo Panel_3
reg prcodavg_log weekly_death sic sales_log, robust

reg prcodavg_log weekly_death sic sales_log cash_log if mkvaltq<19100.34, robust
eststo OLS_4
xtreg prcodavg_log weekly_death sic sales_log cash_log if mkvaltq<19100.34, vce(robust)
eststo Panel_4
reg prcodavg_log weekly_death sic sales_log cash_log,robust


reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets if mkvaltq<19100.34, robust
eststo OLS_5
xtreg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets if mkvaltq<19100.34, vce(robust)
eststo Panel_5
reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets, robust 
esttab 
esttab using rub_2_final.tex, se mtitle title("Robustness Check 3") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 


*******************************END OF PAPER********
*********OTHER INTERESTING STUFF*******************


**check polit impact to the weekly cases
reg weekly_death i.polit, robust 
eststo basic
reg weekly_death polit_check, robust 
eststo only_total_representation
reg weekly_death i.polit_check, robust 
eststo only_total__i
reg weekly_death_log i.polit_check, robust 
eststo only_total_log_i
reg weekly_death i.polit, robust 
eststo basic_i
reg weekly_death_log i.polit, robust 
eststo basic_log_i
esttab
esttab using weekly_death_polit.tex, replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

*Furher checks 
**consider death of the whole United States
**not used in the paper
reg prcodavg US_weekly_death, robust 
eststo simple_regression_US
reg prcodavg_log US_weekly_death_log, robust
eststo simple_regression_US_log
esttab 
esttab using simple_regression_US.tex, replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

**check the effect of cases not deaths!- Robustness Check!
**not used in paper
reg prcodavg weekly_cases, robust 
eststo regression_stock_cases
reg prcodavg_log weekly_cases_log, robust
eststo regression_both_log
reg prcodavg_log weekly_cases, robust
eststo regression_stock_log_cases
reg prcodavg weekly_cases_log, robust 
eststo regression_stock_cases_log 
esttab 
esttab using Regression_with_cases.tex, replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear


**Log-Values with penny stocks
reg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets_log, robust 
xtreg prcodavg_log weekly_death sic sales_log cash_log debt_to_assets_log, vce(robust)



****STATES DURING first wave 
**create indicator fot only the first wave
gen time_state=0 
replace time_state=1 if fyearq==2020 & week>=9 & week<=17
**here only march and april 
**to analysize: are the inisgnificant states at least significant for first wave?- Not used in paper!
reg prcodavg_log c.weekly_death##i.time_state if state=="FL" & log_dummy==0, robust 
eststo florida
reg prcodavg_log c.weekly_death##i.time_state if state=="PA" & log_dummy==0, robust 
eststo pennsylvania
reg prcodavg_log c.weekly_death##i.time_state if state=="CA" & log_dummy==0, robust
eststo california
reg prcodavg_log c.weekly_death##i.time_state if state=="GA" & log_dummy==0, robust 
eststo georgia
reg prcodavg_log c.weekly_death##i.time_state if state=="NY" &  log_dummy==0, robust 
eststo new_york
reg prcodavg_log c.weekly_death##i.time_state if state=="CO" & log_dummy==0, robust 
eststo colorado 
reg prcodavg_log c.weekly_death##i.time_state if state=="TX" & log_dummy==0, robust 
eststo texas
esttab, mtitle
esttab using regression_state_time_1.tex, mtitle replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 

reg prcodavg_log c.weekly_death##i.time_state if state=="CT" & log_dummy==0, robust 
eststo connecticut
reg prcodavg_log c.weekly_death##i.time_state if state=="MA" & log_dummy==0, robust 
eststo massachusetts
reg prcodavg_log c.weekly_death##i.time_state if state=="NC" & log_dummy==0, robust 
eststo north_carolina
reg prcodavg_log c.weekly_death##i.time_state if state=="OH" & log_dummy==0, robust 
eststo ohio
reg prcodavg_log c.weekly_death##i.time_state if state=="IL" & log_dummy==0, robust 
eststo illinois
reg prcodavg_log c.weekly_death##i.time_state if state=="NJ" & log_dummy==0, robust 
eststo new_jersey
reg prcodavg_log c.weekly_death##i.time_state if state=="VA" & log_dummy==0, robust 
eststo virginia
esttab, mtitle
esttab using regression_state_time_2.tex, mtitle replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 
 


******************* 
**Add other independent variables- WITH STOCK AS INDEX INSETEAD OF LOGS 

**add indendent variables to baseline regression 
corr prcodavg weekly_death mkvaltq saleq sic_dummy chq atq  revtq
corr prcodavg_log weekly_death mkvaltq sales_log sic_dummy assets_log revtq

**start with basic case
**In the paper only with log
**this part is not used in Paper
reg prcodavg weekly_death, robust
eststo basic
**add industry 
reg prcodavg weekly_death sic, robust
eststo basic_2
**add sales
reg prcodavg weekly_death sic saleq, robust
eststo basic_3
**test whether it makes sense to take log values 
reg prcodavg weekly_death sic saleq, robust 
predict resid, resid
hist resid, percent
tabstat resid, stats(median mean)
**median is less than the mean, hence the residual is skewed to the right 
**this speakes in favor of using log values- which is done in the latter part 
**first add companie size expressed as total assets 
reg prcodavg weekly_death sic saleq atq, robust 
eststo basic_4
**add cash
reg prcodavg weekly_death sic saleq atq chq, robust
eststo basic_5 
**add leverage
reg prcodavg weekly_death sic saleq atq chq debt_to_assets, robust 
eststo basic_6 
estat vif
esttab 
esttab using further_regression_basic.tex, replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 


***PANEL WITH INDEX INSTEAD OF LOGS 
xtset gvkeyid time_variable 
**log setup as Panel Data 
xtreg prcodavg weekly_death if log_dummy==0, vce(robust)
eststo reg_panel
xtreg prcodavg weekly_death  if log_dummy==0, vce(robust)
eststo reg_panel_2
**Sic is time invariant, but depends for company i 
xtreg prcodavg weekly_death sales_log if log_dummy==0 & sales_dummy==0, vce(robust)
eststo reg_panel_3
xtreg prcodavg weekly_death sales_log cash_log if log_dummy==0 & sales_dummy==0, vce(robust)
eststo reg_panel_4
xtreg prcodavg weekly_death sales_log cash_log debt_to_assets if log_dummy==0 & sales_dummy==0, vce(robust)
eststo reg_panel_5
esttab 
esttab using regression_panel_final.tex, se title("Panel Regression") replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
est clear 


**Further Tables of IV Stay Home Order (Without Independent variables)
***//IV_stay_home_order_logPrice
**eststo: reg prcodavg_log stay_home_order if log_dummy==0, r
**estadd scalar IV_stage_1 =.
**estadd scalar IV_st1_p_value = .
**estadd scalar F_stage_1 = . 

*IV senate percentage
**eststo: ivreg2 prcodavg_log (stay_home_order = polit_check) if log_dummy==0, first savefirst savefprefix(fs_1)
*check the saved first stage results
**esttab fs_1*
**return list
**mat list r(coefs)
*save first stage results, coefficient of first stage and its std.
**estadd scalar IV_stage_1 = r(coefs)[1,1]
**estadd scalar IV_st1_p_value = r(coefs)[1,3]
*keep first stage IV result- F-test
**ereturn list
**mat list e(first)
**estadd scalar F_stage_1 = e(first)[4,1]

*IV latest election
**eststo: ivreg2 prcodavg_log (stay_home_order = polit_last) if log_dummy==0, first savefirst savefprefix(fs_1)
*check the saved first stage results
**esttab fs_1*
**return list
**mat list r(coefs)
*save first stage results, coefficient of first stage and its std.
**estadd scalar IV_stage_1 = r(coefs)[1,1]
**estadd scalar IV_st1_p_value = r(coefs)[1,3]
*keep first stage IV result- F-test
**ereturn list
**mat list e(first)
**estadd scalar F_stage_1 = e(first)[4,1]


*IV :HH>65
**with share of HH with an member of 65 or older
**gen HH_over_65_fraction=TotalHouseholdswithoneormorepeop/popu
**eststo: ivreg2 prcodavg_log (stay_home_order =HH_over_65_fraction) if log_dummy==0, first savefirst savefprefix(fs_1)
*check the saved first stage results
**esttab fs_1*
**return list
**mat list r(coefs)
*save first stage results, coefficient of first stage and its std.
**estadd scalar IV_stage_1 = r(coefs)[1,1]
**estadd scalar IV_st1_p_value = r(coefs)[1,3]
*keep first stage IV result- F-test
**ereturn list
**mat list e(first)
**estadd scalar F_stage_1 = e(first)[4,1]

*IV uninsured percentage
**eststo: ivreg2 prcodavg_log (stay_home_order = unisured_percent_2019) if log_dummy==0, first savefirst savefprefix(fs_1)
*check the saved first stage results
**esttab fs_1*
**return list
**mat list r(coefs)
*save first stage results, coefficient of first stage and its std.
**estadd scalar IV_stage_1 = r(coefs)[1,1]
**estadd scalar IV_st1_p_value = r(coefs)[1,3]
*keep first stage IV result- F-test
**ereturn list
**mat list e(first)
**estadd scalar F_stage_1 = e(first)[4,1]

**esttab
**esttab, se  stats( N IV_stage_1 IV_st1_p_value F_stage_1 ) label          ///
     **title(IV for Stay Home Order Policy with log Prices)       ///
     **nonumbers mtitles("OLS" "Senate Share" "Last Vote" "HH with 65+%" "Uninsured %")
	 
**esttab using "IV_stay_home_order_logPrice.tex", replace se stats(N IV_stage_1 IV_st1_p_value F_stage_1 ) label                               ///
     **title(IV for Stay Home Order Policy with log Prices)       ///
     **nonumbers mtitles("OLS" "Senate Share" "Last Vote" "HH with elders 65+ %" "Uninsured %")
**est clear
******

*****************************************************************************
**IV Part for weekly death 

*//To compare parellely, log price on weekly_death analysis with different IVs are used
******	 
*//IV_Baseline *//IV_log_levels	
*//IV_weekly_death_logPrice
**eststo: reg prcodavg_log weekly_death if log_dummy==0, robust
**estadd scalar IV_stage_1 =.
**estadd scalar IV_st1_p_value = .
**estadd scalar F_stage_1 = . 

*fraction of HH with members >65
**eststo: ivreg2 prcodavg_log (weekly_death = HH_over_65_fraction) if log_dummy==0, first savefirst savefprefix(fs_1)
*check the saved first stage results
**esttab fs_1*
**return list
**mat list r(coefs)
*save first stage results, coefficient of first stage and its std.
**estadd scalar IV_stage_1 = r(coefs)[1,1]
**estadd scalar IV_st1_p_value = r(coefs)[1,3]
*keep first stage IV result- F-test
**ereturn list
**mat list e(first)
**estadd scalar F_stage_1 = e(first)[4,1]


**eststo: ivreg2 prcodavg_log (weekly_death = unisured_percent_2019) if log_dummy==0 ,first savefirst savefprefix(fs_1)
*check the saved first stage results
**esttab fs_1*
**return list
**mat list r(coefs)
*save first stage results, coefficient of first stage and its std.
**estadd scalar IV_stage_1 = r(coefs)[1,1]
**estadd scalar IV_st1_p_value = r(coefs)[1,3]
*keep first stage IV result- F-test
**ereturn list
**mat list e(first)
**estadd scalar F_stage_1 = e(first)[4,1]


**eststo: ivreg2 prcodavg_log (weekly_death = age ) if log_dummy==0, first savefirst savefprefix(fs_1)
*check the saved first stage results
**esttab fs_1*
**return list
**mat list r(coefs)
*save first stage results, coefficient of first stage and its std.
**estadd scalar IV_stage_1 = r(coefs)[1,1]
**estadd scalar IV_st1_p_value = r(coefs)[1,3]
*keep first stage IV result- F-test
**ereturn list
**mat list e(first)
**estadd scalar F_stage_1 = e(first)[4,1]


**esttab ,se stats(N IV_stage_1 IV_st1_p_value F_stage_1 ) label                               ///
     **title(IV for Weekly Death Cases with log Prices)       ///
     **nonumbers mtitles("OLS" "HH with elders 65+ %" "Unsinsured %" "Age_Structure" )

**esttab using "IV_weekly_death_logPrice.tex", replace se stats(N IV_stage_1 IV_st1_p_value F_stage_1 ) label                               ///
     **title(IV for Weekly Death Cases with log Prices)       ///
    **nonumbers mtitles("OLS" "HH with elders 65+ %" "Unsinsured %" "Age_Structure" )

**est clear

*****

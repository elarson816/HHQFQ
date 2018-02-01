****PMA 2020  Data Quality Checks****
** Original Version Written in Bootcamp July 21-23, 2014****

/*
*********** Record of changes
*December 2 2015 removed code to generate country and round variables and moved to
HHQ do file
*March 1, 2016 - Linnea Zimmerman - included section on country specific questions immediately before
	section on weighting
*March 11, 2016	rename lam_probe_current to lam_probe since in some datasets there is lam_probe and in some lam_probe current
*March 21, 2016 rename facility_name to facility_nm to keep from dropping if country includes name of fp facility
*May 2, 2016 updated list of variables to drop based on new form format *
*May 25, 2016 - LZ - updated assets list to remove regexm command 
*Aug 26, 2016 - SJ - HHQ: added language, religion, ethnicity; FQ: added insurance variables and fp_ad_call
*Aug 30, 2016 - LZ - updated label for methods list to 5= injectables (depo) and included
					sayana press as a dichotomous variable
*Jan 3, 2017 - LZ - updated to include women who say first use of contraception as mcp and cp==1.  
		Update analysis do file to reclassify as FS users in method mix
*Jan 29, 2017 - LZ- updated to remove sexresp variable (sex of respondent) and create indicator variable
					for respondent (respondent)
					Rename level1-level4 variables with correct geographic info	
*3 Feb 2017	- LZ - v16 - updated to recode non-LAM users who report an additional method as the other method (must be traditional)
*8 Feb 2017 - SJ - v17 fixed {} for sayana press
v18 -March 22, 2017-LZ replaced current method as sterilization if woman says she has been sterilized
	Relevant only for RJ but included universally anyway
v19	- May 08 2017	- LZ changed sayana press coding.  1. Created recent_methodnum_rc, first_methodnum_rc and recoded
					current_methodnumEC ONLY.  current_method is not changed to account for SP.  SP now called injectables_sc
*v21 - May 18 2017 - LZ replaced penult birth with first birth for women with two children */
*v22 - 20Jun2017 - LZ fixed miscoding in injectables_sc
*V22.2 updated weight section
*v22.3 updated urban/rural designations in spreadsheet
*v23.0 add RE to the GPS datasets, export GPS data as xls files SJ
set more off

local CCRX $CCRX

******************************
use `CCRX'_Combined_$date.dta, clear

*Check if there are any remaining duplicates
duplicates report member_number 
duplicates report FQmetainstanceID
capture drop dupFQmeta
duplicates tag FQmetainstanceID, gen(dupFQmeta)
*br if dupFQmeta!=0 & FQmetainstanceID !=""
duplicates drop FQmetainstanceID if FQmetainstanceID!="", force
save, replace
 
 


********************************************************************************************************************
******************************All country specific variables need to be encoded here********************

/*Section 1 is questions/variables that are in either household/female in all countries
Section 2 is questions/variables only in one country

***Household and Female
*Household
*Update corrected date of interview if phone had incorrect settings.  Update to year/month of data collection
**Assets
**Livestock
**Floor
**Roof
**Walls

*Female
*Update corrected date of interview if phone had incorrect settings.  Update to year/month of data collection
**School
**FP Provider
*/


local level1 county
local level2 district
local level3 divition
local level4 location


*Household DOI
capture drop doi*

gen doi=system_date
replace doi=manual_date if manual_date!="." & manual_date!=""

split doi, gen(doisplit_)
capture drop wrongdate
gen wrongdate=1 if doisplit_3!="2017"
replace wrongdate=1 if doisplit_1!="Nov" & doisplit_1!="Dec" & doisplit_1!="Oct" & doisplit_1!=""
//REVISION: SJ added b/c data collection may span across 2017 and 2018
replace wrongdate=1 if doisplit_3!="2018"
replace wrongdate=1 if doisplit_1!="Jan" & doisplit_1!=""


gen doi_corrected=doi
replace doi_corrected=SubmissionDate if wrongdate==1 & SubmissionDate!=""
drop doisplit*

*Assets
split assets, gen(assets_)
local x=r(nvars)
foreach var in electricity radio tv mobile landline refrigerator solar_panel table ///
chair sofa bed cupboard clock microwave dvd_player cassette_cd_player air_con watch bicycle ///
motorcycle animal_cart car motor_boat {
gen `var'=0 if assets!="" & assets!="-99"
forval y=1/`x' {
replace `var'=1 if assets_`y'=="`var'"
}
}
drop assets_*

*Livestock //SJ: Major changes of livestock varnames, no "other" in KER5
//REVISION: BL 03Nov2017 homestead_* dropped
rename owned_horses_donkey owned_horses_donkeys_camels
*rename homestead_exotic_ca exotic_cattle_homestead
foreach x in local_cattle cows_bulls horses_donkeys_camels goats sheep chickens {
capture rename owned_`x'* `x'_owned
*rename homestead_`x'* `x'_homestead
capture label var `x'_owned 			"Total number of `x' owned"
* label var `x'_homestead		"Total number of `x' on homestead"
destring `x'_owned, replace
*destring `x'_homestead, replace
}

*rename milk_cows_bul* milk_cows_bull*
*rename grasscutt* grasscutter*



*Roof/Wall/Floor
**Numeric codes come from country specific DHS questionnaire 
//SJ:deleted "linoleum" in ODK
label define floor_list 11 earth 12 dung 21 planks 22 palm_bamboo 31 parquet ///
    32 vinyl_asphalt 33 ceramic_tiles 34 cement 35 carpet 96 other -99 "-99"
encode floor, gen(floorv2) lab(floor_list)

//SJ: deleted "no_roof" in ODK	
label define roof_list 11 thatched 12 dung_mud 21 corrugated_iron 22 tin_cans ///
	31 asbestos 32 concrete 33 tiles 96 other -99 "-99"
encode roof, gen(roofv2) lab(roof_list)	

//SJ: NOT COMPLETED V7 "dirt" changed to "dung_mud" since option changed. typo: stone_mod. iron_sheet named wrong.
label define walls_list 11 no_walls 12 cane_palm 14 dung_mud 21 bamboo_mud 22 stone_mud 23 uncovered_adobe ///
	24 plywood 25 cardboard 26 reused_wood 27 iron_sheets 31 cement 32 stone_lime 33 bricks 34 cement_blocks ///
	35 adobe 36 wood_planks_shingles 96 other -99 "-99" 
encode walls, gen(wallsv2) lab(walls_list)

*LANGUAGE 
label define language_list 1 english 2 swahili 96 other
encode survey_language, gen(survey_languagev2) lab(language_list)
label var survey_languagev2 "Language of household interview"


****************************************************************
***************************  Female  ************************

**Country specific female questionnaire changes
*Year and month of data collection.  

gen FQwrongdate=1 if thisyear!=2017 & thisyear!=.
replace FQwrongdate=1 if thismonth!=11 & thismonth!=12 & thismonth!=10 & thismonth!=. 
//REVISION: SJ added b/c data collection may span across 2017 and 2018
replace FQwrongdate=1 if thisyear!=2018 & thisyear!=.
replace FQwrongdate=1 if thismonth!=1 & thismonth!=. 


gen FQdoi=FQsystem_date
replace FQdoi = FQmanual_date if FQmanual_date!="." & FQmanual_date!=""

gen FQdoi_corrected=FQdoi
replace FQdoi_corrected=FQSubmissionDate if FQwrongdate==1 & FQSubmissionDate!=""

*education categories
label define school_list 0 "never" 1 "primary" 2 "post-primary_vocational" 3 "secondary_A_level" 4 "college" 5 "Univerisity" -99 "-99"
encode school, gen(schoolv2) lab(school_list)
label define school_list 5 "university", modify


*REVISION-v19- renamed sayana press to injectables_sc
//REVISION: BL 03Nov2017 washing and other_modern removed from method list in all countries
*the only part that needs to be updated is 5.  In countries with only one injectables option it should be injectables instead of injectables_3mo
label define methods_list 1 female_sterilization 2 male_sterilization 3 implants 4 IUD  5 injectables  ///
	 6 injectables_1mo 7 pill 8 emergency 9 male_condoms 10 female_condoms  11 diaphragm ///
	 12 foam 13 beads 14 LAM 15 N_tablet  16 injectables_sc 30 rhythm 31 withdrawal  ///
	 39 other_traditional  -99 "-99"
	 
	encode first_method, gen(first_methodnum) lab(methods_list)
	order first_methodnum, after(first_method)
	
	encode current_recent_method, gen(current_recent_methodnum) lab(methods_list)
	order current_recent_methodnum, after(current_recent_method)
	
	encode recent_method, gen(recent_methodnum) lab(methods_list)
	order recent_methodnum, after(recent_method)
	
	//REVISION SJ 14NOV2017
	encode pp_method, gen(pp_methodnum) lab(methods_list)
	order pp_methodnum, after(pp_method)
	

*Drop variables not included in country
*In variable list on the foreach line, include any variables NOT asked about in country
foreach var of varlist injectables3 injectables1 N_tablet {
sum `var'
if r(min)==0 & r(max)==0 {
drop `var'
}
}

//REVISION: SJ added to confirm sayana_press
capture confirm var sayana_press 
if _rc==0 {
replace sayana_press=1 if regexm(current_method, "sayana_press") & FRS_result==1
}


*source of contraceptive supplies  //SJ: added "other_private"
label define providers_list 11 govt_hosp 12 govt_health_center 13 govt_dispensary 16 other_public 21 faith_based ///
	22 FHOK_health_center  23 private_hosp  24 pharmacy  25 nursing_maternity 29 other_private 31 mobile_clinic ///
	41 community_based 42 chw 51 shop 61 friend_relative 96 other  -88 "-88" -99 "-99" 
	encode fp_provider_rw, gen(fp_provider_rwv2) lab(providers_list)
	
	capture encode fp_provider_rw, gen(fp_provider_rwv2) lab(providers_list)
	
*FQ language
*LANGUAGE
capture label define language_list 1 english 2 swahili 96 other
capture encode language, gen(languagev2) lab(language_list)
capture label var language "Language of Female interview"

	
***************************************************************************************************
***SECTION 2: COUNTRY SPECIFIC QUESTIONS

capture confirm var religion
	if _rc==0 {
		label define religion_list 1 catholic 2 other_christian 3 islam 4 traditionalist 96 other -77 "-77" -99 "-99"
		encode religion, gen(religionv2) lab(religion_list)
		sort metainstanceID religionv2 
		bysort metainstanceID: replace religionv2 =religionv2[_n-1] if religionv2==.
		label var religionv2 "Religion of household head"
		}

capture confirm var ethnicity
	if _rc==0 {
		label define ethnicity_list 1 afo_gwandara 2 alago 3 eggon 4 fufulde 5 hausa 6 igbo 7 izon_ijaw 8 katab_tyap ///
		9 mada 10 mambila 11 mumuye 12 ogoni 13 rundawa 14 wurkum 15 yoruba 96 other -99 "-99"
		encode ethnicity, gen(ethnicityv2) lab(ethnicity_list)
		sort metainstanceID ethnicityv2 
		bysort metainstanceID: replace ethnicityv2=ethnicityv2[_n-1] if ethnicityv2==.
		label var ethnicityv2 "Ethnicity of household head"
		}

//REVISION: BL 01Nov2017 follow-up consent
capture confirm var flw_*
	if _rc==0 {	
		label var flw_willing					"Willing to participate in another survey"
			encode flw_willing, gen(flw_willingv2) lab(yes_no_dnk_nr_list)
		label var flw_number_yn					"Owns a phone"
			encode flw_number_yn, gen(flw_number_ynv2) lab(yes_no_dnk_nr_list)
		label var flw_number_typed				"Phone number"
		}

*FP AD CALL  //SJ: fp_ad_call transferred to FRQ do file
*capture encode fp_ad_call, gen(fp_ad_callv2) lab(yes_no_dnk_nr_list)
*capture label var fp_ad_call ""
		
unab vars: *v2
local stubs: subinstr local vars "v2" "", all
foreach var in `stubs'{
rename `var' `var'QZ
order `var'v2, after(`var'QZ)
}
rename *v2 *
drop *QZ

//Kenya R6
capture label var hh_location_ladder	"Location of house on wealth ladder: 1 = poorest, 10 = wealthiest"
***************************************************************************************************
********************************* COUNTRY SPECIFIC WEIGHT GENERATION *********************************
***************************************************************************************************

**Import sampling fraction probabilities and urban/rural
**NEED TO UPDATE PER COUNTRY
/*
*merge m:1 EA using "~/Dropbox (Gates Institute)/Uganda/PMADataManagement_Uganda/Round5/WeightGeneration/UGR5_EASelectionProbabilities_20170717_lz.dta", gen(weightmerge)
merge m:1 EA using "C:/Users/Shulin/Dropbox (Gates Institute)/PMADataManagement_Uganda/Round5/WeightGeneration/UGR5_EASelectionProbabilities_20170717_lz.dta", gen(weightmerge)
drop region subcounty district
tab weightmerge

**Need to double check the weight merge accuracy
capture drop if weightmerge!=3
label define urbanrural 1 "URBAN" 2 "RURAL"
label val URCODE urbanrural
rename URCODE ur

capture rename EASelectionProbabiltiy EASelectionProbability
gen HHProbabilityofselection=EASelectionProbability * ($EAtake/HHTotalListed)
replace HHProbabilityofselection=EASelectionProbability if HHTotalListed<$EAtake
generate completedhh=1 if (HHQ_result==1) & metatag==1

*Denominator is any household that was found (NOT dwelling destroyed, vacant, entire household absent, or not found)
generate hhden=1 if HHQ_result<6 & metatag==1

*Count completed and total households in EA
bysort $GeoID: egen HHnumtotal=total(completedhh)
bysort $GeoID: egen HHdentotal=total(hhden)

*HHweight is1/ HHprobability * Missing weight
gen HHweight=(1/HHProbability)*(1/(HHnumtotal/HHdentotal)) if HHQ_result==1

**Generate Female weight based off of Household Weight
**total eligible women in the EA
gen eligible1=1 if eligible==1 & (last_night==1)
bysort $GeoID: egen Wtotal=total(eligible1) 

**Count FQforms up and replace denominator of eligible women with forms uploaded
*if there are more female forms than estimated eligible women
gen FQup=1 if FQmetainstanceID!=""
gen FQup1=1 if FQup==1 & (last_night==1)
bysort $GeoID: egen totalFQup=total(FQup1) 
drop FQup1

replace Wtotal=totalFQup if totalFQup>Wtotal & Wtotal!=. & totalFQup!=.

**Count the number of completed or partly completed forms (numerator)
gen completedw=1 if (FRS_result==1 ) & (last_night==1) //completed, or partly completed
bysort $GeoID: egen Wcompleted=total(completedw)

*Gen FQweight as HHweight * missing weight
gen FQweight=HHweight*(1/(Wcompleted/Wtotal)) if eligible1==1 & FRS_result==1 & last_night==1
gen HHweightorig=HHweight
gen FQweightorig=FQweight
**Normalize the HHweight by dividing the HHweight by the mean HHweight (at the household leve, not the member level)
preserve
keep if metatag==1
su HHweight
replace HHweight=HHweight/r(mean)
sum HHweight
tempfile temp
keep metainstanceID HHweight
save `temp', replace
restore
drop HHweight
merge m:1 metainstanceID using `temp', nogen

**Normalize the FQweight
sum FQweight
replace FQweight=FQweight/r(mean)
sum FQweight


drop weightmerge HHProbabilityofselection completedhh-HHdentotal eligible1-Wcompleted

rename REGIONCODEUR strata
*/
***************************************************************************************************
********************************* GENERIC DONT NEED TO UPDATE *********************************


********************************************************************************************************************


*1. Drop unneccessary variables
//REVISION: BL 03Nov2017 *photo* san_facility water_sources sanitation_sources dropped
rename consent_obtained HQconsent_obtained
drop consent* FQconsent FQconsent_start *warning*   ///
	respondent_in_roster roster_complete  ///
	deviceid simserial phonenumber *transfer *label* ///
	witness_manual *prompt* witness_manual *check* *warn* FQKEY ///
	unlinked* error_*heads metalogging eligibility_screen*  ///
	more_hh_members* *GeoID* dupFRSform deleteTest dupFQ FQresp error *note* ///
	HHmemberdup waitchild 
 capture drop why_not_using_c
 
 capture drop last_time_sex_lab  menstrual_period_lab *unlinked close_exit
 capture drop begin_using_lab
 capture drop anychildren
 capture drop yeschildren
 capture drop childmerge
 capture drop dupFQmeta
 capture drop *Section*

rename HQconsent_obtained consent_obtained

*REVISION-v21- LZ- 2017.05.18 replaced missing penultimate birth with first birth date for women with 2 births
//REVISION: BL 03Nov2017 children_born dropped
/*
replace first_birth=recent_birth if children_born==1
replace penultimate_birth=first_birth if children_born==2
replace first_birthSIF=recent_birthSIF if children_born==1
replace penultimate_birthSIF=first_birthSIF if children_born==2
*/
capture drop if EA=="9999" | EA==9999

//REVISION: BL 03Nov2017 respondent_firstname dropped
*generate sex of respondent
*gen sexresp=gender if respondent_firstname==firstname

sort metainstanceID member_number


/***************** RECODE CURRENT METHOD **********************************
1. Recent EC users recoded to current users
2. LAM Users who are not using LAM recoded
3. Female sterilization users who do not report using sterilization are recoded
4. SP users recoded to SP
********************************************************************/
**Recode recent EC users to current users
//REVISION: BL 03Nov2017 stop_using_why now select multiple 
gen current_methodnum=current_recent_methodnum if current_user==1
label val current_methodnum methods_list
gen current_methodnumEC=current_recent_methodnum if current_user==1
replace current_methodnumEC=8 if current_recent_methodnum==8 & current_user!=1
label val current_methodnumEC methods_list
gen current_userEC=current_user
replace current_userEC=. if current_methodnumEC==-99
replace current_userEC=1 if current_recent_methodnum==8 & current_user!=1
gen recent_userEC=recent_user
replace recent_userEC=. if current_recent_methodnum==8 
gen recent_methodEC=recent_method
replace recent_methodEC="" if recent_method=="emergency"
gen recent_methodnumEC=recent_methodnum
replace recent_methodnumEC=. if recent_methodnum==8
label val recent_methodnumEC methods_list
gen fp_ever_usedEC=fp_ever_used
replace fp_ever_usedEC=1 if current_recent_methodnum==8 & fp_ever_used!=1
gen stop_usingEC=stop_using
gen stop_usingSIFEC=stop_usingSIF

replace stop_using_why_cc=subinstr(stop_using_why_cc, "difficult_to_conceive", "diff_conceive", .)
replace stop_using_why_cc=subinstr(stop_using_why_cc, "interferes_with_body", "interf_w_body", .)

foreach reason in infrequent pregnant wanted_pregnant husband more_effective no_method_available health_concerns ///
	side_effects no_access cost inconvenient fatalistic diff_conceive interf_w_body other {
	gen stop_usingEC_`reason'=stop_using_`reason'
	replace stop_usingEC_`reason'=. if current_recent_methodnum==8

	}

replace stop_usingEC="" if current_recent_methodnum==8
replace stop_usingSIFEC=. if current_recent_methodnum==8
*label val stop_usingEC whystoplist
gen future_user_not_currentEC=future_user_not_current
replace future_user_not_currentEC=. if current_recent_methodnum==8
gen future_user_pregnantEC=future_user_pregnant
replace future_user_pregnantEC=. if current_recent_methodnum==8

gen ECrecode=0 
replace ECrecode=1 if (regexm(current_recent_method, "emergency")) 



*******************************************************************************
* RECODE LAM
*******************************************************************************

tab LAM

* CRITERIA 1.  Birth in last six months
* Calculate time between last birth and date of interview
* FQdoi_corrected is the corrected date of interview
gen double FQdoi_correctedSIF=clock(FQdoi_corrected, "MDYhms")
format FQdoi_correctedSIF %tc

* Number of months since birth=number of hours between date of interview and date 
* of most recent birth divided by number of hours in the month
gen tsincebh=hours(FQdoi_correctedSIF-recent_birthSIF)/730.484
gen tsinceb6=tsincebh<6
replace tsinceb6=. if tsincebh==.
	* If tsinceb6=1 then had birth in last six months

* CRITERIA 2.  Currently ammenhoeric
gen ammen=0

* Ammenhoeric if last period before last birth
replace ammen=1 if menstrual_period==6

* Ammenhoerric if months since last period is greater than months since last birth
g tsincep	    	= 	menstrual_period_value if menstrual_period==3 // months
replace tsincep	    = 	int(menstrual_period_value/30) if menstrual_period==1 // days
replace tsincep	    = 	int(menstrual_period_value/4.3) if menstrual_period==2 // weeks
replace tsincep	    = 	menstrual_period_value*12 if menstrual_period==4 // years

replace ammen=1 if tsincep>tsincebh & tsincep!=.

* Only women both ammenhoerric and birth in last six months can be LAM
gen lamonly=1 if current_method=="LAM"
replace lamonly=0 if current_methodnumEC==14 & (regexm(current_method, "rhythm") | regexm(current_method, "withdrawal") | regexm(current_method, "other_traditional"))
gen LAM2=1 if current_methodnumEC==14 & ammen==1 & tsinceb6==1 
tab current_methodnumEC LAM2, miss
replace LAM2=0 if current_methodnumEC==14 & LAM2!=1

* Replace women who do not meet criteria as traditional method users
capture rename lam_probe_current lam_probe
capture confirm variable lam_probe
if _rc==0 {
capture noisily encode lam_probe, gen(lam_probev2) lab(yes_no_dnk_nr_list)
drop lam_probe
rename lam_probev2 lam_probe
	replace current_methodnumEC=14 if LAM2==1 & lam_probe==1
	replace current_methodnumEC=30 if lam_probe==0 & lamonly==0 & regexm(current_method, "rhythm")
	replace current_methodnumEC=31 if current_methodnumEC==14 & lam_probe==0  & lamonly==0 & regexm(current_method, "withdrawal") & !regexm(current_method, "rhythm")
	replace current_methodnumEC=39 if current_methodnumEC==14 & lam_probe==0  & lamonly==0 & regexm(current_method, "other_traditional") & !regexm(current_method, "withdrawal") & !regexm(current_method, "rhythm")
	replace current_methodnumEC=39 if lam_probe==1 & current_methodnumEC==14 & LAM2==0
	replace current_methodnumEC=. if current_methodnumEC==14 & lam_probe==0 & lamonly==1
	replace current_userEC=0 if current_methodnumEC==. | current_methodnumEC==-99
	}
	
else {
	replace current_methodnumEC=39 if LAM2==0
	}
	

drop tsince* ammen

*******************************************************************************
* RECODE First Method Female Sterilization
*******************************************************************************
replace current_methodnumEC=1 if first_methodnum==1

*REVISION-v18-22Mar2017 LZ - updated to account for sterilization probe, only relevant for RJ but included
*universally
capture replace current_methodnumEC=1 if sterilization_probe==1
*capture replace current_recent_method="female_sterilization" if sterilization_probe==1

*******************************************************************************
* RECODE Injectables_SC
*REVISION v19.0 08May2017 LZ
*REVIsION v20.0 09May2017 LZ fixed error in current_methodnumEC program
*REVISION v22.0 20 Jun 2017 fixed replacement to 16 only if most effective method is i
*injectable
*******************************************************************************
capture replace current_methodnumEC=16 if (injectable_probe_current==2 | injectable_probe_current==3) ///
& regexm(current_recent_method,"injectable")

capture replace recent_methodnumEC=16 if (injectable_probe_recent==2 | injectable_probe_recent==3)
gen first_methodnumEC=first_methodnum
capture replace first_methodnumEC=16 if injectable_probe_first==2

*******************************************************************************
* Define CP, MCP, TCP and longacting
*******************************************************************************
gen cp=0 if HHQ_result==1 & FRS_result==1 & (last_night==1)
replace cp=1 if HHQ_result==1 & current_methodnumEC>=1 & current_methodnumEC<=39 & FRS_result==1 & (last_night==1) 
label var cp "Current use of any contraceptive method"

gen mcp=0 if HHQ_result==1 & FRS_result==1 & (last_night==1)
replace mcp=1 if HHQ_result==1 & current_methodnumEC>=1 & current_methodnumEC<=19 & FRS_result==1 & (last_night==1)
label var mcp "Current use of any modern contraceptive method"

gen tcp=0 if HHQ_result==1 & FRS_result==1 & (last_night==1)
replace tcp=1 if HHQ_result==1 & current_methodnumEC>=30 & current_methodnumEC<=39 & FRS_result==1 & (last_night==1)
label var tcp "Current user of any traditional contraceptive method"

gen longacting=current_methodnumEC>=1 & current_methodnumEC<=4 & mcp==1
label variable longacting "Current use of long acting contraceptive method"
label val cp mcp tcp longacting yes_no_dnk_nr_list
/*
rename level1 `level1'
rename level2 `level2'
capture rename level3 `level3'
capture rename level4 `level4'
*/
sort metainstanceID member_number
//REVISION: BL 07Nov2017 respondent_firstname dropped 
*generate respondent flag
*gen respondent=1 if respondent_firstname==firstname & respondent_firstname!="" & firstname!="" &  (HHQ_result==1 | HHQ_result==5)
gen respondent=1 if firstname!="" & (HHQ_result==1 | HHQ_result==5)
replace respondent=0 if (HHQ_result==1 | HHQ_result==5) & respondent!=1
bysort metainstanceID: egen totalresp=total(respondent)
replace respondent=0 if totalresp>1 & totalresp!=. & relationship!=1 & relationship!=2


recast str244 names, force
saveold `CCRX'_Combined_ECRecode_$date.dta, replace version(12)


****************** KEEP GPS ONLY *******************
********************************************************************
preserve
keep if FQmetainstanceID!=""
*keep FQLatitude FQLongitude FQAltitude FQAccuracy FQmetainstanceID $GeoID
keep FQLatitude FQLongitude FQAltitude FQAccuracy RE FQmetainstanceID $GeoID household structure EA
*saveold `CCRX'_FQGPS_$date.dta, replace version(12)
export excel using "`CCRX'_FQGPS_$date.csv", firstrow(var) replace
restore

preserve
keep if metatag==1
*keep locationLatitude locationLongitude locationAltitude locationAccuracy metainstanceID $GeoID
keep locationLatitude locationLongitude locationAltitude locationAccuracy RE metainstanceID $GeoID household structure EA
rename location* HQ*
*saveold `CCRX'_HHQGPS_$date.dta, replace version(12)
export excel using "`CCRX'_HHQGPS_$date.csv", firstrow(var) replace

restore

****************** REMOVE IDENTIFYING INFORMATION *******************
*******************************************************************
capture rename facility_name* facility_nm*
drop *name* *Name* 
drop *Latitude *Longitude *Altitude *Accuracy location*
capture drop *GPS*
capture rename facility_nm* facility_name*
//REVISION:SJ drop phone number if there's any
capture drop flw_number_type

saveold `CCRX'_NONAME_ECRecode_$date.dta, replace version(12)





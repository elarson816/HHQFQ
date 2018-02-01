****PMA 2020  Data Quality Checks****
***Version Written in Bootcamp July 21-23, 2014****
**Second do file in series***

/************ Record of changes
*July 14, 2015 - revised destring of sanitation frequency and shared sanitation from 10 to 13
*September 1, 2015 - revised to allow for additional version of household form
*September 9, 2015 - revised water/sanitation indicators based on code from Sri Vedachalam
*October 5, 2015 - revised water/sanitation indicators again
*December 2, 2015 - included lines for generating country and round from macros in ParentFile
*December 11, 2015 - Sri updated water code
*December 14, 2015 - Linnea updated to include code for handwashing container
*January 22, 2016 - Linnea updated label lists to be consistent with ODK and codebook
*July 07, 2016 - Linnea updated to include changes to household questionnaire beginning with 
Ghana Round 5 (will not work on data collection conducted prior to July 2016)
*August 26 - SJ encoded water_reliability_1 - water_reliability_14
*October 25, 2016 - LZ- Replaced water sources main other, drinking, and main sanitation with _all if only one source
v13 - 1May2017-SJ dropped all commands related to photos as photos are no longer taken
*October 30, 2017 v14 - BL – 	removed labels for non-existant variables: respondent_firstname homestead_ask handwashing_place
*									handwashing_place_show 
*								added new variables: handwashing_place_rw water_main_drinking the_sanitation sanitation_where 
*									sanitation_vip_check sanitation_pit_with_slap_check
*								rename water new water variables to match old coding
*								water and sanitation facility questions asked for main water source only
*								sanitation_empty* variables added	
*								water_sources_main* now water_sources_all
*								respondent_firstname removed
* November 29, 2017 v16 - BL - 	added capture statements to hh_location_ladder and sanitation_empty_where_other
*/

clear matrix
clear

cd "$datadir"

/*This do file imports the Household Questionnaire (without the roster) into Stata and then cleans it*/

set more off

/*Import Household Questionnaire csv file into Stata.  There is a separate spreadsheet that has 
the roster information for each person.  Input now, but will merge later.  The loop is programmed to look
for questionnaire versions up to version 30.  If versions beyond version 30 are added, the values in the forval 
command below will need to be updated */  

/*generating a dataset with one variable so that all datasets can append to it.  Cannot append 
to a completely empty dataset */

local CCRX $CCRX
local HHQcsv $HHQcsv
local HHQcsv2 $HHQcsv2

set obs 1
gen x=.
save `CCRX'_HHQ.dta, replace

*Create a temporary file 
tempfile tempHHQ

/*If there are multiple versions during the same round, they should all be named the same thing other than ///
the version number. */


clear

	capture noisily insheet using "$csvdir/`HHQcsv'.csv", comma case
	tostring *, replace force
	
	save `tempHHQ', replace
	
	use `CCRX'_HHQ.dta
	append using `tempHHQ', force
	save, replace

	
/*If you need to add an extra version of the forms, this will check if that
version number exists and add it.  If the version does not, it will continue*/


clear

	capture noisily insheet using "$csvdir/`HHQcsv2'.csv", comma case
if _rc==0 {
	tostring *, replace force
	
	save `tempHHQ', replace
	
	use `CCRX'_HHQ.dta
	append using `tempHHQ', force
	save, replace	
}	

**Drop the single empty observation and empty variable x

use `CCRX'_HHQ.dta
drop in 1
drop x
save, replace


***Generate variable for country and round
gen country="$country"
label var country "Country"
gen round="$round"
label var round "Round of data collection"
order country round, first

*****DRC ONLY
capture rename quartier EA*

capture rename water_*refill water_*15
capture rename name_grp* *
rename date_group* *
rename *grp* **
rename assets_assets* assets*
rename s_* *
capture rename sanitation_all_sanitation_all sanitation_all
rename w_* *
rename livestock_* *


**Assign variable labels


label var times_visited					"Visit number"
label var your_name						"Resident Enumerator name"
label var your_name_check				"To RE: Is this your name?"
label var name_typed					"RE name is not correct"
label var system_date					"Date and Time"
label var system_date_check				"Confirm correct date and time"
label var manual_date					"If no, enter correct date"

******

label var EA							"EA"
label var structure						"Structure number"
label var household						"Household number"
label var hh_duplicate_check			"Have you already submitted a form for this structure/household?"
label var resubmit_reasons				"Reason for resubmission"


//REVISION: BL 31Oct2017 removed respondent_firstname, homestead_ask
//REVISION: BL v16 29Nov2017 added capture statement to hh_location_ladder
label var available						"Respondent present and available at least once"
capture label var previous_survey		"Previous PMA survey?"
label var begin_interview				"May I begin"
label var consent_obtained				"Consent obtained" 
label var witness_auto					"Interviewer name"
label var witness_manual				"Name check"
*label var respondent_firstname			"Name of respondent"
*label var SETOFHH_member				"Household Member hyperlink"
label var num_HH_members				"Number of household members in the roster"
label var heads							"Number of heads of households"
label var names							"Names in household"
label var respondent_in_roster			"Check that respondent is in the roster"
label var roster_complete				"Check that Roster is completed"
label var assets						"List of Household Assets"
label var assets_check					"Question 10 Check"
capture label var hh_location_ladder			"Location of house on wealth ladder: 1 = poorest, 10 = wealthiest"
label var owned_ask						"Do you own livestock"
label var owned_livestock_own			"Total number of livestock owned"
*label var homestead_ask 				"Livestock on homestead"


//REVISION: BL 31Oct2017 removed handwashing_place, handwashing_place_show
*						 added handwashing_place_rw
label var floor								"Main floor material"
label var roof								"Main roof material"
label var walls								"Main exterior wall material"
label var handwashing_place_rw				"Can you show me where members most often wash their hands?"
*label var handwashing_place				"Place to wash your hands"
*label var handwashing_place_show			"Can you show it to me?"
label var handwashing_place_observations	"At handwashing observe soap, water, sanitation"
*rename water_sources_all_water_sourc water_sources_all


//REVISION: BL 31Oct2017 rename water variables
rename water_main_drinking_select water_sources_main_drinking
rename water_main_other water_sources_main_other

//REVISION: Bl 31Oct2017 added water_main_drinking
label var water_sources_all					"Which water sources used for any purpose"
label var number_of_sources					"Number of sources in water_sources_all"
label var water_sources_main_drinking 		"Main source of drinking water"
label var water_sources_main_other			"Main source of cooking/ handwashing water"
label var source_labels						"Water sources mentioned"
label var water_main_drinking				"Main drinking water among all sources mentioned"
*label var water_sources					"Water sources check"


//REVISION: BL 31Oct2017 only asked for main water source
/*
capture rename water_seasonality_* water_months_avail_*

forvalue x = 1/15{
capture label var water_uses_`x'					"Use of water source `x'"
capture label var water_months_avail_`x'			"Availability of water source `x' during year"
capture label var water_reliability_`x'				"Availability of water source `x' 	when expected"
capture label var water_collection_`x'				"Minutes in round trip to water source `x'"
}
*/
label var water_uses 						"Use of main water source"
label var water_months_avail				"Availability of main water source during year"
label var water_reliability					"Availability of main water source when expected"
label var water_collection					"Minutes in round trip to main water source"


//REVISION: BL 31Oct2017 the_sanitation sanitation_where sanitation_vip_check & sanitation_pit_with_slap_check added
* label var garden					"Have a garden"
label var sanitation_all					"Use any of the following toilet facilities"
capture label var sanitation_all_other		"Other toilet facility specified"
label var number_of_sanitation				"Total number of toilet facilities"
label var sanitation_main					"Main toilet facility"
label var sanitation_labels					"Toilet facilities mentioned"
*label var sanitation_sources				"Check sanitation"
capture label var sanitation_vip_check 				"Latrine has ventilation pipe"
capture label var sanitation_pit_with_slab_check  	"Latrine has cement slab"
capture label var sanitation_where					"Location of toilet facility"
drop the_sanitation


//REVISION: BL 31Oct2017 sanitation_empty* added
//REVISION: BL v16 29Nov2017 added capture statement to sanitation_empty_where_other
destring sanitation_empty_value, replace
label define dwmy_list 1 days 2 weeks 3 months 4 years -88 "-88" -99 "-99"
encode sanitation_empty_units, gen(sanitation_empty_unitsv2) lab(dwmy_list)
label var sanitation_empty_units			"Days, weeks, months, or years since toilet facility was emptied"
label var sanitation_empty_value			"Number of days, weeks, months, or years since toilet facility was emptied"

label var sanitation_empty_who 				"Last person to empty toilet facility"
label var sanitation_empty_where			"Last place toilet facilities were emptied to"
capture label var sanitation_empty_where_other		"Other emptied location specified"

label define sanitation_who 1 neighbors 2 provider 3 other -88 "-88" -99 "-99"
encode sanitation_empty_who, gen(sanitation_empty_whov2) lab(sanitation_who)

label define sanitation_where 1 covered_hold 2 open_water 3 open_ground ///
	4 taken_facility 5 taken_dnk 6 other -88 "-88" -99 "-99"
encode sanitation_empty_where, gen(sanitation_empty_wherev2) lab(sanitation_where)


//REVISION: BL 31Oct2017 only asked of main sanitation facility
*rename *flushpit* *fp*
/*
forvalue x = 1/13{
capture label var sanitation_frequency_`x'_cc		"How often use toilet facility `x'"
capture label var shared_san_`x'			"Share toilet `x' with other households/public?"
capture label var shared_san_hh_`x'		"Number HH share toilet `x' facility"
}

capture label var sanitation_frequency_fp_cc		"How often use toilet facility flush pit"
capture label var shared_san_fp			"Share toilet flush pit with other households/public?"
capture label var shared_san_hh_fp  	"Number HH share flush pit facility"
*/
label var sanitation_frequency_cc 			"How often use toilet facility"
label var shared_san 						"Share toilet facility with other households/public"
label var shared_san_hh						"Number of HH that share toilet facility"

label var bush_use							"How many people use bush"
label var minAge							"Minimum age of children listed in household"
label var thankyou							"Thank you"
*label var location_photo_result			"Location and photo screen"
label var locationLatitude					"Latitude"
label var locationLongitude					"Longitude"
label var locationAltitude					"Altitude"
label var locationAccuracy					"Accuracy"
capture label var HH_photo					"Hyperlink to photo"
label var HHQ_result						"HHQ Result"
label var start								"Start time"
label var end								"End time"
label var deviceid							"deviceid"
label var simserial							"simserial"

label var metainstanceID					"Household Unique ID - ODK"
capture label var handwashing_container_show "Moveable container available in the household" 

*e. All variables are forced to string to make sure nothing is dropped when appending.  Most variables need to be
*destrung and/or encoded before analysis.  Destring variables (if numbers are stored as string) or encode (if values are in character but can be categories)


capture destring version, replace
destring times_visited, replace
destring structure, replace
destring household, replace
destring num_HH_members, replace
destring heads, replace
destring assets_check, replace
destring EA, replace

destring owned_livestock_own, replace


//REVISION: BL 31Oct2017 shared_san_hh* now shared_san_hh
destring number_of_sources, replace
destring number_of_sanitation, replace
destring shared_san_hh, replace
*destring shared_san_hh_*, replace
*destring shared_san_fp, replace
destring water_collection*, replace
*destring water_months_avail_*, replace

destring bush_use, replace
destring minAge, replace
destring consent_obtained, replace


*Assign value lables.  This should be done before the encoding step to ensure the right number of values
*are encoded
capture drop label, _all


label define yes_no_dnk_nr_list 0 no 1 yes -88 "-88" -99 "-99"

//REVISION: SJ 1MAY2017 takes out photo_permission
//REVISION: BL 31Oct2017 remove handwashing_place_show homestead_ask
foreach var of varlist your_name_check system_date_check hh_duplicate_check available ///
		begin_interview owned_ask roster_complete  {
encode `var', gen(`var'v2) lab(yes_no_dnk_nr_list)
}

*capture encode handwashing_place_show, gen(handwashing_place_showv2) lab(yes_no_dnk_nr_list
label val consent_obtained yes_no_dnk_nr_list

capture encode garden, gen(gardenv2) lab(yes_no_dnk_nr_list)

label define resubmit_reason_list 1 new_members 2 correction 3 dissappeared 4 not_received 5 other
*encode resubmit_reasons, gen(resubmit_reasonsv2) lab(resubmit_reason_list)


label define soap_list 1 soap 2 stored_water 3 tap_water 4 near_sanitation -77 "-77"
encode handwashing_place_observations, gen(handwashing_place_observationsv2) lab(soap_list)
replace water_sources_main_drinking=water_sources_all if number_of_sources==1
replace water_sources_main_other=water_sources_all if number_of_sources==1

label define water_source_list 1 piped_indoor 2 piped_yard 3 piped_public 4 tubewell ///
	5 protected_dug_well 6 unprotected_dug_well 7 protected_spring ///
	8 unprotected_spring 9 rainwater 10 tanker 11 cart 12 surface_water ///
	13 bottled 14 sachet 15 refill -99 "-99"

encode water_sources_main_drinking, gen(water_sources_main_drinkingv2) lab(water_source_list)
encode water_sources_main_other, gen(water_sources_main_otherv2) lab(water_source_list)


*foreach source in bottled cart piped_indoor piped_public piped_yard protected_dug_well protected_spring rainwater ///
*	sachet surface_water tubewell unprotected_dug_well unprotected_spring {
*	gen water_sources_`source'=1 if regexm(water_sources_all, "`source'")

	
replace sanitation_main=sanitation_all if number_of_sanitation==1
label define sanitation_list 1 flush_sewer 2 flush_septic 3 flush_elsewhere 4 flush_unknown 5 vip ///
	6 pit_with_slab 7 pit_no_slab 8 composting 9 bucket 10 hanging 11 other 12 bush 13 flushpit 14 bush_water_body -99 "-99" 
encode sanitation_main, gen(sanitation_mainv2) lab(sanitation_list)

//REVISION: BL 31Oct2017 replace handwashing_place with handwashing_place_rw
*encode handwashing_place, gen(handwashing_placev2) lab(yes_no_dnk_nr_list)
label define handwash_list 1 observed_fixed 2 observed_mobile 3 not_here 4 no_permission ///
	5 not_observed_other -99 "-99"
encode handwashing_place_rw, gen(handwashing_place_rwv2) lab(handwash_list)

label define frequency_of_use_list_v2 1 always 2 mostly 3 occasionally -99 "-99"
label define shared_san_list 1 not_shared 2 shared_under_ten_HH 3 shared_above_ten_HH ///
4 shared_public -99 "-99"

//REVISION: BL 31Oct2017 sanitation_frequency only asked of main sanitation facility
/*
forvalue x = 1/10 {
capture encode sanitation_frequency_`x'_cc, gen(sanitation_frequency_`x'_ccv2) ///
lab(frequency_of_use_list_v2)

capture encode shared_san_`x', gen(shared_san_`x'v2) lab(shared_san_list)
replace shared_san_`x'v2=. if shared_san_`x'==""
}
*/
encode sanitation_frequency_cc, gen(sanitation_frequency_ccv2) lab(frequency_of_use_list_v2)
encode shared_san, gen(shared_sanv2) lab(shared_san_list)
replace shared_sanv2=. if shared_san==""


capture encode shared_san_fp, gen(shared_san_fpv2) lab(shared_san_list)

//REVISION: BL 31Oct2017 sanitation_frequency_fp_cc removed
*encode sanitation_frequency_fp_cc, gen(sanitation_frequency_fp_ccv2) ///
*lab(frequency_of_use_listv2)


//REVISION: BL 31Oct2017 water_reliability asked of main source only
* water_reliability
/*
label define continuity_list 1 always 2 predictable 3 unpredictable -99 "-99"
forvalue x = 1/15 {
capture encode water_reliability_`x', gen(water_reliability_`x'v2) lab(continuity_list)
}
*/
label define continuity_list 1 always 2 predictable 3 unpredictable -99 "-99"
encode water_reliability, gen(water_reliabilityv2) lab(continuity_list)

*************
label define hhr_result_list 1 completed 2 not_at_home 3 postponed 4 refused 5 partly_completed 6 vacant 7 destroyed ///
	8 not_found 9 absent_extended_period
encode (HHQ_result), gen(HHQ_resultv2) lab(hhr_result_list)


*Participated in previous survey
capture label var previous_survey		"Previously participated in PMA 2020 survey - household"
capture encode previous_survey, gen(previous_surveyv2) lab(yes_no_dnk_nr_list)
		
unab vars: *v2
local stubs: subinstr local vars "v2" "", all
foreach var in `stubs'{
rename `var' `var'QZ
order `var'v2, after(`var'QZ)
}
rename *v2 *
drop *QZ

//REVISION: BL 31Oct2017 Asked of main water source only
/*
forval y=1/15{
foreach use in drinking cooking washing livestock business gardening {
capture confirm variable water_uses_`y'
if _rc==0{
gen water_uses_`y'_`use'=.
replace water_uses_`y'_`use'=0 if water_uses_`y'!=""  
replace water_uses_`y'_`use'=1 if (regexm(water_uses_`y', "`use'"))
replace water_uses_`y'_`use'=. if water_uses_`y'=="-99"
}
}
}
*/
foreach use in drinking cooking washing livestock business gardening {
	gen water_uses_`use'=.
		replace water_uses_`use'=0 if water_uses!=""
		replace water_uses_`use'=1 if (regexm(water_uses, "`use'"))
		replace water_uses_`use'=. if water_uses=="-99"
	}

	
//REVISION: BL 31Oct2017 respondent_firstname removed
*duplicates tag EA structure household respondent_firstname, gen (dupHQsurvey)
*tab dupHQsurvey

*****************************Changing time variables*****************************
**Change the date variables into clock time

*replace date_groupc if missing
*replace system_date=manual_date if system_date_check==0 

**Change date variable of upload from scalar to stata time (SIF)
*Drop the day of the week of the interview and the UST
gen double SubmissionDateSIF=clock(SubmissionDate, "MDYhms")
format SubmissionDateSIF %tc

**Change start and end times into SIF to calculate time
*Have to do the same procedures.  Using the end time of the survey as the day of the survey
gen double startSIF=clock(start, "MDYhms")
format startSIF %tc

gen double endSIF=clock(end, "MDYhms")
format endSIF %tc

rename your_name RE
replace RE=name_typed if your_name_check==0

**Check any complete duplicates, duplicates of metainstanceid, and duplicates of structure and household numbers
duplicates report
duplicates report metainstanceID
duplicates tag metainstanceID, gen (dupmeta)


*******Round specific questions
capture confirm var collect_water_dry 
if _rc==0{
label var 	collect_water_dry			"Time collect water - DRY season"
label var	collect_water_dry_value		"Value - collect water dry"
label var	collect_water_wet			"Time collect water - WET season"
label var 	collect_water_wet_value		"Value - collect water wet"

label define collect_water_list 1 minutes 2 hours 3 someone_else 4 no_one -88 "-88" -99 "-99"
encode collect_water_dry, gen(collect_water_dryv2) lab(collect_water_list)
encode collect_water_wet, gen(collect_water_wetv2) lab(collect_water_list)

destring collect_water_dry_value, replace
destring collect_water_wet_value, replace
}

//REVISION: BL 31Oct2017 question asked in all rounds
*capture confirm var child_feces
*if _rc==0{
*Child Feces
label var child_feces					"What do you do with children's waste"

*child_feces is multi-select, need to change to binary
gen child_feces_burn=0 if child_feces!=""
replace child_feces_burn=1 if (regexm(child_feces, ["burn"]))

gen child_feces_latdisp=0 if child_feces!=""
replace child_feces_latdisp=1 if (regexm(child_feces, ["latrine_disposal"]))

gen child_feces_bury=0 if child_feces!=""
replace child_feces_bury=1 if (regexm(child_feces, ["bury"]))

gen child_feces_garbage=0 if child_feces!=""
replace child_feces_garbage=1 if (regexm(child_feces, ["garbage"]))

gen child_feces_manure=0 if child_feces!=""
replace child_feces_manure=1 if (regexm(child_feces, ["manure"]))

gen child_feces_leave=0 if child_feces!=""
replace child_feces_leave=1 if (regexm(child_feces, ["leave"]))

gen child_feces_waste_water=0 if child_feces!=""
replace child_feces_waste_water=1 if (regexm(child_feces, ["waste_water"]))

gen child_feces_latused=0 if child_feces!=""
replace child_feces_latused=1 if (regexm(child_feces, ["latrine_used"]))
*r}



save `CCRX'_HHQ_$date.dta, replace


/*Water sources code updated to be consistent with Sri Vedachalam code
V11 25 Oct 2016 - LZ - updated to make consistent definition of improved and unimproved across all countries
	bottled water is improved only if an improved source is used for washing/cleaning.  Unimproved if washing/cleaning 
	source is unimproved or also bottled water
*v12 - 03.23.2017 - LZ - added capture statement 
*v13 - 07.17.2017 - NGE - recategorized "Tanker truck/cart with small tank" to improved water source per JMP new definition
*v14 - 08.28.2017 - NGE - fixed typo 
*V15 - 09.18.2017- LZ - fixed duplicate label that was causing error
*v16 – 11.10.2017 – BL –	shared_san only asked for main sanitation facility
							sanitation_frequency_* dropped and replaced with sanitation_frequency_cc
*v17 - 11.14.2017 - SJ - destring water availability, encode sanitation where
*v18 - 12.12.2017 - NGE - recode main drinking other sources

*/
capture drop water_source_list_cc
input str60 water_source_list_cc
	piped_indoor
	piped_yard
	piped_public
	tubewell
	protected_dug_well
	unprotected_dug_well
	protected_spring
	unprotected_spring
	rainwater
	tanker
	cart
	surface_water
	bottled
	sachet
	refill
	-99
end

* Replace water_sources_main_drnk equal to response in water_sources_all if only provided one source
gen water_sources_single=water_sources_all if !regexm(water_sources_all,"") & water_sources_all!="-99" & water_sources_all!=""

forvalue i=1/16 {
	replace water_sources_single="`i'" if water_sources_single==water_source_list[`i']
}
destring water_sources_single, replace
replace water_sources_main_drinking=water_sources_single if water_sources_main_drinking==.

//REVISION: SJ 14NOV destring water availability
destring water_months_avail, replace

* Replace water_source_main_other equal to response in water_sources_all if only provided one source
replace water_sources_main_other=water_sources_single if water_sources_main_other==.

gen main_drinking_rc=.
replace main_drinking_rc=1 if water_sources_main_drinking==1 | water_sources_main_drinking==2 
replace main_drinking_rc=2 if water_sources_main_drinking==3 
replace main_drinking_rc=3 if water_sources_main_drinking==4
replace main_drinking_rc=4 if water_sources_main_drinking ==5 
replace main_drinking_rc=5 if water_sources_main_drinking ==7 
replace main_drinking_rc=6 if water_sources_main_drinking ==9 
replace main_drinking_rc=7 if water_sources_main_drinking==13   
replace main_drinking_rc=8 if water_sources_main_drinking==6  
replace main_drinking_rc=9 if water_sources_main_drinking==8 
replace main_drinking_rc=10 if water_sources_main_drinking==10 | water_sources_main_drinking==11  
replace main_drinking_rc=11 if water_sources_main_drinking==12 
replace main_drinking_rc=12 if water_sources_main_drinking==14 
replace main_drinking_rc=13 if water_sources_main_drinking==15 

*v18 - 12.12.2017 - NGE - recode main drinking other sources
gen main_drinking_other_rc=.
replace main_drinking_other_rc=1 if water_sources_main_other==1 | water_sources_main_other==2 
replace main_drinking_other_rc=2 if water_sources_main_other==3 
replace main_drinking_other_rc=3 if water_sources_main_other==4
replace main_drinking_other_rc=4 if water_sources_main_other ==5 
replace main_drinking_other_rc=5 if water_sources_main_other ==7 
replace main_drinking_other_rc=6 if water_sources_main_other ==9 
replace main_drinking_other_rc=7 if water_sources_main_other==13   
replace main_drinking_other_rc=8 if water_sources_main_other==6  
replace main_drinking_other_rc=9 if water_sources_main_other==8 
replace main_drinking_other_rc=10 if water_sources_main_other==10 | water_sources_main_other==11  
replace main_drinking_other_rc=11 if water_sources_main_other==12 
replace main_drinking_other_rc=12 if water_sources_main_other==14 
replace main_drinking_other_rc=13 if water_sources_main_other==15 

* Generate percentage values for (total) improved versus not improved main water sources for drinking purposes
*REVISION - v13-17Jul2017-nge recategorize "Tanker truck/cart with small tank" to improved water source per JMP new definition
gen main_drinking_class=. 
replace main_drinking_class=1 if main_drinking_rc==1 | main_drinking_rc==2 | main_drinking_rc==3 | ///
main_drinking_rc==4 | main_drinking_rc==5 | main_drinking_rc==6 | main_drinking_rc==10 | main_drinking_rc==12 | main_drinking_rc==13

replace main_drinking_class=0 if main_drinking_rc==8 | main_drinking_rc==9 |  main_drinking_rc==11 

*REVISION - v13-17Jul2017-nge recategorize "Tanker truck/cart with small tank" to improved water source per JMP new definition
replace main_drinking_class=1 if main_drinking_rc==7 & (water_sources_main_other>=1 & water_sources_main_other<=5 ///
| water_sources_main_other==7 | water_sources_main_other==9 | water_sources_main_other==10)
replace main_drinking_class=0 if main_drinking_rc==7 & (water_sources_main_other>=6 & water_sources_main_other<=8 ///
| water_sources_main_other>=11 & water_sources_main_other!=.)

* Label new water variables
lab var main_drinking_rc "Main source of drinking water (recode)"
lab var main_drinking_class "Classification of main source of drinking water (improved/unimproved)"

* Label new water varibles' response options
label define classl 1 "Improved" 0 "Unimproved" 
label val main_drinking_class classl 

label define water_sourcel 1 "Piped into dwelling/yard" 2 "Public tap/standpipe" ///
 3 "Tubewell/bore hole" 4 "Protected well" 5 "Protected spring" 6 "Rainwater" 7 "Bottled (Improved and unimproved)" ///
 8 "Unprotected well" 9 "Unprotected spring" 10 "Tanker truck/cart with small tank" 11 "Surface water" ///
 12 "Sachet" 13 "Refill" 
label val main_drinking_rc water_sourcel 
*v18 - 12.12.2017 - NGE - recode main drinking other sources
label val main_drinking_other_rc water_sourcel 

* Order new water variables
capture order water_sources_single main_drinking_rc main_drinking_class, after(water_collection_14)
capture water_sources_single main_drinking_rc main_drinking_class, after(water_collection_15)

/*
label define continuity_list 1 always 2 predictable 3 unpredictable -99 "-99"
label define availability_list 1 all_year 2 some_of_year 3 small_part_of_year -99 "-99"
forval y=1/15{
capture confirm var water_seasonality_`y'
if _rc==0{
encode water_seasonality_`y', gen(water_seasonality_`y'cc) lab(availability_list)
encode water_reliability_`y', gen(water_reliability_`y'cc) lab(continuity_list)
}
}
*/

***Sanitation
*label define frequency_of_use_list_cc 1 always 2 mostly 3 occasionally -99 "-99"
/*
forval x=1/13{
capture confirm var sanitation_frequency_`x'
if _rc==0{
encode sanitation_frequency_`x', gen(sanitation_frequency_`x') lab(frequency_of_use_list_cc)
}
}


label define shared_san_list 1 not_shared 2 shared_under_ten_HH 3 shared_above_ten_HH 4 shared_public -99 "-99"
	forval y=1/13{
	capture confirm var shared_san_`y'
	if _rc==0{
encode shared_san_`y', gen (shared_san_`y'cc) lab(shared_san_list)

	}
}
*/


* Generate variables for improved (not shared/shared) and unimproved sanitation facilities 
gen sanitation_main_rc=.

* Facilities considered improved
	* 1: flush/pour flush to piped sewer system
	* 2: flush/ pour flush to septic tank or pit latrine
	* 3: ventilated improved pit latrine
	* 4: pit latrine with slab
	* 5: composting toilet

//REVISION – v16 BL 07Nov2017 shared_san only asked for main sanitation facility	
*replace sanitation_main_rc=1 if (sanitation_main==1 | sanitation_all =="flush_sewer") & shared_san_1==1
*replace sanitation_main_rc=2 if (sanitation_main==2 | sanitation_all =="flush_septic" ) & (shared_san_2==1)
replace sanitation_main_rc=1 if (sanitation_main==1 | sanitation_all=="flush_sewer") & shared_san==1
replace sanitation_main_rc=2 if (sanitation_main==2 | sanitation_all=="flush_septic") & shared_san==1
capture replace sanitation_main_rc=2 if (sanitation_main==13 | sanitation_all=="flushpit) & (shared_san_fp==1)

*REVISION v12 - 03.23.2017 - LZ - added capture statement 
*capture replace sanitation_main_rc=2 if (sanitation_main==13 | sanitation_all =="flushpit") & (shared_san_fp==1)
 
*replace sanitation_main_rc=3 if (sanitation_main==5 | sanitation_all =="vip") & shared_san_5==1
*replace sanitation_main_rc=4 if (sanitation_main==6 | sanitation_all =="pit_with_slab") & shared_san_6==1
*replace sanitation_main_rc=5 if (sanitation_main==8 | sanitation_all == "composting") & shared_san_8==1
replace sanitation_main_rc=3 if (sanitation_main==5 | sanitation_all=="flushpit") & shared_san==1
replace sanitation_main_rc=4 if (sanitation_main==6 | sanitation_all=="vip") & shared_san==1
replace sanitation_main_rc=5 if (sanitation_main==8 | sanitation_all=="composting") & shared_san==1

* Facilities that would be considered improved if they were not shared by two or more households
	* 6: flush/pour flush to piped sewer system
	* 7: flush/ pour flush to septic tank or pit latrine
	* 8: ventilated improved pit latrine
	* 9: pit latrine with slab
	* 10: composting toilet

*replace sanitation_main_rc=6 if (sanitation_main==1 | sanitation_all =="flush_sewer") & (shared_san_1 !=1 & shared_san_1 !=.)
*replace sanitation_main_rc=7 if (sanitation_main==2 | sanitation_all =="flush_septic") & (shared_san_2 !=1 & shared_san_2 !=.) 
replace sanitation_main_rc=6 if (sanitation_main==1 | sanitation_all=="flush_sewer") & (shared_san!=1 & shared_san!=.)
replace sanitation_main_rc=7 if (sanitation_main==2 | sanitation_all=="flush_septic") & (shared_san!=1 & shared_san!=.)


*REVISION v12 - 03.23.2017 - LZ - added capture statement 
*capture replace sanitation_main_rc=7 if (sanitation_main==13| sanitation_all =="flushpit") & (shared_san_fp !=1 & shared_san_fp !=.)
*replace sanitation_main_rc=8 if (sanitation_main==5 | sanitation_all =="vip") & (shared_san_5 !=1 & shared_san_5 !=.)
*replace sanitation_main_rc=9 if (sanitation_main==6 | sanitation_all =="pit_with_slab") & (shared_san_6 !=1 & shared_san_6 !=.)
*replace sanitation_main_rc=10 if (sanitation_main==8 | sanitation_all == "composting") & (shared_san_8 !=1 & shared_san_8 !=.)
capture replace sanitation_main_rc=7 if (sanitation_main==13 | sanitation_all=="flushpit") & (shared_san_fp!=1 	& shared_san_fp!=.)
replace sanitation_main_rc=8 if (sanitation_main==5 | sanitation_all=="vip") & (shared_san!=1 & shared_san!=.)
replace sanitation_main_rc=9 if (sanitation_main==6 | sanitation_all=="pit_with_slab") & (shared_san!=1 & shared_san!=.)
replace sanitation_main_rc=10 if (sanitation_main==8 | sanitation_all=="composting") & (shared_san!=1 & shared_san!=.)
		
* Non improved facilities 
	* 11: Flush/ pour flush not to sewer/septic tank
	* 12: Pit latrine without slab/bucket toilet
	* 13: Hanging toilet/hanging latrine
	* 14: No facility/bush/field
	* 15: Bush(water body)
	* 16: Other
	* -99: Missing 
	
*replace sanitation_main_rc=11 if shared_san_3 !=. | shared_san_4 !=.
*replace sanitation_main_rc=12 if shared_san_7 !=. | shared_san_9 !=.
*replace sanitation_main_rc=13 if shared_san_10 !=. 
*replace sanitation_main_rc=14 if sanitation_main==12 | sanitation_all=="bush"
*replace sanitation_main_rc=15 if sanitation_main==14 | sanitation_all=="bush_water_body"
*replace sanitation_main_rc=16 if sanitation_main==11 | sanitation_all=="other"
*replace sanitation_main_rc=-99 if sanitation_main_cc==.
replace sanitation_main_rc=11 if sanitation_main==3 | sanitation_main==4 | sanitation_all=="flush_elsewhere" | sanitation_all=="flush_unknown"
replace sanitation_main_rc=12 if sanitation_main==7 | sanitation_main==9 | sanitation_all=="pit_no_slab" | sanitation_all=="bucket"
replace sanitation_main_rc=13 if sanitation_main==10 | sanitation_all=="hanging"
replace sanitation_main_rc=14 if sanitation_main==12 | sanitation_all=="bush"
replace sanitation_main_rc=15 if sanitation_main==14 | sanitation_all=="bush_water_body"
replace sanitation_main_rc=16 if sanitation_main==11 | sanitation_all=="other"


* The 16 sanitation facilities are now aggregated into 4 main types using the DHS classification
* 1= Improved, not shared facility 
* 2= Improved, Shared facility
* 3= Non-improved facility 
* 4= Open defecation

gen sanitation_main_class=.
replace sanitation_main_class=1 if sanitation_main_rc==1 | sanitation_main_rc==2 | sanitation_main_rc==3 | sanitation_main_rc==4 | sanitation_main_rc==5
replace sanitation_main_class=2 if sanitation_main_rc==6 | sanitation_main_rc==7 | sanitation_main_rc==8 | sanitation_main_rc==9 | sanitation_main_rc==10
replace sanitation_main_class=3 if sanitation_main_rc==11 | sanitation_main_rc==12 |sanitation_main_rc==13 | sanitation_main_rc==16 | sanitation_main_rc==-99
replace sanitation_main_class=4 if sanitation_main_rc==14 | sanitation_main_rc==15 // includes only bush (#14) and bush_water_body (#15)[in case of ID]; other (#16) and missing (-99) are categorized as unimproved as per DHS criteria
label define sanitation_main_classl 1 "Improved, not shared facility" 2 "Shared Facility" 3 "Non-improved facility" 4 "Open defecation"
label values sanitation_main_class sanitation_main_classl

* Label new sanitation variables
lab var sanitation_main_rc "Main source of sanitation (recode)"
lab var sanitation_main_class "Classification of the main source of sanitation"

* Label new sanitation varibles' response options
*fixed typo changed "sanitation_main_class" to "sanitation_main_classl":
**REVISION v15.0 fixed duplicate label definition
*label define sanitation_main_classl 1 "Improved, not shared facility" 2 "Shared Facility" ///
3 "Non-improved facility" 4 "open defecation"
label val sanitation_main_class sanitation_main_classl

label define sanitation_main_rcl 1 "Flush/pour flush to piped sewer system" ///
2 "Flush/pour flush to septic tank" 3 "Ventilated improved pit latrine" 4 "Pit latrine with slab" ///
5 "Composting toilet" 6 "Shared-flush/pour flush to piped sewer system" ///
7 "Shared-flush/ pour flush to septic tank" 8 "Shared-ventilated improved pit latrine" ///
9 "Shared-pit latrine with slab" 10 "Shared-composting toilet" 11 "Flush/ pour flush not to sewer/septic tank" ///
12 "Pit latrine without slab/bucket toilet" 13 "Hanging toilet/hanging latrine" 14 "No facility/bush/field" ///
15 "Bush (water body)" 16 "Other" -99 "Missing"
label values sanitation_main_rc sanitation_main_rcl

* Order new sanitation varriables 
//REVISION – v16 – BL 07Nov2017 sanitation_frequency_* dropped and replaced with sanitation_frequency_cc
*order sanitation_main_rc sanitation_main_class, after(sanitation_frequency_12)
*capture order sanitation_main_rc sanitation_main_class, after(sanitation_frequency_13)
order sanitation_main_rc sanitation_main_class, after(sanitation_frequency_cc)

* Drop unnecessary WASH variables
capture drop water_source_list_cc 
capture drop water_sources_single
capture drop watersourcelist

//REVISION SJ 14NOV2017 encode sanitation_where
label define sanitation_where_list 1 "dwelling" 2 "yard" -77 "-77" -99 "-99"
encode sanitation_where, gen(sanitation_wherev2) lab(sanitation_where_list)
label var sanitation_wherev2 "Where is your toilet"

unab vars: *v2
local stubs: subinstr local vars "v2" "", all
foreach var in `stubs'{
rename `var' `var'QZ
order `var'v2, after (`var'QZ)
}
rename *v2 *



save, replace

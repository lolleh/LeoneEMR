SET sql_safe_updates = 0;

SET @sbcuRegister = (SELECT encounter_type_id FROM encounter_type WHERE uuid = '3790ecc6-bc63-48f8-9104-f81dc90ee21c');


DROP TEMPORARY TABLE IF EXISTS temp_sbcu;
CREATE TEMPORARY TABLE temp_sbcu
(
patient_id				    int(11),
emr_id					    varchar(25),
encounter_id			    int(11),
creator					    int(11),
user_entered			    varchar(255),
date_entered			    datetime,
encounter_location_id	    int(11),
encounter_location		    varchar(255),
chart_number			    text,
arrival_datetime		    datetime,
referred_from			    varchar(255),
referred_from_other		    text,
referred_other_PIH_site	    text,
referred_non_PIH_site	    text,
referral_reason			    varchar(255),
referral_reason_other	    text,
referred_by				    varchar(255),
referred_by_other			text,
management_datetime		    datetime,
provider 				    varchar(255),
admission_datetime		    datetime,
admission_age_days		    int,
admission_age_hours		    int,
baby_sex				    varchar(255),
baby_admission_weight	    double,
delivery_place			    varchar(255),
delivery_place_other        text,
delivery_facility		    varchar(255),
delivery_facility_other	    text,
number_of_anc			    int,
delivery_mode			    varchar(255),
prior_diagnoses_coded	    varchar(1000),
prior_diagnoses_noncoded	text,
treatment_provided_coded	varchar(1000),
treatment_provided_noncoded	varchar(255),
APGAR_1_min_numeric		    int,
APGAR_1_min_coded		    varchar(255),
APGAR_5_min_numeric		    int,
APGAR_5_min_coded		    varchar(255),
assisted_ventilation	    varchar(255),
birth_weight			    double,
gestation_age			    double,
admission_problems		    varchar(1000),
admission_problems_other	text,
supportive_care			    varchar(1000),
supportive_care_other	    text,
scbu_outcome			    varchar(255),
death_construct_obs_id		int(11),
death_outcome			    bit,
death_datetime			    datetime,
cause_of_death			    varchar(255),
other_cause				    text,
death_age_days			    int,
death_weight			    double,
discharge_datetime		    datetime,
staff_completing		    text
);

insert into temp_sbcu(patient_id, encounter_id, arrival_datetime, date_entered, creator, encounter_location_id)   
select e.patient_id,  e.encounter_id, e.encounter_datetime, e.date_created, e.creator, e.location_id  from encounter e
where e.encounter_type = @sbcuRegister
and e.voided = 0
and ((date(e.encounter_datetime) >= date(@startDate)) or @startDate is null)
and ((date(e.encounter_datetime) <= date(@endDate)) or @endDate is null);

create index temp_sbcu_ei on temp_sbcu(encounter_id);

update temp_sbcu 
set emr_id = patient_identifier(patient_id, '1a2acce0-7426-11e5-a837-0800200c9a66');  -- wellbody id

update temp_sbcu 
set user_entered  = username(creator);

update temp_sbcu 
set encounter_location = location_name(encounter_location_id);

update temp_sbcu 
set chart_number = obs_value_text(encounter_id, 'PIH','14396');

update temp_sbcu 
set referred_from = obs_value_coded_list(encounter_id, 'PIH','7454',@locale);

update temp_sbcu 
set referred_from_other = obs_comments(encounter_id, 'PIH','7454','PIH','5622');

update temp_sbcu 
set referred_other_PIH_site = obs_comments(encounter_id, 'PIH','7454','PIH','11956');

update temp_sbcu 
set referred_non_PIH_site = obs_comments(encounter_id, 'PIH','7454','PIH','8856');

update temp_sbcu 
set referral_reason = obs_value_coded_list(encounter_id, 'PIH','12879',@locale);

update temp_sbcu 
set referral_reason_other = obs_value_text(encounter_id, 'PIH','14420');

update temp_sbcu 
set referred_by = obs_value_coded_list(encounter_id, 'PIH','10635',@locale);

update temp_sbcu 
set referred_by_other = obs_value_text(encounter_id, 'PIH','14415');

update temp_sbcu 
set management_datetime = obs_value_datetime(encounter_id, 'PIH','14398');

update temp_sbcu 
set provider = obs_value_text(encounter_id, 'PIH','13326');

update temp_sbcu 
set admission_datetime = obs_value_datetime(encounter_id, 'PIH','12240');

update temp_sbcu t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.concept_id = concept_from_mapping('PIH','14393') and o.obs_group_id is null
set t.admission_age_days = value_numeric;

update temp_sbcu 
set admission_age_hours = obs_value_numeric(encounter_id, 'PIH','14394');

update temp_sbcu 
set baby_sex = obs_value_coded_list(encounter_id, 'PIH','13055',@locale);

update temp_sbcu 
set baby_admission_weight = obs_value_numeric(encounter_id, 'PIH','14397');

update temp_sbcu 
set delivery_place = obs_value_coded_list(encounter_id, 'PIH','11348',@locale);

update temp_sbcu 
set delivery_place_other = obs_value_text(encounter_id, 'PIH','1389');

update temp_sbcu 
set delivery_facility = obs_value_coded_list(encounter_id, 'PIH','12365',@locale);

update temp_sbcu 
set delivery_facility_other = obs_value_text(encounter_id, 'PIH','11307');

update temp_sbcu 
set number_of_anc = obs_value_numeric(encounter_id, 'PIH','13321');

update temp_sbcu 
set delivery_mode = obs_value_coded_list(encounter_id, 'PIH','11663',@locale);

set @prior_dx_construct = concept_from_mapping('PIH','14391');
set @coded_dx = concept_from_mapping('PIH','3064');
set @noncoded_dx = concept_from_mapping('PIH','7416');

drop temporary table if exists temp_dx;
create temporary table temp_dx
select o.encounter_id, o.concept_id, GROUP_CONCAT(concept_name(o.value_coded,@locale)) "coded_dxs", o.value_text "noncoded_dx" from obs o 
inner join obs og on og.voided = 0 and og.obs_id = o.obs_group_id and og.concept_id in (@prior_dx_construct)
inner join temp_sbcu t on t.encounter_id = o.encounter_id 
where o.voided = 0
and o.concept_id in (@coded_dx, @noncoded_dx)
group by encounter_id, o.concept_id;

create index temp_dx_i1 on temp_dx(encounter_id,concept_id );

update temp_sbcu t 
inner join temp_dx d on d.encounter_id = t.encounter_id and d.concept_id = @coded_dx
set t.prior_diagnoses_coded = d.coded_dxs;

update temp_sbcu t 
inner join temp_dx d on d.encounter_id = t.encounter_id and d.concept_id = @noncoded_dx
set t.prior_diagnoses_noncoded = d.noncoded_dx; 

drop temporary table if exists temp_trt;
create temporary table temp_trt
select o.encounter_id, GROUP_CONCAT(concept_name(o.value_coded,@locale)) "treatment"
from obs o 
inner join temp_sbcu t2 on t2.encounter_id = o.encounter_id 
where o.voided = 0 and o.concept_id = concept_from_mapping('PIH','3513')
group by o.encounter_id;

create index temp_trt_i1 on temp_trt(encounter_id);

update temp_sbcu t 
inner join temp_trt tt on tt.encounter_id = t.encounter_id
set t.treatment_provided_coded = tt.treatment;

update temp_sbcu t
set treatment_provided_noncoded = obs_comments(t.encounter_id, 'PIH','3513','PIH','5622');

update temp_sbcu 
set APGAR_1_min_numeric = obs_value_numeric(encounter_id, 'PIH','14419');

update temp_sbcu 
set APGAR_5_min_numeric = obs_value_numeric(encounter_id, 'PIH','14417');

update temp_sbcu 
set APGAR_1_min_coded = obs_value_coded_list(encounter_id, 'PIH','12377',@locale);

update temp_sbcu 
set APGAR_5_min_coded = obs_value_coded_list(encounter_id, 'PIH','11932',@locale);

update temp_sbcu 
set assisted_ventilation = obs_value_coded_list(encounter_id, 'PIH','13096',@locale);

update temp_sbcu 
set birth_weight = obs_value_numeric(encounter_id, 'PIH','11067');

update temp_sbcu 
set gestation_age = obs_value_numeric(encounter_id, 'PIH','14390');

drop temporary table if exists temp_prob;
create temporary table temp_prob
select o.encounter_id, GROUP_CONCAT(concept_name(o.value_coded,@locale)) "problems"
from obs o 
inner join temp_sbcu t2 on t2.encounter_id = o.encounter_id 
where o.voided = 0 and o.concept_id = concept_from_mapping('PIH','12564')
group by o.encounter_id;

create index temp_prob_i1 on temp_prob(encounter_id);

update temp_sbcu t 
inner join temp_prob tt on tt.encounter_id = t.encounter_id
set t.admission_problems = tt.problems;

update temp_sbcu t
set admission_problems_other = obs_comments(t.encounter_id, 'PIH','12564','PIH','5622');

drop temporary table if exists temp_care;
create temporary table temp_care
select o.encounter_id, GROUP_CONCAT(concept_name(o.value_coded,@locale)) "care"
from obs o 
inner join temp_sbcu t2 on t2.encounter_id = o.encounter_id 
where o.voided = 0 and o.concept_id = concept_from_mapping('PIH','12943')
group by o.encounter_id;

create index temp_care_i1 on temp_care(encounter_id);

update temp_sbcu t 
inner join temp_care tt on tt.encounter_id = t.encounter_id
set t.supportive_care = tt.care;

update temp_sbcu t
set supportive_care_other = obs_comments(t.encounter_id, 'PIH','12943','PIH','5622');

update temp_sbcu 
set scbu_outcome = obs_value_coded_list(encounter_id, 'PIH','8620',@locale);

update temp_sbcu 
set death_outcome = if(scbu_outcome = concept_name(concept_from_mapping('PIH','8619'),@locale),1,null);

update temp_sbcu 
set death_construct_obs_id = obs_id(encounter_id, 'PIH',11140,0);

update temp_sbcu 
set death_datetime = obs_from_group_id_value_datetime(death_construct_obs_id, 'PIH','14399');

update temp_sbcu 
set cause_of_death = obs_from_group_id_value_coded_list(death_construct_obs_id, 'PIH','3355',@locale);

update temp_sbcu 
set other_cause = obs_from_group_id_value_text(death_construct_obs_id, 'PIH','9715');

update temp_sbcu 
set death_age_days = obs_from_group_id_value_numeric(death_construct_obs_id, 'PIH','14393');

update temp_sbcu 
set death_weight = obs_from_group_id_value_numeric(death_construct_obs_id, 'PIH','5089');

update temp_sbcu 
set discharge_datetime = obs_value_datetime(encounter_id, 'PIH','3800');

update temp_sbcu 
set staff_completing = obs_value_text(encounter_id, 'PIH','2594');

select
emr_id,
encounter_id,
user_entered,
date_entered,
encounter_location,
chart_number,
arrival_datetime,
referred_from,
referred_from_other,
referred_other_PIH_site,
referred_non_PIH_site,
referral_reason,
referral_reason_other,
referred_by,
referred_by_other,
management_datetime,
provider,
admission_datetime,
admission_age_days,
admission_age_hours,
baby_sex,
baby_admission_weight,
delivery_place,
delivery_place_other,
delivery_facility,
delivery_facility_other,
number_of_anc,
delivery_mode,
prior_diagnoses_coded,
prior_diagnoses_noncoded,
treatment_provided_coded,
treatment_provided_noncoded,
APGAR_1_min_numeric,
APGAR_1_min_coded,
APGAR_5_min_numeric,
APGAR_5_min_coded,
assisted_ventilation,
birth_weight,
gestation_age,
admission_problems,
admission_problems_other,
supportive_care,
supportive_care_other,
scbu_outcome,
death_outcome,
death_datetime,
cause_of_death,
other_cause,
death_age_days,
death_weight,
discharge_datetime,
staff_completing
from temp_sbcu;

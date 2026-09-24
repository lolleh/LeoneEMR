SET sql_safe_updates = 0;

SET @maternalRegister = (SELECT encounter_type_id FROM encounter_type WHERE uuid = '9cc89b83-e32f-410a-947d-aeb3bda37571');

DROP TEMPORARY TABLE IF EXISTS temp_maternal;
CREATE TEMPORARY TABLE temp_maternal
(
patient_id			       int(11),
emr_id				       varchar(25),
address				       varchar(1000),
age_at_enc			       int, 
encounter_id		       int(11),
encounter_datetime	       datetime,
creator				       int(11),
user_entered		       varchar(255),
date_entered		       datetime,
encounter_location_id	   int(11),
encounter_location	       varchar(255),
admission_datetime	       datetime,
gravida 			       int,
parity				       int,
gestational_age		       double,
pac_type			       varchar(255),
labor_start_datetime       datetime,
pres_and_position	       varchar(255),
pres_and_position_other	   text,
delivery_datetime	       datetime,
delivery_type		       varchar(255),
delivery_outcome	       varchar(255),
partograph_used 	       bit,
uterotonic_given	       bit,
baby_alive                 bit,
baby_sex			       varchar(255),
baby_weight			       double,
APGAR				       int,
breastfeeding_1_hour	   bit,
initial_coded_diagnoses	   varchar(1000),
initial_noncoded_diagnosis text,
final_coded_diagnoses	   varchar(1000),
final_noncoded_diagnosis   text,
couselled_fp		       bit,
received_fp			       bit,
disposition			       varchar(255),
HCW_Name			       text,
HCW_Cadre			       varchar(255), 
HCW_Cadre_other            text
);


insert into temp_maternal(patient_id, encounter_id, encounter_datetime, date_entered, creator, encounter_location_id)   
select e.patient_id,  e.encounter_id, e.encounter_datetime, e.date_created, e.creator, e.location_id  from encounter e
where e.encounter_type = @maternalRegister
and e.voided = 0
and ((date(e.encounter_datetime) >= date(@startDate)) or @startDate is null)
and ((date(e.encounter_datetime) <= date(@endDate)) or @endDate is null);

create index temp_maternal_ei on temp_maternal(encounter_id);

update temp_maternal 
set emr_id = patient_identifier(patient_id, '1a2acce0-7426-11e5-a837-0800200c9a66');  -- wellbody id

update temp_maternal 
set address = person_address(patient_id); 

update temp_maternal 
set age_at_enc = age_at_enc(patient_id, encounter_id);

update temp_maternal 
set user_entered  = username(creator);

update temp_maternal 
set encounter_location = location_name(encounter_location_id);

update temp_maternal
set admission_datetime = obs_value_datetime(encounter_id, 'PIH','12240');

update temp_maternal
set gravida = obs_value_numeric(encounter_id, 'PIH','5624');

update temp_maternal
set parity = obs_value_numeric(encounter_id, 'PIH','1053');

update temp_maternal
set gestational_age = obs_value_numeric(encounter_id, 'PIH','14390');

update temp_maternal
set pac_type = obs_value_coded_list(encounter_id, 'PIH','14376',@locale);

update temp_maternal
set labor_start_datetime = obs_value_datetime(encounter_id, 'PIH','14377');

update temp_maternal
set pres_and_position = obs_value_coded_list(encounter_id, 'PIH','13047',@locale);

update temp_maternal
set pres_and_position_other = obs_value_text(encounter_id, 'PIH','14414');

update temp_maternal
set delivery_datetime = obs_value_datetime(encounter_id, 'PIH','5599');

update temp_maternal
set delivery_type = obs_value_coded_list(encounter_id, 'PIH','11663',@locale);

update temp_maternal
set delivery_outcome = obs_value_coded_list(encounter_id, 'PIH','13561',@locale);

update temp_maternal 
set partograph_used = obs_value_coded_as_boolean(encounter_id, 'PIH','13964');

update temp_maternal 
set uterotonic_given = obs_value_coded_as_boolean(encounter_id, 'PIH','14373');

update temp_maternal 
set baby_alive = obs_value_coded_as_boolean(encounter_id, 'PIH','1571');

update temp_maternal
set baby_sex = obs_value_coded_list(encounter_id, 'PIH','13055',@locale);

update temp_maternal
set baby_weight = obs_value_numeric(encounter_id, 'PIH','11067');

update temp_maternal
set APGAR = obs_value_numeric(encounter_id, 'PIH','13558');

update temp_maternal 
set breastfeeding_1_hour = obs_value_coded_as_boolean(encounter_id, 'PIH','14372');

update temp_maternal 
set couselled_fp = obs_value_coded_as_boolean(encounter_id, 'PIH','12241');

update temp_maternal 
set received_fp = obs_value_coded_as_boolean(encounter_id, 'PIH','13564');

update temp_maternal
set disposition = obs_value_coded_list(encounter_id, 'PIH','8620',@locale);

update temp_maternal
set HCW_Name = obs_value_text(encounter_id, 'PIH','6592');

update temp_maternal
set HCW_Cadre = obs_value_coded_list(encounter_id, 'PIH','14411',@locale);

update temp_maternal
set HCW_Cadre_other = obs_value_text(encounter_id, 'PIH','14415');

-- initial, final diagnoses
set @prior_dx_construct = concept_from_mapping('PIH','14391');
set @dx_construct = concept_from_mapping('PIH','7539');
set @coded_dx = concept_from_mapping('PIH','3064');
set @noncoded_dx = concept_from_mapping('PIH','7416');

drop temporary table if exists temp_dx;
create temporary table temp_dx
select o.encounter_id, og.concept_id "construct_concept_id", o.concept_id, GROUP_CONCAT(concept_name(o.value_coded,@locale)) "coded_dxs", o.value_text "noncoded_dx" from obs o 
inner join obs og on og.voided = 0 and og.obs_id = o.obs_group_id and og.concept_id in (@prior_dx_construct, @dx_construct)
inner join temp_maternal t on t.encounter_id = o.encounter_id 
where o.voided = 0
and o.concept_id in (@coded_dx, @noncoded_dx)
group by encounter_id, o.concept_id, og.concept_id
;

create index temp_dx_i1 on temp_dx(encounter_id,construct_concept_id,concept_id );

update temp_maternal t 
inner join temp_dx d on d.encounter_id = t.encounter_id and d.construct_concept_id = @prior_dx_construct and d.concept_id = @coded_dx
set t.initial_coded_diagnoses = d.coded_dxs;

update temp_maternal t 
inner join temp_dx d on d.encounter_id = t.encounter_id and d.construct_concept_id = @prior_dx_construct and d.concept_id = @noncoded_dx
set t.initial_noncoded_diagnosis = d.noncoded_dx;

update temp_maternal t 
inner join temp_dx d on d.encounter_id = t.encounter_id and d.construct_concept_id = @dx_construct and d.concept_id = @coded_dx
set t.final_coded_diagnoses = d.coded_dxs;

update temp_maternal t 
inner join temp_dx d on d.encounter_id = t.encounter_id and d.construct_concept_id = @dx_construct and d.concept_id = @noncoded_dx
set t.final_noncoded_diagnosis = d.noncoded_dx;

select 
emr_id,
address,
age_at_enc,
encounter_id,
encounter_datetime,
user_entered,
date_entered,
encounter_location,
admission_datetime,
gravida,
parity,
gestational_age,
pac_type,
labor_start_datetime,
pres_and_position,
pres_and_position_other,
delivery_datetime,
delivery_type,
delivery_outcome,
partograph_used,
uterotonic_given,
baby_alive,
baby_sex,
baby_weight,
APGAR,
breastfeeding_1_hour,
initial_coded_diagnoses,
initial_noncoded_diagnosis,
final_coded_diagnoses,
final_noncoded_diagnosis,
couselled_fp,
received_fp,
disposition,
HCW_Name,
HCW_Cadre,
HCW_Cadre_other
from temp_maternal;

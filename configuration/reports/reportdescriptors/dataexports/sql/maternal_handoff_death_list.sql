-- set @handoverDate = '2026-01-14';
-- set @shift = 'morning'; -- 'evening' ;

set @startTime = 
case
	when @shift = 'morning' then DATE_SUB(@handoverDate, INTERVAL 1 DAY) + INTERVAL 8 HOUR
	when @shift = 'evening' then @handoverDate + INTERVAL 8 HOUR
end;

set @endTime = 
case
	when @shift = 'morning' then @handoverDate + INTERVAL 8 HOUR
	when @shift = 'evening' then @handoverDate + INTERVAL 20 HOUR	
end;


set @identifier_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
select program_id into @pregnancy_program_id from program p where uuid = '6a5713c2-3fd5-46e7-8f25-36a0f7871e12';
select location_id into @anc from location where uuid = '11f5c9f9-40b8-46ad-9e7e-59473ce43246';
select location_id into @labour from location where uuid = '11377a5b-6850-11ee-ab8d-0242ac120002';
select location_id into @nicu from location where uuid = '0ce2f6fb-6850-11ee-ab8d-0242ac120002';
select location_id into @pacu from location where uuid = '17596678-6850-11ee-ab8d-0242ac120002';
select location_id into @pnc from location where uuid = 'ff0d5e73-3fe0-437f-90ba-7d605ac03dc0';
select location_id into @quiet from location where uuid = '28660b7f-3450-4b86-b840-9670ec68235f';
select location_id into @mccu from location where uuid = '4d7e927d-6850-11ee-ab8d-0242ac120002';
select location_id into @postop from location where uuid = 'a39ec469-d1f9-11f0-9d46-169316be6a48';
select location_id into @preop from location where uuid = '142de844-6850-11ee-ab8d-0242ac120002';
select location_id into @mcoe_triage from location where uuid = 'f85feffc-fe54-4648-aa14-01ed6d30b943';
select location_id into @kmc from location where uuid = '81080213-d1f9-11f0-9d46-169316be6a48';
select location_id into @mothers from location where uuid = '989a9b23-d1f9-11f0-9d46-169316be6a48';

drop temporary table if exists temp_deaths;
create temporary table temp_deaths 
(patient_id int,
emr_id varchar(50),
age_of_death float,
death_datetime datetime,
patient_name text,
cause varchar(255),
pregnancy_program_id int,
latest_program_state varchar(255),
pregnancy_status varchar(255),
program_start_datetime datetime,
delivery_datetime datetime,
lmp_entered date,
lmp_entered_datetime datetime,
gestational_age_entered float,
gestational_age_entered_datetime datetime,
gestational_age float,
baby_location varchar(255));

insert into temp_deaths(patient_id, age_of_death, death_datetime, cause)
select p.person_id, TIMESTAMPDIFF(YEAR, p.birthdate, death_date),
p.death_date, concept_name(p.cause_of_death, @locale)  
from person p 
inner join visit v on v.visit_id = 
	(select v2.visit_id from visit v2
	where v2.patient_id = p.person_id
	order by v2.date_started desc limit 1)
where p.death_date >= @startTime
and p.death_date <  @endTime
and exists 
	(select 1 from encounter e 
	where e.visit_id = v.visit_id
	and e.location_id in (@anc, @labour, @nicu, @pacu, @pnc, @quiet, @mccu, @postop, @preop, @mcoe_triage, @kmc, @mothers));

update temp_deaths t
set t.emr_id = patient_identifier(patient_id, @identifier_uuid);

update temp_deaths t
set t.patient_name = person_name(patient_id);

update temp_deaths t
inner join patient_program pp 
	on pp.patient_id = t.patient_id
	and pp.program_id = @pregnancy_program_id
	and pp.date_completed = t.death_datetime
set t.pregnancy_program_id = pp.patient_program_id,
	t.program_start_datetime = pp.date_enrolled;	

update temp_deaths t 
inner join patient_state ps on ps.patient_program_id  = t.pregnancy_program_id and date(ps.end_date) = date(t.death_datetime)
inner join program_workflow_state pws on pws.program_workflow_state_id = ps.state 
set t.pregnancy_status = concept_name(pws.concept_id, @locale);

update temp_deaths t 
inner join obs o on o.obs_id = latest_obs(patient_id, 'PIH','5599') and date(o.obs_datetime) >= date(t.program_start_datetime) 
set t.delivery_datetime = o.value_datetime; 

update temp_deaths t 
inner join obs o on o.obs_id = latest_obs(patient_id, 'PIH','968') and date(o.obs_datetime) >= date(t.program_start_datetime) 
set t.lmp_entered = o.value_datetime,
	t.lmp_entered_datetime = o.obs_datetime; 

update temp_deaths t 
inner join obs o on o.obs_id = latest_obs(patient_id, 'PIH','1279') and date(o.obs_datetime) >= date(t.program_start_datetime) 
set t.gestational_age_entered = o.value_numeric,
	t.gestational_age_entered_datetime = o.obs_datetime; 

update temp_deaths t
set gestational_age = TIMESTAMPDIFF(WEEK, lmp_entered, COALESCE(delivery_datetime, now()))
where lmp_entered is not null;

update temp_deaths t
set gestational_age = gestational_age_entered + TIMESTAMPDIFF(WEEK, gestational_age_entered_datetime, COALESCE(delivery_datetime, now()))
where lmp_entered is null;

select 
emr_id "EMR_Id",
patient_name "Patient_name",
age_of_death "Age_at_Death",
  CONCAT(DATE_FORMAT(death_datetime, '%b %e, %Y '), LTRIM(LOWER(DATE_FORMAT(death_datetime, '%l:%i%p')))) "Time_of_Death",
cause "Cause_of_Death",
pregnancy_status "Pregnancy_Status",
gestational_age "Gestational_Age"
from temp_deaths
order by death_datetime;

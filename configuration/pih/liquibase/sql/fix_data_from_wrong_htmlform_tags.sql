set @hiv_counseling = concept_from_mapping('CIEL','1459');
set @fp_counseling = concept_from_mapping('CIEL','1382');
set @unknown_answer = concept_from_mapping('PIH','1067');

drop temporary table if exists temp_change_obs;
create temporary table temp_change_obs
select * from obs 
where concept_id in (@hiv_counseling, @fp_counseling )
and voided = 0;

update obs o
inner join temp_change_obs t on t.obs_id = o.obs_id
	set o.voided = 1, 
	o.voided_by = 1, 
	o.date_voided = now(), 
	o.void_reason = 'SL-409 fix data from wrong htmlform tags';

insert into obs 
	(person_id,
	concept_id,
	encounter_id,
	order_id,
	obs_datetime,
	location_id,
	obs_group_id,
	accession_number,
	value_coded,
	comments,
	creator,
	date_created,
	uuid,
	previous_version,
	form_namespace_and_path,
	status,
	interpretation)
select 
	person_id,
	concept_id,
	encounter_id,
	order_id,
	obs_datetime,
	location_id,
	obs_group_id,
	accession_number,
	@unknown_answer, -- value_coded
	comments,
	1, -- creator
	now(), -- date_created
	uuid(),
	t.obs_id, -- previous version
	form_namespace_and_path,
	status,
	interpretation
from temp_change_obs t;

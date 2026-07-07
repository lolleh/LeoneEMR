set @mh_program = program('Mental Health');
select  
		pe.uuid as patient_uuid,
		patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')) as emr_id,
		current_age_in_years(p.patient_id) age,
        gender(p.patient_id) gender,
        given_name as first_name, 
		family_name as last_name, 
        Date(p.date_enrolled) as date_enrolled 
from patient_program p 
join person pe on p.patient_id = pe.person_id and pe.voided = 0 
join person_name pn on p.patient_id = pn.person_id and pn.voided = 0 
where p.voided = 0 and p.program_id = @mh_program order by p.patient_id;
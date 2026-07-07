-- set @date = '2026-04-21';
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');

select encounter_type_id into @newborn_discharge from encounter_type where uuid = '153d3182-c76f-4047-b7f2-d83cf967b206';
select location_id into @nicu_location from location where uuid = '0ce2f6fb-6850-11ee-ab8d-0242ac120002';
select visit_attribute_type_id into @bornDuringVisitAttribute from visit_attribute_type where uuid = '86f716fc-5e26-4eb1-9484-46370cff28f0';

DROP TABLE IF EXISTS temp_discharge_list;
CREATE TABLE temp_discharge_list
(
patient_id         int,          
encounter_id       int,          
visit_id           int,          
emr_id             varchar(50),  
name               text,         
discharge_datetime datetime,     
disposition        varchar(255), 
discharge_provider text,         
inborn_outborn     text);        

insert into temp_discharge_list (patient_id, encounter_id, discharge_datetime, visit_id) 
select patient_id, encounter_id, encounter_datetime, visit_id
from encounter e 
where encounter_type = @newborn_discharge 
and date(encounter_datetime) = @date
and location_id = @nicu_location
and voided = 0;

update temp_discharge_list 
set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_discharge_list 
set disposition = obs_value_coded_list(encounter_id, 'PIH', '8620', @locale);

update temp_discharge_list
set name = person_name(patient_id);

update temp_discharge_list
set discharge_provider = provider(encounter_id);

update temp_discharge_list t
inner join visit_attribute va on va.visit_id = t.visit_id
    and va.attribute_type_id = @bornDuringVisitAttribute
    and va.value_reference = 'true'
    and va.voided = 0
set t.inborn_outborn = 'inborn';
update temp_discharge_list t set inborn_outborn = 'outborn' where t.inborn_outborn is null;


select
  emr_id "EMR ID",
  name "Name", 
  CONCAT(DATE_FORMAT(discharge_datetime, '%b %e, %Y '), LTRIM(LOWER(DATE_FORMAT(discharge_datetime, '%l:%i%p')))) "Discharged date/time",
  disposition "Dispositon", 
  discharge_provider "Discharge provider",
  inborn_outborn "Inborn/Outborn"
from temp_discharge_list;

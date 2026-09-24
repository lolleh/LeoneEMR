-- test data:
-- set @date = '2026-05-20';
-- set @locationUUID = 'a39ec469-d1f9-11f0-9d46-169316be6a48';
-- ------------------
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
select encounter_type_id into @exitFromCare from encounter_type where uuid = 'b6631959-2105-49dd-b154-e1249e0fbcd7';
select location_id into @ward_location from location where uuid = @locationUUID;
select visit_attribute_type_id into @bornDuringVisitAttribute from visit_attribute_type where uuid = '86f716fc-5e26-4eb1-9484-46370cff28f0';

DROP TEMPORARY TABLE IF EXISTS temp_discharge_list;
CREATE TEMPORARY TABLE temp_discharge_list
(
patient_id         int,          
encounter_id       int,          
visit_id           int,          
emr_id             varchar(50),  
name               text,         
discharge_datetime datetime,     
disposition        varchar(255), 
discharge_provider text);        

insert into temp_discharge_list (patient_id, encounter_id, discharge_datetime, visit_id) 
select patient_id, encounter_id, encounter_datetime, visit_id
from encounter e 
where encounter_type = @exitFromCare
and date(encounter_datetime) = @date
and location_id = @ward_location
and voided = 0;

update temp_discharge_list 
set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_discharge_list 
set disposition = obs_value_coded_list(encounter_id, 'PIH', '8620', @locale);

update temp_discharge_list
set name = person_name(patient_id);

set @dispositionConceptId = concept_from_mapping('PIH','8620');
update  temp_discharge_list
set disposition = value_coded_name(latestObsInVisit(visit_id, @dispositionConceptId),@locale);

update temp_discharge_list
set discharge_provider = provider(encounter_id);

select
  emr_id "EMR ID",
  name "Name", 
  CONCAT(DATE_FORMAT(discharge_datetime, '%b %e, %Y '), LTRIM(LOWER(DATE_FORMAT(discharge_datetime, '%l:%i%p')))) "Discharged date/time",
  disposition "Dispositon", 
  discharge_provider "Discharge provider"
from temp_discharge_list;

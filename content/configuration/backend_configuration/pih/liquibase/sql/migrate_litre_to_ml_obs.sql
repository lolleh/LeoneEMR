
set @volumeMeasurementUrineOld = (select concept_id from concept where uuid = 'c5d53b25-3f96-491f-8950-e1e0c5169e58');
set @volumeMeasurementUrineNew = (select concept_id from concept where uuid = '3cb248bf-56aa-4e11-951a-7cc644530763');
set @estimatedBloodLossOld = (select concept_id from concept where uuid = '3a7918e4-efa5-458d-8cea-e7d32d375616');
set @estimatedBloodLossNew = (select concept_id from concept where uuid = '0b4f2fbe-cc2a-438e-82b7-04ec7b550081');
set @ivfVolumeOld = (select concept_id from concept where uuid = 'ad60741b-7738-491b-b4e0-c623a157fffa');
set @ivfVolumeNew = (select concept_id from concept where uuid = '40388360-d700-4296-b3f9-446653f6102e');
set @newbornDailyProgressEncounterTypeId = (select encounter_type_id from encounter_type where uuid = '7e42e652-89e7-4559-80fd-41f42826c98c');
set @daemonUser = (select user_id from users where username='daemon');
set @currentDate = now();

-- create temporary table to hold the obs that need to be updated
drop temporary table if exists temp_litre_obs_to_update ;
create temporary table temp_litre_obs_to_update as
select o.* from obs o inner join encounter e on o.encounter_id = e.encounter_id
where o.concept_id in (@volumeMeasurementUrineOld, @estimatedBloodLossOld, @ivfVolumeOld)
  and o.voided = 0
  and e.encounter_type = @newbornDailyProgressEncounterTypeId;

-- create the new obs from the old obs (setting creator to daemonUser, date_created to now(), and uuid to a new uuid)
insert into obs (
    person_id,
    concept_id,
    encounter_id,
    order_id,
    obs_datetime,
    location_id,
    obs_group_id,
    accession_number,
    value_group_id,
    value_coded,
    value_coded_name_id,
    value_drug,
    value_datetime,
    value_numeric,
    value_modifier,
    value_text,
    value_complex,
    comments,
    previous_version,
    form_namespace_and_path,
    status,
    interpretation,
    creator,
    date_created,
    uuid
)
select
    person_id,
    case concept_id
        when @volumeMeasurementUrineOld then @volumeMeasurementUrineNew
        when @estimatedBloodLossOld then @estimatedBloodLossNew
        when @ivfVolumeOld then @ivfVolumeNew
    end,
    encounter_id,
    order_id,
    obs_datetime,
    location_id,
    obs_group_id,
    accession_number,
    value_group_id,
    value_coded,
    value_coded_name_id,
    value_drug,
    value_datetime,
    if(value_numeric < 1, value_numeric * 1000, value_numeric),
    value_modifier,
    value_text,
    value_complex,
    comments,
    obs_id,
    form_namespace_and_path,
    status,
    interpretation,
    @daemonUser,
    @currentDate,
    UUID()
from temp_litre_obs_to_update;

-- now void the old obs
update obs o, temp_litre_obs_to_update t
set o.voided = 1, o.date_voided = @currentDate, o.voided_by = @daemonUser, o.void_reason = 'SL-1149: Migrate obs from litre to mL concepts'
where o.obs_id = t.obs_id;

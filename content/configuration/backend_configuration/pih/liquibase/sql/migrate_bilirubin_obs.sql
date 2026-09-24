
-- Total bilirubin (mg/dL) CIEL: 655
set @oldConceptId = (select concept_id from concept where uuid = '3cd278fa-26fe-102b-80cb-0017a47871b2');
-- Transcutaneous bilirubin (mg/dL) PIH:21391
set @newConceptId = (select concept_id from concept where uuid = 'f1ae479c-6a12-49c0-bdcd-92a1d640abba');
-- Only update obs that are part of the SL Newborn Initial and Discharge encounters
set @newbornInitialEncId= (select encounter_type_id from encounter_type where uuid = '093b6ffc-e55a-461a-85cc-c6acf7714a23');
set @newbornDischargeEncId= (select encounter_type_id from encounter_type where uuid = '153d3182-c76f-4047-b7f2-d83cf967b206');
-- Use daemon for creator and voided_by user
set @daemonUser = (select user_id from users where username='daemon');

-- create temporary table to hold the obs that need to be updated
DROP TEMPORARY TABLE IF EXISTS temp_bili_obs_to_update ;
CREATE TEMPORARY TABLE  temp_bili_obs_to_update (
           `obs_id` int(11),
           `person_id` int(11),
           `concept_id` int(11),
           `encounter_id` int(11),
           `order_id` int(11),
           `obs_datetime` datetime,
           `location_id` int(11),
           `obs_group_id` int(11),
           `accession_number` varchar(255),
           `value_group_id` int(11),
           `value_coded` int(11),
           `value_coded_name_id` int(11),
           `value_drug` int(11),
           `value_datetime` datetime,
           `value_numeric` double,
           `value_modifier` varchar(2),
           `value_text` text,
           `value_complex` varchar(1000),
           `comments` varchar(255),
           `previous_version` int(11),
           `form_namespace_and_path` varchar(255),
           `status` varchar(16) NOT NULL,
           `interpretation` varchar(32));

-- load all the obs that need to be updated
insert into temp_bili_obs_to_update
    (obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime,
     location_id, obs_group_id, accession_number, value_group_id, value_coded,
     value_coded_name_id, value_drug, value_datetime, value_numeric, value_modifier,
     value_text, value_complex, comments, previous_version, form_namespace_and_path, status,
     interpretation)
select o.obs_id, o.person_id, o.concept_id, o.encounter_id, o.order_id, o.obs_datetime, o.location_id, o.obs_group_id,
       o.accession_number, o.value_group_id, o.value_coded, o.value_coded_name_id, o.value_drug, o.value_datetime,
       o.value_numeric, o.value_modifier, o.value_text, o.value_complex, o.comments, o.previous_version, o.form_namespace_and_path,
       o.status, o.interpretation from obs o, encounter e
 where o.concept_id = @oldConceptId
   and o.voided = 0
   and o.encounter_id = e.encounter_id
   and e.encounter_type IN (@newbornInitialEncId, @newbornDischargeEncId);

-- set the previous version to the current version
update temp_bili_obs_to_update
   set previous_version = obs_id;

-- update the concept id to the new concept id
update temp_bili_obs_to_update
   set concept_id = @newConceptId;

-- create the new obs from the old obs (setting creator to daemonUser, date_created to now(), and new uuid)
insert into obs
    (person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, obs_group_id, accession_number,
     value_group_id, value_coded, value_coded_name_id, value_drug, value_datetime, value_numeric, value_modifier,
     value_text, value_complex, comments, previous_version, form_namespace_and_path, status, interpretation,
     creator, date_created, uuid)
select person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, obs_group_id, accession_number, value_group_id,
       value_coded, value_coded_name_id, value_drug, value_datetime, value_numeric, value_modifier, value_text, value_complex,
       comments, previous_version, form_namespace_and_path, status, interpretation,
       @daemonUser, NOW(), UUID()
  from temp_bili_obs_to_update;

-- void the old obs
update obs o, temp_bili_obs_to_update t
   set o.voided = 1, o.date_voided = NOW(), o.voided_by = @daemonUser,
       o.void_reason='SL-1223: Migrate tbili to tcb concept_id'
where o.obs_id = t.obs_id;


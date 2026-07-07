
-- CIEL: 160912, units: mg/dL
set @oldConceptId = (select concept_id from concept where uuid = '160912AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
-- CIEL: 169672, 	Fasting blood glucose (mmol/L), units: mmol/L
set @newConceptId = (select concept_id from concept where uuid = '6e291dc0-9dd6-4ccf-bce4-5339c52667a9');
-- we only want to update obs that are part of the SL Vitals encounter
set @vitalsEncId= (select encounter_type_id from encounter_type where uuid = '2fd151a2-fbef-43e3-b82d-c3f70f1d7333');
-- to use as the creator and voided_by user
set @daemonUser = (select user_id from users where username='daemon');
-- create temporary table to hold the obs that need to be updated
DROP TEMPORARY TABLE IF EXISTS temp_fbs_obs_to_update ;
CREATE TEMPORARY TABLE  temp_fbs_obs_to_update (
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
insert into temp_fbs_obs_to_update (obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime,
                                        location_id, obs_group_id, accession_number, value_group_id, value_coded,
                                        value_coded_name_id, value_drug, value_datetime, value_numeric, value_modifier,
                                        value_text, value_complex, comments, previous_version, form_namespace_and_path, status,
                                        interpretation)
select o.obs_id, o.person_id, o.concept_id, o.encounter_id, o.order_id, o.obs_datetime, o.location_id, o.obs_group_id,
       o.accession_number, o.value_group_id, o.value_coded, o.value_coded_name_id, o.value_drug, o.value_datetime,
       o.value_numeric, o.value_modifier, o.value_text, o.value_complex, o.comments, o.previous_version, o.form_namespace_and_path,
       o.status, o.interpretation from obs o, encounter e where o.concept_id=@oldConceptId and o.voided=0 and o.encounter_id = e.encounter_id
                                                            and e.encounter_type = @vitalsEncId;


-- set the previous version to the current version
update temp_fbs_obs_to_update set previous_version=obs_id;

-- update the concept id to the new concept id
update temp_fbs_obs_to_update set concept_id=@newConceptId;

-- create the new obs from the old obs (setting creator to daemonUser, date_created to now(), and uuid to a new uuid)
insert into obs(person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, obs_group_id, accession_number,
                value_group_id, value_coded, value_coded_name_id, value_drug, value_datetime, value_numeric, value_modifier,
                value_text, value_complex, comments, previous_version, form_namespace_and_path, status, interpretation, creator, date_created, uuid)
select person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, obs_group_id, accession_number, value_group_id,
       value_coded, value_coded_name_id, value_drug, value_datetime, value_numeric, value_modifier, value_text, value_complex,
       comments, previous_version, form_namespace_and_path, status, interpretation, @daemonUser, NOW(), UUID() from temp_fbs_obs_to_update;


-- now void the old obs
update obs o, temp_fbs_obs_to_update t set o.voided=1, o.date_voided=NOW(), o.voided_by=@daemonUser, o.void_reason='SL-913: Migrate FBG obs to use CIEL:169672(mmol/L)'
where o.obs_id=t.obs_id;


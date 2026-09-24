SET @infant_concept_id = (SELECT concept_id FROM concept WHERE uuid ='23eeeec5-7f82-4bea-8bdf-f959900882e7');
SET @birthtime_concept_id = (SELECT concept_id FROM concept WHERE uuid ='5599AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
SET @inborn_visit_attribute_type_uuid = '86f716fc-5e26-4eb1-9484-46370cff28f0';
SET @lnd_encounter_id  = (select encounter_type_id from encounter_type where uuid= 'fec2cc56-e35f-42e1-8ae3-017142c1ca59');

DROP TABLE IF EXISTS tmp_inborn_visit;

CREATE TABLE tmp_inborn_visit AS
SELECT v.*
FROM encounter e
 JOIN obs o1 on e.encounter_id = o1.encounter_id and e.encounter_type = @lnd_encounter_id
 JOIN obs o2    ON o2.obs_group_id = o1.obs_group_id
 JOIN person p  ON p.uuid = o1.comments
 JOIN visit v   ON v.patient_id   = p.person_id
    AND v.date_started = o2.value_datetime
WHERE o1.concept_id = @infant_concept_id
  AND o1.comments REGEXP '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  AND o2.concept_id = @birthtime_concept_id
  AND o1.obs_group_id IS NOT NULL;

INSERT INTO visit_attribute
       (visit_id, attribute_type_id, value_reference, uuid, creator, date_created)
SELECT t.visit_id,
       vat.visit_attribute_type_id,
       'true',
       UUID(),
       t.creator,
       t.date_created
  FROM tmp_inborn_visit t
  JOIN visit_attribute_type vat
    ON vat.uuid = @inborn_visit_attribute_type_uuid
  LEFT JOIN visit_attribute va
         ON va.visit_id          = t.visit_id
        AND va.attribute_type_id = vat.visit_attribute_type_id
        AND va.value_reference   = 'true'
 WHERE va.visit_attribute_id IS NULL;

DROP TABLE IF EXISTS tmp_inborn_visit;

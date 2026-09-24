SET @startDate = COALESCE(@startDate, '2024-01-01');
SET @endDate = COALESCE(@endDate, CURDATE());

SELECT  DATE(e.encounter_datetime) AS "Visit Date",
        pn.given_name AS "First Name",
        pn.family_name AS "Last Name",
        pi.identifier AS "Patient ID",
        (SELECT GROUP_CONCAT(cn2.name ORDER BY cn2.name SEPARATOR '; ')
         FROM   obs o2
         JOIN   concept c2 ON c2.concept_id = o2.concept_id
         JOIN   concept_name cn2 ON cn2.concept_id = c2.concept_id
               AND cn2.concept_name_type = 'FULLY_SPECIFIED'
               AND cn2.locale = 'en'
               AND cn2.voided = 0
         WHERE  o2.encounter_id = e.encounter_id
           AND  o2.concept_id IN (8842,8840,8838,8839,8844,8774,8851,8848,8849,8852,8850,8841,8846,8843,8845,8847)
           AND  o2.value_coded = 8853
           AND  o2.voided = 0) AS "Conditions"
FROM    encounter e
JOIN    patient_identifier pi ON pi.patient_id = e.patient_id AND pi.voided = 0
LEFT JOIN person_name pn ON pn.person_id = e.patient_id AND pn.voided = 0
WHERE   e.encounter_type = 113
  AND   e.voided = 0
  AND   (date(e.encounter_datetime) >= date(@startDate) OR @startDate IS NULL)
  AND   (date(e.encounter_datetime) <= date(@endDate) OR @endDate IS NULL)
ORDER BY e.encounter_datetime DESC
LIMIT 200;

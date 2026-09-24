SET @startDate = COALESCE(@startDate, '2024-01-01');
SET @endDate = COALESCE(@endDate, CURDATE());

SELECT  cn.name AS "Condition",
        COUNT(*) AS "Cases"
FROM    obs o
JOIN    concept c ON c.concept_id = o.concept_id
LEFT JOIN concept_name cn ON cn.concept_id = c.concept_id
      AND cn.concept_name_type = 'FULLY_SPECIFIED'
      AND cn.locale = 'en'
      AND cn.voided = 0
WHERE   o.concept_id IN (8842,8840,8838,8839,8844,8774,8851,8848,8849,8852,8850,8841,8846,8843,8845,8847)
  AND   o.value_coded = 8853
  AND   o.voided = 0
  AND   (date(o.obs_datetime) >= date(@startDate) OR @startDate IS NULL)
  AND   (date(o.obs_datetime) <= date(@endDate) OR @endDate IS NULL)
GROUP BY cn.name
ORDER BY Cases DESC, cn.name;

set @deliveryEncounterType = encounterName('fec2cc56-e35f-42e1-8ae3-017142c1ca59');
set @pregnancyProgram = program('Pregnancy');
set @pregnancyProgramId = mostRecentPatientProgramId(@patientId,@pregnancyProgram);
set @pregnancyProgramStartDate = programStartDate(@pregnancyProgramId);
set @latestDeliveryEncounterId = latestEnc(@patientId, @deliveryEncounterType, @pregnancyProgramStartDate);
set @deliveryType = obs_value_coded_list(@latestDeliveryEncounterId,'PIH','11663','en');
select REPLACE(@deliveryType,' | ',', ') as deliveryType;

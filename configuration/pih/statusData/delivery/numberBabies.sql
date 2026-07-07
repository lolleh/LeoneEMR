set @deliveryEncounterType = encounterName('fec2cc56-e35f-42e1-8ae3-017142c1ca59');
set @pregnancyProgram = program('Pregnancy');
set @pregnancyProgramId = mostRecentPatientProgramId(@patientId,@pregnancyProgram);
set @pregnancyProgramStartDate = programStartDate(@pregnancyProgramId);
set @latestDeliveryEncounterId = latestEnc(@patientId, @deliveryEncounterType, @pregnancyProgramStartDate);

select count(*) into @numberBabies 
from obs o 
where o.encounter_id = @latestDeliveryEncounterId
and o.voided = 0
and o.concept_id = concept_from_mapping('PIH','13561') -- birth outcome
and o.value_coded = concept_from_mapping('PIH','12897'); -- live birth
select @numberBabies as numberBabies,
	if(@numberBabies is null,0,1) as babiesExist;

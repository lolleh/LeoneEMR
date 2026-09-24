set @deliveryEncounterType = encounterName('fec2cc56-e35f-42e1-8ae3-017142c1ca59');
set @pregnancyProgram = program('Pregnancy');
set @pregnancyProgramId = mostRecentPatientProgramId(@patientId,@pregnancyProgram);
set @pregnancyProgramStartDate = programStartDate(@pregnancyProgramId);
set @latestDeliveryEncounterId = latestEnc(@patientId, @deliveryEncounterType, @pregnancyProgramStartDate);
set @baby3ObsGroupId = obs_id_ordered_ascending(@latestDeliveryEncounterId, 'PIH','13555',2);
set @baby3UUID = obs_from_group_id_comment(@baby3ObsGroupId, 'PIH','20150');
set @baby3PatientId = (select person_id from person where UUID = @baby3UUID);
set @baby3Identifier = patient_identifier(@baby3PatientId, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

set @admissionEncounterType = encounterName('260566e1-c909-4d61-a96f-c1019291a09d');
set @transferEncounterType =  encounterName('436cfe33-6b81-40ef-a455-f134a9f7e580');
set @dischargeEncounterType =  encounterName('b6631959-2105-49dd-b154-e1249e0fbcd7');
set @latestDischargeEncounterId = latestEnc(@baby3PatientId, @dischargeEncounterType, null);
set @latestDischargeDatetime = encounter_date(@latestDischargeEncounterId);
set @latestAdmitEncounterId = latestEnc(@baby3PatientId, CONCAT(@admissionEncounterType,',',@transferEncounterType), @latestDischargeDatetime);
set @admitLocation = encounter_location_name(@latestAdmitEncounterId);

select @baby3UUID as baby3Uuid,
       @baby3Identifier as baby3Identifier,
       if(@baby3Identifier is null,0,1) as baby3exists,  		
       @admitLocation as admissionLocation; 


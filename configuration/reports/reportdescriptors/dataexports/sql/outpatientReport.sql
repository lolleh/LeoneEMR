set @locale = global_property_value('default_locale', 'en');

SELECT encounter_type_id into @dispensingEnc from encounter_type where uuid= '8ff50dea-18a1-4609-b4c9-3f8f2d611b84';

## CREATE SCHEMA FOR DATA EXPORT

drop temporary table if exists temp_report;
create temporary table temp_report
(
    Patient_id                  int,
    Visit_id                    int,
    Patient_primary_id          varchar(50),
    Dispensing_encounter_id     int,
    dispensed_encounter_date    datetime,
    patient_name                varchar(200),
    age_at_encounter            int, 
    gender                      char(1),
    patient_address             varchar(1000),
    occupation 			varchar(255),
    height                      double,
    weight                      double,
    z_score                     double,
    muac_in_cm                  double,   
    type_of_visit               varchar(255),
    fp_offered_and_accepted     varchar(255),
    malaria_rdt                 varchar(255),
    diag_1                        varchar(255),
    diag_1_certainty              varchar(255),
    diag_1_order                  varchar(255),
    diag_2                        varchar(255),
    diag_2_certainty              varchar(255),
    diag_2_order                  varchar(255),
    diag_3                        varchar(255),
    diag_3_certainty              varchar(255),
    diag_3_order                  varchar(255),
   	Amoxicillin_125mg	int,
    Amoxicillin_250mg	int,
  	Amoxicillin_500mg	int,
	  Ampicillin_1gram	int,
	  Clotrimazole_20g	int,
    Clotrimazole_500mg	int,
	  Erythromycin_125mg	int,
	  Erythromycin_250mg	int,
	  Gentamicin_drops	int,
	  Gentamicin_40mg_inj	int,
	  AL_6_Tab int,
    AL_12_Tab int,
	  AL_18_Tab int,
	  AL_24_Tab int,
    Artesunate_60mg	int,
	  Quinine_sulfate_300mg int,
	  Sulfadoxine_500mg_Pyrim_25mg	int,
    act                         char(1),
    non_act                     char(1),
    ari_antb                    char(1)
);


insert into temp_report (
    patient_id,
    Visit_id,
    Dispensing_encounter_id,
    dispensed_encounter_date
)
select
    e.patient_id,
    e.Visit_id,
    e.encounter_id,
    e.encounter_datetime
from
    encounter e
where
    e.voided = 0 and
    e.encounter_type = @dispensingEnc and
    date(e.encounter_datetime) >= date(@startDate) and
    date(e.encounter_datetime) <= date(@endDate);

## REMOVE TEST PATIENTS

delete
from temp_report
where Patient_id in
      (
          select a.person_id
          from person_attribute a
          inner join person_attribute_type t on a.person_attribute_type_id = t.person_attribute_type_id
          where a.value = 'true'
          and t.name = 'Test Patient'
      );

## Pull in patient demographics and identifiers

update temp_report set age_at_encounter = age_at_enc(patient_id, Dispensing_encounter_id);
update temp_report set patient_name = person_name(patient_id);
update temp_report set gender = gender(patient_id);
update temp_report set Patient_primary_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_report set patient_address = person_address(patient_id);
update temp_report
  inner join obs o on obs_id = latestObs(patient_id, concept_from_mapping('PIH','1304'),null)
set occupation = concept_name(value_coded,'en');

## pull in observations from that visit
update temp_report set height = obs_from_visit_value_numeric(Visit_id,'CIEL',5090);
update temp_report set weight = obs_from_visit_value_numeric(Visit_id,'CIEL',5089);
update temp_report set z_score = obs_from_visit_value_numeric(Visit_id,'CIEL',162584);
update temp_report set muac_in_cm = obs_from_visit_value_numeric(Visit_id,'PIH',7956)/10;
update temp_report set type_of_visit = obs_from_visit_value_coded_list(Visit_id,'PIH',8879,@locale);  
update temp_report set malaria_rdt= obs_from_visit_value_coded_list(Visit_id,'CIEL',1643,@locale);
update temp_report set fp_offered_and_accepted = obs_from_visit_value_coded_list(Visit_id,'CIEL','1382',@locale); 

## Diagnoses:
## The following retrieves diagnoses by utilizing a function that retrieves the value coded answer based on a visit and offset.

update temp_report t
set diag_1 = obs_from_visit_value_coded(t.Visit_id, 'PIH','3064',0,@locale),
    diag_2 = obs_from_visit_value_coded(t.Visit_id, 'PIH','3064',1,@locale),
    diag_3 = obs_from_visit_value_coded(t.Visit_id, 'PIH','3064',2,@locale),
    diag_1_certainty = obs_from_visit_value_coded(t.Visit_id, 'PIH','1379',0,@locale),
    diag_2_certainty = obs_from_visit_value_coded(t.Visit_id, 'PIH','1379',1,@locale),
    diag_3_certainty = obs_from_visit_value_coded(t.Visit_id, 'PIH','1379',2,@locale),    
    diag_1_order = obs_from_visit_value_coded(t.Visit_id, 'PIH','7537',0,@locale),
    diag_2_order = obs_from_visit_value_coded(t.Visit_id, 'PIH','7537',1,@locale), 
    diag_3_order = obs_from_visit_value_coded(t.Visit_id, 'PIH','7537',2,@locale)    
;



## to update quantity of each of these drugs, use the following nested functions:
## find the drug_id of the desired drug (using name or UUID)
## find obs_id with certain drug answer with that drug_id and the given encounter (using the dispensing encounter_id from the temp table)
## find obs_group_id from that obs_id
## find value_numeric answer of the medication dispensed question with that group_id

update temp_report t
 set  Amoxicillin_125mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Amoxicillin 125mg + clavulanic acid 31.25mg/mL, Powder for oral suspension, 100mL bottle'))),'PIH','9071');
 
update temp_report t
 set  Amoxicillin_250mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Amoxicillin, 250mg tablet'))),'PIH','9071');
 
update temp_report t
 set  Amoxicillin_500mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Amoxicillin, 500mg tablet'))),'PIH','9071');

update temp_report t
 set  Ampicillin_1gram =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Ampicillin, Powder for solution for injection, 1 gram vial'))),'PIH','9071');

update temp_report t
 set  Clotrimazole_20g =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Clotrimazole, Skin cream, 1%, 20 gram tube'))),'PIH','9071');

update temp_report t
 set  Clotrimazole_500mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Clotrimazole, 500mg vaginal tablet with applicator'))),'PIH','9071');

update temp_report t
 set  Erythromycin_125mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Erythromycin, Powder for oral suspension, 125mg/5mL, 100mL bottle'))),'PIH','9071');

update temp_report t
 set  Erythromycin_250mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Erythromycin stearate, 250mg film coated tablet'))),'PIH','9071');

update temp_report t
 set  Gentamicin_drops =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Gentamicin sulfate, Eye and Ear drop, 0.3%, 10mL bottle'))),'PIH','9071');

update temp_report t
 set  Gentamicin_40mg_inj =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Gentamicin, Solution for injection, 40mg/mL, 2mL ampoule'))),'PIH','9071');

update temp_report t
 set  AL_6_Tab =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Artemether (A) 20mg + lumefantrine (L) 120mg tablet, 6 blisters of 1 dispersible tablet (5 to <15kg)'))),'PIH','9071');

update temp_report t
 set  AL_12_Tab =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Artemether (A) 20mg + lumefantrine (L) 120mg tablet,Pack of 6 blisters of 2 disp tablets (15-25kg)'))),'PIH','9071');

update temp_report t
 set  AL_18_Tab =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Artemether (A) 20mg + lumefantrine (L) 120mg tablet, Pack of 6 blisters of 3 tablet (25-35Kg)'))),'PIH','9071');

update temp_report t
 set  AL_24_Tab =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Artemether (A) 20mg + lumefantrine (L) 120mg tablet, Pack of 6 blisters of 4 tablets (Adult, >35kg)'))),'PIH','9071');

update temp_report t
 set  Artesunate_60mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Artesunate, 60mg powder for reconstitution, with 5mL sodium chloride and 1mL sodium bicarbonate 5%'))),'PIH','9071');

update temp_report t
 set  Quinine_sulfate_300mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Quinine sulfate, 300mg tablet'))),'PIH','9071');

update temp_report t
 set  Sulfadoxine_500mg_Pyrim_25mg =  obs_from_group_id_value_numeric(obs_group_id_from_obs(obs_id_with_drug_answer(t.Dispensing_encounter_id,drugId('Sulfadoxine (S) 500mg + Pyrimethamine (P) 25mg tablet'))),'PIH','9071');


-- If the patient is diagnosed as malaria positive and has received at least one of the anti-malarial drugs below(ACT)
update temp_report t
 set act = if((AL_6_Tab > 0 or AL_12_Tab > 0 or AL_18_Tab > 0 or AL_24_Tab > 0) ,1,0);

-- If the patient is diagnosed as malaria positive and has received at least one of the other anti-malarial drugs below(non ACT)
 update temp_report t
 set non_act = if((Artesunate_60mg > 0 or Quinine_sulfate_300mg > 0 or Sulfadoxine_500mg_Pyrim_25mg > 0) ,1,0);
 
 -- If the patient is diagnosed with pneumonia and has received at least one of the antibiotics drugs below
 update temp_report t
 set ari_antb = if((Amoxicillin_125mg > 0 or Amoxicillin_250mg > 0 or Amoxicillin_500mg > 0 or Ampicillin_1gram > 0 or Clotrimazole_20g > 0 or Clotrimazole_500mg > 0 or Erythromycin_125mg > 0 or Erythromycin_250mg > 0 or Gentamicin_40mg_inj > 0),1,0);

-- There were no condition on the diagnosis for now because there are many similar diagnosis for malaria and pneumonia, which requires a longer piece of coding, to consider in a later version 

select * from temp_report;

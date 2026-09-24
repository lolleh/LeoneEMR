DROP TEMPORARY TABLE IF EXISTS temp_patients;
CREATE TEMPORARY TABLE temp_patients
(
 patient_id          int(11),      
 family_name         varchar(255), 
 given_name          varchar(255), 
 chiefdom            varchar(255), 
 village             varchar(255), 
 district            varchar(255), 
 country             varchar(255), 
 section             varchar(255), 
 address             varchar(255), 
 birthdate           datetime,     
 birthdate_estimated char(1),      
 age                 double,       
 gender              char(1),      
 wellbody_emr_id     varchar(50),  
 kgh_emr_id          varchar(50),   
 national_id         varchar(50),  
 telephone_number    varchar(50)   
	);

insert into temp_patients (patient_id)
select patient_id from patient where voided = 0
;

-- patient name
update temp_patients t set t.family_name = person_family_name(patient_id);
update temp_patients t set t.given_name = person_given_name(patient_id);

-- person table fields
update temp_patients t
inner join person p on p.person_id = t.patient_id
set t.birthdate = p.birthdate,
	t.birthdate_estimated = p.birthdate_estimated,
	t.gender = p.gender,
    t.age = TIMESTAMPDIFF(YEAR, p.birthdate, NOW());

-- identifiers
update temp_patients set wellbody_emr_id = patient_identifier(patient_id, '1a2acce0-7426-11e5-a837-0800200c9a66');
update temp_patients set kgh_emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002' );
update temp_patients set national_id = patient_identifier(patient_id,'eb201574-8abe-4393-9a8a-8d30a48a08ad');
-- telephone number
update temp_patients t set t.telephone_number = phone_number(patient_id);

-- patient address
update temp_patients t
INNER JOIN person_address pa on pa.person_address_id =
	(select person_address_id from person_address pa2
	where pa2.person_id = t.patient_id
	and pa2.voided = 0
	order by preferred desc, date_created desc limit 1)
set chiefdom = pa.state_province,
	village = pa.city_village,
	district = pa.county_district,
 	t.country = pa.country,
	section = pa.address1,
	address = pa.address2;

SELECT
       family_name,
       given_name,
       country, 
       district,
       chiefdom,
       section,
       village,
       address,
       birthdate,
       birthdate_estimated,
       age,
       gender,
       wellbody_emr_id,
       kgh_emr_id,
       national_id,
       telephone_number
from temp_patients;

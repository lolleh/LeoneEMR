-- This is a script written to fulfill a data requestion submitted in May 2025
-- by Innocent and Foday. Tracked by UHM-8639.


drop table if exists cohort_staging
CREATE TABLE cohort_staging (
 patient_id                VARCHAR(100),  
 emr_id                    VARCHAR(30),  
 visit_id                  VARCHAR(50),   
 visit_date_started        DATETIME,      
 visit_date_stopped        DATETIME,      
 visit_type                VARCHAR(255),  
 visit_location            VARCHAR(255), 
 visit_user_entered        TEXT,
 mothers_first_name        VARCHAR(255),  
 country                   VARCHAR(255),  
 district                  VARCHAR(255),  
 chiefdom                  VARCHAR(255),  
 section                   VARCHAR(255),  
 village                   VARCHAR(255),  
 telephone_number          VARCHAR(50),   
 civil_status              VARCHAR(255),  
 occupation                VARCHAR(255),  
 reg_location              VARCHAR(50),   
 registration_date         DATE,          
 date_registration_entered DATETIME,      
 user_entered              VARCHAR(50),   
 first_encounter_date      DATE,          
 last_encounter_date       DATE,          
 name                      VARCHAR(50),   
 family_name               VARCHAR(50),   
 birthdate                 DATE,          
 birthdate_estimated       BIT,           
 gender                    VARCHAR(2),    
 dead                      BIT,           
 death_date                DATE,          
 cause_of_death            VARCHAR(100), 
 height             FLOAT, 
 weight             FLOAT, 
 temperature        FLOAT, 
 heart_rate         FLOAT, 
 respiratory_rate   FLOAT,  
 bp_systolic        FLOAT,
 bp_diastolic       FLOAT,
 o2_saturation      FLOAT, 
 muac_mm            FLOAT,
 chief_complaint    TEXT,
 diagnosis_1               VARCHAR(255), 
 diagnosis_2               VARCHAR(255), 
 diagnosis_3               VARCHAR(255),  
 diagnosis_4               VARCHAR(255), 
 diagnosis_5               VARCHAR(255), 
 diagnosis_6               VARCHAR(255),  
 diagnosis_7               VARCHAR(255), 
 diagnosis_8               VARCHAR(255), 
 diagnosis_9               VARCHAR(255),  
 diagnosis_10              VARCHAR(255), 
 diagnosis_11              VARCHAR(255), 
 diagnosis_12              VARCHAR(255), 
 diagnosis_13              VARCHAR(255),  
 diagnosis_14              VARCHAR(255), 
 diagnosis_15              VARCHAR(255), 
 diagnosis_16              VARCHAR(255), -- in this dataset there were up to 16 diagnoses
 med_1                     VARCHAR(255), 
 med_2                     VARCHAR(255), 
 med_3                     VARCHAR(255),  
 med_4                     VARCHAR(255), 
 med_5                     VARCHAR(255), 
 med_6                     VARCHAR(255),  
 med_7                     VARCHAR(255), 
 med_8                     VARCHAR(255), 
 med_9                     VARCHAR(255),  
 med_10                    VARCHAR(255), 
 med_11                    VARCHAR(255), 
 med_12                    VARCHAR(255), 
 med_13                    VARCHAR(255), -- in this dataset there were up to 13 meds
 test_1                    VARCHAR(255), 
 result_1                  VARCHAR(255), 
 test_2                    VARCHAR(255), 
 result_2                  VARCHAR(255), 
 test_3                    VARCHAR(255), 
 result_3                  VARCHAR(255), 
 test_4                    VARCHAR(255), 
 result_4                  VARCHAR(255), 
 test_5                    VARCHAR(255), 
 result_5                  VARCHAR(255), 
 test_6                    VARCHAR(255), 
 result_6                  VARCHAR(255), 
 test_7                    VARCHAR(255), 
 result_7                  VARCHAR(255), 
 test_8                    VARCHAR(255), 
 result_8                  VARCHAR(255), 
 test_9                    VARCHAR(255), 
 result_9                  VARCHAR(255), 
 test_10                   VARCHAR(255), 
 result_10                 VARCHAR(255), 
 test_11                   VARCHAR(255), 
 result_11                 VARCHAR(255), 
 test_12                   VARCHAR(255), 
 result_12                 VARCHAR(255), 
 test_13                   VARCHAR(255), 
 result_13                 VARCHAR(255), 
 test_14                   VARCHAR(255), 
 result_14                 VARCHAR(255), 
 test_15                   VARCHAR(255), 
 result_15                 VARCHAR(255), 
 test_16                   VARCHAR(255), 
 result_16                 VARCHAR(255), 
 test_17                   VARCHAR(255), 
 result_17                 VARCHAR(255), 
 test_18                   VARCHAR(255), 
 result_18                 VARCHAR(255), 
 test_19                   VARCHAR(255), 
 result_19                 VARCHAR(255), 
 test_20                   VARCHAR(255), 
 result_20                 VARCHAR(255), 
 test_21                   VARCHAR(255), 
 result_21                 VARCHAR(255), 
 test_22                   VARCHAR(255), 
 result_22                 VARCHAR(255), 
 test_23                   VARCHAR(255), 
 result_23                 VARCHAR(255), 
 test_24                   VARCHAR(255), 
 result_24                 VARCHAR(255), 
 test_25                   VARCHAR(255), 
 result_25                 VARCHAR(255), 
 test_26                   VARCHAR(255), 
 result_26                 VARCHAR(255), 
 test_27                   VARCHAR(255), 
 result_27                 VARCHAR(255), 
 test_28                   VARCHAR(255), 
 result_28                 VARCHAR(255), 
 test_29                   VARCHAR(255), 
 result_29                 VARCHAR(255), 
 test_30                   VARCHAR(255), 
 result_30                 VARCHAR(255), 
 test_31                   VARCHAR(255), 
 result_31                 VARCHAR(255), 
 test_32                   VARCHAR(255), 
 result_32                 VARCHAR(255), 
 test_33                   VARCHAR(255), 
 result_33                 VARCHAR(255), 
 test_34                   VARCHAR(255), 
 result_34                 VARCHAR(255), 
 test_35                   VARCHAR(255), 
 result_35                 VARCHAR(255), 
 test_36                   VARCHAR(255), 
 result_36                 VARCHAR(255), 
 test_37                   VARCHAR(255), 
 result_37                 VARCHAR(255), 
 test_38                   VARCHAR(255), 
 result_38                 VARCHAR(255), 
 test_39                   VARCHAR(255), 
 result_39                 VARCHAR(255), 
 test_40                   VARCHAR(255), 
 result_40                 VARCHAR(255), 
 test_41                   VARCHAR(255), 
 result_41                 VARCHAR(255), 
 test_42                   VARCHAR(255), 
 result_42                 VARCHAR(255), 
 test_43                   VARCHAR(255), 
 result_43                 VARCHAR(255), 
 test_44                   VARCHAR(255), 
 result_44                 VARCHAR(255), 
 test_45                   VARCHAR(255), 
 result_45                 VARCHAR(255), 
 test_46                   VARCHAR(255), 
 result_46                 VARCHAR(255), 
 test_47                   VARCHAR(255), 
 result_47                 VARCHAR(255) -- in this dataset there were up to 47 tests and results
);

insert into cohort_staging 
	(emr_id,
	visit_id,
	visit_date_started,
	visit_date_stopped,
	visit_type,
	visit_location,
	visit_user_entered)
select -- top 100
	v.emr_id,
	v.visit_id,
	v.visit_date_started,
	v.visit_date_stopped,
	v.visit_type,
	v.visit_location,
	v.visit_user_entered
from all_visits v
	where year(v.visit_date_stopped) >= 2020
	and year(v.visit_date_started) <= 2024;

create index temp_visit_ei on cohort_staging(emr_id);
create index temp_visit_pi on cohort_staging(patient_id);
create index temp_visit_c1 on cohort_staging(visit_id);

update v
set v.patient_id = p.patient_id
from cohort_staging v
inner join all_patients p on p.emr_id = v.emr_id;

update t
set t.mothers_first_name = p.mothers_first_name,
	t.country = p.country,
	t.district = p.district,
	t.chiefdom = p.chiefdom,
	t.section = p.section,
	t.village = p.village,
	t.telephone_number = p.telephone_number,
	t.civil_status = p.civil_status,
	t.occupation = p.occupation,
	t.reg_location = p.reg_location,
	t.registration_date = p.registration_date,
	t.date_registration_entered = p.date_registration_entered,
	t.user_entered = p.user_entered,
	t.first_encounter_date = p.first_encounter_date,
	t.last_encounter_date = p.last_encounter_date,
	t.name = p.name,
	t.family_name = p.family_name,
	t.birthdate = p.dob,
	t.birthdate_estimated = p.dob_estimated,
	t.gender = p.gender,
	t.dead = p.dead,
	t.death_date = p.death_date,
	t.cause_of_death = p.cause_of_death
from cohort_staging t 
inner join all_patients p on p.patient_id = t.patient_id;

-- diagnoses
drop table if exists #temp_dx;
create table #temp_dx
(
	visit_id          varchar(50),  
	diagnosis_entered varchar(255),
	index_asc int
);

insert into #temp_dx
	(visit_id,
	diagnosis_entered,
	index_asc)
select 
	concat(partition_num,'-',d.visit_id),
	d.diagnosis_entered,
	ROW_NUMBER() over (PARTITION by v.visit_id order by obs_id)
from all_diagnosis d
inner join cohort_staging v on v.visit_id = concat(partition_num,'-',d.visit_id);

update v set v.diagnosis_1 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 1;
update v set v.diagnosis_2 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 2;
update v set v.diagnosis_3 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 3;
update v set v.diagnosis_4 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 4;
update v set v.diagnosis_5 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 5;
update v set v.diagnosis_6 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 6;
update v set v.diagnosis_7 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 7;
update v set v.diagnosis_8 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 8;
update v set v.diagnosis_9 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 9;
update v set v.diagnosis_10 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 10;
update v set v.diagnosis_11 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 11;
update v set v.diagnosis_12 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 12;
update v set v.diagnosis_13 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 13;
update v set v.diagnosis_14 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 14;
update v set v.diagnosis_15 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 15;
update v set v.diagnosis_16 = d.diagnosis_entered from cohort_staging v inner join #temp_dx d on d.visit_id = v.visit_id and d.index_asc = 16;

-- add medication info
drop table if exists #temp_meds
create table #temp_meds
(   med_id int IDENTITY(1,1) PRIMARY KEY,
	patient_id varchar(50),
	visit_id          varchar(50),  
	encounter_datetime datetime,
	drug_name varchar(255),  
	index_asc int
);

insert into #temp_meds
	(patient_id,
	encounter_datetime,
	drug_name)
select distinct 
	amd.patient_id, 
	amd.encounter_datetime,
	amd.drug_name
from all_medication_dispensing amd
where year(amd.encounter_datetime) >= 2020
and year(amd.encounter_datetime) <= 2024
and amd.drug_name is not null;

-- associate the meds with visits:
drop table if exists #temp_all_visits;
select
 patient_id, 
 visit_id,
 visit_date_started
into #temp_all_visits
from cohort_staging;

drop table if exists #temp_all_visits_dup;
select * into #temp_all_visits_dup from #temp_all_visits;

create index temp_all_visits_ci on #temp_all_visits(visit_id);
create index temp_all_visits_dup_c1 on #temp_all_visits_dup(patient_id, visit_date_started);

update t
	set t.visit_id = v.visit_id
from #temp_meds t
inner join #temp_all_visits v on v.visit_id = (
	select top 1 v2.visit_id 
	from #temp_all_visits_dup v2
	where v2.patient_id = t.patient_id
	and v2.visit_date_started <= t.encounter_datetime
	order by v2.visit_date_started desc);

drop table if exists #derived_indexes;
select  med_id,
        ROW_NUMBER() over (PARTITION by visit_id order by med_id) as index_asc
into    #derived_indexes
from    #temp_meds;

create index temp_meds_mi on #temp_meds(med_id);
create index temp_meds_c1 on #temp_meds(visit_id, index_asc);

update t
set t.index_asc = i.index_asc
from #temp_meds t inner join #derived_indexes i on i.med_id = t.med_id
;

update v set v.med_1 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 1;
update v set v.med_2 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 2;
update v set v.med_3 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 3;
update v set v.med_4 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 4;
update v set v.med_5 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 5;
update v set v.med_6 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 6;
update v set v.med_7 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 7;
update v set v.med_8 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 8;
update v set v.med_9 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 9;
update v set v.med_10 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 10;
update v set v.med_11 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 11;
update v set v.med_12 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 12;
update v set v.med_13 = m.drug_name from cohort_staging v inner join #temp_meds m on m.visit_id = v.visit_id and m.index_asc = 13;

-- add lab information
drop table if exists #temp_labs;
create table #temp_labs
(   lab_id int IDENTITY(1,1) PRIMARY KEY,
	patient_id varchar(50),
	specimen_collection_date datetime,
	visit_id          varchar(50),  
	test varchar(255),
	result varchar(255),
	index_asc int
);

insert into #temp_labs
	(patient_id,
	specimen_collection_date,
	test, 
	result)
select distinct
	l.patient_id,
	l.specimen_collection_date,
	l.test, 
	l.result
from labs_order_results l
where year(l.specimen_collection_date) >= 2020
and year(l.specimen_collection_date) <= 2024
and l.test is not null;

-- associate the labs with visits:
update t
	set t.visit_id = v.visit_id
from #temp_labs t
inner join #temp_all_visits v on v.visit_id = (
	select top 1 v2.visit_id 
	from #temp_all_visits_dup v2
	where v2.patient_id = t.patient_id
	and cast(v2.visit_date_started as date) <= cast(t.specimen_collection_date as date)
	order by v2.visit_date_started desc);

create index temp_labs_mi on #temp_labs(lab_id);
create index temp_labs_c1 on #temp_labs(visit_id, index_asc);

drop table if exists #derived_indexes;
select  lab_id,
        ROW_NUMBER() over (PARTITION by visit_id order by lab_id) as index_asc
into    #derived_indexes
from    #temp_labs;

update t
set t.index_asc = i.index_asc
from #temp_labs t inner join #derived_indexes i on i.lab_id = t.lab_id
;

UPDATE v SET v.test_1 = l.test, v.result_1 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 1;
UPDATE v SET v.test_2 = l.test, v.result_2 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 2;
UPDATE v SET v.test_3 = l.test, v.result_3 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 3;
UPDATE v SET v.test_4 = l.test, v.result_4 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 4;
UPDATE v SET v.test_5 = l.test, v.result_5 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 5;
UPDATE v SET v.test_6 = l.test, v.result_6 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 6;
UPDATE v SET v.test_7 = l.test, v.result_7 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 7;
UPDATE v SET v.test_8 = l.test, v.result_8 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 8;
UPDATE v SET v.test_9 = l.test, v.result_9 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 9;
UPDATE v SET v.test_10 = l.test, v.result_10 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 10;
UPDATE v SET v.test_11 = l.test, v.result_11 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 11;
UPDATE v SET v.test_12 = l.test, v.result_12 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 12;
UPDATE v SET v.test_13 = l.test, v.result_13 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 13;
UPDATE v SET v.test_14 = l.test, v.result_14 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 14;
UPDATE v SET v.test_15 = l.test, v.result_15 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 15;
UPDATE v SET v.test_16 = l.test, v.result_16 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 16;
UPDATE v SET v.test_17 = l.test, v.result_17 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 17;
UPDATE v SET v.test_18 = l.test, v.result_18 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 18;
UPDATE v SET v.test_19 = l.test, v.result_19 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 19;
UPDATE v SET v.test_20 = l.test, v.result_20 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 20;
UPDATE v SET v.test_21 = l.test, v.result_21 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 21;
UPDATE v SET v.test_22 = l.test, v.result_22 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 22;
UPDATE v SET v.test_23 = l.test, v.result_23 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 23;
UPDATE v SET v.test_24 = l.test, v.result_24 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 24;
UPDATE v SET v.test_25 = l.test, v.result_25 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 25;
UPDATE v SET v.test_26 = l.test, v.result_26 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 26;
UPDATE v SET v.test_27 = l.test, v.result_27 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 27;
UPDATE v SET v.test_28 = l.test, v.result_28 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 28;
UPDATE v SET v.test_29 = l.test, v.result_29 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 29;
UPDATE v SET v.test_30 = l.test, v.result_30 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 30;
UPDATE v SET v.test_31 = l.test, v.result_31 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 31;
UPDATE v SET v.test_32 = l.test, v.result_32 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 32;
UPDATE v SET v.test_33 = l.test, v.result_33 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 33;
UPDATE v SET v.test_34 = l.test, v.result_34 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 34;
UPDATE v SET v.test_35 = l.test, v.result_35 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 35;
UPDATE v SET v.test_36 = l.test, v.result_36 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 36;
UPDATE v SET v.test_37 = l.test, v.result_37 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 37;
UPDATE v SET v.test_38 = l.test, v.result_38 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 38;
UPDATE v SET v.test_39 = l.test, v.result_39 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 39;
UPDATE v SET v.test_40 = l.test, v.result_40 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 40;
UPDATE v SET v.test_41 = l.test, v.result_41 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 41;
UPDATE v SET v.test_42 = l.test, v.result_42 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 42;
UPDATE v SET v.test_43 = l.test, v.result_43 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 43;
UPDATE v SET v.test_44 = l.test, v.result_44 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 44;
UPDATE v SET v.test_45 = l.test, v.result_45 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 45;
UPDATE v SET v.test_46 = l.test, v.result_46 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 46;
UPDATE v SET v.test_47 = l.test, v.result_47 = l.result FROM cohort_staging v INNER JOIN #temp_labs l ON l.visit_id = v.visit_id AND l.index_asc = 47;

-- latest vitals
drop table if exists #temp_vitals;
create table #temp_vitals
(    visit_id          varchar(50),  
	 height             FLOAT, 
	 weight             FLOAT, 
	 temperature        FLOAT, 
	 heart_rate         FLOAT, 
	 respiratory_rate   FLOAT,  
	 bp_systolic        FLOAT,
	 bp_diastolic       FLOAT,
	 o2_saturation      FLOAT, 
	 muac_mm            FLOAT,
	 chief_complaint    TEXT,
	 index_desc         INT
);

insert into #temp_vitals
	(visit_id,
	 height, 
	 weight, 
	 temperature, 
	 heart_rate, 
	 respiratory_rate,  
	 bp_systolic,
	 bp_diastolic,
	 o2_saturation, 
	 muac_mm,
	 chief_complaint,
     index_desc)
select 
	v.visit_id,
	v.height, 
	v.weight, 
	v.temperature, 
	v.heart_rate, 
	v.respiratory_rate,  
	v.bp_systolic,
	v.bp_diastolic,
	v.o2_saturation, 
	v.muac_mm,
	v.chief_complaint,
	ROW_NUMBER() over (PARTITION by v.visit_id order by v.encounter_datetime desc)
from all_vitals v
inner join cohort_staging t on t.visit_id = v.visit_id;

create index temp_vitals_c1 on #temp_vitals(visit_id, index_desc);

update t set t.height = v.height from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.weight = v.weight from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.temperature = v.temperature from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.heart_rate = v.heart_rate from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.respiratory_rate = v.respiratory_rate from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.bp_systolic = v.bp_systolic from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.bp_diastolic = v.bp_diastolic from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.o2_saturation = v.o2_saturation from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.muac_mm = v.muac_mm from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;
update t set t.chief_complaint = v.chief_complaint from cohort_staging t inner join #temp_vitals v on t.visit_id = v.visit_id and v.index_desc = 1;

DROP TABLE IF EXISTS cohort_2020_to_2024;
EXEC sp_rename 'cohort_staging', 'cohort_2020_to_2024';

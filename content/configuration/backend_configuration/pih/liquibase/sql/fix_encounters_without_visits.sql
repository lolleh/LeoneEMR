-- load encounters with no visit (excluding encounter types that typically are not slotted)
drop temporary table if exists temp_no_visits;
CREATE temporary table temp_no_visits
	select e.encounter_id, et.name  , e.patient_id , e.encounter_datetime , count(o.obs_id) "obs_count"
	from encounter e
	inner join encounter_type et on et.encounter_type_id = e.encounter_type 
	left outer join obs o on o.encounter_id = e.encounter_id 
	where e.visit_id is null
		and e.voided = 0
		and encounter_type not in
		(select encounter_type_id from encounter_type where uuid in
		('10db3139-07c0-4766-b4e5-a41b01363145','1545d7ff-60f1-485e-9c95-5740b8e6634b','873f968a-73a8-4f9c-ac78-9f4778b751b6',
		'4d77916a-0620-11e5-a6c0-1697f925ec7b','5b1b4a4e-0084-4137-87db-dba76c784439','74cef0a6-2801-11e6-b67b-9e71128cae77','d5ca53a7-d3b5-44ac-9aa2-1491d2a4b4e9',
		'873f968a-73a8-4f9c-ac78-9f4778b751b6','39C09928-0CAB-4DBA-8E48-39C631FA4286','b3a0e3ad-b80c-4f3f-9626-ace1ced7e2dd'))
	group by e.encounter_id, et.name  , e.patient_id , e.encounter_datetime;

create index temp_no_visits_1 on temp_no_visits(encounter_id);

-- void empty encounters with no visits
update encounter e
inner join temp_no_visits t on t.encounter_id = e.encounter_id and t.obs_count = 0
	set e.voided = 1,
	voided_by = (select user_id from users where system_id = 'admin'),
	date_voided = now(),
	void_reason = 'empty encounter with no visit';

delete from temp_no_visits where obs_count = 0;

-- gather all visits same day as those encounters
drop temporary table if exists temp_visits;
CREATE temporary table temp_visits
	select v.visit_id , v.patient_id , v.date_started , v.date_stopped
	from visit v
	inner join temp_no_visits t on t.patient_id = v.patient_id  
		and ((date(v.date_stopped) = date(t.encounter_datetime))
			or (v.date_started <= t.encounter_datetime and v.date_stopped >=t.encounter_datetime)) ;

drop temporary table if exists temp_visits2;
CREATE temporary table temp_visits2
	select * from temp_visits;

create index temp_visits_1 on temp_visits(visit_id);

-- identify visits encounters should be slotted into
drop temporary table if exists temp_fixed_visits;
create temporary table temp_fixed_visits
	select t.encounter_id,t.patient_id, t.encounter_datetime, v.visit_id, v.date_started, v.date_stopped
	from temp_no_visits t
	left outer join temp_visits v on v.visit_id =
		(select v2.visit_id from temp_visits2 v2
		where v2.patient_id = t.patient_id
		and v2.date_started <= t.encounter_datetime
		and v2.date_stopped >= t.encounter_datetime
		order by v2.date_stopped desc limit 1 
		)
	;

update temp_fixed_visits t
inner join temp_visits v on v.visit_id =
	(select v2.visit_id from temp_visits2 v2
	where v2.patient_id = t.patient_id
	and date(v2.date_stopped) = date(t.encounter_datetime)
	and v2.date_stopped < t.encounter_datetime 
	order by v2.date_stopped desc limit 1
	)
set t.visit_id = v.visit_id,
	t.date_started = v.date_started,
	t.date_stopped = v.date_stopped
where t.visit_id is null;

create index temp_fixed_visits_ei on temp_fixed_visits(encounter_id);

-- expand visit date_stopped
update visit v 
inner join temp_fixed_visits t on t.visit_id = v.visit_id
set v.date_stopped = t.encounter_datetime,
	date_changed = now(),
	changed_by = (select user_id from users where system_id = 'admin')
where v.date_stopped < t.encounter_datetime;

-- slot encounters into visits
update encounter e 
inner join temp_fixed_visits t on t.encounter_id = e.encounter_id
set e.visit_id = t.visit_id,
	date_changed = now(),
	changed_by = (select user_id from users where system_id = 'admin')

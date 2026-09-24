-- set @handoverDate = '2026-02-23';
-- set @shift = 'morning'; -- 'evening' ;

set @startTime = 
case
	when @shift = 'morning' then DATE_SUB(@handoverDate, INTERVAL 1 DAY) + INTERVAL 8 HOUR
	when @shift = 'evening' then @handoverDate + INTERVAL 8 HOUR
end;

set @endTime = 
case
	when @shift = 'morning' then @handoverDate + INTERVAL 8 HOUR
	when @shift = 'evening' then @handoverDate + INTERVAL 20 HOUR	
end;

set @delivery_datetime = concept_from_mapping('PIH','5599');
set @baby_construct = concept_from_mapping('PIH','13555');
set @type_delivery = concept_from_mapping('PIH','11663');
set @outcome = concept_from_mapping('PIH','13561');
set @csection = concept_from_mapping('PIH','9336');
set @vacuum = concept_from_mapping('PIH','10752');
set @vaginal = concept_from_mapping('PIH','1170');
select encounter_type_id into @delivery from encounter_type where uuid = 'fec2cc56-e35f-42e1-8ae3-017142c1ca59';

-- add obs for delivery datetimes 
DROP TEMPORARY TABLE IF EXISTS temp_delivery_datetimes;
create temporary table temp_delivery_datetimes 
(select o.obs_id, o.voided ,o.obs_group_id ,o.concept_id, o.value_coded 
from obs o
inner join encounter e on e.encounter_id = o.encounter_id and e.voided = 0 and e.encounter_type =  @delivery
where o.voided = 0
and o.concept_id in (@delivery_datetime)
and o.value_datetime >= @startTime
and o.value_datetime <=  @endTime);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
(select o.obs_id, o.voided ,o.obs_group_id ,o.concept_id, o.value_coded 
from temp_delivery_datetimes t 
inner join obs o on o.obs_group_id = t.obs_group_id and o.voided = 0 and o.concept_id in (@type_delivery, @outcome)
);

drop temporary table if exists temp_births;
create temporary table temp_births
(select obs_group_id,
max(case when concept_id = @outcome then concept_name(value_coded,'en') end) "outcome",
max(case when concept_id = @type_delivery then value_coded end) "type"
from temp_obs
group by obs_group_id);

drop temporary table if exists temp_final;
create temporary table temp_final 
(outcome varchar(255),
c_section int,
vacuum int,
vaginal int,
no_type_of_delivery int,
total int);

INSERT INTO temp_final (outcome) VALUES
  ('Livebirth'),
  ('Fresh Stillbirth'),
  ('Macerated Stillbirth'),
  ('No Outcome'),
  ('Total');

update temp_final f 
inner join 
	(select outcome,
	sum(case when type = @csection then 1 else 0 end) "c_section",
	sum(case when type = @vacuum then 1 else 0 end) "vacuum",
	sum(case when type = @vaginal then 1 else 0 end) "vaginal",
	sum(case when type is null then 1 else 0 end) "no_type_of_delivery"
	from temp_births
	group by outcome) i on ifnull(i.outcome,'No Outcome') = f.outcome
set 
f.c_section = i.c_section,
f.vacuum = i.vacuum,
f.vaginal = i.vaginal,
f.no_type_of_delivery = i.no_type_of_delivery;

SELECT
  IFNULL(SUM(C_Section),0),
  IFNULL(SUM(Vacuum),0),
  IFNULL(SUM(Vaginal),0),
  IFNULL(SUM(No_Type_of_Delivery),0),
  IFNULL(SUM(Total),0)
INTO
  @c_section,
  @vacuum,
  @vaginal,
  @no_type,
  @total
FROM temp_final;

update temp_final f 
set c_section = @c_section,
	vacuum = @vacuum,
	vaginal = @vaginal,
	no_type_of_delivery = @no_type, 
	total = @total 
where f.outcome = 'Total';

update temp_final f set total = 0 where total is null;
update temp_final f set c_section = 0 where c_section is null;
update temp_final f set vacuum = 0 where vacuum is null;
update temp_final f set vaginal = 0 where vaginal is null;
update temp_final f set no_type_of_delivery = 0 where no_type_of_delivery is null;

update temp_final f 
set total = c_section + vacuum + vaginal + no_type_of_delivery ;

delete from temp_final 
where outcome = 'No Outcome' and total = 0 ;

select 
outcome "Outcome", 
c_section "C_Section",
vacuum "Vacuum",
vaginal "Vaginal",
no_type_of_delivery "missing_Delivery_Type",
total "Total"
from temp_final;

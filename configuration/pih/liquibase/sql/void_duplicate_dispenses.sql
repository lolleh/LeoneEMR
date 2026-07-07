drop temporary table if exists tmp_medication_dispense_left;
drop temporary table if exists tmp_medication_dispense_right;
select concept_id into @complete from concept where uuid='3cd93172-26fe-102b-80cb-0017a47871b2';

-- create a temp table of the core elements of a medication dispense plus the linked order
-- ignore all voided orders/dispenses, any orders with refills, and any dispenses that aren't of type "complete"
create temporary table tmp_medication_dispense_left as
select do.order_id, md.medication_dispense_id, md.drug_order_id, md.dispenser, md.concept, md.drug_id, md.quantity, md.quantity_units, md.dose, md.route, md.frequency, md.as_needed, md.date_created
from drug_order do, medication_dispense md, orders o
where do.order_id = md.drug_order_id
  and o.order_id = do.order_id
  and o.voided = 0
  and do.num_refills = 0
  and md.status = @complete
  and md.voided = 0;

-- add a "to_void" boolean and a counter to the table
alter table tmp_medication_dispense_left  add column to_void boolean;
alter table tmp_medication_dispense_left  add column counter INT, ADD INDEX(counter);

-- number the rows in the table, sorted by order id and then by date created
-- we now should have an ordered list, grouped by order, with any dispenses associated with that order ordered by date_created
set @counter = 0;
update tmp_medication_dispense_left
set counter = (@counter := @counter + 1)
    order by order_id, date_created;

-- copy the table
create temporary table tmp_medication_dispense_right as
select * from tmp_medication_dispense_left;

-- increment the counter on this new table so we now can join on these two tables to compare each row to the subsequent row
update tmp_medication_dispense_right
set counter = counter + 1;

-- join the two tables and pull out all cases where the order, dispenser, concept, drug, quantity,quantity units, dose, route, frequency and as needed are the same
-- AND the difference between the date_created of the two dispenses is less than a minute
-- set the "to_void" on the second of the two rows to "true"
update tmp_medication_dispense_left md_left, tmp_medication_dispense_right md_right
set md_right.to_void = true
where md_left.counter = md_right.counter
  and md_left.order_id = md_right.order_id
  and md_left.dispenser = md_right.dispenser
  and md_left.concept = md_right.concept
  and md_left.drug_id = md_right.drug_id
  and md_left.quantity = md_right.quantity
  and md_left.quantity_units = md_right.quantity_units
  and md_left.dose = md_right.dose
  and md_left.route = md_right.route
  and md_left.frequency = md_right.frequency
  and md_left.as_needed = md_right.as_needed
  and ABS(TIMESTAMPDIFF(SECOND , md_left.date_created, md_right.date_created)) < 60;

-- void the rows in the medication dispense table that have been flagged
update medication_dispense md, tmp_medication_dispense_right tmp
set voided=1, voided_by=1, date_voided=NOW(), void_reason='flagged as duplicate by cleanup script - UHM-8795'
where md.medication_dispense_id = tmp.medication_dispense_id and tmp.to_void=true;
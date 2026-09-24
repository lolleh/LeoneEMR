-- EMR ID generator FAL-prefix guard (Falaba deployment)
--
-- pihcore 2.2.0 hardcodes a "KGH Primary Identifier Source" (uuid
-- 809b23e3-7162-11eb-8aa6-0242ac110002, prefix 'KGH'yyMM) for all Sierra Leone
-- KGH-family sites and re-applies it on EVERY OpenMRS boot. This repo/city
-- runs the Falaba site, so we hold the generator on the FAL prefix.
--
-- Apply once against the OpenMRS DB (mysql client). The scheduler events below
-- re-assert the FAL prefix/name every 15s, so a pihcore reset at boot is
-- corrected within seconds. The OpenMRS db service must run mysqld with
-- --event-scheduler=ON (docker-compose.yml does this) for the events to fire.
--
--   docker exec -i phu360-openmrs-db-1 mysql -uroot -pAdmin123 openmrs < scripts/emr-id-falaba-guard.sql

CREATE EVENT IF NOT EXISTS emr_id_falaba_prefix_guard
  ON SCHEDULE EVERY 15 SECOND
  DO UPDATE idgen_seq_id_gen SET prefix = '''FAL''yyMM'
     WHERE id = 1 AND prefix <> '''FAL''yyMM';

CREATE EVENT IF NOT EXISTS emr_id_falaba_source_name_guard
  ON SCHEDULE EVERY 15 SECOND
  DO UPDATE idgen_identifier_source i JOIN idgen_seq_id_gen s ON s.id = i.id
     SET i.name = 'FAL Primary Identifier Source',
         i.description = 'Primary Identifier Generator for FAL'
     WHERE i.uuid = '809b23e3-7162-11eb-8aa6-0242ac110002'
       AND i.name <> 'FAL Primary Identifier Source';

-- Registration-facility guard: a patient's registration facility must be one of
-- the three CHCs (Falaba CHC, Mongo Bendugu CHC, Sinkunia CHC). Registration
-- stamps the EMR identifier with the staff sub-location (e.g. "Falaba CHC
-- Clinic", "Mongo Bendugu CHC Triage"), whose parent is the CHC. This event
-- normalizes the EMR identifier location up to its top-level CHC (parent with
-- parent_location IS NULL among the three CHCs) every 30s, so the patient
-- search "Reg Facility" column only ever shows one of the three health centers.

CREATE EVENT IF NOT EXISTS emr_id_reg_facility_guard
  ON SCHEDULE EVERY 30 SECOND
  DO UPDATE patient_identifier pi
       JOIN location child ON child.location_id = pi.location_id
       JOIN location root  ON root.location_id = child.parent_location
       LEFT JOIN location grand ON grand.location_id = root.parent_location
     SET pi.location_id = root.location_id
     WHERE pi.identifier_type = 5 AND pi.voided = 0
       AND child.parent_location IS NOT NULL
       AND root.parent_location IS NULL
       AND root.name IN ('Falaba CHC','Mongo Bendugu CHC','Sinkunia CHC');
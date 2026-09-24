#!/usr/bin/env python3
"""
Seed demo clinical data for the "Above Five (General) Treatment Register".

Inserts demo patients, Visit Note encounters (range 2026-01-01..2026-12-31),
and obs for the header dropdown fields + morbidity conditions, so that the
"Above Five Register - Morbidity Summary" and "Above Five Register - Patient
List" reports produce populated output.

Idempotent: deletes previously seeded demo patients (identifiers 20001V..) and
their encounters/obs first, then re-inserts.
"""
import subprocess
import uuid

MYSQL = "docker compose exec -T openmrs-db mysql -uopenmrs -pAdmin123 openmrs --batch --raw"
HERE = "/home/ubuntu/dhis2-demo-server/openmrs-forms/above-five-treatment-register"

YES = 1065                      # OpenMRS built-in "Yes"
ENC_TYPE = 3                    # Visit Note
FORM_ID = 6                     # Above Five (General) Treatment Register
IDENT_TYPE = 4                  # OpenMRS ID
CREATOR = 1                     # admin

# Header concept ids (from the register form)
T = {
    "ownership": 165276,
    "service_point": 165277,
    "reg_num": 165278,
    "date_onset": 165279,
    "nin": 165280,
    "type_of_visit": 165281,
    "category": 165282,
}
# Dropdown answer concept ids
A = {
    "public": 165300, "private": 165301, "faithbase": 165302,
    "in_facility": 165303, "outreach": 165304,
    "new": 165305, "follow_up": 165306,
    "preg": 165307, "lact": 165308, "evd_surv": 165309,
    "disability": 165310, "gen": 165311,
}

# Condition concept ids (morbidity), from the register checklist
import json
COND = json.load(open("/tmp/afr_cond_names.json"))
COND_NAME_TO_ID = {k.split(": ")[-1].strip(): v for k, v in COND.items()}


def db(sql):
    out = subprocess.run(MYSQL, shell=True, input=sql + "\n", capture_output=True, text=True)
    if out.returncode != 0:
        raise RuntimeError("MySQL error: %s" % out.stderr)
    return out.stdout


def uuid4():
    return str(uuid.uuid4())


def clean():
    db("""
DROP TEMPORARY TABLE IF EXISTS _afr_pids;
CREATE TEMPORARY TABLE _afr_pids AS
  SELECT patient_id FROM patient_identifier WHERE identifier LIKE '20001V%';
DELETE o FROM obs o JOIN _afr_pids p ON p.patient_id = o.person_id;
DELETE e FROM encounter e JOIN _afr_pids p ON p.patient_id = e.patient_id;
DELETE FROM patient_identifier WHERE patient_id IN (SELECT patient_id FROM _afr_pids);
DELETE FROM patient WHERE patient_id IN (SELECT patient_id FROM _afr_pids);
DELETE FROM person_name WHERE person_id IN (SELECT patient_id FROM _afr_pids);
DELETE FROM person WHERE person_id IN (SELECT patient_id FROM _afr_pids);
DROP TEMPORARY TABLE _afr_pids;
""")


def insert_patient(given, family, gender, birthdate, identifier):
    pid = uuid4()
    return db(f"""
SET @person_id = NULL;
INSERT INTO person (gender, birthdate, birthdate_estimated, dead, death_date, cause_of_death, creator, date_created, voided, uuid)
VALUES ('{gender}', '{birthdate}', 0, 0, NULL, NULL, {CREATOR}, NOW(), 0, '{pid}');
SET @person_id = LAST_INSERT_ID();
INSERT INTO patient (patient_id, creator, date_created, changed_by, date_changed, voided, voided_by, date_voided, void_reason, allergy_status)
VALUES (@person_id, {CREATOR}, NOW(), NULL, NULL, 0, NULL, NULL, NULL, 'Unknown');
INSERT INTO person_name (preferred, person_id, given_name, family_name, creator, date_created, voided, uuid)
VALUES (1, @person_id, '{given}', '{family}', {CREATOR}, NOW(), 0, '{uuid4()}');
INSERT INTO patient_identifier (patient_id, identifier, identifier_type, preferred, location_id, creator, date_created, voided, uuid)
VALUES (@person_id, '{identifier}', {IDENT_TYPE}, 1, 7, {CREATOR}, NOW(), 0, '{uuid4()}');
SELECT @person_id;
""")


def insert_encounter(pid, dt):
    return db(f"""
INSERT INTO encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, voided, uuid)
VALUES ({ENC_TYPE}, {pid}, 7, {FORM_ID}, '{dt}', {CREATOR}, NOW(), 0, '{uuid4()}');
SET @enc_id = LAST_INSERT_ID();
SELECT @enc_id;
""")


def insert_obs(pid, enc_id, concept_id, dt, value_coded=None, value_text=None):
    vc = "NULL" if value_coded is None else str(value_coded)
    vt = "NULL" if value_text is None else "'%s'" % str(value_text).replace("'", "''")
    db(f"""
INSERT INTO obs (person_id, concept_id, encounter_id, obs_datetime, location_id, obs_group_id, accession_number,
                 value_group_id, value_coded, value_coded_name_id, value_drug, value_datetime, value_numeric,
                 value_modifier, value_text, value_complex, comments, creator, date_created, voided, uuid, status, interpretation)
VALUES ({pid}, {concept_id}, {enc_id}, '{dt}', 7, NULL, NULL, NULL, {vc}, NULL, NULL, NULL, NULL, NULL, {vt}, NULL, NULL,
        {CREATOR}, NOW(), 0, '{uuid4()}', 'FINAL', NULL);
""")


# ---------------------------------------------------------------------------
DEMO = [
    # (given, family, gender, birthdate, identifier, type_of_visit, category, ownership, service_point, reg_num, conditions)
    ("Amina", "Nakato", "F", "2011-03-15", "20001V", "new", "gen", "public", "in_facility", "2001", ["Malaria microscopy positive", "UTI (urinary tract infection)"]),
    ("John", "Okello", "M", "2000-07-22", "20002V", "follow_up", "gen", "public", "in_facility", "2002", ["Diabetes (Type 1 or 2)", "Hypertension"]),
    ("Grace", "Apio", "F", "1993-11-02", "20003V", "new", "preg", "private", "outreach", "2003", ["Malaria treated with ACT less than 24 hours", "Severe malaria"]),
    ("Peter", "Ochieng", "M", "2016-05-30", "20004V", "new", "gen", "faithbase", "in_facility", "2004", ["Pneumonia with antibiotic", "Diarrhoea without blood treated with ORS and Zinc"]),
    ("Betty", "Namukasa", "F", "1980-01-19", "20005V", "follow_up", "lact", "public", "in_facility", "2005", ["Dysentery (bloody diarrhoea)", "Anaemia"]),
    ("David", "Mugisha", "M", "2010-09-09", "20006V", "follow_up", "disability", "public", "outreach", "2006", ["Meningitis / Encephalitis"]),
    ("Sarah", "Adong", "F", "2005-04-25", "20007V", "new", "gen", "public", "in_facility", "2007", ["Fever cases (suspected malaria)", "Worm infestation"]),
]

clean()

for given, family, gender, birthdate, identifier, t_of_visit, cat, own, sp, reg, conds in DEMO:
    pid_raw = insert_patient(given, family, gender, birthdate, identifier)
    pid = pid_raw.splitlines()[-1].strip()
    for i, dt in enumerate(["2026-02-10 09:30:00", "2026-05-15 14:00:00", "2026-08-20 10:15:00"]):
        enc_raw = insert_encounter(pid, dt)
        enc = enc_raw.splitlines()[-1].strip()
        insert_obs(pid, enc, T["type_of_visit"], dt, value_coded=A[t_of_visit])
        insert_obs(pid, enc, T["category"], dt, value_coded=A[cat])
        insert_obs(pid, enc, T["ownership"], dt, value_coded=A[own])
        insert_obs(pid, enc, T["service_point"], dt, value_coded=A[sp])
        insert_obs(pid, enc, T["reg_num"], dt, value_text=reg)
        for cond in conds:
            if cond in COND_NAME_TO_ID:
                insert_obs(pid, enc, COND_NAME_TO_ID[cond], dt, value_coded=YES)

print("Seed complete: %d demo patients, %d encounters each." % (len(DEMO), 3))

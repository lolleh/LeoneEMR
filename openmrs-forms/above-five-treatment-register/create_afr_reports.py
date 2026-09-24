#!/usr/bin/env python3
"""
Create the "Above Five Register" reports for the OpenMRS Reporting module.

Inserts two ReportDefinition serialized objects + matching report designs:
  1. Above Five Register - Morbidity Summary (count cases per condition in a range)
  2. Above Five Register - Patient List (per-visit header details)

Relies on the running OpenMRS/MySQL stack (docker compose).
"""
import json
import subprocess
import uuid
import html as html_mod

HERE = "/home/ubuntu/dhis2-demo-server/openmrs-forms/above-five-treatment-register"
YES_CONCEPT_ID = 1065          # OpenMRS built-in "Yes"
ENCOUNTER_TYPE_ID = 3          # Visit Note
HEADER = {
    "type_of_visit": 165281,
    "category": 165282,
    "ownership": 165276,
    "service_point": 165277,
    "reg_num": 165278,
    "date_onset": 165279,
    "nin": 165280,
}
COND = json.load(open("/tmp/afr_cond_names.json"))  # name -> concept_id

MYSQL = "docker compose exec -T openmrs-db mysql -uopenmrs -pAdmin123 openmrs --batch --raw"


def db(sql):
    out = subprocess.run(MYSQL, shell=True, input=sql + "\n", capture_output=True, text=True)
    return out.stdout, out.stderr


def quote_sql(s):
    """Escape a string for safe embedding in a MySQL string literal."""
    return s.replace("\\", "\\\\").replace("'", "''").replace("\n", "\\n").replace("\r", "\\r")


def xml_escape(s):
    """XML-escape text content that will be deserialised by XStream."""
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def build_morbidity_query():
    """Per-condition case counts for the date range."""
    cond_ids = ",".join(str(v) for v in sorted(set(COND.values())))
    return f"""
select
  cn.name as `Condition`,
  count(distinct o.obs_id) as `Cases`
from obs o
join encounter e on e.encounter_id = o.encounter_id
join concept c on c.concept_id = o.concept_id
join concept_name cn on cn.concept_id = c.concept_id
  and cn.locale_preferred = 1 and cn.concept_name_type in ('FULLY_SPECIFIED')
where e.encounter_type = {ENCOUNTER_TYPE_ID}
  and o.voided = 0
  and o.concept_id in ({cond_ids})
  and o.value_coded = {YES_CONCEPT_ID}
  and e.encounter_datetime >= :startDate
  and e.encounter_datetime <= :endDate
group by o.concept_id, cn.name
order by `Cases` desc
"""


def build_headers_query():
    """Per-visit list with header fields, one row per encounter."""
    return f"""
select
  e.encounter_datetime as `Date seen`,
  concat(pn.given_name, ' ', coalesce(pn.family_name,'')) as `Patient`,
  pers.gender as `Sex`,
  timestampdiff(year, pers.birthdate, e.encounter_datetime) as `Age`,
  max(case when o.concept_id = {HEADER['type_of_visit']} then coalesce(ca.name, cast(o.value_coded as char)) end) as `Type of visit`,
  max(case when o.concept_id = {HEADER['category']} then coalesce(ca.name, cast(o.value_coded as char)) end) as `Category of patient`,
  max(case when o.concept_id = {HEADER['ownership']} then coalesce(ca.name, cast(o.value_coded as char)) end) as `Ownership`,
  max(case when o.concept_id = {HEADER['service_point']} then coalesce(ca.name, cast(o.value_coded as char)) end) as `Service point`,
  max(case when o.concept_id = {HEADER['reg_num']} then o.value_text end) as `Registration no.`
from encounter e
join patient p on p.patient_id = e.patient_id and p.voided = 0
join person pers on pers.person_id = p.patient_id
left join person_name pn on pn.person_id = p.patient_id and pn.voided = 0
left join obs o on o.encounter_id = e.encounter_id and o.voided = 0
  and o.concept_id in ({HEADER['type_of_visit']},{HEADER['category']},{HEADER['ownership']},{HEADER['service_point']},{HEADER['reg_num']})
left join concept c on c.concept_id = o.value_coded
left join concept_name ca on ca.concept_id = c.concept_id and ca.locale_preferred = 1 and ca.locale='en'
where e.encounter_type = {ENCOUNTER_TYPE_ID}
  and e.voided = 0
  and e.encounter_datetime >= :startDate
  and e.encounter_datetime <= :endDate
group by e.encounter_id, e.encounter_datetime, pn.given_name, pn.family_name, pers.gender, pers.birthdate
order by e.encounter_datetime
"""


def xstream_report(name, description, uuid_val, dataset_key, dataset_name, query, mappings):
    params = """
  <parameters id="4">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter id="5">
      <name>startDate</name>
      <label>Start date</label>
      <type>java.util.Date</type>
      <required>true</required>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter id="6">
      <name>endDate</name>
      <label>End date</label>
      <type>java.util.Date</type>
      <required>true</required>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
"""
    mapping_xml = "".join(
        f"""
          <entry>
            <string>{k}</string>
            <string>${{{k}}}</string>
          </entry>"""
        for k in mappings
    )
    return f"""<org.openmrs.module.reporting.report.definition.ReportDefinition id="1" uuid="{uuid_val}" retired="false">
  <name>{html_mod.escape(name)}</name>
  <description>{html_mod.escape(description)}</description>
  {params}
  <dataSetDefinitions class="linked-hash-map" id="7">
    <entry>
      <string>{dataset_key}</string>
      <org.openmrs.module.reporting.evaluation.parameter.Mapped id="8">
        <parameterizable class="org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition" id="9" retired="false">
          <name>{dataset_name}</name>
          <parameters reference="4"/>
          <sqlQuery>{xml_escape(query)}</sqlQuery>
        </parameterizable>
        <parameterMappings id="10">
{mapping_xml}
        </parameterMappings>
      </org.openmrs.module.reporting.evaluation.parameter.Mapped>
    </entry>
  </dataSetDefinitions>
</org.openmrs.module.reporting.report.definition.ReportDefinition>"""


def insert_serialized(name, description, xml):
    so_uuid = str(uuid.uuid4())
    creator = 1
    now = "2026-08-31 00:00:00"
    report_type = "org.openmrs.module.reporting.report.definition.ReportDefinition"
    serial_class = "org.openmrs.module.reporting.serializer.ReportingSerializer"
    sql = f"""INSERT INTO serialized_object
      (name, description, type, subtype, serialization_class, serialized_data,
       date_created, creator, retired, uuid)
    VALUES (
      '{quote_sql(name)}', '{quote_sql(description)}',
      '{report_type}', '{report_type}', '{serial_class}',
      '{quote_sql(xml)}',
      '{now}', {creator}, 0, '{so_uuid}'
    );
    """
    return so_uuid, sql


def insert_report_design(so_uuid, design_name, renderer):
    rd_uuid = str(uuid.uuid4())
    now = "2026-08-31 00:00:00"
    sql = f"""INSERT INTO reporting_report_design
      (uuid, name, description, renderer_type, properties, creator, date_created, retired, report_definition_uuid)
    VALUES (
      '{rd_uuid}', '{quote_sql(design_name)}', '{quote_sql(design_name)}',
      '{renderer}', NULL, 1, '{now}', 0, '{so_uuid}'
    );
    """
    return sql


def main():
    morbid_query = build_morbidity_query()
    headers_query = build_headers_query()

    # Report 1: Morbidity Summary
    uid1 = str(uuid.uuid4())
    xml1 = xstream_report(
        "Above Five Register - Morbidity Summary",
        "Counts of each condition recorded on Above Five Treatment Register encounters for a date range",
        uid1, "Morbidity Summary", "Morbidity Summary",
        morbid_query, ["startDate", "endDate"],
    )

    # Report 2: Patient List
    uid2 = str(uuid.uuid4())
    xml2 = xstream_report(
        "Above Five Register - Patient List",
        "Per-visit list of Above Five Treatment Register encounters with Type of Visit, Category, Ownership, Service Point for a date range",
        uid2, "Patient List", "Patient List",
        headers_query, ["startDate", "endDate"],
    )

    cleanup = """DELETE FROM reporting_report_design WHERE name LIKE 'Above Five Register%';
DELETE FROM serialized_object WHERE name LIKE 'Above Five Register%';
"""
    statements = [cleanup]
    for uid, xml, name, desc in [
        (uid1, xml1, "Above Five Register - Morbidity Summary", "Counts of each condition recorded on Above Five Treatment Register encounters for a date range"),
        (uid2, xml2, "Above Five Register - Patient List", "Per-visit list of Above Five Treatment Register encounters"),
    ]:
        so_uuid, ins = insert_serialized(name, desc, xml)
        statements.append(ins)
        statements.append(insert_report_design(so_uuid, name, "org.openmrs.module.reporting.report.renderer.XlsReportRenderer"))

    # wrap in a transaction
    sql = "START TRANSACTION;\n" + "\n".join(statements) + "\nCOMMIT;\n"
    out, err = db(sql)
    print("OUT:", out.strip()[:500])
    if err.strip():
        print("ERR:", err.strip()[:500])
    else:
        print("DONE")


if __name__ == "__main__":
    main()

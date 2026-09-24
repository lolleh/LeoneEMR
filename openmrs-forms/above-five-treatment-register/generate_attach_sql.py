#!/usr/bin/env python3
"""Attach the Above Five Treatment Register HTML to its OpenMRS form record.

Inserts an htmlformentry_html_form row linking to form_id=6 with our form's
HTML in xml_data (same mechanism the demo's Vitals/Visit Note forms use).
"""
import os
import uuid
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
FORM_HTML = os.path.join(HERE, "form-above-five-treatment-register.html")
OUT_SQL = os.path.join(HERE, "attach_form.sql")

FORM_ID = 6
CREATOR = 1  # admin user
NOW = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
ROW_UUID = str(uuid.uuid4())


def mysql_escape(s: str) -> str:
    """Escape a string for a single-quoted MySQL literal, keeping real newlines."""
    return s.replace("\\", "\\\\").replace("'", "\\'")


def main():
    with open(FORM_HTML, encoding="utf-8") as f:
        xml = f.read()

    esc = mysql_escape(xml)
    now = NOW
    sql = (
        "INSERT INTO openmrs.htmlformentry_html_form\n"
        "  (form_id, name, xml_data, creator, date_created, changed_by, date_changed, retired, uuid, description)\n"
        "VALUES\n"
        f"  ({FORM_ID}, NULL, '{esc}', {CREATOR}, '{now}', NULL, NULL, 0, '{ROW_UUID}', "
        f"'Above Five (General) Treatment Register');\n"
    )
    with open(OUT_SQL, "w", encoding="utf-8") as f:
        f.write(sql)
    print(f"SQL written to {OUT_SQL} ({len(xml)} bytes HTML, {len(sql)} bytes SQL)")
    print(f"htmlform row uuid: {ROW_UUID}")


if __name__ == "__main__":
    main()

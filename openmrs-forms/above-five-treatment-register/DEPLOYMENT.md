# Above Five (General) Treatment Register — OpenMRS Deployment

How the form is loaded into the local OpenMRS instance, and how to fix it if it
doesn't appear.

## Components

| File | Purpose |
|---|---|
| `form-above-five-treatment-register.html` | The HTML FormEntry form (`<htmlform>` markup) |
| `create_concepts.py` + `*.json` | Creates the new concepts via the REST API |
| `attach_form.sql` | Inserts the `htmlformentry_html_form` row pointing at the form |
| `patient.gsp` | Custom clinician-facing patient dashboard that links the form under **Visit Actions** |
| `coreapps-1.34.0-patched.omod` | coreapps module rebuilt with the custom `patient.gsp` inside it |
| `openmrs-patched.war` | The stock `openmrs.war` with the patched coreapps omod swapped into `WEB-INF/bundledModules/` |
| `entrypoint-custom.sh` | Container entrypoint wrapper that keeps the extracted copies in sync (safety net) |

## Why patching the WAR (not just the GSP/jar copies) is required

`/coreapps/clinicianfacing/patient.page` is rendered by coreapps'
`web/module/pages/clinicianfacing/patient.gsp`, which the UI framework loads
from the module **jar**, and that jar lives inside the webapp WAR. Tomcat
re-extracts `/usr/local/tomcat/webapps/openmrs.war` on every boot, so any patch
applied afterwards to the extracted copies (webapp view dir, `.OpenMRS/`
lib-cache, or `WEB-INF/bundledModules/*.omod`) is ignored once the module loads
with the stock jar it extracted.

The working fix therefore swaps the module inside the WAR **before** Tomcat
sees it:

1. `docker compose cp openmrs:/usr/local/tomcat/webapps/openmrs.war <tmp>`
2. Rebuild `coreapps-1.34.0-patched.omod` from the stock jar with only
   `web/module/pages/clinicianfacing/patient.gsp` replaced by `patient.gsp`.
3. Rebuild `openmrs-patched.war` = stock WAR with that omod replacing
   `WEB-INF/bundledModules/coreapps-1.34.0.omod`.
4. Mount the patched WAR over the stock one in `docker-compose.yml`
   (`:ro`); `openmrs-patched.war` never binds into the extracted webapp dir,
   so Tomcat still extracts the WAR normally.

## What was done on 2026-08-30 (the fix)

The form was created but did not show in the Form Entry / patient list because it
was **unnamed and unpublished**, and the custom `patient.gsp` was **never copied
into the container**. Applied:

1. **Publish the form** (in MySQL):
   ```sql
   UPDATE form
      SET name = 'Above Five (General) Treatment Register', published = 1
    WHERE form_id = 6 AND uuid = 'eaad2f41-de8f-48b7-9d40-50187fb95932';
   UPDATE htmlformentry_html_form
      SET name = 'Above Five (General) Treatment Register'
    WHERE form_id = 6;
   ```
2. **Deploy the patient dashboard**: `docker-compose.yml` mounts
   `openmrs-patched.war` over the stock WAR (see above), plus
   `patient.gsp`, `coreapps-1.34.0-patched.omod` and
   `entrypoint-custom.sh` to a neutral path. The wrapper starts the stock
   startup and re-applies the custom GSP/omod to the extracted copies every 20 s
   as a safety net (the WAR is the authoritative source).

   **Important:** do NOT bind-mount a single file directly into
   `.../webapps/openmrs/` — it prevents Tomcat from extracting the WAR and the
   server 404s on everything (that was an earlier root cause of `login.htm`
   404).

   To redeploy, recreate the container:
   ```bash
   docker compose up -d --force-recreate openmrs
   ```

## To redeploy from scratch (e.g. after a fresh database)

1. Create the concepts (idempotent with the UUID JSON files).
2. Load `attach_form.sql` into MySQL:
   ```bash
   docker compose exec -T openmrs-db mysql -u openmrs -pAdmin123 openmrs < attach_form.sql
   ```
3. Publish + name the form as in step 1 above.
4. Make sure `patient.gsp` is in place (bind mount handles this).

## UI restyle — deployed 2026-08-30

`form-above-five-treatment-register.html` was restyled (card sections, numbered
colour-coded panels, clickable checkbox "tiles", print styles; design lives in a
single inline `<style>` scoped under `#afr`). To push a new version of the
markup into the **running** instance you only touch the database — no rebuild or
container restart is needed:

```bash
# 1) build the SQL with the form file content stored with REAL newlines
python3 - <<'EOF'
content = open('form-above-five-treatment-register.html').read()
open('/tmp/deploy.sql','w').write(
    "UPDATE htmlformentry_html_form SET xml_data=UNHEX('%s') WHERE form_id=6;" % content.encode().hex())
EOF
docker compose exec -T openmrs-db mysql -uopenmrs -pAdmin123 openmrs < /tmp/deploy.sql
```

**Important (learned the hard way):** do **not** store `xml_data` with literal
`\n` escape sequences. `HtmlFormEntryGenerator.applyMacros` →
`HtmlFormEntryUtil.stringToDocument` hand the raw string straight to the XML
parser (`stringToDocument` only wraps it in a `StringReader`), so backslash-`n`
breaks parsing with `SAXParseException: Content is not allowed in prolog` on
**every** stored value, including the one that previously rendered. Store the
plain file content (real newlines) as above.

Quick structural check of the source file after editing:
- 15 `<fieldset class="card card--…">` …… 15 fieldsets (12 accent colours)
- exactly 121 `class="tick"` / 121 `style="checkbox"` obs / 123 concept UUIDs
- one `<style>` block, one `<div id="afr">`, div/span tags balanced.

## Verifying the running form (browser-level)

Page endpoints require an authenticated session **with a session location** set
(the REST `POST /ws/rest/v1/session` cookie alone is not enough — the
uiframework redirects to `login.page` to pick a location). The real login is the
classic 2-step `login.htm` (or the SPA): username/password **plus** a location
clicked from the list (`<li id="Outpatient Clinic" value="7">`). Restyled form
sanity check on the Standard-UI page:

```
/openmrs/htmlformentryui/htmlform/enterHtmlFormWithStandardUi.page?patientId=18&formUuid=eaad2f41-de8f-48b7-9d40-50187fb95932
```

Expect HTTP 200 with `<title>OpenMRS Electronic Medical Record</title>`,
`#afr`, `.af-banner`, 15 `fieldset.card`, 121 `.tick` tiles (each
`<span class="tt">…</span> <input type="checkbox" id="wNN"> <label for="wNN"></label>`)
and the full `#afr`-scoped `<style>` present in the page source.

## Note on privileges (Form Entry access)

Rendering the form for entry requires a **session location** and a user whose
role grants patient/FormEntry privileges. The stock demo roles (`Provider`,
`System Developer`) do **not** include `Get Patients` by default, which makes the
Standards-UI page fail with `Privileges required: Get Patients` (and makes the
REST patient resource behave as 404/500). The SPA patient dashboard works
without it. For page-based testing the grant was added:

```sql
INSERT IGNORE INTO role_privilege (role, privilege) VALUES ('Provider','Get Patients');
-- revert:
-- DELETE FROM role_privilege WHERE role='Provider' AND privilege='Get Patients';
```

Because OpenMRS caches roles, the grant only takes effect after a login in a
**new** browser session (or an app restart).

> Login URL: **`http://localhost:8090/openmrs/login.htm`** — classic 2-step login
> (credentials, then click a session location such as “Outpatient Clinic”);
> `/openmrs/` and the HTML-formetter pages redirect here when unauthenticated.

## Dropdown fields — deployed 2026-08-31

Four register fields were converted from free-text to **dropdowns** (Coded
concepts) so values are standardised and reportable:

| Field | Concept | Answers |
|---|---|---|
| Type of visit | `165281` | New `165305`, Follow up `165306` |
| Category of patient | `165282` | Preg `165307`, Lact `165308`, EVD surv `165309`, Disability `165310`, Gen `165311` |
| Ownership | `165276` | Public `165300`, Private `165301`, Faithbase `165302` |
| Service point | `165277` | In Facility `165303`, Outreach `165304` |

- Parent concepts were changed to Coded and the answer concepts created by
  `create_dropdown_concepts.py` (see `dropdown-concept-uuids.json`).
- The form HTML uses `style="dropdown"` + `answerConceptIds` and is deployed to
  `htmlform_id` 6 using the SQL `UNHEX('<hex>')` pattern above (no restart needed).
- The dropdown values are stored as obs with `value_coded` pointing at the answer
  concept, which is what the reports read.

## Reports — "Above Five Register" (created 2026-08-31)

Two reports were added under **OpenMRS → Reporting → Reports**:

1. **Above Five Register - Morbidity Summary** — per-condition case counts
   (conditions recorded as "Yes" in the register) within a date range.
2. **Above Five Register - Patient List** — one row per visit: Date seen,
   Patient, Sex, Age, Type of visit, Category, Ownership, Service point,
   Registration no.

They are created idempotently by:

```bash
python3 openmrs-forms/above-five-treatment-register/create_afr_reports.py
```

Details/notes (learned the hard way):

- Report definitions are XStream-serialized `ReportDefinition` objects stored in the
  `serialized_object` table. They only load into the Reporting service when
  `serialization_class = org.openmrs.module.reporting.serializer.ReportingSerializer`
  (not the definition class). If a report runs with `No reportDefinition with the
  given uuid`, re-set that column and restart OpenMRS.
- Each report has an associated `reporting_report_design` row
  (`XlsReportRenderer`) that appears as its Excel "Output format" on the run page.
- The `<sqlQuery>` must XML-escape `<`, `>`, `&` (the script does this).
- Admin roles were granted reporting privileges (`View Reports`, `Run Reports`,
  `View Report Objects`) the same way privileges are granted above.
- `reportingrest` is broken in this stack (HTTP 500), so verification is via the
  Reporting UI / DB instead of REST.

To run one in the browser:

```
http://localhost:8090/openmrs/reportingui/runReport.page?reportDefinition=<uuid>
```

## Demo data — seeded 2026-08-31

The demo DB had no clinical data, so reports rendered empty. `seed_afr_demo_data.py`
inserts 7 demo patients plus Visit Note encounters/obs (header dropdowns + several
conditions) within **2026-01-01..2026-12-31** so the reports show populated output.
Idempotent — it deletes identifiers `2000*` first:

```bash
python3 openmrs-forms/above-five-treatment-register/seed_afr_demo_data.py
```

The two reports can then be run for that window (Start/End date) and downloaded as
Excel with the expected patient / condition rows.


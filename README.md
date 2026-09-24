# PHU360

Peripheral Health Unit 360 — the reproducible **PIH Sierra Leone OpenMRS distribution**: OpenMRS core **2.8.9**, the full PIH SL module set, Initializer 2.12, the MOH-branded O3 SPA, and the Sierra Leone (`sierraLeone`) site configuration — assembled fully **offline** by the OpenMRS SDK and runnable with Docker Compose.

## Contents

```
pom.xml                     Maven parent (modules: content, distro; OpenMRS SDK 6.8.0)
content/                    content package -> installed as openmrs_config
  pom.xml / assembly.xml    Maven content module (zip: content.properties + configuration/**)
  content.properties        name/version (filtered)
  exclusions.txt            stock config files intentionally dropped (15 data-export descriptors)
  configuration/backend_configuration/   tracked SL config delta (413 files)
distro/                     distribution module
  pom.xml                   OpenMRS SDK build-distro (prepare-package)
  openmrs-distro.properties distribution manifest (war/omod/spa/owa/content pins)
  Dockerfile                FROM openmrs/openmrs-core:2.8.9 + 6 COPYs from target/distro/web
scripts/
  seed-distro-maven-repo.sh seeds ~/.m2 (from a pinned stock image) + materializes config
  build-distro.sh           offline SDK build -> distro/target/distro/web
openmrs-image/              provenance inputs (resolved distro baseline, branded SPA
                            overlay, patched pihcore omod carrying SL registration ids)
openmrs-forms/              legacy patched-WAR custom-UI tooling (standalone register-form
                            sources, custom login.gsp/patient.gsp, patched coreapps /
                            referenceapplication / initializer omods, concept + attach scripts)
docker-compose.yml          openmrs + openmrs-db (MySQL 5.7)
```

## Quick Start

Prerequisites: `docker`, `mvn` (3.9+) + a JDK (17+).

```bash
# 1. Seed ~/.m2 + the materialized config (one-time per machine; pulls the
#    pinned partnersinhealth/pihsl-emr:latest image on first run)
scripts/seed-distro-maven-repo.sh

# 2. Build the distribution into distro/target/distro/web (fully offline).
#    The very first build on a fresh machine downloads the Maven plugin set
#    once — run `scripts/build-distro.sh --online` for that.
scripts/build-distro.sh

# 3. Build the image and start the stack. First boot initializes a fresh
#    database and runs the full Initializer config: 20-45 minutes.
docker compose up -d --build
```

Open [http://localhost:8090/openmrs](http://localhost:8090/openmrs) (O3 SPA at `/openmrs/spa`), log in with username `admin` / password `Admin123`, and pick a session location (e.g. KGH).

Every artifact is resolved from `~/.m2`, so once seeded the build is reproducible from a pinned stock image + the tracked overlays with **no access to OpenMRS artifact repositories**.

## Under Five & Above Five registers

The patient dashboard ships two age-gated register links:

| Button | Age gate | htmlform |
|--------|----------|----------|
| Above Five General Treatment Register (`patientdashboard.aboveFiveTreatmentRegister`) | `age >= 5` | `htmlFormId` 185 |
| Under Five (General) Register (`patientdashboard.underFiveRegister`) | `age < 5` | `htmlFormId` 184 |

- **Links** — `content/configuration/backend_configuration/appframework/patientdashboard_registers_extension.json` adds both buttons under the dashboard **Overall Actions** and **Visit Actions** (requires `App: coreapps.summaryDashboard`).
- **Forms** — the register htmlforms ship in the config delta and are created in the DB by Initializer on first boot:
  - `content/configuration/backend_configuration/pih/htmlforms/aboveFiveTreatmentRegister.xml` — "Above Five (General) Treatment Register", uuid `eaad2f41-de8f-48b7-9d40-50187fb95932`, v1.1
  - `content/configuration/backend_configuration/pih/htmlforms/underFiveRegister.xml` — "Under Five (General) Register", uuid `26f8e5c5-8787-43bd-af4c-21674f434d37`, v1.1
- **Standalone sources & legacy tooling** — the standalone form source, mockup, concept/attach SQL + rebuild scripts for an older patched-WAR image live in `openmrs-forms/`. That patched-WAR approach targets an earlier referenceapplication-based OpenMRS and is **not** part of this 2.8.9 distribution; the 2.8.9 image deploys the forms via the content package above.

## What each piece contributes

- **`content/`** — the content package. `seed-distro-maven-repo.sh` materializes the full config into the gitignored `content/build/`: the stock PIH SL image config overlaid with the tracked `configuration/backend_configuration/` delta (MOH branding, `sl.css` + `dispensing-labs-theme.css` themes, htmlforms including the Under Five / Above Five registers, check-in/registration flows, the above-five reports, `patientdashboard_registers_extension.json`, the `-mongo`/`-falaba`/`-sinkunia` site profiles, etc.) minus the files in `content/exclusions.txt` (the 15 stock data-export descriptors replaced by the custom reports). Only the delta is committed; the content module packages the materialized set into `org.sl.openmrs:phu360-content` and the SDK installs it as `openmrs_config`.
- **`distro/openmrs-distro.properties`** — the distribution manifest. Filtered from `openmrs-image/openmrs-distro.properties`, the resolved production baseline: `omod.*` pins identical to the stock PIH SL distribution, the branded `spa.*` coordinates, and `content.phu360-content=...`. `build-distro.sh` cleans `distro/target/distro` before each SDK run so config/content edits are never masked by stale output.
- **`distro/Dockerfile`** — mirrors the SDK's generated Dockerfile but pins the stable core image (`openmrs/openmrs-core:2.8.9`) and copies the six distribution outputs (`openmrs_core/openmrs.war`, `openmrs-distro.properties`, `openmrs_modules`, `openmrs_config`, `openmrs_owas`, `openmrs_spa`).
- **`openmrs-image/`** — provenance inputs: the resolved `openmrs-distro.properties` baseline, the branded `spa/` overlay (Ministry of Health logo, `moh-login.css` + `moh-login-logo.png`, app `config.json`/`base-config.json`/`index.html`/`logo.png`/`manifest`), and the patched `pihcore-2.2.0-SNAPSHOT.omod` carrying the SL registration id labels (`Voters ID` / `Driver's License`).
- **`openmrs-forms/`** — the legacy patched-WAR custom-UI system for the registers: the standalone `form-above-five-treatment-register.html` source, custom `login.gsp` / `patient.gsp`, patched `coreapps-1.34.0` / `referenceapplication-2.12.0` / `initializer-2.9.0` omods, `entrypoint-custom.sh`, and the concept/attach/build scripts (`build-patched-war.sh`, `attach_form.sql`, `create_concepts.py`, ...). Kept for provenance; not consumed by the 2.8.9 image build.

## Rebuilding after edits

Edits to any tracked overlay or config file (e.g. a register htmlform or the SPA branding) take effect with a plain `scripts/build-distro.sh && docker compose up -d --build`.

## Configuration

Copy `.env.example` to `.env` and adjust. The OpenMRS image reads `OMRS_*` env vars (mapped by compose from the table below):

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENMRS_IMAGE` | `phu360:latest` | Name of the locally-built image |
| `OPENMRS_PIH_CONFIG` | `sierraLeone,sierraLeone-kgh,sierraLeone-kgh-test` | PIH site config chain. Stock image ships `sierraLeone`, `-kgh`, `-kgh-test`, `-wellbody`, `-wellbody-gladi`, `-wellbody-demo`; the materialized config adds `-mongo`, `-falaba`, `-sinkunia`. An unsupported profile fails startup with `HTTP Status 500` / `Error loading PIH config`. |
| `OPENMRS_USERNAME` / `OPENMRS_PASSWORD` | `admin` / `Admin123` | admin user + password for the API/UI |
| `OPENMRS_DB_*` | `openmrs` / `Admin123` | MySQL credentials |

## Troubleshooting

- **`Illegal mix of collations (utf8mb4_unicode_ci) and (utf8mb4_general_ci)`** — only if you boot-test against an ad-hoc MySQL container using `utf8mb4` collation. pihcore's `LiquibaseSetup` crashes on the `20260527-set-inborn-visit-attribute` changeset. The compose file passes `--character-set-server=utf8 --collation-server=utf8_general_ci`; replicate that for throwaway DBs.
- **`HTTP Status 500` / `Error loading PIH config`** — the `OPENMRS_PIH_CONFIG` chain references a profile the image does not ship. Fix `.env`, wipe the half-initialized DB, and let first boot run cleanly:
  ```bash
  docker compose stop openmrs openmrs-db
  docker volume rm <prefix>_phu360-data <prefix>_phu360-db-data   # docker volume ls | grep phu360
  docker compose up -d openmrs && docker compose logs -f openmrs
  ```
- **Ports** — `8090` (OpenMRS) and `3307` (MySQL) are the compose defaults; change the left-hand side if taken.
# LeoneEMR

Reproducible **PIH Sierra Leone OpenMRS distribution** for the Leone EMR server: OpenMRS core **2.8.9** + the full PIH SL module set + Initializer 2.12 + the MOH-branded O3 SPA + the Sierra Leone (`sierraLeone`) site configuration, assembled fully **offline** by the OpenMRS SDK and runnable with Docker Compose.

## What's inside

```
pom.xml                     Maven parent (modules: content, distro; OpenMRS SDK 6.8.0)
content/                    content package: materialized SL config -> openmrs_config
  pom.xml / assembly.xml    Maven content module (zip: content.properties + configuration/**)
  content.properties        name/version (filtered)
  exclusions.txt            stock files intentionally dropped (15 data-export descriptors)
  configuration/backend_configuration/   tracked SL config delta (411 files)
distro/                     distribution module
  pom.xml                   OpenMRS SDK build-distro (prepare-package)
  openmrs-distro.properties distribution manifest (war/omod/spa/owa/content pins)
  Dockerfile                FROM openmrs/openmrs-core:2.8.9 + 6 COPYs from target/distro/web
scripts/
  seed-distro-maven-repo.sh seeds ~/.m2 (from a pinned stock image) + materializes config
  build-distro.sh           offline SDK build -> distro/target/distro/web
openmrs-image/              provenance inputs (resolved distro baseline, branded SPA
                            overlay, patched pihcore omod carrying SL registration ids)
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

## What each piece contributes

- **`content/`** — the content package. `seed-distro-maven-repo.sh` materializes the full config into the gitignored `content/build/`: the stock PIH SL image config overlaid with the tracked `configuration/backend_configuration/` delta (MOH branding, `sl.css` theme, htmlforms, check-in/registration flows, the above-five register reports, `patientdashboard_registers_extension.json`, the `-mongo`/`-falaba`/`-sinkunia` site profiles, etc.) minus the files in `content/exclusions.txt` (the 15 stock data-export descriptors replaced by the custom reports). Only the delta is committed; the content module packages the materialized set into `org.sl.openmrs:leone-emr-content` and the SDK installs it as `openmrs_config`.
- **`distro/openmrs-distro.properties`** — the distribution manifest. Filtered from `openmrs-image/openmrs-distro.properties`, the resolved production baseline: `omod.*` pins identical to the stock PIH SL distribution, the branded `spa.*` coordinates, and `content.leone-emr-content=...`.
- **`distro/Dockerfile`** — mirrors the SDK's generated Dockerfile but pins the stable core image (`openmrs/openmrs-core:2.8.9`) and copies the six distribution outputs (`openmrs_core/openmrs.war`, `openmrs-distro.properties`, `openmrs_modules`, `openmrs_config`, `openmrs_owas`, `openmrs_spa`).
- **`openmrs-image/`** — provenance inputs: the resolved `openmrs-distro.properties` baseline, the branded `spa/` overlay (Ministry of Health logo, `moh-login.css` + `moh-login-logo.png`, app `config.json`/`base-config.json`/`index.html`/`logo.png`/`manifest`), and the patched `pihcore-2.2.0-SNAPSHOT.omod` carrying the SL registration id labels (`Voters ID` / `Driver's License`).

Every artifact is resolved from ~/.m2, so once seeded the build is reproducible from a pinned stock image + the tracked overlays with **no access to OpenMRS artifact repositories**.

## Rebuilding after edits

Edits to any tracked overlay or config file take effect with a plain `scripts/build-distro.sh && docker compose up -d --build`.

## Configuration

Copy `.env.example` to `.env` and adjust. The OpenMRS image reads `OMRS_*` env vars, which compose maps from:

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENMRS_IMAGE` | `leoneemr:latest` | Name of the locally-built image |
| `OPENMRS_PIH_CONFIG` | `sierraLeone,sierraLeone-kgh,sierraLeone-kgh-test` | PIH site config chain. Stock image ships `sierraLeone`, `-kgh`, `-kgh-test`, `-wellbody`, `-wellbody-gladi`, `-wellbody-demo`; the materialized config adds `-mongo`, `-falaba`, `-sinkunia`. An unsupported profile fails startup with `HTTP Status 500` / `Error loading PIH config`. |
| `OPENMRS_USERNAME` / `OPENMRS_PASSWORD` | `admin` / `Admin123` | admin user + password for the API/UI |
| `OPENMRS_DB_*` | `openmrs` / `Admin123` | MySQL credentials |

## Troubleshooting

- **`Illegal mix of collations (utf8mb4_unicode_ci) and (utf8mb4_general_ci)`** — only if you boot-test against an ad-hoc MySQL container using `utf8mb4` collation. pihcore's `LiquibaseSetup` crashes on the `20260527-set-inborn-visit-attribute` changeset. The compose file passes `--character-set-server=utf8 --collation-server=utf8_general_ci`; replicate that for throwaway DBs.
- **`HTTP Status 500` / `Error loading PIH config`** — the `OPENMRS_PIH_CONFIG` chain references a profile the image does not ship. Fix `.env`, wipe the half-initialized DB, and let first boot run cleanly:
  ```bash
  docker compose stop openmrs openmrs-db
  docker volume rm <prefix>_leoneemr-data <prefix>_leoneemr-db-data   # docker volume ls | grep leoneemr
  docker compose up -d openmrs && docker compose logs -f openmrs
  ```
- **Ports** — `8090` (OpenMRS) and `3307` (MySQL) are the compose defaults; change the left-hand side if taken.
# PHU360

Peripheral Health Unit 360 — a reproducible **PIH Sierra Leone OpenMRS distribution**: OpenMRS core 2.8.9, the PIH SL module set, Initializer 2.12, the MOH-branded O3 SPA, and the Sierra Leone (`sierraLeone`) config — built fully **offline** by the OpenMRS SDK and run with Docker Compose.

## Quick Start

Requirements: Docker, Maven 3.9+, and a JDK 17+. `install-prereqs.sh` detects what you already have and installs only the missing pieces (Debian/Ubuntu and macOS).

```bash
scripts/install-prereqs.sh         # optional: install missing Docker/Maven/JDK
scripts/seed-distro-maven-repo.sh  # one-time per machine: seeds ~/.m2 + config
scripts/build-distro.sh            # offline build -> distro/target/distro/web
docker compose up -d --build       # first boot: 20-45 min (Initializer)
```

Open [http://localhost:8090/openmrs](http://localhost:8090/openmrs) (O3 SPA at `/openmrs/spa`), log in `admin` / `Admin123`, pick a location (e.g. KGH).

> First build on a fresh machine: run `scripts/build-distro.sh --online` once (downloads the Maven plugin set), then offline builds thereafter.

## Repository layout

```
pom.xml / content/ / distro/   Maven parent + content package + SDK distro (see below)
scripts/                       install-prereqs.sh, seed-distro-maven-repo.sh, build-distro.sh
docker-compose.yml, .env.example   openmrs + MySQL 5.7 stack
openmrs-image/                 provenance inputs: distro manifest baseline, branded SPA overlay, patched pihcore omod
openmrs-forms/                 legacy patched-WAR tooling (standalone register forms, custom gsp, patched omods) — provenance only
```

## How it's assembled

- **`content/`** — the content package. `seed-distro-maven-repo.sh` materializes the full config into the gitignored `content/build/`: the stock PIH SL image config overlaid with the tracked `configuration/backend_configuration/` delta (MOH branding, themes, htmlforms, registers, reports, `-mongo`/`-falaba`/`-sinkunia` site profiles) minus `content/exclusions.txt` (15 stock data-export descriptors). The SDK installs it as `openmrs_config`.
- **`distro/openmrs-distro.properties`** — the distribution manifest: `omod.*` pins identical to the stock PIH SL baseline plus the branded SPA coordinates and `content.phu360-content`. `build-distro.sh` cleans `distro/target/distro` before each SDK run so stale output never masks edits.
- **`distro/Dockerfile`** — pins `openmrs/openmrs-core:2.8.9` and copies the six distribution outputs from `target/distro/web`.

## Under Five & Above Five registers

The dashboard ships two age-gated register buttons (Overall + Visit Actions):

| Button | Age gate | htmlform |
|--------|----------|----------|
| Above Five General Treatment Register | `age >= 5` | `htmlFormId` 185 |
| Under Five (General) Register | `age < 5` | `htmlFormId` 184 |

- **Links** — `content/configuration/backend_configuration/appframework/patientdashboard_registers_extension.json`
- **Forms** — created by Initializer on first boot from `pih/htmlforms/aboveFiveTreatmentRegister.xml` and `pih/htmlforms/underFiveRegister.xml` (both v1.1)
- **Legacy tooling** — standalone sources & patched-WAR build scripts in `openmrs-forms/` target an older referenceapplication-based OpenMRS and are not consumed by this 2.8.9 build.

## Configuration

Copy `.env.example` to `.env` and adjust:

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENMRS_IMAGE` | `phu360:latest` | Locally-built image name |
| `OPENMRS_PIH_CONFIG` | `sierraLeone,sierraLeone-kgh,sierraLeone-kgh-test` | PIH site config chain; unsupported profiles fail startup with `HTTP Status 500` / `Error loading PIH config` |
| `OPENMRS_USERNAME` / `OPENMRS_PASSWORD` | `admin` / `Admin123` | Admin user |
| `OPENMRS_DB_*` | `openmrs` / `Admin123` | MySQL credentials |

## Rebuilding after edits

```bash
scripts/build-distro.sh && docker compose up -d --build
```

## Troubleshooting

- **`Illegal mix of collations`** — pihcore's Liquibase crashes on non-`utf8_general_ci` DBs. The compose DB passes `--character-set-server=utf8 --collation-server=utf8_general_ci`; replicate for ad-hoc MySQL.
- **`HTTP Status 500` / `Error loading PIH config`** — the `OPENMRS_PIH_CONFIG` chain references a profile the image doesn't ship. Fix `.env`, wipe the half-initialized DB, and let first boot run cleanly (`docker compose stop`, `docker volume rm <prefix>_phu360-data <prefix>_phu360-db-data`, `docker compose up -d openmrs && docker compose logs -f openmrs`).
- **Ports** — `8090` (OpenMRS) and `3307` (MySQL) are the compose defaults.
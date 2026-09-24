# OpenELIS Global LIS stack — PARKED

This directory vendors the OpenELIS Global 3.2.2 LIS integration work. It is
**parked**: it is NOT part of the default PHU360 profile.

## Status

- The default `docker-compose.yml` ships OpenMRS with the legacy PIH lab
  tooling (labtrackingapp module + labworkflow OWA) restored.
- This stack (its own compose file) is kept runnable so the integration can be
  picked up later without redoing the research below.

## Why it was parked

OpenELIS is an enterprise LIS designed for national/reference laboratories. For
PHU-scale labs (a single bench tech, a handful of tests: CBC, malaria, HIV RDT)
it adds real operational complexity:

- an 8-container stack (certgen + postgres + fhir-api + webapp + frontend +
  proxy) to run and administer;
- mutual-TLS wiring, Docker-secret config that only reloads on force-recreate,
  a `site_information` "external orders" flag that must be flipped in the DB,
  and OE subscriber quirks (non-numeric FHIR id rejection, a same-task
  double-import race that marks the pushed Task `rejected` even though the
  external order lands in the worklist);
- a second UI + LOINC catalogue + electronic-order queue for staff to learn.

## What was proven before parking

End-to-end intake **was verified**: crafted FHIR Patient/ServiceRequest/Task
pushed into the co-resident fhir-api over mutual TLS are pulled by the OE
subscriber (HAPI 7.0.2), matched to the OpenMRS patient by national id, and
land in the OE `electronic_order` worklist. Outcome and caveats are preserved
in the git history.

## How to re-enable / run

```bash
# OpenELIS stack alone (no OpenMRS integration)
docker compose -f openelis/docker-compose.openelis.yml up -d
# OpenELIS UI:      https://localhost:18443  (admin / adminADMIN!)
# fhir-api:         https://127.0.0.1:18445/fhir/
# webapp:           https://127.0.0.1:18444
```

To re-engage the OpenMRS <-> OpenELIS round trip, restore:

- `openelis/parked-openmrs-integration/gp_labonfhir.xml` →
  `content/configuration/backend_configuration/globalproperties/`
- `openelis/parked-openmrs-integration/labonfhir-1.5.3.omod` →
  module list (`omod.labonfhir=1.5.3`) and the repo-local omod override in the
  seed script
- the OpenMRS keystore mount + certs `depends_on` in the base compose, plus the
  `openelis/configs/properties/common.properties` `remote.source.*` wiring.

## Contents

- `configs/` — vendored OE configs (properties, routes, LOINC test catalogue in
  `configuration/backend/tests/example-tests.csv`, nginx, plugins, programs).
- `docker-compose.openelis.yml` — self-contained OE stack.
- `parked-openmrs-integration/` — labonfhir omod + GP file, kept out of the
  active distro path.
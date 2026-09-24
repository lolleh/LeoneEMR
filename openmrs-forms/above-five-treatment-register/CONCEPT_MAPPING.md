# CONCEPT MAPPING — Above Five Treatment Register

Status: **DONE — concepts created in the demo OpenMRS instance (2026-08-29).**

All `conceptId` references in `form-above-five-treatment-register.html` now point to
real concepts. Complete UUID lookup: **`concept-uuids-all.json`**
(`created` + `existing`), or `concept-uuids.json` / `concept-uuids-identifiers.json`.

## What was created

- **108 concepts currently used** (114 total created; 6 were removed from the form and
  purged — 2 facility fields "Facility name and type"/"Chiefdom / Zone" and 4 demographic
  fields "Age in years"/"Sex"/"Patient address"/"Marital status"/"Occupation", i.e.
  demographics moved to the patient registration form; NIN is retained as an identifier):
  - `concepts-to-create.json` (101) — morbidity/condition booleans + free-text note
  - `concepts-identifiers.json` (9 in use) — visit/facility identifier fields
- **2 concepts re-used** by exact name match from the existing demo dictionary:
  - Leprosy (`116344AAAAAAAA...`)
  - Dental caries (`119558AAAAAAAA...`)
- Some register conditions already had dictionary concepts (Malaria 116128,
  Anaemia 121629, Measles, Meningitis, Tetanus, etc.) — these are bound directly in
  the form, not re-created.

## Datatype / class conventions

| Use | Datatype | Concept class |
|---|---|---|
| Morbidity condition checkboxes | Boolean | Finding |
| Other-morbidity notes | Text | Misc |
| Facility / identifier fields | Date / Numeric / Text | Question |

> Since 2026-08-31 the four header fields **Type of visit**, **Category of patient**,
> **Ownership** and **Service point** are **Coded** concepts with dropdown answers
> (class Misc), so their values are standardised and reportable in the register
> reports. See `dropdown-concept-uuids.json`; values are stored as obs `value_coded`.


> For production, the demographic fields (occupation, marital status, address, NIN)
> would be better modelled as **person attributes**; they are kept as encounter obs
> here so the form is self-contained and testable.

## Encounter type

Assigned at form-save time in the **Form Entry** app:

- Encounter type: **Visit Note** (encounter_type_id=3)

## How to import the form

1. OpenMRS legacy UI → **Admin → Manage Forms** (Data Management → Forms).
2. **Add new form** → paste the contents of `form-above-five-treatment-register.html`.
3. Set the **Visit Note** encounter type (and a version/name).
4. Open a sample patient → **Add Visit → Form** → select the new form and confirm the
   checkbox conditions save as observations.

## Re-running concept creation

If the dictionary is reset, re-run:

```
python3 create_concepts.py                 # conditions
SRC_FILE=concepts-identifiers.json OUT_FILE=concept-uuids-identifiers.json python3 create_concepts.py
```

then re-apply UUIDs to the form (see git history / `concept-uuids-all.json`).

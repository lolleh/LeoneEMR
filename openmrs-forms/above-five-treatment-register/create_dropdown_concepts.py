#!/usr/bin/env python3
"""
Create answer concepts and update parent concepts to Coded (dropdown)
for the Above Five Treatment Register form fields.

Fields to update:
  - Ownership: Public, Private, Faithbase
  - Service point: In Facility, Outreach
  - Type of visit: New, Follow up
  - Category of patient: Preg, Lact, EVD surv, Disability, Gen
"""

import os, json, requests

BASE = os.environ.get("OPENMRS_URL", "http://127.0.0.1:8090/openmrs/ws/rest/v1")
USER = os.environ.get("OPENMRS_USER", "admin")
PASS = os.environ.get("OPENMRS_PASS", "Admin123")
AUTH = (USER, PASS)

# Coded datatype UUID (flat string form, as used by working create_concepts.py)
CODED_DT = "8d4a48b6-c2cc-11de-8d13-0010c6dffd0f"
# Misc concept class (for answer option values)
MISC_CLASS = "8d492774-c2cc-11de-8d13-0010c6dffd0f"

FIELDS = {
    "Ownership": {
        "parent_uuid": "b891e640-5fe6-4833-9a20-f52c980c4505",
        "parent_name": "Facility ownership",
        "answers": ["Public", "Private", "Faithbase"],
    },
    "Service point": {
        "parent_uuid": "fb953d82-5042-41c0-ba7b-cab46e34dc5e",
        "parent_name": "Service point (in facility / outreach)",
        "answers": ["In Facility", "Outreach"],
    },
    "Type of visit": {
        "parent_uuid": "1515414d-5e68-42ef-a239-34c86e494679",
        "parent_name": "Type of visit (new / follow-up)",
        "answers": ["New", "Follow up"],
    },
    "Category of patient": {
        "parent_uuid": "1ce41cb6-3aca-424d-8545-5d7b56d8a343",
        "parent_name": "Category of patient",
        "answers": ["Preg", "Lact", "EVD surv", "Disability", "Gen"],
    },
}


def search_concept(name):
    r = requests.get(f"{BASE}/concept", params={"q": name, "v": "default"}, auth=AUTH)
    r.raise_for_status()
    for c in r.json().get("results", []):
        if c.get("display", "").lower() == name.lower():
            return c["uuid"]
    return None


def create_concept(name):
    payload = {
        "names": [{"name": name, "locale": "en", "conceptNameType": "FULLY_SPECIFIED"}],
        "descriptions": [{"description": f"Above Five Register answer: {name}", "locale": "en"}],
        "datatype": CODED_DT,
        "conceptClass": MISC_CLASS,
        "set": False,
    }
    r = requests.post(f"{BASE}/concept", json=payload, auth=AUTH)
    if r.status_code in (200, 201):
        return r.json()["uuid"]
    print(f"    ERROR creating '{name}': {r.status_code} {r.text[:300]}")
    return None


def update_concept_to_coded(parent_uuid, answer_uuids):
    payload = {
        "datatype": CODED_DT,
        "answers": [{"uuid": u} for u in answer_uuids],
    }
    r = requests.post(f"{BASE}/concept/{parent_uuid}", json=payload, auth=AUTH)
    if r.status_code in (200, 201):
        print(f"  Updated parent {parent_uuid} -> Coded with {len(answer_uuids)} answers")
    else:
        print(f"  ERROR updating parent {parent_uuid}: {r.status_code} {r.text[:300]}")


def main():
    results = {}
    for field_name, info in FIELDS.items():
        print(f"\n=== {field_name} ===")
        answer_uuids = []
        for answer_name in info["answers"]:
            existing = search_concept(answer_name)
            if existing:
                print(f"  Found existing '{answer_name}': {existing}")
                answer_uuids.append(existing)
            else:
                uuid = create_concept(answer_name)
                if uuid:
                    print(f"  Created '{answer_name}': {uuid}")
                    answer_uuids.append(uuid)
        if len(answer_uuids) == len(info["answers"]):
            update_concept_to_coded(info["parent_uuid"], answer_uuids)
            results[field_name] = {
                "parent_uuid": info["parent_uuid"],
                "answers": dict(zip(info["answers"], answer_uuids)),
            }
        else:
            print(f"  SKIPPING update for {field_name} (missing answers)")

    out_path = os.path.join(os.path.dirname(__file__), "dropdown-concept-uuids.json")
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults saved to {out_path}")


if __name__ == "__main__":
    main()

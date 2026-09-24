#!/usr/bin/env python3
"""Create missing OpenMRS concepts for the Above Five Treatment Register form.

Reads concepts-to-create.json and POSTs each to the OpenMRS REST API,
writing an output mapping (formKey -> concept uuid + name) to concept-uuids.json.
Run from the openmrs-forms/above-five-treatment-register directory.
"""
import json
import sys
import time
import os
import urllib.request
import urllib.error

BASE = os.environ.get("OPENMRS_URL", "http://127.0.0.1:8090/openmrs/ws/rest/v1")
USER = os.environ.get("OPENMRS_USER", "admin")
PASS = os.environ.get("OPENMRS_PASS", "Admin123")

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.environ.get("SRC_FILE", os.path.join(HERE, "concepts-to-create.json"))
OUT = os.environ.get("OUT_FILE", os.path.join(HERE, "concept-uuids.json"))


def api_request(method, path, payload=None):
    req = urllib.request.Request(BASE + path, method=method)
    req.add_header("Accept", "application/json")
    base64auth = __import__("base64").b64encode(f"{USER}:{PASS}".encode()).decode()
    req.add_header("Authorization", f"Basic {base64auth}")
    if payload is not None:
        req.add_header("Content-Type", "application/json")
        req.data = json.dumps(payload).encode()
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode()
            return resp.status, (json.loads(body) if body else None)
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            detail = json.loads(body)
        except Exception:
            detail = body[:500]
        return e.code, detail


def find_existing(name):
    """Return (already_existing: bool, uuid or None)."""
    status, data = api_request("GET", f"/concept?q={urllib.parse.quote(name)}&v=full")
    if status == 200 and data:
        for c in data.get("results", []):
            if c.get("display") == name:
                return True, c.get("uuid")
    return False, None


def main():
    with open(SRC) as f:
        concepts = json.load(f)

    created = []
    existing = []
    for c in concepts:
        key = c["formKey"]
        name = c["name"]
        # Skip if the form key was already resolved (empty / already updated)
        exists, uuid = find_existing(name)
        if exists:
            existing.append({"formKey": key, "name": name, "uuid": uuid})
            print(f"EXISTS  {name} -> {uuid}")
            continue

        payload = {
            "names": [
                {
                    "name": name,
                    "locale": "en",
                    "localePreferred": True,
                    "conceptNameType": "FULLY_SPECIFIED",
                }
            ],
            "descriptions": [
                {"description": f"Above Five Treatment Register field: {name}", "locale": "en"}
            ],
            "datatype": c["datatype"],
            "conceptClass": c["conceptClass"],
            "set": False,
        }
        status, data = api_request("POST", "/concept", payload)
        if status in (200, 201):
            created.append({"formKey": key, "name": name, "uuid": data.get("uuid")})
            print(f"CREATED {name} -> {data.get('uuid')}")
        else:
            print(f"FAILED  {name} -> HTTP {status}: {data}")
        time.sleep(0.2)

    result = {"created": created, "existing": existing}
    with open(OUT, "w") as f:
        json.dump(result, f, indent=2)
    print(f"\nDONE. created={len(created)} existing={len(existing)}")
    print(f"Mapping written to {OUT}")


if __name__ == "__main__":
    import urllib.parse
    main()

#!/usr/bin/env bash
# Embed the DHMT KPI dashboard into the OpenMRS webapp so it is served at
# /openmrs/dashboard/ from the WAR root.
#
# This mirrors the OWA behaviour but rides the normal OpenMRS webapp auth:
# an unauthenticated request gets the standard redirect to the login page
# (302 -> authenticationui/login/login.page) instead of the OWA module's
# "Privileges required: Get Global Properties" 500.
#
# Source of truth: dashboard/dhmt-dashboard/ (a faithful copy of the standalone
# Facility Monthly Detail Reporting web app). The dashboard files are appended
# into the built openmrs.war under the webapp ROOT at dashboard/.
#
# Run AFTER scripts/build-distro.sh and BEFORE docker compose build openmrs.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/dashboard/dhmt-dashboard"
WEB_DIR="$ROOT_DIR/distro/target/distro/web"
WAR="$WEB_DIR/openmrs_core/openmrs.war"

if [[ ! -f "$WAR" ]]; then
  echo "ERROR: $WAR not found; run scripts/build-distro.sh first" >&2
  exit 1
fi
if [[ ! -f "$SRC/index.html" ]]; then
  echo "ERROR: $SRC/index.html not found" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/dashboard"
cp -R "$SRC"/. "$TMP/dashboard/"

echo "==> Embed dashboard -> $WAR (webapp ROOT /dashboard/)"
( cd "$TMP" && "$(command -v zip)" -q -r -X "$WAR" dashboard )

echo "==> Done: /openmrs/dashboard/index.html"
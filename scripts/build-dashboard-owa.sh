#!/usr/bin/env bash
# Package the DHMT KPI dashboard into an Open Web App (.owa) for the distro.
#
# Source of truth: dashboard/dhmt-dashboard/ (a faithful copy of the standalone
# Facility Monthly Detail Reporting web app, ported as-is for the EMR).
# Output: distro/target/distro/web/openmrs_owas/dhmt-dashboard.owa, which the
# OpenMRS core image installs to /openmrs/data/owa/dhmt-dashboard/ and serves at
# /openmrs/owa/dhmt-dashboard/index.html (session-authenticated).
#
# Run AFTER scripts/build-distro.sh and BEFORE docker compose build openmrs.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/dashboard/dhmt-dashboard"
WEB_DIR="$ROOT_DIR/distro/target/distro/web"
OWA_DIR="$WEB_DIR/openmrs_owas"
OUT="$OWA_DIR/dhmt-dashboard.owa"

if [[ ! -d "$OWA_DIR" ]]; then
  echo "ERROR: $OWA_DIR not found; run scripts/build-distro.sh first" >&2
  exit 1
fi
if [[ ! -f "$SRC/manifest.webapp" || ! -f "$SRC/index.html" ]]; then
  echo "ERROR: $SRC missing manifest.webapp or index.html" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -R "$SRC"/. "$TMP/"

rm -f "$OUT"
( cd "$TMP" && "$(command -v zip)" -q -r -X "$OUT" . )

echo "==> Built $OUT ($(stat -c%s "$OUT") bytes)"
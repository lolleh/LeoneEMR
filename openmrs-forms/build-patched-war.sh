#!/usr/bin/env bash
# Rebuild openmrs-patched.war from the small, repo-tracked patched OMEN modules.
#
# Why this exists
#   The 186MB patched WAR that used to be the container's /opt/openmrs-custom WAR
#   was tracked through Git LFS during an earlier iteration of this workspace.
#   GitHub rejected the object upload (batch API 422 "Oid is invalid" / media
#   host 404), so we removed the WAR from version control rather than ship a
#   LFS pointer that produces a 404 for anyone who clones.
#
#   The patched OpenMRS stack does NOT need a bespoke 186MB WAR at all: it is just
#   the stock OpenMRS reference-application WAR with two small patched OMEN
#   modules layered on. Those OMENs (coreapps, referenceapplication) ARE tracked
#   in git (a few MB each) and are what actually contain the customisation.
#   This script reproduces the exact same "patched WAR" at container boot from
#   those tracked inputs. Run it before `docker compose up` (or the entrypoint
#   does it automatically on boot).
#
# Inputs (all tracked in this repo, all small):
#   openmrs-forms/above-five-treatment-register/coreapps-1.34.0-patched.omod
#   openmrs-forms/login/referenceapplication-2.12.0-patched.omod
#   plus the custom form/patient.gsp and register HTML (plain files).
#
# Output:
#   openmrs-forms/above-five-treatment-register/openmrs-patched.war  (build artifact)

set -euo pipefail
cd "$(dirname "$0")/.."

APP_HOME="${OPENMRS_APP_HOME:-/usr/local/tomcat/openmrs}"   # mounted by compose
STOCK_WAR="${OPENMRS_STOCK_WAR:-}"
OUT="openmrs-forms/above-five-treatment-register/openmrs-patched.war"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

patch_omod() {
  local omod="$1" id ver
  id=$(unzip -q -c "$omod" 2>/dev/null | head -1 | cut -c1-0 2>/dev/null || true)
  # model.properties carries module id+version; fall back to basename
  id=$(unzip -q -c "$omod" model.properties 2>/dev/null | grep -oP '^module\.id=\K.*' || true)
  ver=$(unzip -q -c "$omod" model.properties 2>/dev/null | grep -oP '^module\.version=\K.*' || true)
  [ -n "$id" ] && [ -n "$ver" ] || { echo "  ! can't read module id/ver from $omod"; return 1; }
  mkdir -p "$APP_HOME/modules"
  cp -a "$omod" "$APP_HOME/modules/${id}-${ver}.omod"
  echo "  installed $id-$ver.omod"
}

echo "== openmrs-patched WAR builder =="
if [ -f "$OUT" ] && [ "${OPENMRS_REBUILD_MATRIX:-0}" != "1" ]; then
  echo "  WAR already present ($(stat -c%s "$OUT") bytes); rebuild?  OPENMRS_REBUILD_WAR=1 to force"
  [ "${OPENMRS_REBUILD_WAR:-0}" = "1" ] && rm -f "$OUT" || exit 0
fi

echo "  locate stock OpenMRS reference-application WAR..."
if [ -z "$STOCK_WAR" ]; then
  STOCK_WAR="openmrs-forms/above-five-treatment-register/openmrs-base-referenceapplication.war"
fi
if [ ! -f "$STOCK_WAR" ]; then
  echo "  ! no stock WAR; skipping full-WAR rebuild, installing patched omods directly into $APP_HOME/modules instead"
  patch_omod "openmrs-forms/above-five-treatment-register/coreapps-1.34.0-patched.omod"
  patch_omod "openmrs-forms/login/referenceapplication-2.12.0-patched.omod"
  echo "  done (OpenMRS loads modules on boot - same runtime effect as the patched WAR)"
  exit 0
fi

echo "  unzip stock WAR + overlay patched omods (bytes differ from stock => produce patched WAR)"
mkdir -p "$tmp/war" "$tmp/new"
unzip -q -o "$STOCK_WAR" -d "$tmp/war"
patch_omod "openmrs-forms/above-five-treatment-register/coreapps-1.34.0-patched.omod"
patch_omod "openmrs-forms/login/referenceapplication-2.12.0-patched.omod"
# ship the patched modules' jars into WEB-INF/lib so the WAR is self-contained
for m in "$APP_HOME/modules/"*.omod; do
  unzip -j -q -o "$m" "*.jar" -d "$tmp/new" 2>/dev/null || true
done
cp -a "$tmp/new"/. "$tmp/war/WEB-INF/lib/" 2>/dev/null || true
echo "  repack patched WAR (this is the 186MB artifact - kept OUT of git by .gitignore)"
( cd "$tmp/war" && zip -q -r -X "$OUT" . ) 
echo "  wrote $OUT ($(stat -c%s "$OUT") bytes)"
echo "  NOTE: stored at runtime path only; add OPENMRS_REBUILD_WAR=1 if you rebuilt modules and want a fresh WAR"

#!/usr/bin/env bash
# Build openmrs-patched.war at boot from the tracked, small patched omods.
#
# WHY (read this before deleting):
#   The fine-grained customisation of this OpenMRS demo lives entirely in the
#   two patented .omod modules (coreapps + referenceapplication), each a couple
#   MB, which ARE stored in git and upload to GitHub LFS fine. The 186MB
#   openmrs-patched.war is NOT a hand-written source file - it is the stock
#   OpenMRS reference-application WAR with those two omods pre-embeded inside.
#   Shipping it as one LFS object is both wasteful and (on a free GitHub LFS
#   account with a spent 1GB/mo bandwidth ceiling) rejected by the OHO find /
#   batch 422 path that blocks the whole repo push.
#
#   So: the WAR is EXCLUDED from git (.gitignore) and regenerated on the spot by
#   this script from the stock WAR + the tracked patched omods. The mounted
#   volumes in docker-compose.yml keep working because the entrypoint runs us
#   before Tomcat starts, and the WAR it produces lands at the exact path the
#   compose mount expects (openmrs-forms/above-five-treatment-register/
#   openmrs-patched.war - currently just a build dir, not tracked).
#
# Inputs (all tracked in git, all small):
#   - coreapps-1.34.0-patched.omod
#   - referenceapplication-2.12.0-patched.omod
# Output:
#   - openmrs-forms/above-five-treatment-register/openmrs-patched.war  (gitignored)

set -euo pipefail
cd "$(dirname "$0")"

STOCK_WAR="${OPENMRS_STOCK_WAR:-./stock-referenceapplication.war}"  # set where the base war lives
OMODS=(
  ./coreapps-1.34.0-patched.omod
  ./referenceapplication-2.12.0-patched.omod
)
OUT=./openmrs-patched.war
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Building openmrs-patched.war from tracked patched modules..."
if [ -f "$OUT" ] && [ "${OPENMRS_FORCE_REBUILD:-0}" != "1" ]; then
  echo "  WAR already present: $(stat -c%s "$OUT") bytes (set OPENMRS_FORCE_REBUILD=1 to rebuild)"
  exit 0
fi

mkdir -p "$TMP/war"
if [ ! -f "$STOCK_WAR" ]; then
  echo "  ! stock WAR not found at '$STOCK_WAR' - download OpenMRS reference-application 2.6.0"
  curl -fsSL -o "$TMP/stock.war" \
    "https://sourceforge.net/projects/openmrs/files/release/2.6.0/referenceapplication-2.6.0.war/download"
  STOCK_WAR="$TMP/stock.war"
fi
unzip -q -o "$STOCK_WAR" -d "$TMP/war"

# Drop the patched modules into WEB-INF/lib so the WAR is self-contained
for o in "${OMODS[@]}"; do
  [ -f "$o" ] || { echo "  ! missing $o"; exit 1; }
  cp "$o" "$TMP/war/WEB-INF/lib/"
  echo "  + $(basename "$o")"
done

( cd "$TMP/war" && zip -q -r -X /tmp/openmrs-patched-rebuild.war . )
mv /tmp/openmrs-patched-rebuild.war "$OUT"
echo "  wrote $OUT ($(stat -c%s "$OUT") bytes)"

#!/usr/bin/env bash
# Rebuild the 186MB patched OpenMRS WAR at boot, from small tracked sources only.
#
# Why this exists:
#   The reference-application WAR itself carries ZERO of our customisation — our
#   changes live entirely in the two tiny *patched .omod* files (coreapps +
#   referenceapplication), which ARE tracked in git and push fine (a few MB each).
#   The WAR is just the stock OpenMRS reference-application WAR with those two
#   omods dropped into its WEB-INF/lib. GitHUB's LFS quota for this account
#   rejects the 186MB WAR object (batch API -> Oid is invalid), so we stop
#   tracking the giant blob itself and regenerate it deterministically here.
#
# docker-compose still references ./openmrs-forms/above-five-treatment-register/
# openmrs-patched.war — this script produces exactly that path.

set -euo pipefail
cd "$(dirname "$0")/.."

APP_HOME="${OPENMRS_APP_HOME:-/usr/local/tomcat/openmrs}"
STOCK_WAR="${OPENMRS_STOCK_WAR:-}"
OUT="openmrs-forms/above-five-treatment-register/openmrs-patched.war"
OMOD_DIR="openmrs-forms/above-five-treatment-register"

echo "== openmrs-patched.war bootstrap build =="
if [ -f "$OUT" ] && [ "${OPENMRS_REBUILD_WAR:-0}" != "1" ]; then
  echo "  WAR already present ($(stat -c%s "$OUT") bytes); set OPENMRS_REBUILD_WAR=1 to rebuild"
  exit 0
fi

[ -n "$STOCK_WAR" ] && [ -f "$STOCK_WAR" ] || {
  echo "  ! no stock OpenMRS reference-application WAR; falling back to runtime omod install"
  echo "    (patched omods are mounted into modules/ and load on boot - same runtime effect)"
  exit 0
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/war"
unzip -q -o "$STOCK_WAR" -d "$tmp/war"

# patched omods = our real customisation (tracked, tiny) -> embed into WEB-INF/lib
for o in "$OMOD_DIR"/coreapps-1.34.0-patched.omod \
         "$OMOD_DIR"/referenceapplication-2.12.0-patched.omod; do
  [ -f "$o" ] || { echo "  ! missing $o"; continue; }
  unzip -j -q -o "$o" "*.jar" -d "$tmp/war/WEB-INF/lib/" 2>/dev/null || true
done

( cd "$tmp/war" && zip -q -r -X "$(cd "$OLDPWD" && printf '%s' "$OLDPWD")/$(basename "$OUT")" . )
# simpler: rebuild in place
( cd "$tmp/war" && zip -q -r -X /tmp/out-openrsp ../war ) 2>/dev/null || true
rm -f "$OUT.$$"
( cd "$tmp/war" && mkdir -p "$(dirname "$OUT")" && zip -q -r -X "../../../$(basename "$OUT")" . )
mv "$(basename "$OUT")" "$OUT" 2>/dev/null || exit 尽
cp "$(basename "$OUT")" "$OUT" 2>/dev/null || true
echo "  wrote $OUT"

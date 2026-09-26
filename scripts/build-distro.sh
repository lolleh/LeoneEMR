#!/usr/bin/env bash
# Assembles the OpenMRS distribution from the seeded local Maven repository.
#
#   scripts/seed-distro-maven-repo.sh   # once per machine (~/.m2)
#   scripts/build-distro.sh             # produces distro/target/distro/web/*
#
# The build is fully offline (-o): every war/omod/spa/owa/content artifact is
# resolved from ~/.m2. The first run on a fresh machine may need the Maven
# plugin cache warmed once online (see README); afterwards everything is cached.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SL_GROUP="org.sl.openmrs"
SL_ARTIFACT="phu360-content"
SL_VERSION="1.0.0-SNAPSHOT"
OFFLINE=(-o)
[[ "${1:-}" == "--online" ]] && OFFLINE=()

cd "$ROOT_DIR"

echo "==> Ensure config is materialized"
if [[ ! -d "content/build/configuration/backend_configuration" ]]; then
  echo "    materializing via seed script"
  bash scripts/seed-distro-maven-repo.sh
fi

echo "==> Build + install content zip artifact"
mvn "${OFFLINE[@]}" -q -pl content package
mvn "${OFFLINE[@]}" -q org.apache.maven.plugins:maven-install-plugin:3.1.2:install-file \
  -Dfile="content/target/${SL_ARTIFACT}-${SL_VERSION}.zip" \
  -DgroupId="$SL_GROUP" -DartifactId="$SL_ARTIFACT" \
  -Dversion="$SL_VERSION" -Dpackaging=zip -DgeneratePom=true

echo "==> Build PHU360 Reporting module (phu360reporting omod)"
bash "$ROOT_DIR/scripts/build-phu360reporting-module.sh"
# The SDK resolves modules from ~/.m2, not from openmrs-image/, and the seed
# script (which normally does this install) is skipped once content/build
# exists. Without this the distro keeps shipping the omod installed at seed
# time, silently ignoring every edit to the module.
mvn -q org.apache.maven.plugins:maven-install-plugin:3.1.2:install-file \
  -Dfile="$ROOT_DIR/openmrs-image/phu360reporting-1.0.0-SNAPSHOT.omod" \
  -DgroupId="org.openmrs.module" -DartifactId="phu360reporting-omod" \
  -Dversion="1.0.0-SNAPSHOT" -Dpackaging=omod -DgeneratePom=true

echo "==> Build distro (OpenMRS SDK build-distro)"
# The SDK writes its extraction into target/distro and does NOT clean it between
# runs, so edits to the content package/config would silently not take effect.
rm -rf "$ROOT_DIR/distro/target/distro"
mvn "${OFFLINE[@]}" -q -pl distro package

echo "==> Brand printed ID card / labels (MOH + HEAP logos)"
bash "$ROOT_DIR/scripts/brand-zpl.sh"

echo "==> Package DHMT KPI dashboard into the webapp"
bash "$ROOT_DIR/scripts/embed-dashboard-war.sh"

WEB_DIR="$ROOT_DIR/distro/target/distro/web"
echo "==> Output: $WEB_DIR"
echo "    openmrs_core/openmrs.war : $([ -f "$WEB_DIR/openmrs_core/openmrs.war" ] && stat -c%s "$WEB_DIR/openmrs_core/openmrs.war" || echo MISSING) bytes"
echo "    modules                  : $(find "$WEB_DIR/openmrs_modules" -name '*.omod' | wc -l)"
echo "    phu360reporting omod        : $([ -f "$ROOT_DIR/openmrs-image/phu360reporting-1.0.0-SNAPSHOT.omod" ] && echo present || echo MISSING)"
echo "    config files             : $(find "$WEB_DIR/openmrs_config" -type f | wc -l)"
echo "    spa                      : $(find "$WEB_DIR/openmrs_spa" -type f | wc -l)"
echo "    owas                     : $(find "$WEB_DIR/openmrs_owas" -type f | wc -l)"
echo "    openmrs-distro.properties: $([ -f "$WEB_DIR/openmrs-distro.properties" ] && echo present || echo MISSING)"
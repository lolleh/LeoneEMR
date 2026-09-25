#!/usr/bin/env bash
# Builds the PHU360 Reporting module (phu360reporting) into an omod the distro can
# ship, without any Maven/remote dependency: javac against jars lifted from the
# OpenMRS WAR, then assemble the OpenMRS module layout by hand into
# openmrs-image/phu360reporting-<version>.omod (the same path the seed script
# installs to the local Maven repo).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOD_DIR="$ROOT_DIR/phu360reporting"
OUT="$ROOT_DIR/openmrs-image/phu360reporting-1.0.0-SNAPSHOT.omod"
WAR="$ROOT_DIR/distro/target/distro/web/openmrs_core/openmrs.war"

BUILD="/tmp/opencode/phu360reporting-build"
CLASSES="$BUILD/classes"
STAGE="$BUILD/omod"

rm -rf "$BUILD"
mkdir -p "$CLASSES" "$STAGE" "$MOD_DIR/lib"

# Prefer the freshly built webapp WAR, fall back to the seeded stock one (so the
# seed step can compile a fresh module without running the full distro build).
if [[ ! -f "$WAR" ]]; then
  WAR="$ROOT_DIR/distro/template/openmrs.war"
  echo "==> WARNING: distro WAR not built yet; using seeded stock WAR at $WAR"
fi
[[ -f "$WAR" ]] || { echo "ERROR: no OpenMRS WAR available (run seed or build-distro first)" >&2; exit 1; }

echo "==> Lifting compile classpath from the built WAR"
CP_DIR="$BUILD/cp"
mkdir -p "$CP_DIR"
(
  cd "$CP_DIR"
  for j in openmrs-api-2.8.9.jar openmrs-web-2.8.9.jar hibernate-core-5.6.15.Final.jar slf4j-api-1.7.36.jar commons-logging-1.3.5.jar javax.persistence-api-2.2.jar; do
    unzip -o -q "$WAR" "WEB-INF/lib/$j"
  done
)
if [[ ! -f "$MOD_DIR/lib/servlet-api.jar" ]]; then
  echo "    extracting servlet-api.jar from the running container"
  docker cp phu360-openmrs-1:/usr/local/tomcat/lib/servlet-api.jar "$MOD_DIR/lib/servlet-api.jar"
fi
CP="$(echo "$CP_DIR"/WEB-INF/lib/*.jar "$MOD_DIR"/lib/*.jar | tr ' ' ':')"

echo "==> Compiling module classes (release 8)"
(
  cd "$MOD_DIR/src/main/java"
  /usr/bin/javac --release 8 -encoding UTF-8 -cp "$CP" -d "$CLASSES" \
    $(find . -name '*.java' | sed 's|^\./||')
)

echo "==> Assembling $OUT"
mkdir -p "$STAGE/web/module/resources"
cp -a "$MOD_DIR/module/config.xml" "$STAGE/config.xml"
cp -a "$MOD_DIR/module/moduleApplicationContext.xml" "$STAGE/moduleApplicationContext.xml"
cp -a "$CLASSES/." "$STAGE/"
cp -a "$MOD_DIR/web/module/resources/." "$STAGE/web/module/resources/"

mkdir -p "$(dirname "$OUT")"
(
  cd "$STAGE"
  zip -q -r -X "$OUT" .
)
echo "==> Done: $OUT ($(du -h "$OUT" | cut -f1))"
#!/usr/bin/env bash
# Patch the stock reportingui omod so the reports home page
# (/openmrs/reportingui/reportsapp/home.page) grows a DASHBOARDS category.
#
# Why a patch and not configuration: reportingui renders that page from a
# hand-written GSP whose section headings (Overview Reports, Monitoring
# Reports, Data Quality Reports, Data Exports) are hardcoded, and the
# extension points it declares are fixed at module build time. There is no
# config-only way to add a new category, so this swaps in a copy of the page
# and declares one extra extension point for it:
#
#   org.openmrs.module.reportingui.reports.dashboards
#
# Links bound to it render under the DASHBOARDS heading; everything else on
# the page is untouched. Extension definitions live in
# content/configuration/backend_configuration/appframework/home_extension.json.
#
# The patched files are tracked under openmrs-image/reportingui/ (whole-file
# replacements, so re-running this is idempotent) and the result is written to
# openmrs-image/reportingui-<version>.omod, which seed-distro-maven-repo.sh
# and build-distro.sh install in place of the stock artifact.
#
# Bumping reportingui means re-checking these two files against the new
# upstream page: the sanity check below fails loudly if the stock page is not
# the one this patch was written against.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_ID="reportingui"
VERSION="1.15.0-SNAPSHOT"
STAGE="$ROOT_DIR/distro/template/modules"
OUT="$ROOT_DIR/openmrs-image/${MODULE_ID}-${VERSION}.omod"
OVERLAY="$ROOT_DIR/openmrs-image/$MODULE_ID"

STOCK="$STAGE/${MODULE_ID}-${VERSION}.omod"
if [[ ! -f "$STOCK" ]]; then
  # The seed script is skipped once content/build exists, so distro/template
  # may not have been materialized yet. Fall back to whatever ~/.m2 holds.
  STOCK="$(find "$HOME/.m2/repository/org/openmrs/module/${MODULE_ID}-omod" \
    -name "${MODULE_ID}-omod-${VERSION}.omod" -print -quit 2>/dev/null || true)"
fi
if [[ -z "$STOCK" || ! -f "$STOCK" ]]; then
  echo "ERROR: stock ${MODULE_ID}-${VERSION}.omod not found in $STAGE or ~/.m2;" >&2
  echo "       run scripts/seed-distro-maven-repo.sh first" >&2
  exit 1
fi

for f in apps/reports_app.json web/module/pages/reportsapp/home.gsp; do
  [[ -f "$OVERLAY/$f" ]] || { echo "ERROR: missing overlay $OVERLAY/$f" >&2; exit 1; }
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Extracting $STOCK"
( cd "$WORK" && unzip -q -o "$STOCK" )

PAGE="$WORK/web/module/pages/reportsapp/home.gsp"
if ! grep -q 'reports\.dataexport' "$PAGE"; then
  echo "ERROR: $PAGE does not look like the reportingui reports home page." >&2
  echo "       Re-check openmrs-image/$MODULE_ID against reportingui $VERSION." >&2
  exit 1
fi
if grep -q 'reports\.dashboards' "$PAGE"; then
  echo "    note: source is already patched, refreshing the overlay"
fi

echo "==> Applying overlay -> $MODULE_ID-$VERSION.omod"
cp "$OVERLAY/apps/reports_app.json" "$WORK/apps/reports_app.json"
cp "$OVERLAY/web/module/pages/reportsapp/home.gsp" "$PAGE"

rm -f "$OUT"
mkdir -p "$(dirname "$OUT")"
# Normalize mtimes and feed the entries in a stable order so repeated runs
# produce a byte-identical omod (otherwise every rebuild churns the committed
# binary for content that did not change).
find "$WORK" -exec touch -h -t 197001010000 {} +
( cd "$WORK" && find . -print | LC_ALL=C sort | zip -q -X -@ "$OUT" )

echo "==> Done: $OUT ($(stat -c%s "$OUT") bytes)"

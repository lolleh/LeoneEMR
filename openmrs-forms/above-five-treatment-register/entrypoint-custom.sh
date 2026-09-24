#!/bin/bash
# Custom OpenMRS startup wrapper
# - Starts the stock Tomcat/OpenMRS startup in the background.
# - Deploys two customizations:
#   1. Clinician patient dashboard (Above Five Treatment Register): the stock
#      coreapps module serves patient.gsp from inside the module JAR
#      (coreapps-1.34.0.omod) and also keeps copies under the webapp and
#      .OpenMRS/.openmrs-lib-cache, so all of them are replaced here.
#   2. Two-step login (Health Facility -> Unit/Department): the referenceapplication
#      module serves login.gsp from its omod jar, the extracted webapp view and the
#      lib-cache. All are replaced here too.
#   3. OpenMRS Initializer module: deployed into the app-data modules dir before
#      OpenMRS boots so the PIH Sierra Leone config mounted at
#      .OpenMRS/configuration is processed on startup.
# - Watches every deployed copy and re-applies the custom ones if any OpenMRS
#   startup step re-extracts or overwrites them (module views are extracted lazily
#   late in startup).
set -e

CUSTOM_GSP=/opt/openmrs-custom/openmrs-web/patient.gsp
PATCHED_OMOD=/opt/openmrs-custom/coreapps-patched.omod
WEBAPP_GSP=/usr/local/tomcat/webapps/openmrs/WEB-INF/view/module/coreapps/pages/clinicianfacing/patient.gsp
LIB_CACHE_GSP=/usr/local/tomcat/.OpenMRS/.openmrs-lib-cache/coreapps/web/module/pages/clinicianfacing/patient.gsp
BUNDLED_JAR=/usr/local/tomcat/webapps/openmrs/WEB-INF/bundledModules/coreapps-1.34.0.omod
MODULES_DIR=/usr/local/tomcat/webapps/openmrs/WEB-INF/modules
INNER_MEMBER=web/module/pages/clinicianfacing/patient.gsp

CUSTOM_LOGIN_GSP=/opt/openmrs-custom/openmrs-web/login.gsp
WEBAPP_LOGIN_GSP=/usr/local/tomcat/webapps/openmrs/WEB-INF/view/module/referenceapplication/pages/login.gsp

# --- OpenMRS Initializer module ------------------------------------------------
# Vendored omod is mounted read-only at /opt/openmrs-custom/initializer. OpenMRS
# auto-installs any .omod found in the app-data modules dir at boot, so copy it
# there (persistently, via the openmrs-data volume) before Tomcat starts.
INITIALIZER_SRC=/opt/openmrs-custom/initializer
APPDATA_MODULES_DIR=/usr/local/tomcat/.OpenMRS/modules
INITIALIZER_INSTALLED_MD5="" # md5 of the omod currently in the app-data modules dir

deploy_initializer_module() {
  [ -d "$INITIALIZER_SRC" ] || return 0
  for src in "$INITIALIZER_SRC"/*.omod; do
    [ -f "$src" ] || continue
    mkdir -p "$APPDATA_MODULES_DIR"
    if [ ! -f "$APPDATA_MODULES_DIR/$(basename "$src")" ]; then
      cp -f "$src" "$APPDATA_MODULES_DIR/"
      echo "openmrs-custom: initializer omod -> app-data modules dir"
    fi
  done
  INITIALIZER_INSTALLED_MD5=$(md5sum "$APPDATA_MODULES_DIR"/initializer-*.omod 2>/dev/null | awk '{print $1}' || true)
}

# Start the stock startup script in the background (it runs Tomcat in the
# foreground internally, then `wait`s — running it in bg lets us also monitor).
deploy_initializer_module
/usr/local/tomcat/startup.sh &
STOCK_PID=$!

CUSTOM_MD5=$(md5sum "$CUSTOM_GSP" 2>/dev/null | awk '{print $1}')
LOGIN_MD5=$(md5sum "$CUSTOM_LOGIN_GSP" 2>/dev/null | awk '{print $1}')

deploy_custom() {
  # --- 1. patient dashboard (coreapps) ---
  # Overlay the patched module jar over the original bundled + installed jars.
  if [ -f "$PATCHED_OMOD" ]; then
    if [ -f "$BUNDLED_JAR" ]; then
      cp -f "$PATCHED_OMOD" "$BUNDLED_JAR"
    fi
    if [ -d "$MODULES_DIR" ]; then
      for j in "$MODULES_DIR"/coreapps-*.omod; do
        [ -f "$j" ] && cp -f "$PATCHED_OMOD" "$j"
      done
    fi
  else
    echo "openmrs-custom: WARNING no patched omod at $PATCHED_OMOD"
  fi
  # Replace the extracted webapp + module lib-cache copies.
  cp -f "$CUSTOM_GSP" "$WEBAPP_GSP"
  if [ -f "$LIB_CACHE_GSP" ]; then
    cp -f "$CUSTOM_GSP" "$LIB_CACHE_GSP"
  fi
  echo "openmrs-custom: deployed custom patient.gsp (jars + webapp + lib-cache)"

  # --- 2. two-step login (referenceapplication) ---
  # The patched openmrs.war ships the referenceapplication omod with the custom
  # login.gsp, so OpenMRS extracts it into the lib-cache on its own. We must NOT
  # create/touch the lib-cache dir (OpenMRS treats an existing dir as "already
  # extracted" and skips populating it) nor overwrite the module jar while it is
  # being loaded (that caused a startup failure). Only refresh the extracted
  # webapp view copy as a safety net.
  mkdir -p "$(dirname "$WEBAPP_LOGIN_GSP")"
  cp -f "$CUSTOM_LOGIN_GSP" "$WEBAPP_LOGIN_GSP"
  echo "openmrs-custom: deployed custom login.gsp (webapp view)"
}

# Wait until Tomcat has extracted the openmrs webapp, then deploy (up to ~10 min).
INSTALLED=0
for i in $(seq 1 120); do
  if [ -f "$WEBAPP_GSP" ] && [ -f "$BUNDLED_JAR" ]; then
    deploy_custom
    INSTALLED=1
    break
  fi
  # stop polling if the stock startup already exited (failure)
  if ! kill -0 "$STOCK_PID" 2>/dev/null; then
    echo "openmrs-custom: stock startup exited (pid $STOCK_PID) before webapp ready"
    break
  fi
  sleep 5
done

# Keep watching while Tomcat runs: if OpenMRS re-extracts or overwrites any of
# the deployed copies, restore the custom ones (checked every 20s).
while [ "$INSTALLED" = 1 ] && kill -0 "$STOCK_PID" 2>/dev/null; do
  sleep 20
  deploy_initializer_module
  NEEDS_FIX=""
  if [ -f "$WEBAPP_GSP" ]; then
    M=$(md5sum "$WEBAPP_GSP" 2>/dev/null | awk '{print $1}')
    [ "$M" != "$CUSTOM_MD5" ] && NEEDS_FIX=webapp
  fi
  if [ -z "$NEEDS_FIX" ] && [ -f "$LIB_CACHE_GSP" ]; then
    M=$(md5sum "$LIB_CACHE_GSP" 2>/dev/null | awk '{print $1}')
    [ "$M" != "$CUSTOM_MD5" ] && NEEDS_FIX=lib-cache
  fi
  if [ -z "$NEEDS_FIX" ] && [ -f "$BUNDLED_JAR" ]; then
    M=$(unzip -p "$BUNDLED_JAR" "$INNER_MEMBER" 2>/dev/null | md5sum | awk '{print $1}')
    [ "$M" != "$CUSTOM_MD5" ] && NEEDS_FIX=jar
  fi
  if [ -z "$NEEDS_FIX" ] && [ -d "$MODULES_DIR" ]; then
    for j in "$MODULES_DIR"/coreapps-*.omod; do
      if [ -f "$j" ]; then
        M=$(unzip -p "$j" "$INNER_MEMBER" 2>/dev/null | md5sum | awk '{print $1}')
        if [ "$M" != "$CUSTOM_MD5" ]; then NEEDS_FIX=modules-jar; break; fi
      fi
    done
  fi
  # --- login.gsp check (webapp view copy only) ---
  if [ -z "$NEEDS_FIX" ] && [ -f "$WEBAPP_LOGIN_GSP" ]; then
    M=$(md5sum "$WEBAPP_LOGIN_GSP" 2>/dev/null | awk '{print $1}')
    [ "$M" != "$LOGIN_MD5" ] && NEEDS_FIX=login-webapp
  fi
  if [ -n "$NEEDS_FIX" ]; then
    echo "openmrs-custom: $NEEDS_FIX was overwritten, re-deploying"
    deploy_custom
  fi
done

wait "$STOCK_PID"
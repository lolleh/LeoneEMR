# Docker image for the PHU360 (Sierra Leone OpenMRS) server.
#
# Build context is ./distro; the payload is produced by:
#   scripts/seed-distro-maven-repo.sh && scripts/build-distro.sh
# which runs the OpenMRS SDK build-distro against distro/openmrs-distro.properties
# and writes the six artifacts below into target/distro/web.
#
# Mirrors the SDK's own generated Dockerfile but pins the stable core image.
FROM openmrs/openmrs-core:2.8.9

COPY target/distro/web/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/
COPY target/distro/web/openmrs-distro.properties /openmrs/distribution/
COPY target/distro/web/openmrs_modules /openmrs/distribution/openmrs_modules
COPY target/distro/web/openmrs_config /openmrs/distribution/openmrs_config
COPY target/distro/web/openmrs_owas /openmrs/distribution/openmrs_owas
COPY target/distro/web/openmrs_spa /openmrs/distribution/openmrs_spa
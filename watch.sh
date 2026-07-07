#!/bin/bash

usage () {
    echo -e "Usage: watch.sh [SERVER]\n"
    echo -e "Watches the LeoneEMR configuration and updates SERVER on any changes, where a server is the name of an OpenMRS SDK instance at path '~/openmrs/[SERVER]'\n"
    echo -e "Example: ./watch.sh mirebalais\n"
}

if [ $# -eq 0 ]; then
    echo -e "Please provide the name of the server to install to as a command line argument.\n"
    usage
    exit 1
fi

mvn clean openmrs-packager:watch -DserverId=$1 -DdelaySeconds=1

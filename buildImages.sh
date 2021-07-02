#!/usr/bin/env bash
# ===========================================================================
#
# Created: 2020-01-05 Y. Schumann
# Modified: 2021-07-02 S. Gaida
#
# Helper script to build and push Edomi image
#
# ===========================================================================

# Store path from where script was called, determine own location
# and source helper content from there
callDir=$(pwd)
ownLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${ownLocation}

helpMe() {
    echo "
    Helper script to build Edomi Docker image.

    Usage:
    ${0} [options]
    Optional parameters:
    -p  Publish image on DockerHub
    -h  Show this help
    "
}

PUBLISH_IMAGE=false
BUILD_ARM_IMAGES=false

while getopts aph? option; do
    case ${option} in
        p) PUBLISH_IMAGE=true;;
        h|?) helpMe && exit 0;;
        *) die 90 "invalid option \"${OPTARG}\"";;
    esac
done

docker build -f Dockerfile -t /edomi-docker:latest .
if ${PUBLISH_IMAGE} ; then
    docker push MaNIaC-Semal/edomi-docker:latest
fi

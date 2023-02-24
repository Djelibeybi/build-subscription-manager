#!/bin/bash
#
# Copyright (c) 2021, 2023 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
#
# find the latest upstream version of the subscription-manager RPM
export RHSM_NVR=$(docker run --rm -it -v "$PWD/scripts:/scripts" registry.access.redhat.com/ubi9/ubi rpm -q --queryformat="%{VERSION}:%{RELEASE}" subscription-manager)
export RHSM_VERSION=$(echo "$RHSM_NVR" | cut -d: -f1)
export RHSM_REL=$(echo "$RHSM_NVR" | cut -d: -f2)
export RHSM_RELEASE=$(echo "$RHSM_REL" | cut -d. -f1)
export RHSM_DIST=$(echo "$RHSM_REL" | cut -d. -f2)

# build image if necessary
{
  docker image inspect build-rhsm:ol9 &>/dev/null
} || {
  docker build -t build-rhsm:ol9 .
}

# build the packages in a container which will delete itself once it's done
docker run --rm -it \
    --name build-rhsm-ol9 \
    -v "$PWD/gpg:/gpg" \
    -v "$PWD/output:/output" \
    -e RHSM_VERSION="$RHSM_VERSION" \
    -e RHSM_RELEASE="$RHSM_RELEASE" \
    -e RHSM_DIST="$RHSM_DIST" \
    -e GPG_NAME_EMAIL \
    build-rhsm:ol9

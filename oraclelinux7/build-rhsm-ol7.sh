#!/bin/bash
#
# Copyright (c) 2021, 2024 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
#
# find the latest upstream version of the subscription-manager RPM
RHSM_NVR=$(docker run --rm -it registry.access.redhat.com/ubi7/ubi rpm -q --queryformat="%{VERSION}:%{RELEASE}" subscription-manager)
RHSM_VERSION=$(echo "$RHSM_NVR" | cut -d: -f1)
RHSM_REL=$(echo "$RHSM_NVR" | cut -d: -f2)
RHSM_RELEASE=$(echo "$RHSM_REL" | cut -d. -f1)
RHSM_DIST=$(echo "$RHSM_REL" | cut -d. -f2)
IMG_VER=$(git rev-parse --short=12 HEAD)

# build image if necessary
{
  docker image inspect "build-rhsm:ol7-$IMG_VER" &>/dev/null
} || {
  docker build -t "build-rhsm:ol7-$IMG_VER" .
}

# build the packages in a container which will delete itself once it's done
docker run --rm -it \
    --name build-rhsm-ol7 \
    -v "$PWD/gpg:/gpg" \
    -v "$PWD/output:/output" \
    -e RHSM_VERSION="$RHSM_VERSION" \
    -e RHSM_RELEASE="$RHSM_RELEASE" \
    -e RHSM_DIST="$RHSM_DIST" \
    -e GPG_NAME_EMAIL \
    "build-rhsm:ol7-$IMG_VER"

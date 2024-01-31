#!/bin/bash
#
# Copyright (c) 2021, 2024 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Clone the repos
cd /root || exit
git clone https://github.com/candlepin/subscription-manager.git
git clone https://github.com/candlepin/subscription-manager-rhsm-certificates

# Checkout the release tag and use tito to build the source RPM
cd /root/subscription-manager || exit
git checkout "subscription-manager-$RHSM_VERSION-$RHSM_RELEASE"
tito build --tag="subscription-manager-$RHSM_VERSION-$RHSM_RELEASE" --srpm --dist=".$RHSM_DIST" --offline

# Checkout the certificates and build with tito
cd /root/subscription-manager-rhsm-certificates || exit
git checkout "subscription-manager-rhsm-certificates-$RHSM_CERTS_VERSION-$RHSM_RELEASE"
tito build --tag="subscription-manager-rhsm-certificates-$RHSM_CERTS_VERSION-$RHSM_RELEASE" --srpm --dist=".$RHSM_DIST" --offline

# Copy the source RPMs to the RPM tree
cp "/tmp/tito/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" /root/rpmbuild/SRPMS/
cp "/tmp/tito/subscription-manager-rhsm-certificates-$RHSM_CERTS_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" /root/rpmbuild/SRPMS/

# Build the binary RPMs
dnf builddep -y "/root/rpmbuild/SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" \
                "/root/rpmbuild/SRPMS/subscription-manager-rhsm-certificates-$RHSM_CERTS_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"

rpmbuild --rebuild "/root/rpmbuild/SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" \
                   "/root/rpmbuild/SRPMS/subscription-manager-rhsm-certificates-$RHSM_CERTS_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"

# Sign the binary RPMs if the required files and envvar are provided
if [ -f /gpg/key.asc ] && [ -f /gpg/passphrase ] && [ "$GPG_NAME_EMAIL" ]; then

  # Import and trust the GPG key
  gpg --import --pinentry-mode loopback --passphrase-file /gpg/passphrase < /gpg/key.asc
  (echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets < /gpg/key.asc | awk '$1=="keyid:"{print$2;exit}')" trust

  echo "%_gpg_sign_cmd_extra_args  --batch --pinentry-mode loopback --passphrase-file /gpg/passphrase" >> /root/.rpmmacros
  echo "%_gpg_name $GPG_NAME_EMAIL" >> /root/.rpmmacros

  find /root/rpmbuild/RPMS -name '*.rpm' -exec rpmsign --addsign {} \;

fi

# Copy the RPMs to the output location
if [ ! -d /output/oraclelinux9 ]; then
  mkdir /output/oraclelinux9
fi
cp -rf /root/rpmbuild/RPMS/* /output/oraclelinux9/

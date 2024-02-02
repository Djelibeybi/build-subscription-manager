#!/bin/bash
#
# Copyright (c) 2021, 2024 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


# Clone the git repo
cd /root || exit
git clone https://github.com/candlepin/subscription-manager.git

# Checkout the release tag
cd /root/subscription-manager || exit
git checkout "subscription-manager-$RHSM_VERSION-$RHSM_RELEASE"

# Use tito to build the source RPM
tito build --tag="subscription-manager-$RHSM_VERSION-$RHSM_RELEASE" --srpm --dist=".$RHSM_DIST" --offline
cp "/tmp/tito/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" /root/rpmbuild/SRPMS/


# Patch the subscription-manager.spec file
rpm -ivh "/root/rpmbuild/SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"
cd /root/rpmbuild/SPECS || exit
patch -p0 < /obsolete-rhn-rpms.diff

# Build the binary RPMs
cd /root/rpmbuild || exit
yum-builddep -y --enablerepo=ol7_optional_latest "/tmp/tito/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"
rpmbuild -ba SPECS/subscription-manager.spec

# Sign the binary RPMs if the required files and envvar are provided.
if [ -f /gpg/key.asc ] && [ -f /gpg/passphrase ] && [ "$GPG_NAME_EMAIL" ]; then

  # Import GPG key and trust it
  gpg --import --passphrase-file /gpg/passphrase < /gpg/key.asc
  (echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets < /gpg/key.asc | awk '$1=="keyid:"{print$2;exit}')" trust

  echo "%_gpg_name $GPG_NAME_EMAIL" >> /root/.rpmmacros
  find /root/rpmbuild/RPMS -name '*.rpm' -exec /rpm-sign.exp {} \;
fi

# Copy the RPMs to the output location
if [ ! -d /output/oraclelinux7 ]; then
  mkdir /output/oraclelinux7
fi
cp -rf /root/rpmbuild/RPMS/* /output/oraclelinux7/

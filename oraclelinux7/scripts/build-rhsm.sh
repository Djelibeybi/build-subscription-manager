#!/bin/bash
#
# Copyright (c) 2021, 2023 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Clone the repo
cd /root || exit
git clone https://github.com/candlepin/subscription-manager.git

# Checkout the release tag
cd /root/subscription-manager || exit
git checkout "subscription-manager-$RHSM_VERSION-$RHSM_RELEASE"

# Use tito to build the source tar.gz files
/bin/rpmdev-setuptree
tito build --tag subscription-manager-$RHSM_VERSION-$RHSM_RELEASE --tgz --offline
cp "/tmp/tito/subscription-manager-$RHSM_VERSION.tar.gz" /root/rpmbuild/SOURCES/
cp "/tmp/tito/subscription-manager-cockpit-$RHSM_VERSION.tar.gz" /root/rpmbuild/SOURCES/
cp -fr /root/subscription-manager/* /root/rpmbuild/SOURCES/

# Use tito to build src.rpm files
tito build --tag="subscription-manager-$RHSM_VERSION-$RHSM_RELEASE" --srpm --dist=".$RHSM_DIST" --offline
cp "/tmp/tito/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" /root/rpmbuild/SRPMS/
rpm -ivh "/root/rpmbuild/SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"

# Patch the subscription-manager.spec file
cd /root/rpmbuild/SPECS || exit
patch -p0 < /obsolete-rhn-rpms.diff

# Use rpmbuild to build and sign the binary RPMs
if [ -f /gpg/key.asc ] && [ -f /gpg/passphrase ] && [ "$GPG_NAME_EMAIL" ]; then

  # Import and trust the GPG key
  gpg --import --pinentry-mode loopback --passphrase-file /gpg/passphrase < /gpg/key.asc
  (echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets < /gpg/key.asc | awk '$1=="keyid:"{print$2;exit}')" trust

   SIGN="--sign"
  cd /root/rpmbuild || exit
  cat << EOF >> /root/.rpmmacros

%_gpg_sign_cmd_extra_args  --batch --pinentry-mode loopback --passphrase-file /gpg/passphrase
%_gpg_name ${GPG_NAME_EMAIL}
EOF

else
  echo "Not signing the packages. One or more of the key.asc and passphrase files and the GPG_NAME_EMAIL environment variable are missing."
fi

yum-builddep -y --enablerepo=ol7_optional_latest "/tmp/tito/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"
rpmbuild -ba /root/rpmbuild/SPECS/subscription-manager.spec

# Copy the RPMs to the output location
if [ ! -d /output/oraclelinux7 ]; then
  mkdir /output/oraclelinux7
fi
cp -rf /root/rpmbuild/RPMS/* /output/oraclelinux7/

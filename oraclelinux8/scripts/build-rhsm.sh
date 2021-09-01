#!/bin/bash
#
# Copyright (c) 2021 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Import and trust the GPG key
gpg --import --pinentry-mode loopback --passphrase-file /gpg/passphrase < /gpg/key.asc
(echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets < /gpg/key.asc | awk '$1=="keyid:"{print$2;exit}')" trust

# Clone the repo
cd /root || exit
git clone https://github.com/candlepin/subscription-manager.git

# Use tito to build the source RPM
cd /root/subscription-manager || exit
tito build --tag="subscription-manager-$RHSM_VERSION-$RHSM_RELEASE" --srpm --dist=".$RHSM_DIST" --offline
cp "/tmp/tito/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" /root/rpmbuild/SRPMS/

# Use rpmbuild to build and sign the binary RPMs
if [ -f /gpg/key.asc ] && [ -f /gpg/passphrase ] && [ "$GPG_NAME_EMAIL" ]; then
   SIGN="--sign"
  cd /root/rpmbuild || exit
  cat << EOF >> /root/.rpmmacros

%_gpg_sign_cmd_extra_args  --batch --pinentry-mode loopback --passphrase-file /gpg/passphrase
%_gpg_name ${GPG_NAME_EMAIL}
EOF

else
  echo "Not signing the packages. One or more of the key.asc and passphrase files and the GPG_NAME_EMAIL environment variable are missing."
fi

dnf builddep -y "SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"
rpmbuild --rebuild $SIGN "SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"

# Copy the RPMs to the output location
mkdir /output/oraclelinux8
cp -r /root/rpmbuild/RPMS/* /output/oraclelinux8/

#!/bin/bash
#
# Copyright (c) 2021, 2023 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


# Clone the repo
cd /root || exit
git clone https://github.com/candlepin/subscription-manager.git

# Use tito to build the source RPM
cd /root/subscription-manager || exit
tito build --tag="subscription-manager-$RHSM_VERSION-$RHSM_RELEASE" --srpm --dist=".$RHSM_DIST" --offline
cp "/tmp/tito/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm" /root/rpmbuild/SRPMS/

# use dnf builddep to install the dependencies for the build
dnf builddep -y "/root/rpmbuild/SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"
# use rpmbuild --rebuild to build the binary RPM from the src.rpm created by tito
rpmbuild --rebuild "/root/rpmbuild/SRPMS/subscription-manager-$RHSM_VERSION-$RHSM_RELEASE.$RHSM_DIST.src.rpm"


# Import the provided GPG signature and sign the binary RPMs using rpmsign
if [ -f /gpg/key.asc ] && [ -f /gpg/passphrase ] && [ "$GPG_NAME_EMAIL" ]; then

  # Import and trust the GPG key
  gpg --import --pinentry-mode loopback --passphrase-file /gpg/passphrase < /gpg/key.asc
  (echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets < /gpg/key.asc | awk '$1=="keyid:"{print$2;exit}')" trust

  cd /root/rpmbuild || exit
  cat << EOF >> /root/.rpmmacros

%_gpg_sign_cmd_extra_args  --batch --pinentry-mode loopback --passphrase-file /gpg/passphrase
%_gpg_name ${GPG_NAME_EMAIL}
EOF

  echo "Signing binary RPMs"
  find /root/rpmbuild/RPMS -name "*.rpm*" -exec rpmsign --addsign --key-id="$GPG_NAME_EMAIL" {} \;

else
  echo "Not signing the packages. One or more of the key.asc and passphrase files and the GPG_NAME_EMAIL environment variable are missing."
fi


# Copy the RPMs to the output location
mkdir /output/oraclelinux9
cp -r /root/rpmbuild/RPMS/* /output/oraclelinux9/

#!/bin/bash
#
# Copyright (c) 2021 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Import GPG key and trust it
gpg --import --passphrase-file /gpg/passphrase < /gpg/key.asc
(echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets < /gpg/key.asc | awk '$1=="keyid:"{print$2;exit}')" trust

# Clone the git repo
cd /root || exit
git clone https://github.com/candlepin/subscription-manager.git

# Build the SRPM using tito
cd subscription-manager || exit
tito build --tag subscription-manager-1.24.45-1 --srpm --dist=.el7 --offline
cp /tmp/tito/*.src.rpm /root/rpmbuild/SRPMS/

# Build the binary RPMs
cd /root/rpmbuild || exit
yum-builddep -y --enablerepo=ol7_optional_latest SRPMS/subscription-manager-1.24.45-1.el7.src.rpm
rpmbuild --rebuild SRPMS/subscription-manager-1.24.45-1.el7.src.rpm

# Sign the binary RPMs
echo "%_gpg_name Avi Miller <me@dje.li>" >> /root/.rpmmacros
find /root/rpmbuild/RPMS -name '*.rpm' -exec /rpm-sign.exp {} \;

# Copy the RPMs to the output location
mkdir /output/oraclelinux7
cp -r /root/rpmbuild/RPMS/* /output/oraclelinux7/

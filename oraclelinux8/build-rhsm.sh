#!/bin/bash

# Import and trust the GPG key
gpg --import --pinentry-mode loopback --passphrase-file /gpg/passphrase < /gpg/key.asc
(echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(gpg --list-packets < /gpg/key.asc | awk '$1=="keyid:"{print$2;exit}')" trust

# Clone the repo
cd /root || exit
git clone https://github.com/candlepin/subscription-manager.git

# Use tito to build the source RPM
cd /root/subscription-manager || exit
tito build --tag=subscription-manager-1.27.16-1 --srpm --dist=.el8 --offline
cp /tmp/tito/*.src.rpm /root/rpmbuild/SRPMS/

# Use rpmbuild to build and sign the binary RPMs
cd /root/rpmbuild || exit
cat << EOF >> /root/.rpmmacros

%_gpg_sign_cmd_extra_args  --batch --pinentry-mode loopback --passphrase-file /gpg/passphrase
%_gpg_name Avi Miller <me@dje.li>
EOF

dnf builddep -y SRPMS/subscription-manager-1.27.16-1.el8.src.rpm
rpmbuild --rebuild --sign SRPMS/subscription-manager-1.27.16-1.el8.src.rpm

# Copy the RPMs to the output location
mkdir /output/oraclelinux8
cp -r /root/rpmbuild/RPMS/* /output/oraclelinux8/

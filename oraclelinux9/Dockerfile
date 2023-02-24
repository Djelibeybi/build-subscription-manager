# Copyright (c) 2021, 2023 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

FROM oraclelinux:9

RUN echo > /etc/dnf/vars/ociregion \
    && dnf config-manager --enable ol9_codeready_builder ol9_distro_builder \
    && dnf -y install oracle-epel-release-el9 python3-pip python3-setuptools \
    && dnf config-manager  --setopt=tsflags=nodocs --save \
    && dnf -y module enable nodejs:18 \
    && dnf -y groups install "Development Tools" "RPM Development Tools" \
    && dnf -y install nodejs npm which \
    && dnf -y clean all \
    && npm i -g corepack \
    && corepack prepare yarn@stable --activate \
    && python3 -m pip install tito \
    && rpmdev-setuptree 

COPY scripts/build-rhsm.sh /
RUN chmod +x /build-rhsm.sh

CMD ["/build-rhsm.sh"]

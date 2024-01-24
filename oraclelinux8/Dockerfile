# Copyright (c) 2021, 2024 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

FROM oraclelinux:8

RUN echo > /etc/dnf/vars/ociregion \
    && dnf config-manager --enable ol8_codeready_builder ol8_distro_builder \
    && dnf config-manager  --setopt=tsflags=nodocs --save \
    && dnf -y module install nodejs \
    && dnf -y install oracle-epel-release-el8 \
    && dnf -y groups install "Development Tools" \
    && dnf -y install tito which \
    && dnf -y remove java-1.8.0-openjdk-headless-1.8.0.275.b01-1.el8_3.x86_64 'urw*' \
    && dnf -y clean all \
    && npm install -g yarn \
    && rpmdev-setuptree

COPY scripts/* /
RUN chmod +x /build-rhsm.sh

CMD ["/build-rhsm.sh"]

# Copyright (c) 2021, 2024 Avi Miller
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

FROM oraclelinux:7-slim

RUN yum -y install oracle-epel-release-el7 oracle-nodejs-release-el7 \
    && yum -y --enablerepo=ol7_optional_latest install @buildsys-build tito rpm-build rpm-sign nodejs npm which expect\
    && rm -rf /var/cache/yum \
    && npm install -g yarn \
    && rpmdev-setuptree

COPY scripts/* /
RUN chmod +x /build-rhsm.sh /rpm-sign.exp

CMD ["/build-rhsm.sh"]

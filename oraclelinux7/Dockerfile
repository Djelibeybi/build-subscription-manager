FROM oraclelinux:7-slim

RUN yum -y install oracle-epel-release-el7 oracle-nodejs-release-el7 \
    && yum -y --enablerepo=ol7_optional_latest install @buildsys-build tito rpm-build rpm-sign nodejs which expect \
    && rm -rf /var/cache/yum \
    && npm install -g yarn \
    && rpmdev-setuptree

COPY build-rhsm.sh rpm-sign.exp /
RUN chmod +x /build-rhsm.sh /rpm-sign.exp

CMD ["/build-rhsm.sh"]

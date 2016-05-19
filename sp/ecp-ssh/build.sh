#!/bin/bash

set -e
set -x

MECH_SAML_DIR=/home/vagrant/mech_saml_ec

OPENSSH_SRC_DIR=/home/vagrant/openssh
OPENSSH_BUILD_DIR=/home/vagrant/moonshot-ssh

KERBEROS_SRC_DIR=/home/vagrant/krb5-1.13.2
KERBEROS_BUILD_DIR=/home/vagrant/krb5-install

# Build Kerberos
if [ ! -d ${KERBEROS_BUILD_DIR} ]; then
    cd ${KERBEROS_SRC_DIR}/src
    if [ ! -f Makefile ]; then
        CFLAGS=-g ./configure --prefix=${KERBEROS_BUILD_DIR} --enable-shared
    fi
    make clean
    make
    make install

    mkdir -p ${KERBEROS_BUILD_DIR}/etc
    echo -e "[libdefaults]\n   default_realm = $(hostname | tr '[:lower:]' '[:upper:]')" > ${KERBEROS_BUILD_DIR}/etc/krb5.conf
fi

# Build OpenSSH
if [ ! -d ${OPENSSH_BUILD_DIR} ]; then
    cd ${OPENSSH_SRC_DIR}
    if [ ! -d Makefile ]; then
        ./configure --prefix=${OPENSSH_BUILD_DIR} --with-kerberos5=${KERBEROS_BUILD_DIR}
    fi
    make clean
    make
    make install

    cd ${OPENSSH_BUILD_DIR}

    sed -i \
        -e "s/^#\?GSSAPIAuthentication.*$/GSSAPIAuthentication yes/" \
        -e "s/^#\?UsePrivilegeSeparation.*$/UsePrivilegeSeparation no/" \
        ./etc/sshd_config

    sed -i \
        -e "s/^#\?\s*Host \*$/Host */" \
        -e "s/^#\?\(\s*GSSAPIAuthentication\).*$/\1 yes/" \
        ./etc/ssh_config
fi

# Build mech_saml_ec
cd ${MECH_SAML_DIR}
if [ ! -f Makefile ]; then
    ./autogen.sh
    ./configure --with-krb5=${KERBEROS_BUILD_DIR}
fi

if [ $1 == "clean" ]; then
  make clean
fi
INCLUDES=-I${KERBEROS_BUILD_DIR}/include LIBS="-L${KERBEROS_BUILD_DIR}/lib -lgssapi_krb5" make

# Install mech_saml_ec
mkdir -p ${KERBEROS_BUILD_DIR}/etc/gss
echo "saml-ec 1.3.6.1.4.1.11591.4.6 mech_saml_ec.so" > ${KERBEROS_BUILD_DIR}/etc/gss/mech

mkdir -p ${KERBEROS_BUILD_DIR}/lib/gss
cp ${MECH_SAML_DIR}/mech_saml_ec/.libs/mech_saml_ec.so ${KERBEROS_BUILD_DIR}/lib/gss/

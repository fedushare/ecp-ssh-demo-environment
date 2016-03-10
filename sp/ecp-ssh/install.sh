#!/bin/bash

set -e
set -x

# Install dependencies
yum install -y \
    shibboleth-devel \
    xerces-c \
    xerces-c-devel \
    libsaml8 \
    libsaml-devel \
    opensaml-schemas \
    liblog4shib1 \
    liblog4shib-devel \
    libxml-security-c17 \
    libxml-security-c-devel \
    libxmltooling6 \
    libxmltooling-devel \
    xmltooling-schemas \
    libevent \
    libxml2-devel \
    libtool \
    gcc \
    gcc-c++ \
    byacc \
    libcurl \
    libcurl-devel

cd /home/vagrant

# Download Kerberos
curl "http://web.mit.edu/kerberos/dist/krb5/1.13/krb5-1.13.2-signed.tar" > krb5-1.13.2-signed.tar
tar -xf krb5-1.13.2-signed.tar
tar -xzf krb5-1.13.2.tar.gz

# Download Moonshot SSH
git clone "http://www.project-moonshot.org/git/openssh.git"

# Download mech_saml_ec
git clone "https://github.com/fedushare/mech_saml_ec.git"

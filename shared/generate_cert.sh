#!/bin/bash

if [ -z "$1" ]; then
    echo "No cert name given"
    exit 1
fi

NAME=$1

set -e
set -x

mkdir -p /vagrant/certs
cd /vagrant/certs

# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "${NAME}.key" -out "${NAME}.crt" \
    -subj "/C=US/ST=South Carolina/L=Clemson/O=Clemson University/OU=FeduShare Demo/CN=${NAME}.vagrant.test"

# Convert to PKCS12 and replace Jetty keystore
# reuse default passwords so Jetty configuration doesn't have to change
openssl pkcs12 -inkey "${NAME}.key" -in "${NAME}.crt" -export -out "${NAME}.pkcs12" -password "pass:keypwd"
$JAVA_HOME/bin/keytool -importkeystore -noprompt \
    -srckeystore "${NAME}.pkcs12" -srcstoretype PKCS12 -srcstorepass "keypwd" \
    -destkeystore "/opt/iam-jetty-base/etc/keystore" -deststorepass "storepwd"

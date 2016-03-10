#!/bin/bash

set -e
set -x

if [ -z $SHIB_IDP_VERSION ]; then
    echo "SHIB_IDP_VERSION is not set"
    exit 1
fi

if [ -z $SHIB_IDP_HASH ]; then
    echo "SHIB_IDP_HASH is not set"
    exit 1
fi

if [ -z $SHIB_IDP_HOME ]; then
    echo "SHIB_IDP_HOME is not set"
    exit 1
fi

# Download Shibboleth IdP, verify the hash, and install
wget -O "/tmp/shibboleth-identity-provider-${SHIB_IDP_VERSION}.zip" \
    "https://shibboleth.net/downloads/identity-provider/${SHIB_IDP_VERSION}/shibboleth-identity-provider-${SHIB_IDP_VERSION}.zip"
echo "${SHIB_IDP_HASH} /tmp/shibboleth-identity-provider-${SHIB_IDP_VERSION}.zip" | sha1sum -c -
unzip "/tmp/shibboleth-identity-provider-${SHIB_IDP_VERSION}.zip" -d /tmp

cd "/tmp/shibboleth-identity-provider-${SHIB_IDP_VERSION}/"

cat <<EOF > ./to_merge.properties
idp.entityID=https://$(hostname)/idp/shibboleth
idp.scope=$(hostname | rev | cut -d "." -f 1-2 | rev)
idp.sealer.storePassword=password
idp.sealer.keyPassword=password
EOF

bin/install.sh \
    -Didp.noprompt=true \
    -Didp.src.dir=. \
    -Didp.target.dir=$SHIB_IDP_HOME \
    -Didp.keystore.password=password \
    -Didp.sealer.password=password \
    -Didp.host.name=$(hostname) \
    -Didp.scope=$(hostname | rev | cut -d "." -f 1-2 | rev) \
    -Didp.merge.properties=./to_merge.properties

rm "/tmp/shibboleth-identity-provider-${SHIB_IDP_VERSION}.zip"
rm -r "/tmp/shibboleth-identity-provider-${SHIB_IDP_VERSION}/"

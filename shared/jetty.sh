#!/bin/bash

set -e
set -x

if [ -z $JETTY_VERSION ]; then
    echo "JETTY_VERSION is not set"
    exit 1
fi

if [ -z $JETTY_HASH ]; then
    echo "JETTY_HASH is not set"
    exit 1
fi

if [ -z $JETTY_HOME ]; then
    echo "JETTY_HOME is not set"
    exit 1
fi

wget -O /tmp/jetty.tar.gz "https://eclipse.org/downloads/download.php?file=/jetty/${JETTY_VERSION}/dist/jetty-distribution-${JETTY_VERSION}.tar.gz&r=1"
echo "${JETTY_HASH} /tmp/jetty.tar.gz" | sha1sum -c -
tar -zxvf /tmp/jetty.tar.gz -C $(dirname $JETTY_HOME)
mv "/opt/jetty-distribution-${JETTY_VERSION}" "${JETTY_HOME}"
rm /tmp/jetty.tar.gz

cp "${JETTY_HOME}/bin/jetty.sh" /etc/init.d/jetty

useradd jetty -U -s /bin/false

chown -R jetty:root "${JETTY_HOME}"

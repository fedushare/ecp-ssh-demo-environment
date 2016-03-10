#!/bin/bash

set -e
set -x

if [ -z $SHIB_IDP_HOME ]; then
    echo "SHIB_IDP_HOME is not set"
    exit 1
fi

# Install MySQL Java Connector
MYSQL_CONNECTOR_VERSION="5.0.8"
wget -O "/tmp/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz" \
    "http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz"
echo "7a3caaa764fd6266bc312d8930972e8f /tmp/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz" | md5sum -c -
tar -zxvf "/tmp/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz"
cp "mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar" "${SHIB_IDP_HOME}/edit-webapp/WEB-INF/lib/"

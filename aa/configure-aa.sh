#!/bin/bash

set -e
set -x

# https://www.eduid.cz/en/tech/idp/shibboleth

if [ -z $SHIB_IDP_HOME ]; then
    echo "SHIB_IDP_HOME is not set"
    exit 1
fi

cd /vagrant/aa/conf
for f in $(find . -name '*' -type f); do
    cp "/vagrant/aa/conf/$f" "${SHIB_IDP_HOME}/conf/$f"
done

# Rebuild IDP WAR
${SHIB_IDP_HOME}/bin/build.sh -Didp.target.dir=${SHIB_IDP_HOME}

# Load identities into MySQL
mysql -u root < "/vagrant/aa/accounts.sql"

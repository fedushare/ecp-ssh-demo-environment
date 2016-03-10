#!/bin/bash

set -e
set -x

# https://www.eduid.cz/en/tech/idp/shibboleth

if [ -z $SHIB_IDP_HOME ]; then
    echo "SHIB_IDP_HOME is not set"
    exit 1
fi

# Install tagishauth module for JAAS DB authentication
cd /tmp
git clone https://github.com/tauceti2/jaas-rdbms.git
cd /tmp/jaas-rdbms
sed -i 's/JAVAC=.*/JAVAC=javac/' Makefile
PATH=$PATH:$JAVA_HOME/bin make
cp ./tagishauth.jar "${SHIB_IDP_HOME}/edit-webapp/WEB-INF/lib/tagishauth.jar"

cd /vagrant/idp/conf
for f in $(find . -name '*' -type f); do
    cp "/vagrant/idp/conf/$f" "${SHIB_IDP_HOME}/conf/$f"
done

# Load identities into MySQL
mysql -u root < "/vagrant/idp/identities.sql"

# Rebuild IDP WAR
${SHIB_IDP_HOME}/bin/build.sh -Didp.target.dir=${SHIB_IDP_HOME}

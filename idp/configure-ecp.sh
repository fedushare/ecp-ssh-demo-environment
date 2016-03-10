#!/bin/bash

set -e
set -x

# ECP configuration
# https://wiki.shibboleth.net/confluence/display/IDP30/ECPConfiguration

cp /vagrant/idp/webapp/WEB-INF/web.xml "${SHIB_IDP_HOME}/webapp/WEB-INF/web.xml"

sed -i 's/idp.authn.flows=.*/idp.authn.flows=Password|RemoteUserInternal/' "${SHIB_IDP_HOME}/conf/idp.properties"

cp /vagrant/idp/jetty/jetty.xml "/opt/jetty/etc/jetty.xml"

cd /vagrant/idp/iam-jetty-base
for f in $(find . -name '*' -type f); do
    cp "/vagrant/idp/iam-jetty-base/$f" "${JETTY_BASE}/$f"
done

${SHIB_IDP_HOME}/bin/build.sh -Didp.target.dir=${SHIB_IDP_HOME}

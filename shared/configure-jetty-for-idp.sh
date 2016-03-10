#!/bin/bash

set -e
set -x

if [ -z $JETTY_BASE ]; then
    echo "JETTY_BASE is not set"
    exit 1
fi

if [ -z $SHIB_IDP_HOME ]; then
    echo "SHIB_IDP_HOME is not set"
    exit 1
fi

# Create JETTY_BASE directory structure
mkdir -p "${JETTY_BASE}/etc"
mkdir -p "${JETTY_BASE}/modules"
mkdir -p "${JETTY_BASE}/lib/ext"
mkdir -p "${JETTY_BASE}/resources"
mkdir -p "${JETTY_BASE}/start.d"
mkdir -p "${JETTY_BASE}/webapps/idp.d"

cd "${JETTY_BASE}"
$JAVA_HOME/bin/java -jar "${JETTY_HOME}/start.jar" --add-to-startd=http,https,deploy,ext,annotations,jstl,logging,setuid

sed -i 's/# jetty.http.port=8080/jetty.http.port=80/g' "${JETTY_BASE}/start.d/http.ini"
sed -i 's/# jetty.ssl.port=8443/jetty.ssl.port=443/g' "${JETTY_BASE}/start.d/ssl.ini"

# Download setuid, verify the hash, and place
SETUID_VERSION="8.1.9.v20130131"
wget -O "/tmp/libsetuid-${SETUID_VERSION}.so" \
    "https://repo1.maven.org/maven2/org/mortbay/jetty/libsetuid/${SETUID_VERSION}/libsetuid-${SETUID_VERSION}.so"
echo "7286c7cb836126a403eb1c2c792bde9ce6018226 /tmp/libsetuid-${SETUID_VERSION}.so" | sha1sum -c -
mv /tmp/libsetuid-8.1.9.v20130131.so "${JETTY_BASE}/lib/ext/"

# Download the library to allow SOAP Endpoints, verify the hash, and place
wget -O "/tmp/jetty9-dta-ssl-1.0.0.jar" \
    "https://build.shibboleth.net/nexus/content/repositories/releases/net/shibboleth/utilities/jetty9/jetty9-dta-ssl/1.0.0/jetty9-dta-ssl-1.0.0.jar"
echo "2f547074b06952b94c35631398f36746820a7697 /tmp/jetty9-dta-ssl-1.0.0.jar" | sha1sum -c -
mv /tmp/jetty9-dta-ssl-1.0.0.jar "${JETTY_BASE}/lib/ext/"

chown -R jetty:root "${SHIB_IDP_HOME}/logs"

cd /vagrant/shared/iam-jetty-base
for f in $(find . -name '*' -type f); do
    cp "/vagrant/shared/iam-jetty-base/$f" "${JETTY_BASE}/$f"
done

chown -R jetty:root "${JETTY_BASE}"
chown -R jetty:root "${SHIB_IDP_HOME}"


cat <<EOF > /etc/systemd/system/idp.service
[Unit]
Description=Shibboleth Identity Provider

[Service]
Environment=JAVA_HOME=${JAVA_HOME} JETTY_HOME=${JETTY_HOME} JETTY_BASE=${JETTY_BASE}
WorkingDirectory=${JETTY_BASE}
ExecStart=${JAVA_HOME}/bin/java -jar \${JETTY_HOME}/start.jar jetty.home=\${JETTY_HOME} jetty.base=\${JETTY_BASE}

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable idp

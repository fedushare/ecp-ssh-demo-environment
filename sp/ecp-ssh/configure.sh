#!/bin/bash

set -e
set -x

echo "tls-server-end-point" > /root/.gss_saml_ec_cb_type
echo "tls-server-end-point" > /home/vagrant/.gss_saml_ec_cb_type

cat <<EOF > /etc/profile.d/mech_saml_ec_debug.sh
export MECH_SAML_EC_DEBUG=true
export SAML_EC_IDP="https://idp.vagrant.test/idp/profile/SAML2/SOAP/ECP"
EOF

chmod +x /etc/profile.d/mech_saml_ec_debug.sh

cat <<EOF > /home/vagrant/.gss_eap_id
jsmith
password
EOF

for u in user1 user2 user3; do
    useradd $u --password $u
done

python -c '
import re
with open("/etc/shibboleth/shibboleth2.xml", "r+") as f:
    conf = f.read()

    conf = re.sub("<(ApplicationDefaults.*?)>", "<\g<1> signing=\"true\" requireSignedAssertions=\"true\">", conf, count=1, flags=re.I|re.M|re.S)

    f.seek(0)
    f.write(conf)
    f.truncate()
'

systemctl restart shibd
systemctl restart httpd

METADATA=$(curl -k "https://$(hostname)/Shibboleth.sso/Metadata")
MAX_ACS_INDEX=$(echo $METADATA | grep AssertionConsumerService | sed -e 's/.*index="\([0-9]\+\)".*/\1/' | sort | tail -n1)
NEW_ACS_INDEX=$(($MAX_ACS_INDEX + 1))
ACS_TAG="<md:AssertionConsumerService Binding=\"urn:oasis:names:tc:SAML:2.0:bindings:PAOS\" Location=\"host@$(hostname)\" index=\"${NEW_ACS_INDEX}\"\/>"
SSO_END_TAG='<\/md:SPSSODescriptor>'
echo "$METADATA" | sed -e "s/${SSO_END_TAG}/  ${ACS_TAG}\n&/" > /var/www/html/sp-metadata.xml

cat <<EOF > /etc/systemd/system/ecp-sshd.service
[Unit]
Description=Shibboleth enabled SSH server
After=network.target

[Service]
Environment=LD_LIBRARY_PATH=/opt/shibboleth/lib64
WorkingDirectory=/home/vagrant
ExecStart=/home/vagrant/moonshot-ssh/sbin/sshd -D -p 10022
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload

#!/bin/bash

set -e
set -x

echo "tls-server-end-point" > /root/.gss_saml_ec_cb_type
echo "tls-server-end-point" > /home/vagrant/.gss_saml_ec_cb_type

cat <<EOF > /etc/profile.d/mech_saml_ec_debug.sh
export MECH_SAML_EC_DEBUG=true
EOF

chmod +x /etc/profile.d/mech_saml_ec_debug.sh

cat <<EOF > /home/vagrant/.gss_eap_id
jsmith
password
EOF

cat <<EOF >> /home/vagrant/.bashrc

export SAML_EC_IDP="https://idp.vagrant.test/idp/profile/SAML2/SOAP/ECP"

EOF

#!/bin/bash

set -e
set -x

sed -i 's/\(<\/Attributes>\)/    <Attribute name="local-login-user" id="local-login-user"\/>\n\1/' /etc/shibboleth/attribute-map.xml

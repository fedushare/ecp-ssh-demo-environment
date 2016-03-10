#!/bin/bash

set -e
set -x

# Edit IDP metadata to support SAML2 attribute queries

# Make two changes
# * Uncomment SAML 2 AttributeQuery AttributeService
# * Add SAML2 to AttributeAuthorityDescriptor's protocol enumeration

METADATA_FILE=$1


ATTR_QUERY_SERVICE='AttributeService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"'

ATTR_AUTH_DESC_TAG='<AttributeAuthorityDescriptor protocolSupportEnumeration'
SAML2_PROTOCOL='urn:oasis:names:tc:SAML:2.0:protocol'


awk "/$ATTR_QUERY_SERVICE/ { gsub(/<!-- ?/, \"\"); gsub(\"-->\", \"\"); print; } !/$ATTR_QUERY_SERVICE/ { print; }" $METADATA_FILE | \
sed -e "s/$ATTR_AUTH_DESC_TAG=\"\(.*\)\">/$ATTR_AUTH_DESC_TAG=\"\1 $SAML2_PROTOCOL\">/"

#!/bin/python

# * Set entityID of SSO to primary IDP and remove discovery attributes
# * Add metadata provider for primary IDP
# * Add SimpleAggregation AttributeResolver config for AA IDP

import re

metadata_provider = """
        <MetadataProvider type="XML" validate="true" path="/vagrant/metadata/idp-metadata.xml" />
"""

attribute_resolver = """
        <AttributeResolver type="SimpleAggregation" attributeId="eppn" format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">
            <Entity>https://vo.vagrant.test/idp/shibboleth</Entity>
            <MetadataProvider type="XML" validate="true" path="/vagrant/metadata/vo-aa-metadata.xml" />
        </AttributeResolver>

        <AttributeResolver type="SimpleAggregation" attributeId="eppn" format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">
            <Entity>https://aa.vagrant.test/idp/shibboleth</Entity>
            <MetadataProvider type="XML" validate="true" path="/vagrant/metadata/resource-aa-metadata.xml" />
        </AttributeResolver>
"""

with open("/etc/shibboleth/shibboleth2.xml", "r+") as f:
    conf = f.read()

    conf = re.sub("<SSO entityID.*?>", "<SSO entityID=\"https://idp.vagrant.test/idp/shibboleth\">", conf, count=1, flags=re.I|re.M|re.S)

    conf = re.sub("(<Errors.*?>)", "\g<1>\n%s" % metadata_provider, conf, count=1, flags=re.I|re.M|re.S)

    conf = re.sub("(<AttributeResolver.*?>)", "\g<1>\n%s" % attribute_resolver, conf, count=1, flags=re.I|re.M|re.S)

    f.seek(0)
    f.write(conf)
    f.truncate()

# VO Attribute Authority returns list of a user's VOs

In this case, the resource provider's SP queries a VO AA for the full list of VOs of which a user (identified by
an EPPN) is a member. The SP then makes the decision to allow/reject access based on that list.

For this example, assume the AA returns the list in an attribute named `vo-memberships`.

## SP Configuration

The SP needs to query the AA and map the returned attribute:

`/etc/shibboleth/shibboleth2.xml`
```xml
...

<AttributeResolver type="SimpleAggregation" attributeId="eppn" format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">
   <Entity>https://aa.virtualorganization.com/idp/shibboleth</Entity>
   <MetadataProvider type="XML" validate="true" path="/path/to/vo-aa-metadata.xml" />
</AttributeResolver>

...
```

The SP then needs to map the attribute returned by the VO AA.

`/etc/shibboleth/attribute-map.xml`
```xml
<Attributes ...>
   ...
   <Attribute name="voMemberships" id="voMemberships" />
   ...
</Attributes>
```

## Attribute Authority Configuration

The VO AA can use the queried EPPN to look up which VOs the user is a member of. For example:

`$IDP_HOME/conf/attribute-resolver.xml`
```xml
...

<resolver:AttributeDefinition id="voMemberships" xsi:type="ad:Simple" sourceAttributeID="voNames">

   <resolver:Dependency ref="membershipsQuery" />

   <resolver:AttributeEncoder xsi:type="enc:SAML1String" name="voMemberships" encodeType="false" />
   <resolver:AttributeEncoder xsi:type="enc:SAML2String" name="voMemberships" friendlyName="voMemberships" encodeType="false" />

</resolver:AttributeDefinition>

<resolver:DataConnector id="membershipsQuery" xsi:type="dc:RelationalDatabase">

   <dc:ApplicationManagedConnection jdbcDriver="com.mysql.jdbc.Driver"
                                    jdbcURL="jdbc:mysql://host:port/db"
                                    jdbcUserName="user"
                                    jdbcPassword="password" />

   <dc:QueryTemplate>
      <![CDATA[
         SELECT `vo_name` FROM `vo_memberships` WHERE `eppn` = '$requestContext.principalName'
      ]]>
   </dc:QueryTemplate>

   <dc:Column columnName="vo_name" attributeId="voNames" />

</resolver:DataConnector>

...
```

`$IDP_HOME/conf/attribute-filter.xml`
```xml
...

<afp:AttributeRule attributeID="voMemberships">
   <afp:PermitValueRule xsi:type="basic:ANY" />
</afp:AttributeRule>

...
```

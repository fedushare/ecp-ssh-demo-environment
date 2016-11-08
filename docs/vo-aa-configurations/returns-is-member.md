# VO Attribute Authority returns user is/is not member of a VO

In this case, the resource provider's SP queries a VO AA with a user's EPPN and the name of a VO. The VO AA
responds with a boolean attribute, true if the user is a member of the VO, false if they are not. The SP
decides to allow/reject access based on that value.

This case requires a more complicated configuration, but it has the advantage of avoiding the privacy implications
of releasing all of a user's VO memberships to an SP.

Because the [SimpleAggregation AttributeResolver](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeResolver#NativeSPAttributeResolver-SimpleAggregationAttributeResolver(Version2.2andAbove))
can only pass one attribute value (the query identifier) to the attribute authority, the user's EPPN and the name
of the VO to check their membership in must be first joined into a single value. The SP and VO AA would need to
agree on a method encoding/decoding the two attribute values in advance. Because the AA will use this attribute's
value as the [principal name](https://wiki.shibboleth.net/confluence/display/IDP30/PrincipalNameAttributeDefinition)
in attribute queries, it must be able to be encoded as a
[Name Identifier](https://wiki.shibboleth.net/confluence/display/SHIB2/IdPNameIdentifier).

A [Template AttributeResolver](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeResolver#NativeSPAttributeResolver-TemplateAttributeResolver(Version2.5andAbove))
could be used to join multiple attributes into one. From its documentation:

> To use this plugin, the plugins.so shared library must be loaded via the &lt;OutOfProcess&gt; element's
> &lt;Library&gt; element.

`/etc/shibboleth/shibboleth2.xml`
```xml
...

<OutOfProcess>
   <Extensions>
      <Library path="plugins.so" fatal="true"/>
   </Extensions>
</OutOfProcess>

...

<AttributeResolver type="Template" sources="eppn" dest="eppnPlusVO">
   <Template>AllowedUsers/$eppn</Template>
</AttributeResolver>

<AttributeResolver type="SimpleAggregation" attributeId="eppnPlusVO" format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">
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
   <Attribute name="isMemberOfVO" id="isMemberOfVO" />
   ...
</Attributes>
```

## Attribute Authority Configuration

At the VO attribute authority, this joined attribute needs to be split up again. This can be done using a
[Script AttributeDefinition](https://wiki.shibboleth.net/confluence/display/SHIB2/ResolverScriptAttributeDefinition).
(The static data connector is necessary to create attributes if using
[Java 1.8's Nashorn engine](https://wiki.shibboleth.net/confluence/display/SHIB2/IdPJava1.8))

`$IDP_HOME/conf/attribute-resolver.xml`
```xml
...

<!-- Create attributes for script definitions -->
<resolver:DataConnector id="scriptAttrCreation" xsi:type="dc:Static" xmlns="urn:mace:shibboleth:2.0:resolver:dc">
   <Attribute id="eppn">
      <Value>placeholder</Value>
   </Attribute>
   <Attribute id="voName">
      <Value>placeholder</Value>
   </Attribute>
</resolver:DataConnector>

<!-- Extract VO name from attribute query -->
<resolver:AttributeDefinition id="voName" xsi:type="ad:Script">
   <resolver:Dependency ref="scriptAttrCreation" />
   <ad:Script>
      <![CDATA[
         voName.getValues().clear();
         voName.getValues().add(requestContext.principalName.split("/")[0]);
      ]]>
   </ad:Script>
</resolver:AttributeDefinition>

<!-- Extract EPPN from attribute query -->
<resolver:AttributeDefinition id="eppn" xsi:type="ad:Script">
   <resolver:Dependency ref="scriptAttrCreation" />
   <ad:Script>
      <![CDATA[
         eppn.getValues().clear();
         eppn.getValues().add(requestContext.principalName.split("/")[1]);
      ]]>
   </ad:Script>
</resolver:AttributeDefinition>

...
```

Now that the VO name and user's EPPN are determined, they can be used in another data connector to determine
whether or not the user is a member of that VO. For example:

`$IDP_HOME/conf/attribute-resolver.xml`
```xml
...

<resolver:AttributeDefinition id="isMemberOfVO" xsi:type="ad:Simple" sourceAttributeID="isMember">

   <resolver:Dependency ref="db" />

   <resolver:AttributeEncoder xsi:type="enc:SAML1String" name="isMemberOfVO" encodeType="false" />
   <resolver:AttributeEncoder xsi:type="enc:SAML2String" name="isMemberOfVO" friendlyName="isMemberOfVO" encodeType="false" />

</resolver:AttributeDefinition>

<resolver:DataConnector id="db" xsi:type="dc:RelationalDatabase">

   <!-- This connector depends on EPPN and VO name having been extracted -->
   <resolver:Dependency ref="eppn" />
   <resolver:Dependency ref="voName" />

   <dc:ApplicationManagedConnection jdbcDriver="com.mysql.jdbc.Driver"
                                    jdbcURL="jdbc:mysql://host:port/db"
                                    jdbcUserName="user"
                                    jdbcPassword="password" />

   <dc:QueryTemplate>
      <![CDATA[
         SELECT IF(COUNT(*) > 0, 'true', 'false') AS `isMember` FROM `vo_memberships` WHERE `vo_name` = '${voName.get(0)}' AND `eppn` = '${eppn.get(0)}'
      ]]>
   </dc:QueryTemplate>

   <dc:Column columnName="isMember" />

</resolver:DataConnector>

...
```

`$IDP_HOME/conf/attribute-filter.xml`
```xml
...

<afp:AttributeRule attributeID="isMemberOfVO">
   <afp:PermitValueRule xsi:type="basic:ANY" />
</afp:AttributeRule>

...
```

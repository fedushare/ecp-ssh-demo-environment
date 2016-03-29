# VO Attribute Authority returns user is/is not member of a VO

In this case, the resource provider's SP queries a VO AA with a user's EPPN and the
name of a VO. The VO AA responds with a boolean attribute, true if the user is a
member of the VO, false if they are not. The SP decides to allow/reject access based
on that value.

This case requires a more complicated configuration, but it has the advantage of
avoiding the privacy implications of releasing all of a user's VO memberships to an SP.

Because the [SimpleAggregation AttributeResolver](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeResolver#NativeSPAttributeResolver-SimpleAggregationAttributeResolver(Version2.2andAbove))
can only pass one attribute value (the query identifier) to the attribute authority,
the user's EPPN and the name of the VO to check their membership in must be first
joined into a single value. This can be done using a
[Template AttributeResolver](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeResolver#NativeSPAttributeResolver-TemplateAttributeResolver(Version2.5andAbove))
Because the AA will use this attribute's value as the
[principal name](https://wiki.shibboleth.net/confluence/display/IDP30/PrincipalNameAttributeDefinition)
in attribute queries, it must be able to be encoded as a
[Name Identifier](https://wiki.shibboleth.net/confluence/display/SHIB2/IdPNameIdentifier).

`/etc/shibboleth/shibboleth2.xml`
```xml
<AttributeResolver type="Template" sources="eppn" dest="eppnPlusVO">
    <Template>AllowedUsers/$eppn</Template>
</AttributeResolver>
```

From the Template AttributeResolver's documentation:

> To use this plugin, the plugins.so shared library must be loaded via the
> &lt;OutOfProcess&gt; element's &lt;Library&gt; element.

`/etc/shibboleth/shibboleth2.xml`
```xml
<OutOfProcess>
    <Extensions>
        <Library path="plugins.so" fatal="true"/>
    </Extensions>
</OutOfProcess>
```

At the VO attribute authority, this joined attribute needs to be split up again.
This can be done using a
[Script AttributeDefinition](https://wiki.shibboleth.net/confluence/display/SHIB2/ResolverScriptAttributeDefinition).
(The static data connector is necessary to create attributes if using
[Java 1.8's Nashorn engine](https://wiki.shibboleth.net/confluence/display/SHIB2/IdPJava1.8))

`$IDP_HOME/conf/attribute-resolver.xml`
```xml
<!-- Create attributes for script definitions -->
<resolver:DataConnector id="scriptAttrCreation" xsi:type="dc:Static" xmlns="urn:mace:shibboleth:2.0:resolver:dc">
    <Attribute id="eppn"><Value>dummy</Value></Attribute>
    <Attribute id="voName"><Value>dummy</Value></Attribute>
</resolver:DataConnector>

<!-- Extract VO name from attribute query -->
<resolver:AttributeDefinition id="voName" xsi:type="ad:Script">
    <resolver:Dependency ref="scriptAttrCreation" />
    <ad:Script><![CDATA[
        voName.getValues().clear();
        voName.getValues().add(requestContext.principalName.split("/")[0]);
    ]]></ad:Script>
</resolver:AttributeDefinition>

<!-- Extract EPPN from attribute query -->
<resolver:AttributeDefinition id="eppn" xsi:type="ad:Script">
    <resolver:Dependency ref="scriptAttrCreation" />
    <ad:Script><![CDATA[
        eppn.getValues().clear();
        eppn.getValues().add(requestContext.principalName.split("/")[1]);
    ]]></ad:Script>
</resolver:AttributeDefinition>
```

Now that the VO name and user's EPPN are determined, they can be used in another data connector
to determine whether or not the user is a member of that VO. For example:

`$IDP_HOME/conf/attribute-resolver.xml`
```xml
<resolver:AttributeDefinition id="isMemberOfVO" xsi:type="ad:Simple" sourceAttributeID="isMember">
    <resolver:Dependency ref="isMemberOfVoQuery" />
    <resolver:AttributeEncoder xsi:type="enc:SAML1String" name="isMemberOfVO" encodeType="false" />
    <resolver:AttributeEncoder xsi:type="enc:SAML2String" name="isMemberOfVO" friendlyName="isMemberOfVO" encodeType="false" />
</resolver:AttributeDefinition>
<resolver:DataConnector id="isMemberOfVoQuery" xsi:type="dc:RelationalDatabase">

    <!-- This connector depends on EPPN and VO name having been extracted -->
    <resolver:Dependency ref="eppn" />
    <resolver:Dependency ref="voName" />

    <dc:ApplicationManagedConnection jdbcDriver="com.mysql.jdbc.Driver"
                                     jdbcURL="jdbc:mysql://host:port/db"
                                     jdbcUserName="user"
                                     jdbcPassword="password" />

    <dc:QueryTemplate>
        <![CDATA[
            SELECT COUNT(*) as `isMember` FROM `vo_memberships` WHERE `vo_name` = '$voName.get(0)' AND `eppn` = '$eppn.get(0)'
        ]]>
    </dc:QueryTemplate>

    <dc:Column columnName="isMember" />

</resolver:DataConnector>
```

`$IDP_HOME/conf/attribute-filter.xml`
```xml
<afp:AttributeRule attributeID="isMemberOfVO">
    <afp:PermitValueRule xsi:type="basic:ANY" />
</afp:AttributeRule>
```

Then, the SP can filter the value of `local-login-user` based on the value of `isMemberOfVO`
and reject `local-login-user` if `isMemberOfVO` is false.

`/etc/shibboleth/attribute-map.xml`
```xml
<Attributes ...>
    ...
    <Attribute name="isMemberOfVO" id="isMemberOfVO" />
</Attributes>
```

`/etc/shibboleth/attribute-policy.xml`
```xml
<afp:AttributeFilterPolicyGroup ...>
    ...

    <!-- Permit local-login-user is isMemberOfVO is true -->
    <afp:AttributeFilterPolicy>
        <afp:PolicyRequirementRule xsi:type="AttributeValueString" attributeID="isMemberOfVO" value="1" />
        <afp:AttributeRule attributeID="local-login-user">
            <afp:PermitValueRule xsi:type="ANY" />
        </afp:AttributeRule>
    </afp:AttributeFilterPolicy>

    <!-- Deny if false-->
    <afp:AttributeFilterPolicy>
        <afp:PolicyRequirementRule xsi:type="AttributeValueString" attributeID="isMemberOfVO" value="0" />
        <afp:AttributeRule attributeID="local-login-user">
            <afp:DenyValueRule xsi:type="ANY" />
        </afp:AttributeRule>
    </afp:AttributeFilterPolicy>

    ...
</afp:AttributeFilterPolicyGroup>
```

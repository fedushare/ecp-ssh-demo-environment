# Access Control

When using `mech_saml_ec`, the value of the `local-login-user` determines which account on the resource an authenticated
user gains access to. Thus, denying a user access is accomplished by not setting a value for that attribute or
filtering a previously set value.

When only an IdP and SP are involved, access control can be done by configuring the SP's
[attribute filter](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeFilter).
However, when the resource provider uses an attribute authority to resolve `local-login-user`, the situation gets
more complicated. The value of `local-login-user` is retrieved from the AA using a
[Simple Aggregation Attribute Resolver](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeResolver#NativeSPAttributeResolver-SimpleAggregationAttributeResolver(Version2.2andAbove)).
However:
> After each query is performed, the resolver applies the attribute extractor and filter configured for the
> application before continuing with other queries and eventually returning the resulting attributes. Each filtering
> step will operate on only the attributes extracted as a result of a particular query, and the filter policies can be
> expressed in terms of the actual "issuer" of each set of attributes for fine-grained control.

Thus, the SP cannot filter `local-login-user` based on attribute values obtained from either the user's primary
IdP or a virtual organization's attribute authority.

To get around this, the decision to release a value for `local-login-user` can be done at the resource AA. For this
to work, the resource AA has to be queried with the user's EPPN as well as any other attributes necessary for the
access control decision. Because the [SimpleAggregation AttributeResolver](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeResolver#NativeSPAttributeResolver-SimpleAggregationAttributeResolver(Version2.2andAbove))
can only pass one attribute value (the query identifier) to the attribute authority, the user's EPPN and the other
attributes must be first joined into a single attribute. The choice of method for encoding/decoding the attribute
values will affect both SP and resource AA configuration.

## Example

For this example, assume the SP queries a virtual organization's AA with an EPPN and a VO name. The VO's AA releases
an `isMemberOf` attribute with a boolean value indicating whether or not the user is a member of that VO. The SP
should allow access through `mech_saml_ec` if `isMemberOf` is true.

### SP Configuration

The SP needs to query the resource AA with the user's EPPN and the value of the `isMemberOf` attribute.

One way to join the attributes into a single attribute to use for the query is with a Template Attribute Resolver.
From its documentation:

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

<AttributeResolver type="Template" sources="eppn isMemberOf" dest="eppnAndMembership">
   <Template>$eppn:$isMemberOf</Template>
</AttributeResolver>

<AttributeResolver type="SimpleAggregation" attributeId="eppnAndMembership" format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">
   <Entity>https://aa.resourceprovider.com/idp/shibboleth</Entity>
   <MetadataProvider type="XML" validate="true" path="/path/to/resource-aa-metadata.xml" />
</AttributeResolver>

...
```

### Attribute Authority Configuration

At the resource's attribute authority, this joined attribute needs to be split up again. This can be done using a
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
   <Attribute id="isAllowed">
      <Value>placeholder</Value>
   </Attribute>
</resolver:DataConnector>

<!-- Extract EPPN from attribute query -->
<resolver:AttributeDefinition id="eppn" xsi:type="ad:Script">
   <resolver:Dependency ref="scriptAttrCreation" />
   <ad:Script>
      <![CDATA[
         eppn.getValues().clear();
         eppn.getValues().add(requestContext.principalName.split(":")[0]);
      ]]>
   </ad:Script>
</resolver:AttributeDefinition>

<!-- Extract isAllowed from attribute query -->
<resolver:AttributeDefinition id="isAllowed" xsi:type="ad:Script">
   <resolver:Dependency ref="scriptAttrCreation" />
   <ad:Script>
      <![CDATA[
         isAllowed.getValues().clear();
         isAllowed.getValues().add(requestContext.principalName.split(":")[1]);
      ]]>
   </ad:Script>
</resolver:AttributeDefinition>

...
```

Now that the user's EPPN and whether or not they are allowed access are determined, those attributes can be used
in an [attribute filter](https://wiki.shibboleth.net/confluence/display/IDP30/AttributeFilterConfiguration) to
clear the value of `local-login-user` if `isAllowed` is not true. For example:

`$IDP_HOME/conf/attribute-filter.xml`
```xml
<afp:AttributeFilterPolicyGroup ...>
   ...

   <!-- Permit local-login-user is isAllowed is true -->
   <afp:AttributeFilterPolicy>
      <afp:PolicyRequirementRule xsi:type="basic:AttributeValueString" attributeID="isAllowed" value="true" />
      <afp:AttributeRule attributeID="local-login-user">
         <afp:PermitValueRule xsi:type="basic:ANY" />
      </afp:AttributeRule>
   </afp:AttributeFilterPolicy>

    <!-- Deny if false-->
   <afp:AttributeFilterPolicy>
      <afp:PolicyRequirementRule xsi:type="basic:AttributeValueString" attributeID="isAllowed" value="false" />
      <afp:AttributeRule attributeID="local-login-user">
         <afp:DenyValueRule xsi:type="basic:ANY" />
      </afp:AttributeRule>
   </afp:AttributeFilterPolicy>

   ...
</afp:AttributeFilterPolicyGroup>
```

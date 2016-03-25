# VO Attribute Authority returns list of a user's VOs

In this case, the resource provider's SP queries a VO AA for the full list of VOs of
which a user (identified by an EPPN) is a member. The SP then makes the decision
to allow/reject access based on that list.

For this example, assume the AA returns the list in an attribute named `vo-memberships`.

## SP Configuration

For this example, we want to allow the user to login with the ECP SSH if the VO
attribute authority says they are a member of either the group `AllowedUsers` or
`AllowedUsers2`. Since rejecting access in the ECP SSH server is accomplished by
not releasing the `local-login-user` attribute, an
[attribute filter](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeFilter)
can be used to reject users not in one of the allowed groups.

It's safest to reject a user if they are not a member of any allowed group rather
than permitting them if they are a member of some allowed group. Since Deny rules
override Permit rules, this prevents the release of `local-login-user` from
accidentally being permitted by another policy.

`/etc/shibboleth/attribute-policy.xml`

```xml
<afp:AttributeFilterPolicyGroup ...>
    ...

    <!-- Normally permit local-login-user -->
    <afp:AttributeFilterPolicy>
        <afp:PolicyRequirementRule xsi:type="ANY" />
        <afp:AttributeRule attributeID="local-login-user">
            <afp:PermitValueRule xsi:type="ANY" />
        </afp:AttributeRule>
      </afp:AttributeFilterPolicy>

    <afp:AttributeFilterPolicy>
        <!-- Enforce this policy if vo-memberships does not contain "AllowedUsers" -->
        <afp:PolicyRequirementRule xsi:type="AND">
            <Rule xsi:type="NOT">
                <Rule xsi:type="AttributeValueString" attributeID="vo-memberships" value="AllowedUsers" />
            </Rule>
            <Rule xsi:type="NOT">
                <Rule xsi:type="AttributeValueString" attributeID="vo-memberships" value="AllowedUsers2" />
            </Rule>
        </afp:PolicyRequirementRule>

        <!-- Filter out local-login-user -->
        <afp:AttributeRule attributeID="local-login-user">
            <afp:DenyValueRule xsi:type="ANY" />
        </afp:AttributeRule>
    </afp:AttributeFilterPolicy>

    ...
</afp:AttributeFilterPolicyGroup>
```

#!/bin/bash

set -e
set -x

# Install Apache and PHP
yum install -y httpd mod_ssl php

# Add Shibboleth repo
curl "http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo" > /etc/yum.repos.d/shibboleth.repo

# Install Shibboleth
yum install -y shibboleth

# Disable SELinux
sed -i -e 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

# Set entityID
sed -i "s/\(<ApplicationDefaults entityID=\)\"[^\"]*\"/\1\"https:\/\/$(hostname)\/shibboleth\"/" /etc/shibboleth/shibboleth2.xml

# Set handlerSSL="true" and cookieProps="https"
sed -i 's/handlerSSL="false"/handlerSSL="true"/' /etc/shibboleth/shibboleth2.xml
sed -i 's/cookieProps="http"/cookieProps="https"/' /etc/shibboleth/shibboleth2.xml

# Start Shibboleth and Apache services on boot
systemctl enable shibd
systemctl enable httpd

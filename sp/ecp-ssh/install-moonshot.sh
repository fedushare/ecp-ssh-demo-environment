#!/bin/bash

set -e
set -x

# Install Moonshot Identity Selector
# https://wiki.moonshot.ja.net/pages/viewpage.action?pageId=6881344

yum install -y epel-release

cat <<EOF > /etc/yum.repos.d/moonshot.repo
[Moonshot]
name=Moonshot
baseurl=http://repository.project-moonshot.org/rpms/centos7/
failovermethod=priority
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/Moonshot

EOF

wget -O "/etc/pki/rpm-gpg/Moonshot" "http://repository.project-moonshot.org/rpms/centos7/moonshot.key"

yum install -y moonshot-ui moonshot-ui-devel

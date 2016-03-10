#!/bin/bash

set -e
set -x

# https://www.linode.com/docs/databases/mysql/how-to-install-mysql-on-centos-7

# Add MySQL community repository
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum -y update


# Install MySQL
yum -y install mysql-server
systemctl start mysqld

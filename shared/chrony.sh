#!/bin/bash

set -e
set -x

yum install -y chrony
systemctl enable chronyd
systemctl start chronyd

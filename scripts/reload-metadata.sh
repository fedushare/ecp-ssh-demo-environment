#!/bin/bash

set -e
set -x

curl -k "https://idp.vagrant.test/idp/profile/admin/reload-metadata?id=SPMetadata"
curl -k "https://aa.vagrant.test/idp/profile/admin/reload-metadata?id=SPMetadata"

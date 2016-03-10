#!/bin/bash

set -e
set -x

# Allow .htaccess overrides in /var/www/html
python <<EOF
import re
with open("/etc/httpd/conf/httpd.conf", "r+") as f:
    contents = f.read()
    new_contents = re.sub("(<Directory \"/var/www/html\".+?)AllowOverride None", "\g<1>AllowOverride All", contents, flags=re.I|re.M|re.S)
    f.seek(0)
    f.write(new_contents)
    f.truncate()
    print new_contents
EOF

# Place test files in web root
mkdir -p /var/www/html/protected

cat <<EOF > /var/www/html/protected/index.php
<?php phpinfo(); ?>
EOF

cat <<EOF > /var/www/html/protected/.htaccess
AuthType shibboleth
ShibRequireSession On
require valid-user
EOF

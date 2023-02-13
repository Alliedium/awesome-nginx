#!/bin/sh
cp ./ssl.conf.template ./ssl.conf
cat <<EOF >> ssl.conf

[alt_names]
DNS.1 = $COMMON_NAME
EOF

#!/bin/sh
BASEDIR=$(dirname "$0")
cp $BASEDIR/ssl.conf.template $BASEDIR/ssl.conf
cat <<EOF >> $BASEDIR/ssl.conf

[alt_names]
DNS.1 = $1
EOF

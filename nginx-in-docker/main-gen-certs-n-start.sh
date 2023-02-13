#!/bin/sh
set -e
BASEDIR=$(dirname "$0")
$BASEDIR/main-gen-certs.sh $1
nginx -g 'daemon off;'

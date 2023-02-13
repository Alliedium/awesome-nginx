#!/bin/sh
set -e
BASEDIR=$(dirname "$0")
$BASEDIR/main_gen_certs.sh $1
nginx -g 'daemon off;'

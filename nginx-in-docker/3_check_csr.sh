#!/bin/sh
BASEDIR=$(dirname "$0")
openssl req -text -noout -in $BASEDIR/private.csr

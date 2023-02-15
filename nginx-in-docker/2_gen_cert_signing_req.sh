#!/bin/sh
BASEDIR=$(dirname "$0")
openssl req -new -sha256 \
    -out $BASEDIR/private.csr \
    -key $BASEDIR/private.key \
    -config $BASEDIR/ssl.conf \
    -batch  # feel free to remove -batch to enable an interactive mode

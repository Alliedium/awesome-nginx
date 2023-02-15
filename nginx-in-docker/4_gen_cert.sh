#!/bin/sh
BASEDIR=$(dirname "$0")
openssl x509 -req \
    -days 3650 \
    -in $BASEDIR/private.csr \
    -signkey $BASEDIR/private.key \
    -out $BASEDIR/public.crt \
    -extensions req_ext \
    -extfile $BASEDIR/ssl.conf

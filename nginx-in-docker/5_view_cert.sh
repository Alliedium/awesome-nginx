#!/bin/sh
BASEDIR=$(dirname "$0")
openssl x509 -in $BASEDIR/public.crt --text

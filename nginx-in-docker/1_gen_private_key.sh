#!/bin/sh
BASEDIR=$(dirname "$0")
openssl genrsa -out $BASEDIR/private.key 4096
# this command prints e is ...
# see https://stackoverflow.com/questions/10736382/what-does-e-is-65537-0x10001-mean for details

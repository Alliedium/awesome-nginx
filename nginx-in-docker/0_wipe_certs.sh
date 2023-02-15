#!/bin/sh
set -e
BASEDIR=$(dirname "$0")
rm $BASEDIR/private.key || true
rm $BASEDIR/private.csr || true
rm $BASEDIR/public.crt || true

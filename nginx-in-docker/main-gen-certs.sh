#!/bin/sh
set -e
BASEDIR=$(dirname "$0")
$BASEDIR/00_gen-ssl-conf.sh "$1"
$BASEDIR/0_wipe_certs.sh
$BASEDIR/1_gen_private_key.sh
$BASEDIR/2_gen_cert_signing_req.sh
$BASEDIR/3_check_csr.sh
$BASEDIR/4_gen_cert.sh

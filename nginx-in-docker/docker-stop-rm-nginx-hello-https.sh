#!/bin/sh
set -e
BASEDIR=$(dirname "$0")
$BASEDIR/docker-stop-rm.sh "alliedium/nginx-hello-https:0.1"


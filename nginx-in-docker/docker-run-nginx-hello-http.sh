#!/bin/sh
if [[ -z "$1" ]] ; then
    echo "Container name is expected as the first argument"
    exit 1
fi
IMAGE_NAME="nginxdemos/hello"
BASEDIR=$(dirname "$0")
$BASEDIR/docker-run-nginx-hello.sh $IMAGE_NAME $1

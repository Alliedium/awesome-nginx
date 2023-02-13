#!/bin/sh 
BASEDIR=$(dirname "$0")
IMAGE_NAME="alliedium/nginx-hello-https:0.1"
docker build $BASEDIR -t $IMAGE_NAME

#!/bin/sh
set -e
if [[ -z "$1" ]] ; then
    echo "Image name is expected as the first argument"
    exit 1
fi

if [[ -z "$2" ]] ; then
    echo "Container name is expected as the second argument"
    exit 1
fi
image_name=$1
host_name="$(hostname -s)"
container_name="$2"
DOMAIN_NAME="intranet"
common_name=$container_name.$host_name.$DOMAIN_NAME
docker run -d --name "$container_name" \
	--hostname "$container_name" \
        -e "COMMON_NAME=$common_name" \
        "$image_name"

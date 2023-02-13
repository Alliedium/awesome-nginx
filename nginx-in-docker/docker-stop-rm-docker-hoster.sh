#!/bin/sh
set -e
BASEDIR=$(dirname "$0")
$BASEDIR/docker-stop-rm.sh "dvdarias/docker-hoster"


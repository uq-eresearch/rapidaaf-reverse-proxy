#!/bin/sh

set -ex

echo "listen $LISTEN_HOST:$LISTEN_PORT;" \
  > /dev/shm/nginx_listen.conf

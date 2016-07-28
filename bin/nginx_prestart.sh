#!/bin/sh

set -ex

echo "listen $DIT4C_INSTANCE_HELPER_AUTH_HOST:$DIT4C_INSTANCE_HELPER_AUTH_PORT;" \
  > /dev/shm/nginx_listen.conf

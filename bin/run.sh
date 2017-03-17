#!/bin/sh

set -ex

# Import any extra environment we might need
if [[ -f /dit4c/env.sh ]]; then
  set -a
  source /dit4c/env.sh
  set +a
fi

if [[ "$LISTEN_HOST" == "" ]]; then
  echo "Must specify LISTEN_HOST to listen on"
  exit 1
fi

if [[ "$LISTEN_PORT" == "" ]]; then
  echo "Must specify LISTEN_PORT to listen on"
  exit 1
fi

if [[ "$UPSTREAM_HOST" == "" ]]; then
  echo "Must specify UPSTREAM_HOST for authorized traffic"
  exit 1
fi

if [[ "$UPSTREAM_PORT" == "" ]]; then
  echo "Must specify UPSTREAM_PORT for authorized traffic"
  exit 1
fi

/opt/bin/nginx_prestart.sh

exec /usr/local/openresty/nginx/sbin/nginx -c /etc/nginx/nginx.conf

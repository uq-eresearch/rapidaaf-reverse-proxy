#!/bin/sh

set -ex

# Import any extra environment we might need
if [[ -f /dit4c/env.sh ]]; then
  set -a
  source /dit4c/env.sh
  set +a
fi

if [[ "$DIT4C_INSTANCE_HELPER_AUTH_HOST" == "" ]]; then
  echo "Must specify DIT4C_INSTANCE_HELPER_AUTH_HOST to listen on"
  exit 1
fi

if [[ "$DIT4C_INSTANCE_HELPER_AUTH_PORT" == "" ]]; then
  echo "Must specify DIT4C_INSTANCE_HELPER_AUTH_PORT to listen on"
  exit 1
fi

if [[ "$DIT4C_INSTANCE_HTTP_PORT" == "" ]]; then
  echo "Must specify DIT4C_INSTANCE_HTTP_PORT to expose"
  exit 1
fi

if [[ ! -f "$DIT4C_INSTANCE_PRIVATE_KEY" ]]; then
  echo "Unable to find DIT4C_INSTANCE_PRIVATE_KEY: $DIT4C_INSTANCE_PRIVATE_KEY"
  exit 1
fi

if [[ "$DIT4C_INSTANCE_JWT_ISS" == "" ]]; then
  echo "Must specify DIT4C_INSTANCE_JWT_ISS for JWT auth token"
  exit 1
fi

if [[ "$DIT4C_INSTANCE_JWT_KID" == "" ]]; then
  echo "Must specify DIT4C_INSTANCE_JWT_KID for JWT auth token"
  exit 1
fi

if [[ "$DIT4C_INSTANCE_OAUTH_AUTHORIZE_URL" == "" ]]; then
  echo "Must specify DIT4C_INSTANCE_OAUTH_AUTHORIZE_URL for OAuth calls"
  exit 1
fi

if [[ "$DIT4C_INSTANCE_OAUTH_ACCESS_TOKEN_URL" == "" ]]; then
  echo "Must specify DIT4C_INSTANCE_OAUTH_ACCESS_TOKEN_URL for OAuth calls"
  exit 1
fi

export CLIENT_ID=$DIT4C_INSTANCE_JWT_ISS
export CLIENT_SECRET=$(jwt -k $DIT4C_INSTANCE_PRIVATE_KEY \
    -alg RS512 \
    -enc \
    iss=$DIT4C_INSTANCE_JWT_ISS \
    kid=$DIT4C_INSTANCE_JWT_KID)

/opt/bin/nginx_prestart.sh

exec /usr/local/openresty/nginx/sbin/nginx -c /etc/nginx/nginx.conf

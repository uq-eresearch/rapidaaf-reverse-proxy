#!/usr/bin/env bats

IMAGE="$BATS_TEST_DIRNAME/../dist/dit4c-helper-auth-portal.linux.amd64.aci"
RKT_DIR="$BATS_TMPDIR/rkt-env"
RKT_STAGE1="$BATS_TEST_DIRNAME/../build/rkt/stage1-coreos.aci"
RKT="$BATS_TEST_DIRNAME/../build/rkt/rkt --dir=$RKT_DIR"

teardown() {
  sudo $RKT gc --grace-period=0s
}

@test "has valid nginx config after running /opt/bin/nginx_prestart.sh" {
  run sudo $RKT run --insecure-options=image --stage1-path=$RKT_STAGE1 \
    $IMAGE \
    --set-env DIT4C_INSTANCE_HELPER_AUTH_HOST=127.1.1.1 \
    --set-env DIT4C_INSTANCE_HELPER_AUTH_PORT=8081 \
    --exec /bin/sh -- -c "/opt/bin/nginx_prestart.sh && /usr/local/openresty/nginx/sbin/nginx -t -c /etc/nginx/nginx.conf"
  echo $output
  [ "$status" -eq 0 ]
}

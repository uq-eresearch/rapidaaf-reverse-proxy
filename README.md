# rapidaaf-reverse-proxy

[![Build Status](https://travis-ci.org/uq-eresearch/rapidaaf-reverse-proxy.svg?branch=master)](https://travis-ci.org/uq-eresearch/rapidaaf-reverse-proxy)

Container image for authenticating HTTP traffic via RapidAAF & reverse proxying. After authenticating, it sets `X-Remote-User` with the username, and adds a HTTP Basic `Authorization` header with the username and a blank password.

It is intended to be used behind TLS, and in front of whatever is making authorization decisions:

```
         +-----------------+        +------------------------+        +-----+
--HTTPS->| TLS Termination |--HTTP->| rapidaaf reverse proxy |--HTTP->| app |
         +-----------------+        +------------------------+        +-----+
```

## Docker

```
sudo docker run -p 9000:8080 \
  -e COOKIE_DOMAIN=mydomain.com \
  -e USERNAME_ATTRIBUTE="edupersonprincipalname" \
  -e UPSTREAM_HOST=172.17.0.1 \
  -e UPSTREAM_PORT=1313 \
  -e RAPIDAAF_SECRET=ImF1ZCI6Imh0d \
  -e RAPIDAAF_URL="https://rapid.test.aaf.edu.au/jwt/authnrequest/research/jR0RUVWWEpKWjNZeVhreF-jwiQ" \
  rapidaaf-reverse-proxy
```

## rkt
```
sudo rkt run --insecure-options image ./dist/rapidaaf-reverse-proxy.linux.amd64.aci \
  --port 8080-tcp:9000 \
  --set-env COOKIE_DOMAIN=mydomain.com \
  --set-env USERNAME_ATTRIBUTE="edupersonprincipalname" \
  --set-env UPSTREAM_HOST=172.16.28.1 \
  --set-env UPSTREAM_PORT=1313 \
  --set-env RAPIDAAF_SECRET=ImF1ZCI6Imh0d \
  --set-env RAPIDAAF_URL="https://rapid.test.aaf.edu.au/jwt/authnrequest/research/jR0RUVWWEpKWjNZeVhreF-jwiQ"
```

# password-reverse-proxy

[![Build Status](https://travis-ci.org/dit4c/password-reverse-proxy.svg?branch=master)](https://travis-ci.org/dit4c/password-reverse-proxy)

Container image for password-protecting HTTP traffic via reverse proxying.

It is extremely minimal, taking a simple static password.

```
sudo rkt run --insecure-options image ./dist/password-reverse-proxy.linux.amd64.aci \
  --set-env LISTEN_HOST=0.0.0.0
  --set-env LISTEN_PORT=8080
  --set-env TARGET_HOST=127.0.0.1
  --set-env TARGET_PORT=1313
  --set-env PASSWORD_SECRET=mypass
```

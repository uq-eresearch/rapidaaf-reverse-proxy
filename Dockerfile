FROM openresty/openresty:latest-alpine

ENV COOKIE_DOMAIN="" USERNAME_ATTRIBUTE="mail" \
  UPSTREAM_HOST="" UPSTREAM_PORT="" \
  RAPIDAAF_SECRET="" RAPIDAAF_URL=""
RUN apk update && apk add perl curl && \
  PATH=/usr/local/openresty/bin:$PATH opm get SkyLothar/lua-resty-jwt && \
  apk del perl curl
COPY etc/nginx /etc/nginx

EXPOSE 8080
CMD ["-c", "/etc/nginx/nginx.conf"]

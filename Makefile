.DEFAULT_GOAL := dist/SHA512SUM
.PHONY: clean test

ACBUILD_VERSION=0.3.1
ACBUILD=build/acbuild
DOCKER2ACI_VERSION=0.12.0
RKT_VERSION=1.11.0

dist/SHA512SUM: dist/dit4c-helper-auth-portal.linux.amd64.aci
	sha512sum $^ | sed -e 's/dist\///' > dist/SHA512SUM

dist/dit4c-helper-auth-portal.linux.amd64.aci: build/acbuild build/openresty-openresty-latest-alpine.aci build/jwt bin/* etc/* | dist
	rm -rf .acbuild
	$(ACBUILD) --debug begin ./build/openresty-openresty-latest-alpine.aci
	$(ACBUILD) copy etc/nginx /etc/nginx
	$(ACBUILD) copy build/jwt /usr/bin/jwt
	$(ACBUILD) environment add DIT4C_INSTANCE_PRIVATE_KEY ""
	$(ACBUILD) environment add DIT4C_INSTANCE_JWT_KID ""
	$(ACBUILD) environment add DIT4C_INSTANCE_JWT_ISS ""
	$(ACBUILD) environment add DIT4C_INSTANCE_HELPER_AUTH_HOST ""
	$(ACBUILD) environment add DIT4C_INSTANCE_HELPER_AUTH_PORT ""
	$(ACBUILD) environment add DIT4C_INSTANCE_HTTP_PORT ""
	$(ACBUILD) environment add DIT4C_INSTANCE_OAUTH_AUTHORIZE_URL ""
	$(ACBUILD) environment add DIT4C_INSTANCE_OAUTH_ACCESS_TOKEN_URL ""
	$(ACBUILD) copy bin /opt/bin
	$(ACBUILD) set-name dit4c-helper-auth-portal
	$(ACBUILD) set-exec -- /opt/bin/run.sh
	$(ACBUILD) write --overwrite dist/dit4c-helper-auth-portal.linux.amd64.aci
	$(ACBUILD) end

dist:
	mkdir -p dist

build:
	mkdir -p build

build/jwt: | build/rkt
	sudo -v && sudo build/rkt/rkt run --dns=8.8.8.8 --insecure-options=image \
	  --volume output-dir,kind=host,source=`pwd`/build \
	  docker://golang:alpine \
	  --set-env CGO_ENABLED=0 \
	  --set-env GOOS=linux \
	  --mount volume=output-dir,target=/output \
	  --exec /bin/sh --  -c "apk add --update git && /usr/local/go/bin/go get -v --ldflags '-extldflags \"-static\"' github.com/knq/jwt/cmd/jwt && install -t /output -o $(shell id -u) -g $(shell id -g) /go/bin/jwt"

build/openresty-openresty-latest-alpine.aci: build/docker2aci
	cd build && ./docker2aci docker://openresty/openresty:latest-alpine

$(ACBUILD): | build
	curl -sL https://github.com/appc/acbuild/releases/download/v${ACBUILD_VERSION}/acbuild-v${ACBUILD_VERSION}.tar.gz | tar xz -C build
	mv build/acbuild-v${ACBUILD_VERSION}/acbuild build/acbuild
	-rm -rf build/acbuild-v${ACBUILD_VERSION}

build/docker2aci: | build
	curl -sL https://github.com/appc/docker2aci/releases/download/v${DOCKER2ACI_VERSION}/docker2aci-v${DOCKER2ACI_VERSION}.tar.gz | tar xvz -C build
	mv build/docker2aci-v${DOCKER2ACI_VERSION}/docker2aci build/docker2aci
	rm -rf build/docker2aci-v${DOCKER2ACI_VERSION}

build/bats: | build
	curl -sL https://github.com/sstephenson/bats/archive/master.zip > build/bats.zip
	unzip -d build build/bats.zip
	mv build/bats-master build/bats
	rm build/bats.zip

build/rkt: | build
	curl -sL https://github.com/coreos/rkt/releases/download/v${RKT_VERSION}/rkt-v${RKT_VERSION}.tar.gz | tar xz -C build
	mv build/rkt-v${RKT_VERSION} build/rkt

test: build/bats build/rkt dist/dit4c-helper-auth-portal.linux.amd64.aci
	sudo -v && echo "" && build/bats/bin/bats --pretty test

clean:
	-rm -rf build .acbuild dist

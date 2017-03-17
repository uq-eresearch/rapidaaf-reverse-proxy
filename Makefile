NAME=password-reverse-proxy
IMAGE=dist/$(NAME).linux.amd64.aci

.DEFAULT_GOAL := $(IMAGE)
.PHONY: clean test deploy

GPG=gpg2

ACBUILD_VERSION=0.4.0
ACBUILD=build/acbuild
DOCKER2ACI_VERSION=0.16.0
RKT_VERSION=1.25.0

deploy: $(IMAGE) $(IMAGE).asc

dist/%.aci.asc: dist/%.aci signing.key
	$(eval TMP_PUBLIC_KEYRING := $(shell mktemp -p ./build))
	$(eval TMP_SECRET_KEYRING := $(shell mktemp -p ./build))
	$(eval GPG_FLAGS := --batch --no-default-keyring --keyring $(TMP_PUBLIC_KEYRING) --secret-keyring $(TMP_SECRET_KEYRING) )
	$(GPG) $(GPG_FLAGS) --import signing.key
	rm -f $@
	$(GPG) $(GPG_FLAGS) --armour --detach-sign $<
	rm $(TMP_PUBLIC_KEYRING) $(TMP_SECRET_KEYRING)

$(IMAGE): build/acbuild build/openresty-openresty-latest-alpine.aci bin/* $(shell find etc -type f) | dist
	rm -rf .acbuild
	$(ACBUILD) --debug begin ./build/openresty-openresty-latest-alpine.aci
	$(ACBUILD) copy etc/nginx /etc/nginx
	$(ACBUILD) environment add LISTEN_HOST ""
	$(ACBUILD) environment add LISTEN_PORT ""
	$(ACBUILD) environment add TARGET_HOST ""
	$(ACBUILD) environment add TARGET_PORT ""
	$(ACBUILD) environment add PASSWORD_SECRET ""
	$(ACBUILD) copy bin /opt/bin
	$(ACBUILD) set-name $(NAME)
	$(ACBUILD) set-exec -- /opt/bin/run.sh
	$(ACBUILD) write --overwrite $@
	$(ACBUILD) end

dist:
	mkdir -p dist

build:
	mkdir -p build

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

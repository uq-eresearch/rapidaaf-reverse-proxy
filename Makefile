NAME=rapidaaf-reverse-proxy
DOCKER_IMAGE_FILE=dist/$(NAME).docker
ACI_IMAGE_FILE=dist/$(NAME).linux.amd64.aci

.DEFAULT_GOAL := $(IMAGE)
.PHONY: clean test deploy

GPG=gpg2

ACBUILD_VERSION=0.4.0
ACBUILD=build/acbuild
DOCKER2ACI_VERSION=0.16.0
RKT_VERSION=1.25.0

deploy: $(DOCKER_IMAGE_FILE).xz $(ACI_IMAGE_FILE)

$(DOCKER_IMAGE_FILE).xz: $(DOCKER_IMAGE_FILE)
	xz -k $(DOCKER_IMAGE_FILE)

$(DOCKER_IMAGE_FILE): build/acbuild $(shell find etc -type f) | dist
	sudo docker build -t $(NAME) .
	sudo docker save $(NAME) | cat > $(DOCKER_IMAGE_FILE)

$(ACI_IMAGE_FILE): $(DOCKER_IMAGE_FILE) build/docker2aci $(ACBUILD)
	sudo rm -rf ./build/library-password-reverse-proxy-latest-alpine.aci .acbuild
	(cd build && ./docker2aci ../$(DOCKER_IMAGE_FILE))
	sudo $(ACBUILD) --debug begin ./build/library-$(NAME)-latest.aci
	sudo $(ACBUILD) set-name $(NAME)
	sudo $(ACBUILD) label add version latest
	sudo $(ACBUILD) port add http tcp 8080
	sudo $(ACBUILD) write --overwrite $@
	sudo $(ACBUILD) end

dist:
	mkdir -p dist

build:
	mkdir -p build

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

test: build/bats build/rkt $(ACI_IMAGE_FILE)
	sudo -v && echo "" && build/bats/bin/bats --pretty test

clean:
	-rm -rf build .acbuild dist

# Change these in your parent Makefile if desired
TF_BUILD_HARNESS_IMAGE ?= quay.io/pennstate/tf-build-harness:latest
AWS_DEFAULT_REGION ?= us-east-1
TERRATEST_TIMEOUT ?= 10m

# Do not edit below this line

TERRAFORM := /usr/local/bin/terraform
BUILD_CACHE ?= $(shell pwd)/.build-cache
DOCKER_UID ?= $(shell id -u)
TF_BUILD_HARNESS_PATH ?= /tf-build-harness

PWD := $(shell pwd)
PROJECT := $(shell basename $PWD)
DOCKER = echo "=== Running in docker container $(TF_BUILD_HARNESS_IMAGE)"; \
	docker run --rm -it \
	-w /workdir/src/$(PROJECT) \
	-v $(PWD):/workdir/src/$(PROJECT) \
	-v $(BUILD_CACHE):/cache \
	-v $(HOME)/.ssh:/home/tfbuild/$(DOCKER_USER)/.ssh \
	-e DOCKER_UID=$(DOCKER_UID) \
	-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	-e AWS_REGION=$(AWS_DEFAULT_REGION) \
	-e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
	-e AWS_SESSION_TOKEN=$(AWS_SESSION_TOKEN) \
	-e AWS_SECURITY_TOKEN=$(AWS_SECURITY_TOKEN) \
	-e BUNDLE_PATH=/cache/bundle \
	-e BUNDLE_USER_CACHE=/cache/bundle-cache \
	-e TF_PLUGIN_CACHE_DIR=/cache/terraform/plugin-cache \
	-e BUNDLE_SILENCE_ROOT_WARNING=1 \
	$(TF_BUILD_HARNESS_IMAGE) 

DOCKER_TARGETS := docs test lint get validate kitchen-test kitchen-destroy terratest
.PHONY: $(DOCKER_TARGETS)

.PHONY: help
help:
	@echo Available targets:
	@for t in $(DOCKER_TARGETS) clean; do echo -e \\t$$t ; done ;

.PHONY: .adduser
.adduser:
	@adduser -D -u $(DOCKER_UID) tfbuild

.PHONY: .lint 
.lint:
	$(TERRAFORM) fmt -write=false -check=true -recursive

.PHONY: .validate
.validate: .get
	$(TERRAFORM) validate

.PHONY: .get
.get:
	$(TERRAFORM) init -get-plugins -backend=false -input=false >/dev/null
	$(TERRAFORM) init -get -backend=false -input=false >/dev/null

.PHONY: .kitchen-test
.kitchen-test:
ifeq (,$(wildcard .kitchen.yml))
	@echo "No .kitchen.yml, skipping kitchen-terraform tests";
else
	bundle install >/dev/null
	bundle exec kitchen test || ( cat .kitchen/logs/*.log ; ret=$$? ; $(MAKE) .kitchen-destroy ; exit $$ret)
endif

.PHONY: .kitchen-destroy
.kitchen-destroy:
ifeq (,$(wildcard .kitchen.yml))
	@echo "No .kitchen.yml, skipping kitchen-terraform tests"
else
	bundle install >/dev/null
	bundle exec kitchen destroy
endif

.PHONY: .terratest
.terratest:
ifeq (,$(wildcard test/*.go))
	@echo "No terratest tests, skipping terratest"
else
	cd test
	go test -count=1 -timeout=$(TERRATEST_TIMEOUT)
endif

.PHONY: clean
clean:
	rm -rf .build-cache .terraform .kitchen terraform.tfstate.d .tf-build-harness.mk

.PHONY: .test
.test: .kitchen-test .terratest

.PHONY: .docs
.docs:
ifeq (,$(wildcard README.header.md))
	rm -f README.md
else
	cat README.header.md > README.md
endif
	terraform-docs . >> README.md
	cat README.md


$(DOCKER_TARGETS):
ifdef CI
	@echo "=== Running in CI environment, running targets without docker"
	$(MAKE) .$@
else
	mkdir -p $(BUILD_CACHE)
	@$(DOCKER) sh -c "$(MAKE) .adduser && su tfbuild -c '$(MAKE) .$@'"
endif

# vim: syntax=make

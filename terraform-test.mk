# Change these in your parent Makefile if desired
TERRAFORM_TEST ?= acobaugh/terraform-test:latest
AWS_DEFAULT_REGION ?= us-east-1

# Do not edit below this line

TERRAFORM := /usr/local/bin/terraform
BUILD_CACHE ?= $(shell pwd)/.build-cache
DOCKER_USER ?= $(shell id -u)

DOCKER = echo "=== Running in docker container $(TERRAFORM_TEST)"; \
	docker run --rm -it -u $(DOCKER_USER)\
	-w /workdir \
	-v $(shell pwd):/workdir \
	-v $(BUILD_CACHE):/cache \
	-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	-e AWS_REGION=$(AWS_DEFAULT_REGION) \
	-e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
	-e BUNDLE_PATH=/cache/bundle \
	-e BUNDLE_USER_CACHE=/cache/bundle-cache \
	-e TF_PLUGIN_CACHE_DIR=/cache/terraform/plugin-cache \
	-e BUNDLE_SILENCE_ROOT_WARNING=1 \
	$(TERRAFORM_TEST) 

DOCKER_TARGETS := test test-all lint get validate kitchen-test kitchen-destroy bundle-install
.PHONY: $(DOCKER_TARGETS)

.PHONY: help
help:
	@echo Available targets:
	@for t in $(DOCKER_TARGETS) clean; do echo -e \\t$$t ; done ;

.PHONY: .lint 
.lint:
	$(TERRAFORM) fmt -write=false -check=true

.PHONY: .validate
.validate:
	$(TERRAFORM) validate -check-variables=false

.PHONY: .get
.get:
	$(TERRAFORM) init -get-plugins -backend=false -input=false >/dev/null
	$(TERRAFORM) init -get -backend=false -input=false >/dev/null

.PHONY: .bundle-install bundle-install
.bundle-install:
	bundle install

.PHONY: .kitchen-test kitchen-test
.kitchen-test: .lint .validate .bundle-install
	test -f .kitchen.yml || (echo "No .kitchen.yml, skipping kitchen-terraform tests" ; exit 0)
	bundle exec kitchen test || (ret=$$?; $(MAKE) .kitchen-destroy; exit $$ret)

.PHONY: .kitchen-destroy kitchen-destroy
.kitchen-destroy: .bundle-install
	bundle exec kitchen destroy

.PHONY: clean
clean:
	rm -rf .build-cache .terraform .kitchen terraform.tfstate.d .terraform-test.mk
	docker volume rm $(CACHE_VOLUME)

.PHONY: _test test
.test: .lint .validate .get

.PHONY: .test-all test-all
.test-all: .test .kitchen-test

$(DOCKER_TARGETS):
ifdef CI
	@echo "=== Running in CI environment, running targets without docker"
	$(MAKE) .$@
else
	mkdir -p $(BUILD_CACHE)
	@$(DOCKER) make .$@
endif

# vim: syntax=make

# Change these in your parent Makefile if desired
TERRAFORM_TEST ?= acobaugh/terraform-test:latest
AWS_DEFAULT_REGION ?= us-east-1

# Do not edit below this line
.PHONY: help .lint .validate .get .kitchen-verify .kitchen-destroy shell clean

TERRAFORM := /usr/local/bin/terraform
CACHE_VOLUME := terraform-test-cache

RUN = echo "=== Running in docker container $(TERRAFORM_TEST)"; \
	docker run --rm -it \
	-w /workdir \
	-v $(shell pwd):/workdir \
	-v $(CACHE_VOLUME):/cache \
	-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	-e AWS_REGION=$(AWS_DEFAULT_REGION) \
	-e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
	-e BUNDLE_PATH=/cache/bundle \
	-e BUNDLE_USER_CACHE=/cache/bundle-cache \
	-e TF_PLUGIN_CACHE_DIR=/cache/terraform/plugin-cache \
	-e BUNDLE_SILENCE_ROOT_WARNING=1 \
	$(TERRAFORM_TEST) 

INIT_CACHE = \
	docker volume ls | grep $(CACHE_VOLUME) >/dev/null || \
	docker volume create $(CACHE_VOLUME)

help:
	@echo Available targets:
	@for t in lint validate get kitchen-test kitchen-destroy clean shell; do echo -e \\t$$t ; done ;

.lint:
	$(TERRAFORM) fmt -write=false -check=true

.validate:
	$(TERRAFORM) validate -check-variables=false

.get:
	$(TERRAFORM) init -get-plugins -backend=false -input=false >/dev/null
	$(TERRAFORM) init -get -backend=false -input=false >/dev/null

.bundle-install:
	bundle install

.kitchen-test: .lint .validate .bundle-install
	env
	bundle exec kitchen test || (ret=$$?; $(MAKE) .kitchen-destroy; exit $$ret)

.kitchen-destroy: .bundle-install
	bundle exec kitchen destroy

shell:
	@$(INIT_CACHE)
	@$(RUN) bash

clean:
	rm -rf .terraform .kitchen terraform.tfstate.d .terraform-test.mk

%:
	@$(INIT_CACHE)
	@$(RUN) make .$@

# vim: syntax=make

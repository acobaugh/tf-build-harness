# terraform-test

This repo contains a GNU Makefile and Dockerfile. It is intended to enable
local development and CI tests of terraform modules using terraform,
kitchen-terraform, and terratest (comming soon!).

The Dockerfile builds an
[image](https://hub.docker.com/u/acobaugh/terraform-test) based on Alpine with
Ruby (via rbenv), Terraform, Golang, and a basic build environment.

The Makefile is more complicated. It has multiple hidden targets defined, which
are executed directly when running in a CI envionment under the
acobaugh/terraform-test:latest image, or via `docker run` when running locally.
See the output of `make help`

# Usage

At a minimum, copy the [Makefile.sample](/Makefile.sample) file to the root of
your project. This file retrieves and includes the upstream
[terraform-test.mk](/terraform-test.mk) file automatically via curl. You can
alter the values of `AWS_DEFAULT_REGION` and the docker image to run via
`TERRAFORM_TEST`.

## test

`make test` requires no further setup, just the sample `Makefile`.

## test-all

Today, `test-all` only runs kitchen-test.

## kitchen-test

`make kitchen-terraform` requires, at a minimum, a Gemfile (and Gemfile.lock
for consistent Gem versioning, this is usually built automatically by bundler),
`.kitchen.yml`, and a kitchen profile with controls. Examples of the
first two are below. The latter is described in more detail on the
[kitchen-terraform's website](https://github.com/newcontext-oss/kitchen-terraform).

### .kitchen.yml
```yml
---
driver:
  name: terraform
  root_module_directory: test/fixtures/tf_module

provisioner:
  name: terraform

verifier:
  name: terraform
  systems: 
    - name: default
      backend: aws

platforms:
  - name: terraform

suites:
  - name: default
```

### Gemfile
```Ruby
# frozen_string_literal: true

source "https://rubygems.org/" do
	gem "kitchen-terraform", "~> 4.0"
end
```

### Credentials

At present, creds to access AWS are pulled from the usual AWS CLI environment
variables. Tests will be run in `us-east-1`, so your fixtures should specify
`us-east-1` for the aws provider region.

## Make targets

* test: lint (fmt), validate, get
* test-all: all targets from test, plus kitchen-terraform (and soon, [terratest](https://github.com/gruntwork-io/terratest)) 
* Other targets are listed via `make help`

# Versions

* Terraform: 0.11.10
* Go: 1.11.2
* Ruby: 2.4.5

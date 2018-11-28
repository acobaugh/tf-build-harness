# stand on the shoulders of giants
-include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

TERRAFORM_TEST := acobaugh/terraform-test:latest

# wrapper that either calls docker run, or runs the command directly
define execute
	if [ -z "$(CI)" ] ; then \
		docker run --rm -it -w /workdir -v $(shell pwd):/workdir \
			-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
			-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
			$(TERRAFORM_TEST) \
			$(1); \
	else \
		echo $(1); \
		$(1); \
	fi;
endef

kitchen-test:

kitchen-destroy:

FROM alpine:3.8

ARG BUILD_DATE
ARG VCS_REF

ENV TERRAFORM_VERSION=0.11.11
ENV RUBY_VERSION=2.4.5
ENV TERRATEST_LOG_PARSER_VERSION=0.13.13

LABEL \
	org.label-schema.build-date="$BUILD_DATE" \
	org.label-schema.name="terraform-test:light" \
	org.label-schema.description="Terraform test light image" \
	org.label-schema.vcs-url="https://github.com/acobaugh/terraform-test" \
	org.label-schema.vcs-ref="$VCS_REF" \
	org.label-schema.terraform_version="$TERRAFORM_VERSION" \
	org.label-schema.ruby_version="$RUBY_VERSION" \
	org.label-schema.terratest_log_parser_version="$TERRATEST_LOG_PARSER_VERSION"


ENV TF_TEST_PATH=/terraform-test

RUN mkdir -p ${TF_TEST_PATH}
ADD bin ${TF_TEST_PATH}
RUN chmod +x ${TF_TEST_PATH}/bin/*
ENV PATH=${TF_TEST_PATH}/bin:$PATH

# update/upgrade and all other packages
RUN apk update \
 && apk upgrade \
 && apk add curl gnupg go git unzip bash libssl1.0 libcrypto1.0 libffi-dev build-base linux-headers zlib-dev openssl-dev readline-dev

# terraform
ADD pgp_keys.asc .
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
 && cat pgp_keys.asc | gpg --import \
 && curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig \
 && gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS \
 && sha256sum -c terraform_${TERRAFORM_VERSION}_SHA256SUMS 2>&1 | grep "${TERRAFORM_VERSION}_linux_amd64.zip:\sOK" \
 && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
 && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# gopath
ENV GOPATH $HOME/go

# rbenv
ENV PATH /usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH
ENV RBENV_ROOT /usr/local/rbenv
ENV RUBY_CONFIGURE_OPTS --disable-install-doc

RUN git clone https://github.com/rbenv/rbenv.git /usr/local/rbenv \
 && echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh \
 && mkdir -p "$(rbenv root)"/plugins \
 && git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

# ruby
RUN rbenv install ${RUBY_VERSION} \
 && rbenv rehash \
 && rbenv global ${RUBY_VERSION}

# bundler
RUN gem update --system && gem install --force bundler

# terratest_log_parser
RUN curl --location --silent --fail --show-error -o terratest_log_parser https://github.com/gruntwork-io/terratest/releases \
 && chmod +x terratest_log_parser \
 && mv terratest_log_parser /usr/local/bin

WORKDIR /work

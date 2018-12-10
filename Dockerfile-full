FROM alpine:3.8

ARG BUILD_DATE
ARG VCS_REF

LABEL \
	org.label-schema.build-date="$BUILD_DATE" \
	org.label-schema.name="terraform-test" \
	org.label-schema.description="Terraform test image with Go, Ruby, Terraform" \
	org.label-schema.vcs-url="https://github.com/acobaugh/terraform-test" \
	org.label-schema.vcs-ref="$VCS_REF"

ENV TERRAFORM_VERSION=0.11.10
ENV GOLANG_VERSION=1.11.2
ENV RUBY_VERSION=2.4.5

# packages
# -dev, lib*, build-base, bash, and linux-headers are needed for rbenv install
RUN apk add curl unzip gnupg git bash libssl1.0 libcrypto1.0 libffi-dev build-base linux-headers zlib-dev openssl-dev readline-dev

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

# go
RUN curl -Os https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-amd64.tar.gz >/dev/null 2>&1 \
    && tar -zxvf go${GOLANG_VERSION}.linux-amd64.tar.gz -C /usr/local/ >/dev/null \
    && rm -f go${GOLANG_VERSION}.linux-amd64.tar.gz
ENV PATH /usr/local/go/bin:$PATH
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

WORKDIR /work

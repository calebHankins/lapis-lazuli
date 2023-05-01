## Build Stage
ARG BUILDER_BASE_REGISTRY=docker.io
ARG BUILDER_BASE_IMAGE=alpine:latest
ARG BASE_REGISTRY=docker.io
ARG BASE_IMAGE=hashicorp/terraform:1.1.2
FROM $BUILDER_BASE_REGISTRY/$BUILDER_BASE_IMAGE AS builder
# FROM $BUILDER_BASE_IMAGE AS builder

# Install packages needed to fetch tools
RUN apk add --no-cache bash curl wget tar openssl jq unzip coreutils dos2unix

# Trust self-signed certs in the chain for schemastore.azurewebsites.net:443 for intellisense
# Comment this out for non-corporate envs where you might have MitM attacks from IP loss prevention software like Netskope
# @See: https://en.wikipedia.org/wiki/Netskope
# If you need this kind of mitigation at home on personal hardware, someone might be doing a legit MitM attack against you
# @see: https://en.wikipedia.org/wiki/Man-in-the-middle_attack
# Alpine version
RUN openssl s_client -showcerts  -connect schemastore.azurewebsites.net:443 2>&1 < /dev/null |\
  sed -n '/-----BEGIN/,/-----END/p' |\
  csplit - -z -b %02d.crt -f /usr/local/share/ca-certificates/schemastore.azurewebsites.net. '/-----BEGIN CERTIFICATE-----/' '{*}' \
  && chmod 644 /usr/local/share/ca-certificates/*.crt \
  && update-ca-certificates

# helm
ARG HELM_RELEASE=v3.5.2
ADD https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 /usr/local/bin/get_helm.sh
RUN chmod +x /usr/local/bin/get_helm.sh
RUN ./usr/local/bin/get_helm.sh --version $HELM_RELEASE && helm version

# kubectl (aws vended)
# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
ARG KUBECTL_RELEASE=https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
RUN curl --silent -o kubectl $KUBECTL_RELEASE
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl && kubectl version --client

# eksctl
# https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html
# ARG EKSCTL_RELEASE=hhttps://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz
ARG EKSCTL_RELEASE=https://github.com/weaveworks/eksctl/releases/download/v0.99.0/eksctl_Linux_amd64.tar.gz
RUN curl --silent --location "${EKSCTL_RELEASE}" | tar xz -C /tmp
RUN mv /tmp/eksctl /usr/local/bin && eksctl version

# EKS-vended aws-iam-authenticator
ARG AWS_IAM_AUTHENTICATOR_RELEASE=https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
RUN curl --silent -o aws-iam-authenticator "${AWS_IAM_AUTHENTICATOR_RELEASE}"
RUN chmod +x ./aws-iam-authenticator
RUN mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator && aws-iam-authenticator version

# terragrunt
ARG TERRAGRUNT_RELEASE=v0.28.7
COPY ./scripts/get_terragrunt.sh /usr/local/bin/get_terragrunt.sh
RUN dos2unix /usr/local/bin/get_terragrunt.sh \
    && chmod +x /usr/local/bin/get_terragrunt.sh \
    && ./usr/local/bin/get_terragrunt.sh \
    && terragrunt --version

# hclq (jq for hcl)
# https://hclq.sh/
# RUN curl -sSLo install.sh https://install.hclq.sh
# RUN sh install.sh

## Final Stage
FROM $BASE_REGISTRY/$BASE_IMAGE AS final

# Copy over certs from build stage and trust for the tools
COPY --from=builder /usr/local/share/ca-certificates /usr/local/share/ca-certificates
RUN update-ca-certificates
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# QoL and automation tooling
RUN apk add --no-cache \
  groff jq bash coreutils binutils curl wget unzip tar dos2unix \
  ansible nodejs npm \
  && ansible --version && node --version && npm --version

# helm
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
RUN chmod +x /usr/local/bin/helm
RUN helm repo add stable https://charts.helm.sh/stable && \
    helm repo update;

# kubectl
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# eksctl
COPY --from=builder /usr/local/bin/eksctl /usr/local/bin/eksctl
RUN chmod +x /usr/local/bin/eksctl

# aws-iam-authenticator
COPY --from=builder /usr/local/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
RUN chmod +x /usr/local/bin/aws-iam-authenticator

# terragrunt
COPY --from=builder /usr/local/bin/terragrunt /usr/local/bin/terragrunt
RUN chmod +x /usr/local/bin/terragrunt

# hclq (jq for hcl)
# COPY --from=builder /usr/local/bin/hclq /usr/local/bin/hclq
# RUN chmod +x /usr/local/bin/hclq

# aws-cli 2 (also needs glibc on alpine)
# @see: https://stackoverflow.com/questions/60298619/awscli-version-2-on-alpine-linux
# @see: https://gist.github.com/so0k/3f0546be5f06431a55a0a90ac9c25da8 for alpine curl issues
ARG GLIBC_VER=2.31-r0
RUN apk upgrade \
    && apk --no-cache add \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && apk add --no-cache \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip -q awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
    && rm glibc-${GLIBC_VER}.apk \
    && rm glibc-bin-${GLIBC_VER}.apk \
    && rm -rf /var/cache/apk/* \
    && aws --version

# Mark all directories as safe for git for backwards compatibility with builds prior to Git v2.35.2
ARG GIT_GLOBAL_SAFE_DIRECTORY=true
RUN git config --global --add safe.directory '*' && git config --global --list --show-origin | cat

# Add git lfs support
RUN apk add git-lfs

# Add gh cli
RUN echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && apk add github-cli@community

# Entrypoint override, setting to shell since this thing has turned into more of a tool grab bag
ENTRYPOINT [ "bash" ]

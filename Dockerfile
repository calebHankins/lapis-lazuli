## Build Stage
FROM alpine:latest AS builder

# Install packages needed to fetch tools
RUN apk add --no-cache bash curl wget tar openssl jq unzip

# helm
ADD https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 /usr/local/bin/get_helm.sh
RUN chmod +x /usr/local/bin/get_helm.sh
RUN ./usr/local/bin/get_helm.sh

# kubectl (aws vended)
# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
RUN curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# eksctl
# https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
RUN mv /tmp/eksctl /usr/local/bin

# EKS-vended aws-iam-authenticator
RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
RUN chmod +x ./aws-iam-authenticator
RUN mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

# terragrunt
ARG TERRAGRUNT_RELEASE=
COPY ./scripts/get_terragrunt.sh /usr/local/bin/get_terragrunt.sh
RUN chmod +x /usr/local/bin/get_terragrunt.sh
RUN ./usr/local/bin/get_terragrunt.sh

## Final Stage
FROM hashicorp/terraform:latest

# helm
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
RUN chmod +x /usr/local/bin/helm
RUN helm repo add stable https://kubernetes-charts.storage.googleapis.com/ && \
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

# aws-cli 2 (also needs glibc on alpine)
# https://stackoverflow.com/questions/60298619/awscli-version-2-on-alpine-linux
ENV GLIBC_VER=2.31-r0
RUN apk --no-cache add \
        binutils \
        curl \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && apk add --no-cache \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
    && apk --no-cache del \
        binutils \
        curl \
        unzip \
    && rm glibc-${GLIBC_VER}.apk \
    && rm glibc-bin-${GLIBC_VER}.apk \
    && rm -rf /var/cache/apk/*

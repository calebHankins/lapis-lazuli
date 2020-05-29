## Build Stage
FROM alpine:latest AS builder

# Install packages needed to fetch tools
RUN apk add --no-cache bash curl wget tar openssl jq

# Install helm
ADD https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 /usr/local/bin/get_helm.sh
RUN chmod +x /usr/local/bin/get_helm.sh
RUN ./usr/local/bin/get_helm.sh

# Install kubectl (aws vended)
# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
RUN curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Install EKS-vended aws-iam-authenticator
RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
RUN chmod +x ./aws-iam-authenticator
RUN mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

# Install terragrunt
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

# aws-iam-authenticator
COPY --from=builder /usr/local/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
RUN chmod +x /usr/local/bin/aws-iam-authenticator

# terragrunt
COPY --from=builder /usr/local/bin/terragrunt /usr/local/bin/terragrunt
RUN chmod +x /usr/local/bin/terragrunt

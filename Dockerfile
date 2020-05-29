
FROM hashicorp/terraform:latest

# Install helm
ADD https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 /usr/local/bin/get_helm.sh
RUN chmod 700 /usr/local/bin/get_helm.sh
RUN apk add --no-cache bash curl tar openssl
RUN ./usr/local/bin/get_helm.sh

# Install terragrunt
ARG TERRAGRUNT_RELEASE=v0.23.23
RUN echo "Pulling terragrunt version: ${TERRAGRUNT_RELEASE}"
ADD https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_RELEASE}/terragrunt_linux_amd64 /usr/local/bin/terragrunt
RUN chmod +x /usr/local/bin/terragrunt


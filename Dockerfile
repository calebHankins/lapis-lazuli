
FROM hashicorp/terraform:latest

ARG TERRAGRUNT_RELEASE=v0.23.23
RUN echo "Pulling terragrunt version: ${TERRAGRUNT_RELEASE}"

# Grab terragrunt release and add execute permissions
ADD https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_RELEASE}/terragrunt_linux_amd64 /usr/local/bin/terragrunt
RUN chmod +x /usr/local/bin/terragrunt


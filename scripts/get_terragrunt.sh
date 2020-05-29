#!/bin/sh -x

# Install required tools
apk add --no-cache wget jq

# Determine install version
TERRAGRUNT_RELEASE_LATEST=$(curl -sL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name)
TERRAGRUNT_RELEASE=${TERRAGRUNT_RELEASE:-$TERRAGRUNT_RELEASE_LATEST}
echo "Pulling terragrunt version: ${TERRAGRUNT_RELEASE}"
echo "Pulling from: https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_RELEASE}/terragrunt_linux_amd64"

# Download terragrunt executable
wget https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_RELEASE}/terragrunt_linux_amd64

# Set execute flag and copy to bin dir
chmod +x ./terragrunt_linux_amd64
cp ./terragrunt_linux_amd64 /usr/local/bin/terragrunt

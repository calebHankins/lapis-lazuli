#!/bin/sh

# Determine install version
TERRAGRUNT_RELEASE_LATEST=$(curl -sL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name)
TERRAGRUNT_RELEASE=${TERRAGRUNT_RELEASE:-$TERRAGRUNT_RELEASE_LATEST}
TERRAGRUNT_URL="https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_RELEASE}/terragrunt_linux_amd64"
echo "Pulling terragrunt version: ${TERRAGRUNT_RELEASE}"
echo "Pulling from: $TERRAGRUNT_URL"

# Download terragrunt executable
wget -q $TERRAGRUNT_URL

# Set execute flag and copy to bin dir
chmod +x ./terragrunt_linux_amd64
cp ./terragrunt_linux_amd64 /usr/local/bin/terragrunt

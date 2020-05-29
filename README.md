# lapis-lazuli

[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/calebhankins/lapis-lazuli.svg?style=flat-square)](https://hub.docker.com/r/calebhankins/lapis-lazuli/)
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/calebhankins/lapis-lazuli.svg?style=flat-square)](https://hub.docker.com/r/calebhankins/lapis-lazuli/)


This project aims to provide a thin wrapping container around cloud infrastructure tools, primarily [HashiCorp's Terraform](https://github.com/hashicorp/terraform) ([specifically their light container as our base](https://hub.docker.com/r/hashicorp/terraform)) and [Gruntwork.io's terragrunt](https://github.com/gruntwork-io/terragrunt).

## Build

Run these commands from the same folder as this readme. Tweak the Dockerfile to meet your needs.

```bash
docker build --pull --rm -t lapis-lazuli .

```

## Using The Tool Suite From Docker

```bash
# Bypass default entrypoint and explore w/ ash
docker run --rm --entrypoint ash -it lapis-lazuli
# / # terragrunt --version
# terragrunt version v0.23.23

# Execute default entrypoint (terraform)
docker run --rm -it lapis-lazuli plan main.tf

```

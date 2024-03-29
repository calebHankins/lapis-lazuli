# lapis-lazuli

[![GitHub Actions](https://github.com/calebHankins/lapis-lazuli/workflows/.github/workflows/build-docker-images.yaml/badge.svg)](https://github.com/calebHankins/lapis-lazuli/actions)
[![Version](https://img.shields.io/github/package-json/v/calebHankins/lapis-lazuli/master)](https://github.com/calebHankins/lapis-lazuli/blob/master/package.json)

This project aims to provide a thin wrapping container around [cloud infrastructure](https://aws.amazon.com/what-is-cloud-computing/) and [kubernetes](https://kubernetes.io/) management tools.

For [cloud infrastructure](https://aws.amazon.com/what-is-cloud-computing/), primarily focusing on enabling: [HashiCorp's Terraform](https://github.com/hashicorp/terraform), [Gruntwork.io's terragrunt](https://github.com/gruntwork-io/terragrunt), and the [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html).

For [k8s](https://kubernetes.io/) support: [helm](https://helm.sh/), [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/), [eksctl](https://eksctl.io/).

- [lapis-lazuli](#lapis-lazuli)
  - [Build](#build)
    - [Pre-Built](#pre-built)
    - [A Note Concerning Self-Signed Certificates](#a-note-concerning-self-signed-certificates)
  - [Run](#run)

## Build

Run these commands from the same folder as this readme. Tweak the [Dockerfile](Dockerfile) to meet your needs.

```bash
# Build w/ project defaulted tool versions
docker build --pull --rm -t lapis-lazuli .
```

There are also hooks for specifying specific base images and tool versions, check out the [Dockerfile](Dockerfile) for available [build args](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg).

```bash
# Build for the latest released terraform version
docker build --pull --rm --build-arg BASE_IMAGE=hashicorp/terraform:latest -t lapis-lazuli .
```

### Pre-Built

A pre-built version can also be pulled from [docker hub](https://hub.docker.com/r/calebhankins/lapis-lazuli):

```bash
docker pull calebhankins/lapis-lazuli
docker tag  calebhankins/lapis-lazuli lapis-lazuli
```

### A Note Concerning Self-Signed Certificates

If you are in a corporate env or for some other reason have self-signed certificates in your chain, the tools will fail with SSL errors. To mitigate this, the build will ping a site over ssl and trust the certs in the chain. If you wish to not do this, comment out the 'Trust self-signed certs' code in the [Dockerfile](Dockerfile) prior to building.

If you pulled from docker hub instead of building, you may need to run the code related to self-signed certs after starting your image to trust your self-signed certs.

## Run

```bash
# Explore
docker run --rm -it lapis-lazuli
# / # terragrunt --version
# terragrunt version v0.23.23
```

More involved example, execute a particular tool using an env file and mounts:

```bash
# Load an env file that contains key=val pairs needed for Terragrunt
# Mount the current working directory as '/workspace' in the container
# Set the current working directory in the container to be '/workspace'
# Set the entrypoint app to be 'terragrunt'
# Run the image tagged as 'lapis-lazuli'
# Supply the entrypoint app (terragrunt) with the command line options '...'
docker run --rm -it \
--env-file ~/terragrunt_envs/sampleEnv.env
-v ~/terragrunt_envs:/root/terragrunt_envs \
-v $(pwd):/workspace \
--workdir /workspace \
--entrypoint terragrunt \
lapis-lazuli \
plan -out ./plans/sampleEnv_tf -var-file='/root/terragrunt_envs/sampleEnv.tfvars'
```

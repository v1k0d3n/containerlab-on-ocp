### Usage

Place the file called `docker-sonic-vs.gz` from the following link [HERE](https://sonic.software/). Leave the name exactly as is, and then in the lab configuration settings in the main[Makefile](../../../Makefile) under the "SONiC Image Preparation" section be sure to change the following sections as need/required:

```bash
SONIC_BRANCH ?= 202505                             # Name of the container image tag
SONIC_IMAGE_NAME ?= docker-sonic-vs                # Name of the container registry
SONIC_REGISTRY ?= quay.io/bjozsa-redhat            # URL for your container registry account
SONIC_CONTAINER_ENGINE ?= podman                   # Options are "podman" or "docker"
```
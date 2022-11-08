#!/bin/sh

. ./image-env.sh

podman run -it --rm --entrypoint bash localhost/$IMAGE_NAME:$IMAGE_VERSION
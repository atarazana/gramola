#!/bin/sh

. ./image-env.sh

podman build -t $IMAGE_NAME:$IMAGE_VERSION --build-arg FROM_IMAGE="${FROM_IMAGE}"  .
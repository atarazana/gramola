#!/bin/sh
ARGOCD_APP_NAME=events
#DEBUG="true"
helm template ../../helm_base --name-template $ARGOCD_APP_NAME --set debug=${DEBUG} --include-crds > ../../helm_base/all.yml && kustomize build
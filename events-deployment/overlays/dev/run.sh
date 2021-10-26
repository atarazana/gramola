#!/bin/sh
ARGOCD_APP_NAME=events
#DEBUG="true"
BASE_REPO_URL=https://github.com/atarazana/gramola
helm template ../../helm_base --name-template $ARGOCD_APP_NAME --set debug=${DEBUG},baseRepoUrl=${BASE_REPO_URL} --include-crds > ../../helm_base/all.yml && kustomize build
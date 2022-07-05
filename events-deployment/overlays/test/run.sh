#!/bin/sh
ARGOCD_APP_NAME=gramola-events
DESTINATION_NAME=in-cluster
BASE_REPO_URL=https://github.com/atarazana/gramola
helm template ../../helm_base --name-template ${ARGOCD_APP_NAME} --set debug=${DEBUG},clusterName=${DESTINATION_NAME},baseRepoUrl=${BASE_REPO_URL} --include-crds > ../../helm_base/all.yml && kustomize build
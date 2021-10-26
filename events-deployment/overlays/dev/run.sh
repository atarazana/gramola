#!/bin/sh
ARGOCD_APP_NAME=events
BASE_REPO_URL=https://github.com/atarazana/gramola
NAMESPACE_SUFFIX="-user1"
helm template ../../helm_base --name-template $ARGOCD_APP_NAME --set debug=${DEBUG},baseRepoUrl=${BASE_REPO_URL} --include-crds > ../../helm_base/all.yml && kustomize build | sed "s/\(namespace:[[:space:]]\{1,\}\)\(gramola-.*\)/\1\2${NAMESPACE_SUFFIX}/"
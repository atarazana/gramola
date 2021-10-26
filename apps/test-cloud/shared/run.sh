#!/bin/sh
ARGOCD_APP_NAME=shared
#DEBUG="true"
BASE_REPO_URL=https://github.com/atarazana/gramola
NAMESPACE_SUFFIX="-user1"
helm template . --name-template $ARGOCD_APP_NAME --set debug=${DEBUG},baseRepoUrl=${BASE_REPO_URL},namespaceSuffix=${NAMESPACE_SUFFIX} --include-crds
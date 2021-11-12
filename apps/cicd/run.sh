#!/bin/sh
ARGOCD_APP_NAME=gramola-events
BASE_REPO_URL=https://repository-gitea-system.apps.cluster-e608.e608.sandbox465.opentlc.com/user1/gramola
NAMESPACE_SUFFIX="-user1"
helm template . --name-template ${ARGOCD_APP_NAME} --set baseRepoUrl=${BASE_REPO_URL},username=${USERNAME},namespaceSuffix=${NAMESPACE_SUFFIX} --include-crds
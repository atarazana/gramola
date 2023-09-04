#!/bin/sh
ARGOCD_APP_NAME=gramola-events
ARGOCD_ENV_BASE_REPO_URL=https://github.com/atarazana/gramola
ARGOCD_ENV_NAMESPACE_SUFFIX="-user1"
helm template ../../helm_base --name-template $ARGOCD_APP_NAME --set debug=${ARGOCD_ENV_DEBUG},clusterName=${ARGOCD_ENV_DESTINATION_NAME},baseRepoUrl=${ARGOCD_ENV_BASE_REPO_URL},namespaceSuffix=${ARGOCD_ENV_NAMESPACE_SUFFIX} --include-crds > ../../helm_base/all.yml && kustomize build | sed "s/\(namespace:[[:space:]]\{1,\}\)\(gramola-.*\)/\1\2${ARGOCD_ENV_NAMESPACE_SUFFIX}/"
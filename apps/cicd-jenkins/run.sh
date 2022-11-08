#!/bin/sh
ARGOCD_APP_NAME=arco-saer
GIT_URL=https://github.com
GIT_USERNAME=cvicens
BASE_REPO_NAME=arco-saer-conf
GIT_REVISION=main
helm template . --name-template ${ARGOCD_APP_NAME} \
  --set debug=${DEBUG},clusterName=${DESTINATION_NAME},gitUrl=${GIT_URL},gitUsername=${GIT_USERNAME},baseRepoName=${BASE_REPO_NAME},gitRevision=${GIT_REVISION} \
  --include-crds
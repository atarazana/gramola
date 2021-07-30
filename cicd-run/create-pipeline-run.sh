#!/bin/sh

export ARGOCD_APP_NAME=gramola-cicd
export CICD_NAMESPACE=$(yq r ../apps/cicd/values.yaml cicdNamespace)
export GIT_URL=$(yq r ../apps/cicd/values.yaml gitUrl)
export GIT_USERNAME=$(yq r ../apps/cicd/values.yaml gitUsername)
export GIT_BASE_REPO_NAME=$(yq r ../apps/cicd/values.yaml baseRepoName)
export BUILD_BOT_SERVICE_ACCOUNT_NAME=$(yq r ../apps/cicd/values.yaml pipelinesServiceAccountName)

export CONTAINER_REGISTRY_SERVER=$(yq r ../apps/cicd/values.yaml containerRegistryServer)
export CONTAINER_REGISTRY_ORG=$(yq r ../apps/cicd/values.yaml containerRegistryOrg)
export IMAGE_TAG=$(git rev-parse --short HEAD)

export BASE_REPO_URL="${GIT_URL}/${GIT_USERNAME}/${GIT_BASE_REPO_NAME}"

helm template . --name-template ${ARGOCD_APP_NAME} --include-crds \
  --set baseRepoUrl=${BASE_REPO_URL},serviceAccountName=${BUILD_BOT_SERVICE_ACCOUNT_NAME},containerRegistryServer=${CONTAINER_REGISTRY_SERVER},containerRegistryOrg=${CONTAINER_REGISTRY_ORG},imageTag=${IMAGE_TAG} \
  | kubectl -n ${CICD_NAMESPACE} create -f -
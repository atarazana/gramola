#!/bin/sh

# Create git secret
export CICD_NAMESPACE=$(yq r ./values.yaml cicdNamespace)
export GIT_URL=$(yq r ./values.yaml gitUrl)
export GIT_USERNAME=$(yq r ./values.yaml gitUsername)
export GIT_PAT_SECRET_NAME=$(yq r ./values.yaml gitPatSecretName)

NAMESPACE_STATUS=$(kubectl get namespace/${CICD_NAMESPACE} -o jsonpath='{.status.phase}')
if [ "${NAMESPACE_STATUS}" == *"Active"* ]; then
    echo "Wait until ArgoCD has create ns ${CICD_NAMESPACE} or create it manually"
    exit 1
fi

echo "PAT for ${GIT_URL}: " && read -s GIT_PAT
if [ -z "${GIT_PAT}" ]; then
    echo "You should provide a PAT for ${GIT_URL}"
    exit 1
fi

kubectl create secret -n ${CICD_NAMESPACE} generic ${GIT_PAT_SECRET_NAME} --dry-run=client -o yaml \
  | yq w - type kubernetes.io/basic-auth \
  | yq w - stringData.[user.name] ${GIT_USERNAME} \
  | yq w - stringData.[user.email] "${GIT_USERNAME}@example.com" \
  | yq w - stringData.username ${GIT_USERNAME} \
  | yq w - stringData.password ${GIT_PAT} | kubectl apply -f -

kubectl annotate -n ${CICD_NAMESPACE} secret ${GIT_PAT_SECRET_NAME} \
  "tekton.dev/git-0=https://github.com"

# Create container registry secret
export CONTAINER_REGISTRY_SECRET_NAME=$(yq r ./values.yaml containerRegistrySecretName)
export CONTAINER_REGISTRY_SERVER=$(yq r ./values.yaml containerRegistryServer)
export CONTAINER_REGISTRY_ORG=$(yq r ./values.yaml containerRegistryOrg)

echo "User for ${CONTAINER_REGISTRY_SERVER}/${CONTAINER_REGISTRY_ORG}: " && read CONTAINER_REGISTRY_USERNAME
if [ -z "${CONTAINER_REGISTRY_USERNAME}" ]; then
    echo "You should provide a user for ${CONTAINER_REGISTRY_SERVER}/${CONTAINER_REGISTRY_ORG}"
    exit 1
fi
echo "Password for ${CONTAINER_REGISTRY_SERVER}/${CONTAINER_REGISTRY_ORG}: " && read -s CONTAINER_REGISTRY_PASSWORD
if [ -z "${CONTAINER_REGISTRY_PASSWORD}" ]; then
    echo "You should provide a password for ${CONTAINER_REGISTRY_SERVER}/${CONTAINER_REGISTRY_ORG}"
    exit 1
fi

kubectl create -n ${CICD_NAMESPACE} secret docker-registry ${CONTAINER_REGISTRY_SECRET_NAME} \
  --docker-server=https://$CONTAINER_REGISTRY_SERVER \
  --docker-username=$CONTAINER_REGISTRY_USERNAME \
  --docker-password=$CONTAINER_REGISTRY_PASSWORD

kubectl annotate -n ${CICD_NAMESPACE} secret ${CONTAINER_REGISTRY_SECRET_NAME} \
  "tekton.dev/docker-0=https://quay.io"

#!/bin/sh

# Create git secret
export CICD_NAMESPACE=$(yq eval '.jenkinsNamespace' ./values.yaml)
export GIT_URL=$(yq eval '.gitUrl' ./values.yaml)
export GIT_USERNAME=$(yq eval '.gitUsername' ./values.yaml)
export GIT_PAT_SECRET_NAME=$(yq eval '.gitPatSecretName' ./values.yaml)

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

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${GIT_PAT_SECRET_NAME}
  namespace: ${CICD_NAMESPACE}
type: kubernetes.io/basic-auth
stringData:
  user.name: ${GIT_USERNAME}
  user.email: "${GIT_USERNAME}@example.com"
  username: ${GIT_USERNAME}
  password: ${GIT_PAT}
EOF

kubectl annotate -n ${CICD_NAMESPACE} secret ${GIT_PAT_SECRET_NAME} \
  "tekton.dev/git-0=https://github.com"

kubectl annotate -n ${CICD_NAMESPACE} secret ${GIT_PAT_SECRET_NAME} \
  "build.openshift.io/source-secret-match-uri-1=https://github.com/*"

kubectl label -n ${CICD_NAMESPACE} secret ${GIT_PAT_SECRET_NAME} \
  credential.sync.jenkins.openshift.io=true

# Create container registry secret
export CONTAINER_REGISTRY_SECRET_NAME=$(yq eval '.containerRegistrySecretName' ./values.yaml)
export CONTAINER_REGISTRY_SERVER=$(yq eval '.containerRegistryServer' ./values.yaml)
export CONTAINER_REGISTRY_ORG=$(yq eval '.containerRegistryOrg' ./values.yaml)

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

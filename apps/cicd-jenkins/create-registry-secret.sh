#!/bin/sh
cd $(dirname $0)

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ] || [ -z $5 ];
then 
    printf "%s %s %s %s %s %s\n" "$0" '${JENKIS_NAMESPACE}' '${CONTAINER_REGISTRY_SERVER}' '${CONTAINER_REGISTRY_ORG}' '${CONTAINER_REGISTRY_USERNAME}' '${CONTAINER_REGISTRY_PASSWORD}'
    exit 1
fi


JENKIS_NAMESPACE=$1
CONTAINER_REGISTRY_SERVER=$2
CONTAINER_REGISTRY_ORG=$3
CONTAINER_REGISTRY_USERNAME=$4
CONTAINER_REGISTRY_PASSWORD=$5
CONTAINER_REGISTRY_SECRET_NAME=$(yq eval '.containerRegistrySecretName' ./values.yaml)


if [ -z "${CONTAINER_REGISTRY_USERNAME}" ]; then
    echo "You should provide a user for ${CONTAINER_REGISTRY_SERVER}/${CONTAINER_REGISTRY_ORG}"
    exit 1
fi

if [ -z "${CONTAINER_REGISTRY_PASSWORD}" ]; then
    echo "You should provide a password for ${CONTAINER_REGISTRY_SERVER}/${CONTAINER_REGISTRY_ORG}"
    exit 1
fi

kubectl create -n ${JENKIS_NAMESPACE} secret docker-registry ${CONTAINER_REGISTRY_SECRET_NAME} \
  --docker-server=https://$CONTAINER_REGISTRY_SERVER \
  --docker-username=${CONTAINER_REGISTRY_USERNAME} \
  --docker-password=${CONTAINER_REGISTRY_PASSWORD}

kubectl annotate -n ${JENKIS_NAMESPACE} secret ${CONTAINER_REGISTRY_SECRET_NAME} \
  "tekton.dev/docker-0=https://${CONTAINER_REGISTRY_SERVER}"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${CONTAINER_REGISTRY_SECRET_NAME}-raw
  namespace: ${JENKIS_NAMESPACE}
type: kubernetes.io/basic-auth
stringData:
  username: ${CONTAINER_REGISTRY_USERNAME}
  password: ${CONTAINER_REGISTRY_PASSWORD}
EOF

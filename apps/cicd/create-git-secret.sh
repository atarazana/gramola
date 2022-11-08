#!/bin/sh
cd $(dirname $0)

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ];
then 
    printf "%s %s %s %s %s\n" "$0" '${CICD_NAMESPACE}' '${GIT_HOST}' '${GIT_USERNAME}' '${GIT_PAT}'
    exit 1
fi

CICD_NAMESPACE=$1
GIT_HOST=$2
GIT_USERNAME=$3
GIT_PAT=$4

GIT_PAT_SECRET_NAME=$(yq eval '.gitPatSecretName' ./values.yaml)

NAMESPACE_STATUS=$(oc get namespace/${CICD_NAMESPACE} -o jsonpath='{.status.phase}')
if [ "${NAMESPACE_STATUS}" == *"Active"* ]; then
    echo "Wait until ArgoCD has create ns ${CICD_NAMESPACE} or create it manually"
    exit 1
fi

if [ -z "${GIT_PAT}" ]; then
    echo "You should provide a PAT for ${GIT_URL}"
    exit 1
fi

cat <<EOF | oc apply -f -
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

oc annotate -n ${CICD_NAMESPACE} secret ${GIT_PAT_SECRET_NAME} \
  "tekton.dev/git-0=https://${GIT_HOST}"


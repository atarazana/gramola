#!/bin/sh

# https://gist.github.com/janeczku/b16154194f7f03f772645303af8e9f80
# https://argoproj.github.io/argo-cd/getting_started/#5-register-a-cluster-to-deploy-apps-to-optional


if [ "$#" -ne 2 ]; then
    echo "CLUSTER_NAME: " && read CLUSTER_NAME
    echo "API_SERVER: " && read API_SERVER
    
    if [ -z "${CLUSTER_NAME}" ] || [ -z "${API_SERVER}" ]; then
        echo "You should provide CLUSTER_NAME and API_SERVER."
        echo "Usage: $0 <CLUSTER_NAME> <API_SERVER>"
        echo "For instance: $0 aws-managed1 api.cluster-10d2.10d2.sandbox909.opentlc.com"
        exit 1
    fi

else
    CLUSTER_NAME=$1
    API_SERVER=$2
fi


CONTEXT_NAME=$(kubectl config get-contexts -o name | grep ${API_SERVER})

argocd cluster add ${CONTEXT_NAME} --name ${CLUSTER_NAME}

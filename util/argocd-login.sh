#!/bin/sh


export ARGOCD_HOST=$(oc get route/openshift-gitops-server -o jsonpath='{.status.ingress[0].host}' -n openshift-gitops)

#export ARGOCD_USERNAME=admin
#export ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' -n openshift-gitops | base64 -d)

#argocd login $ARGOCD_HOST --insecure --grpc-web --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD

argocd login $ARGOCD_HOST --insecure --grpc-web --sso
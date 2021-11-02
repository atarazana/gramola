#!/bin/sh

export ARGOCD_USERNAME=admin
export ARGOCD_SERVER=$(oc get route/openshift-gitops-server -o jsonpath='{.status.ingress[0].host}' -n openshift-gitops)
export ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' -n openshift-gitops | base64 -d)

argocd login $ARGOCD_SERVER --insecure --grpc-web --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD

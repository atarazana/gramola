#!/bin/sh
ARGOCD_APP_NAME=economiacircular
helm template ../../helm_base --name-template ${ARGOCD_APP_NAME} --include-crds > ../../helm_base/all.yml && kustomize build
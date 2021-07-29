#!/bin/sh
ARGOCD_APP_NAME=gramola-cicd
helm template . --name-template ${ARGOCD_APP_NAME} --include-crds
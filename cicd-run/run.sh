#!/bin/sh
ARGOCD_APP_NAME=gramola-events
helm template . --name-template ${ARGOCD_APP_NAME} --include-crds
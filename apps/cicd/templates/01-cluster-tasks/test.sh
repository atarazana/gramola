#!/bin/sh
APP_NAME=events-app-dev
TWIN_OVERLAY_SUFFIX=cloud

echo "ARGOCD_VERSION=$(argocd version)"
echo "OC_VERSION=$(oc version)"

ARGOCD_USERNAME=admin
ARGOCD_SERVER=$(oc get route/openshift-gitops-server -o jsonpath='{.status.ingress[0].host}' -n openshift-gitops)
ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' -n openshift-gitops | base64 -d)

argocd login $ARGOCD_SERVER --insecure --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD

argocd app sync --timeout 120 ${APP_NAME}
if [ "$?" == 0 ]; then
    argocd app get ${APP_NAME}-${TWIN_OVERLAY_SUFFIX}
    if [ "$?" == 0 ]; then
        argocd app sync --timeout 120 ${APP_NAME}-${TWIN_OVERLAY_SUFFIX}
        if ! [ "$?" == 0 ]; then
            echo "ERROR WHILE SYNCING TWIN APP ${APP_NAME}-${TWIN_OVERLAY_SUFFIX}"
            # echo -n "false" > $(results.APP_SYNC_SUCCESS.path)
            exit 1
        fi
    else
        echo "No Twin App called: ${APP_NAME}-${TWIN_OVERLAY_SUFFIX}"
    fi
else
    echo "ERROR WHILE SYNCING ${APP_NAME}"
    # echo -n "false" > $(results.APP_SYNC_SUCCESS.path)
    exit 1
fi

# echo -n "true" > $(results.APP_SYNC_SUCCESS.path)
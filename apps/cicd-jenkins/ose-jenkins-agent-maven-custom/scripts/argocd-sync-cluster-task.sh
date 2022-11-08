 #!/bin/sh

printf "\n>>> START\n\n"

# WAIT_FOR_HEALTH
WAIT_FOR_HEALTH_FLAG=""
if [ $(params.WAIT_FOR_HEALTH) == "TRUE" ]; then
    WAIT_FOR_HEALTH_FLAG="--health"
fi

printf "APP_NAME=$(params.APP_NAME)\n"
printf "TWIN_OVERLAY_SUFFIX=$(params.TWIN_OVERLAY_SUFFIX)\n\n"

printf "Gathering credentials for logging in ArgoCD instance in-cluster\n"
printf "===============================================================\n\n"
ARGOCD_USERNAME=admin
ARGOCD_SERVER=$(oc get route/openshift-gitops-server -o jsonpath='{.status.ingress[0].host}' -n openshift-gitops)
ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' -n openshift-gitops | base64 -d)

printf "\nARGOCD_USERNAME=${ARGOCD_USERNAME}"
printf "\nARGOCD_SERVER=${ARGOCD_SERVER}\n\n"

printf "Attempting logging in ArgoCD instance in-cluster\n"
printf "================================================\n\n"
argocd --grpc-web login $ARGOCD_SERVER --insecure --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD

SUB_OVERLAYS_TO_UPDATE="$(params.SUB_OVERLAYS_TO_UPDATE)"
echo "SUB_OVERLAYS_TO_UPDATE=${SUB_OVERLAYS_TO_UPDATE}"

for SUB_OVERLAY in ${SUB_OVERLAYS_TO_UPDATE}
do
    ARGOCD_APP_NAME=$(params.APP_NAME)-${SUB_OVERLAY}
    printf "Starting sync of ${ARGOCD_APP_NAME}\n"
    printf "================================================\n\n"
    argocd --grpc-web app sync --async ${ARGOCD_APP_NAME}
    argocd --grpc-web app get --refresh ${ARGOCD_APP_NAME} > /dev/null && argocd --grpc-web app wait ${ARGOCD_APP_NAME} --sync ${WAIT_FOR_HEALTH_FLAG}
    printf "\nSync of ${ARGOCD_APP_NAME} ended\n"
    printf "================================================\n\n"
    if [ "$?" == 0 ]; then
    ARGOCD_TWIN_APP_NAME=$(params.APP_NAME)-$(params.TWIN_OVERLAY_SUFFIX)-${SUB_OVERLAY}
    printf "Checking if twin app ${ARGOCD_TWIN_APP_NAME} exists\n"
    printf "================================================================\n\n"
    argocd --grpc-web app get ${ARGOCD_TWIN_APP_NAME}
    if [ "$?" == 0 ]; then
        printf "Starting sync of ${ARGOCD_TWIN_APP_NAME}\n"
        printf "==============================================================\n\n"
        argocd --grpc-web app sync --async ${ARGOCD_TWIN_APP_NAME}
        argocd --grpc-web app get --refresh ${ARGOCD_TWIN_APP_NAME} > /dev/null && argocd --grpc-web app wait ${ARGOCD_TWIN_APP_NAME} --sync ${WAIT_FOR_HEALTH_FLAG}
        if ! [ "$?" == 0 ]; then
        printf "\n*** ERROR WHILE SYNCING TWIN APP ${ARGOCD_TWIN_APP_NAME} ***\n"
        echo -n "false" > $(results.TWIN_APP_SYNC_SUCCESS.path)
        exit 1
        else
        echo -n "true" > $(results.TWIN_APP_SYNC_SUCCESS.path)
        fi
    else
        printf "\n*** APP ${ARGOCD_TWIN_APP_NAME} NOT FOUND ***\n"
    fi
    else
    printf "\n*** ERROR WHILE SYNCING $(params.APP_NAME) ***"
    echo -n "false" > $(results.APP_SYNC_SUCCESS.path)
    exit 1
    fi
done

echo -n "true" > $(results.APP_SYNC_SUCCESS.path)
printf "\n<<< END\n\n"
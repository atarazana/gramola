#!/bin/sh
OC_USER=$(oc whoami)
OC_TOKEN=$(oc whoami -t)

if [ -z "${OC_TOKEN}" ]
then
    echo "You have to log in the OpenShift cluster and have cluster-admin permissions"
    exit 1
fi

until kubectl apply -k ./bootstrap/; do sleep 2; done



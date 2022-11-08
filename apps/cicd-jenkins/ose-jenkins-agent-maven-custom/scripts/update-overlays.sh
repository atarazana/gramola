#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo "Provide OVERLAYS_PATH SUB_OVERLAYS_TO_UPDATE OVERLAY NEW_DIGEST"
    echo "$0 ./arco-saer-deployment/overlays 'L01,L02' dev XYZ"
    exit 1;
fi


# OVERLAYS_PATH="./arco-saer-deployment/overlays"
# SUB_OVERLAYS_TO_UPDATE="L01 L02"
# OVERLAY="dev"
# NEW_VALUE=

OVERLAYS_PATH=${1}
SUB_OVERLAYS_TO_UPDATE=${2//,/ }
OVERLAY=${3}
NEW_VALUE=${4}

FILE_NAME="kustomization.yml"
TWIN_OVERLAY_SUFFIX="cloud"
SELECT_EXPRESSION='(.images.[] | select(.name == "arco-saer*")).newTag'


echo "SELECT_EXPRESSION=${SELECT_EXPRESSION}"
echo "NEW_VALUE=${NEW_VALUE}"
echo "SUB_OVERLAYS_TO_UPDATE=${SUB_OVERLAYS_TO_UPDATE}"

for SUB_OVERLAY in ${SUB_OVERLAYS_TO_UPDATE}
do
    FILE_TO_UPDATE="${OVERLAYS_PATH}/${OVERLAY}/${SUB_OVERLAY}/${FILE_NAME}"
    echo "FILE_TO_UPDATE=${FILE_TO_UPDATE}"

    if [ ! -f ${FILE_TO_UPDATE} ]; then
    echo "======== ERROR ========"
    echo "File not found, aborting"
    ls -ltrh
    exit 1;
    fi;

    # echo "======== BEFORE CHANGES ========"
    # cat ${FILE_TO_UPDATE}

    # Update target with new value
    yq -i eval '(.images.[] | select(.name == "arco-saer*")).newTag |= "'"${NEW_VALUE}"'"' ${FILE_TO_UPDATE}
    
    # echo "======== AFTER CHANGES ========"
    # cat ${FILE_TO_UPDATE}
done

# If twin env
for SUB_OVERLAY in ${SUB_OVERLAYS_TO_UPDATE}
do
    FILE_TO_UPDATE_TWIN="${OVERLAYS_PATH}/${OVERLAY}-${TWIN_OVERLAY_SUFFIX}/${SUB_OVERLAY}/${FILE_NAME}"
    echo "FILE_TO_UPDATE_TWIN=${FILE_TO_UPDATE_TWIN}"

    if [ -f ${FILE_TO_UPDATE_TWIN} ]; then
    echo "======== UPDATING TWIN OVERLAY ========"
    # Update target with new value
    yq -i eval '(.images.[] | select(.name == "arco-saer*")).newTag |= "'"${NEW_VALUE}"'"' ${FILE_TO_UPDATE_TWIN}
    else
    echo "TWIN OVERLAY NOT FOUND!"
    fi;
done

#echo -n "true" > $(results.SUCCESS)
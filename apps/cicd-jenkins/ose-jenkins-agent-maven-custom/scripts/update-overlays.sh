#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
    echo "Provide OVERLAYS_PATH OVERLAY IMAGE_NAME NEW_NAME NEW_TAG"
    echo "$0 ./events-deployment/overlays dev gramola-events:0.0.0 quay.io/atarazana/gramola-events 1231231231212313"
    exit 1;
fi


OVERLAYS_PATH=${1}
OVERLAY=${2}
IMAGE_NAME=${3}
NEW_NAME=${4}
NEW_TAG=${5}

echo "OVERLAYS_PATH=${OVERLAYS_PATH}"
echo "OVERLAY=${OVERLAY}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "NEW_NAME=${NEW_NAME}"
echo "NEW_TAG=${NEW_TAG}"

FILE_NAME="kustomization.yml"
TWIN_OVERLAY_SUFFIX="cloud"
SELECT_EXPRESSION='(.images.[] | select(.name == "'"${IMAGE_NAME}"'"))'

echo "SELECT_EXPRESSION=${SELECT_EXPRESSION}"

FILE_TO_UPDATE="${OVERLAYS_PATH}/${OVERLAY}/${FILE_NAME}"
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
yq -i eval ''"${SELECT_EXPRESSION}"'.newName |= "'"${NEW_NAME}"'"' ${FILE_TO_UPDATE}
yq -i eval ''"${SELECT_EXPRESSION}"'.newTag |= "'"${NEW_TAG}"'"' ${FILE_TO_UPDATE}

# echo "======== AFTER CHANGES ========"
# cat ${FILE_TO_UPDATE}

FILE_TO_UPDATE_TWIN="${OVERLAYS_PATH}/${OVERLAY}-${TWIN_OVERLAY_SUFFIX}/${FILE_NAME}"
echo "FILE_TO_UPDATE_TWIN=${FILE_TO_UPDATE_TWIN}"

if [ -f ${FILE_TO_UPDATE_TWIN} ]; then
    echo "======== UPDATING TWIN OVERLAY ========"
    # Update target with new value
    yq -i eval ''"${SELECT_EXPRESSION}"'.newName |= "'"${NEW_NAME}"'"' ${FILE_TO_UPDATE_TWIN}
    yq -i eval ''"${SELECT_EXPRESSION}"'.newTag |= "'"${NEW_TAG}"'"' ${FILE_TO_UPDATE_TWIN}
    else
    echo "TWIN OVERLAY NOT FOUND!"
fi;

#echo -n "true" > $(results.SUCCESS)
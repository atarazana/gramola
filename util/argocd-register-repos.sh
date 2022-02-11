#!/bin/sh

echo "Configuration Repo URL (DON'T add .git at the end): " && read GIT_BASE_URL
echo "GIT_BASE_URL=${GIT_BASE_URL}"
if [ -z "${GIT_BASE_URL}" ]; then
    echo "You have to provide the url of the configuration repo"
    exit 1
fi

echo "User for ${GIT_BASE_URL} (type git if Gitlab): " && read GIT_USERNAME
echo "GIT_USERNAME=${GIT_USERNAME}"
if [ -z "${GIT_USERNAME}" ]; then
    echo "You have to provide the user of the configuration repo"
    exit 1
fi

# IF git repo is NOT secure uncomment
# argocd repo add ${GIT_BASE_URL}.git
# argocd repo add ${GIT_BASE_URL}-events.git

# IF git repo is secure uncomment
echo "Token for ${GIT_BASE_URL}: " && read -s GIT_TOKEN
echo "GIT_TOKEN=${GIT_TOKEN}"
if [ -z "${GIT_TOKEN}" ]; then
    echo "You have to provide a Personal Access Token to access the configuration repo"
    exit 1
fi

# Register
argocd repo add ${GIT_BASE_URL}.git --username ${GIT_USERNAME} --password $GIT_TOKEN --upsert --grpc-web
#argocd repo add ${GIT_BASE_URL}-events.git --username ${GIT_USERNAME} --password $GIT_TOKEN --upsert


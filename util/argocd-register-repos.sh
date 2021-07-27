#!/bin/sh

GIT_USERNAME=cvicens
# Ue this for gitlab
# GIT_USER=git
GIT_BASE_URL=https://github.com/atarazana/gramola

# IF git repo is NOT secure uncomment
# argocd repo add ${GIT_BASE_URL}.git
# argocd repo add ${GIT_BASE_URL}-events.git

# IF git repo is secure uncomment
echo "Token for ${GIT_BASE_URL}: " && read -s GIT_TOKEN
echo "GIT_TOKEN=${GIT_TOKEN}"
argocd repo add ${GIT_BASE_URL}.git --username ${GIT_USERNAME} --password $GIT_TOKEN --upsert
argocd repo add ${GIT_BASE_URL}-events.git --username ${GIT_USERNAME} --password $GIT_TOKEN --upsert


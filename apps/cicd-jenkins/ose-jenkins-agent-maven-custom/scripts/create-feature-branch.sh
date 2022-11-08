#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Provide GIT_USER_EMAIL GIT_USER_NAME"
    exit 1;
fi

if [ ! -d .git ]; then
    echo "Not a git repository found, aborting"
    exit 1;
fi;

echo "====> ~/.gitconfig"
cat ~/.gitconfig
git config --global user.email "${1}"
git config --global user.name "${2}"
echo "====> ~/.gitconfig"
cat ~/.gitconfig

# Create a temporary branch to stash changes in
BRANCH_NAME=fb-$(tr -cd '[:alnum:]' < /dev/urandom | fold -w8 | head -n1)   
git checkout -b ${BRANCH_NAME}

# Commit changes
git commit -a -m "Current changes into feature branch ${BRANCH_NAME}"

# Push changes
git push origin ${BRANCH_NAME}

# Lets return the random branch name
echo -n "${BRANCH_NAME}" > BRANCH_NAME
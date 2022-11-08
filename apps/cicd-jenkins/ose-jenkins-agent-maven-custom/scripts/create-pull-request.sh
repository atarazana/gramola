#!/bin/sh

echo "PR_BASE=${PR_BASE}"
PR_HEAD=$(cat $(results.PR_HEAD.path))
echo "PR_HEAD=${PR_HEAD}"
echo "PR_TITLE=${PR_TITLE}"
echo "PR_BODY=${PR_BODY}"
echo "PAT_SECRET_NAME=$(params.PAT_SECRET_NAME)"
echo "PAT_SECRET_KEY=$(params.PAT_SECRET_KEY)"

echo "WORKING_DIR=$(workspaces.source.path)"
echo "PWD=`pwd`"

# Login `gh` using a Personal Access Token
echo ${GITHUB_TOKEN} > ./github.token 
gh auth login --with-token < ./github.token 

# Create a PR
PR_CREATE_OUT=$(gh pr create --base ${PR_BASE} --head ${PR_HEAD} --title "${PR_TITLE}" --body "${PR_BODY}")
PR_URL=$(echo ${PR_CREATE_OUT} | grep -e "https://github.com/.*/pull")

echo -n "${PR_URL}" > $(results.PR_URL.path)
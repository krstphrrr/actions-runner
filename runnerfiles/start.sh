#!/bin/bash
# add these when running the container
REPO=$REPO
ACCESS_TOKEN=$TOKEN 


# standard post request for runner token against the github's api using an correctly configured access_token 
REG_TOKEN=$(curl -L \
 -X POST \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer ${ACCESS_TOKEN}" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/actions/runners/registration-token |
jq .token --raw-output)

cd /home/docker/actions-runner

./config.sh --url https://github.com/${REPO} --token ${REG_TOKEN}

cleanup(){
  echo "Removing runner..."
  ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT 
trap 'cleanup; exit 143' TERM 

./run.sh & wait $!
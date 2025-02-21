#!/bin/bash
#echo "waiting for volumes to set up before allowing ownership of docker.sock.."

# sleep 10
# sudo chown github:github /var/run/docker.sock
#echo "done!"
# add these when running the container
# alias docker='sudo docker '

REPO=$TARGETREPO
ACCESS_TOKEN=$TOKEN

# standard post request for runner token against the github's api using an correctly configured access_token 

# pat requires: admin read/write 
REG_TOKEN=$(curl -L \
 -X POST \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer ${ACCESS_TOKEN}" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 https://api.github.com/orgs/${REPO}/actions/runners/registration-token |
jq .token --raw-output)

## organization token request

# pat requires: self-hosted runner org permission read/write

# curl -L \
#   -X POST \
#   -H "Accept: application/vnd.github+json" \
#   -H "Authorization: Bearer ${ACCESS_TOKEN}" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   https://api.github.com/orgs/${REPO}/actions/runners/registration-token

cd /home/github/actions-runner

./config.sh --url https://github.com/${REPO} --token ${REG_TOKEN}

cleanup(){
  echo "Removing runner..."
  ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT 
trap 'cleanup; exit 143' TERM 

./run.sh & wait $!

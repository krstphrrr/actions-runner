FROM ubuntu:20.04

## preparing the ubuntu for the runner resources
ARG RUNNER_VERSION="2.315.0"
ARG CHANNEL=stable
ARG DEBIAN_FRONTEND=noninteractive
ARG DOCKER_VERSION=24.0.7
ARG DOCKER_COMPOSE_VERSION=v2.23.0
ARG TARGETPLATFORM
ARG DOCKER_GROUP_GID=121
ARG RUNNER_USER_UID=1001 

# adding docker user
RUN apt update -y && apt upgrade -y && useradd -m docker 

# add build dependencies
RUN apt install -y curl gpg apt-transport-https ca-certificates software-properties-common
# Install Docker GPG keys
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add the Docker repository to Apt sources
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

#installing docker
RUN apt update && apt install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip docker-ce \
        docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  

RUN usermod -aG docker docker && newgrp docker

# download and untar runner software
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -o actions-runner-linux-x64-2.315.0.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# changing ownership of home directory & installing dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

COPY ./runnerfiles/start.sh ./start.sh

RUN touch /var/run/docker.sock && chown docker:docker /var/run/docker.sock


RUN chmod +x start.sh 

RUN groupmod -g 1002 docker
USER docker

ENTRYPOINT ["./start.sh"]
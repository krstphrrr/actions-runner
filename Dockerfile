FROM ubuntu:20.04

## preparing the ubuntu for the runner resources
ARG RUNNER_VERSION="2.317.0"


# add build dependencies
RUN apt update && apt install -y curl gpg apt-transport-https ca-certificates software-properties-common
# Install Docker GPG keys
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add the Docker repository to Apt sources
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt update && apt install -y docker-ce-cli sudo jq

RUN useradd -m github && \
  usermod -aG sudo github && \
  echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN groupadd docker && usermod -aG docker github && newgrp docker


# # download and untar runner software
RUN cd /home/github && mkdir actions-runner && cd actions-runner \
    && curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# # changing ownership of home directory & installing dependencies
RUN sudo chown -R github /home/github/actions-runner && sudo /home/github/actions-runner/bin/installdependencies.sh

WORKDIR /home/github/actions-runner

COPY ./runnerfiles/start.sh ./start.sh

RUN sudo chmod +x ./start.sh 
RUN sed -i -e 's/\r$//' ./start.sh




USER github
RUN sudo usermod -aG docker github && newgrp docker


# CMD ["tail", "-f", "/dev/null"]

ENTRYPOINT ["/home/github/actions-runner/start.sh"]
#!/bin/bash
# filepath: /home/elrey/actions-runner/reset-runners.sh

# Set up logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Lock file to prevent multiple instances
LOCK_FILE="/tmp/reset-runners.lock"
if [ -f "$LOCK_FILE" ]; then
    echo "Script is already running"
    exit 1
fi
trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE

# Function to check command status
check_command() {
    if [ $? -ne 0 ]; then
        logger -t reset-runners "ERROR: $1 failed"
        rm -f $LOCK_FILE
        exit 1
    fi
}

logger -t reset-runners "Starting runner reset sequence..."

# Remove stacks
logger -t reset-runners "Removing stacks..."
/usr/bin/docker stack rm jer_runner
/usr/bin/docker stack rm ldc_runner

logger -t reset-runners "Starting runner reset sequence..."

# Git operations
logger -t reset-runners "Performing git operations..."
cd /home/elrey/actions-runner
git stash
check_command "git stash"
git pull
check_command "git pull"

# Ensure script is executable
logger -t reset-runners "Setting script permissions..."
chmod +x /home/elrey/actions-runner/reset-runners.sh
check_command "chmod script"

# Wait for stack removal
logger -t reset-runners "Waiting for stacks to be removed..."
sleep 30

# Bring down sidecar
logger -t reset-runners "Stopping sidecar..."
/usr/bin/docker compose -f /home/elrey/actions-runner/sidecar.yml down
check_command "sidecar shutdown"

# System prune
logger -t reset-runners "Pruning system..."
/usr/bin/docker system prune -a -f --volumes
check_command "system prune"

# Building the sidecar image
logger -t reset-runners "Building sidecar image..."
/usr/bin/docker compose -f /home/elrey/actions-runner/sidecar.yml build
check_command "sidecar image build"

# Build runner images
logger -t reset-runners "Building jer runner image..."
/usr/bin/docker image build -t landscapedatacommons/jornada-runner-jer:1.0.0 -f /home/elrey/actions-runner/jer.Dockerfile /home/elrey/actions-runner
check_command "jer runner image build"

# Build runner images
logger -t reset-runners "Building ldc runner images..."
/usr/bin/docker image build -t landscapedatacommons/jornada-runner-ldc:1.0.0 -f /home/elrey/actions-runner/ldc.Dockerfile /home/elrey/actions-runner
check_command "ldc runner image build"

# Create network if it doesn't exist
logger -t reset-runners "Checking/Creating network..."
if ! /usr/bin/docker network ls | grep -q "runner-network"; then
    /usr/bin/docker network create -d overlay --attachable runner-network
    check_command "network creation"
else
    logger -t reset-runners "Network runner-network already exists"
fi

# Start sidecar
logger -t reset-runners "Starting sidecar..."
/usr/bin/docker compose -f /home/elrey/actions-runner/sidecar.yml up -d
check_command "sidecar startup"

# Wait for sidecar
logger -t reset-runners "Waiting for sidecar initialization..."
sleep 15

# Deploy stacks
logger -t reset-runners "Deploying runner stacks..."
/usr/bin/docker stack deploy -c /home/elrey/actions-runner/jer-runner.yml jer_runner
check_command "JER runner deployment"

/usr/bin/docker stack deploy -c /home/elrey/actions-runner/ldc-runner.yml ldc_runner
check_command "LDC runner deployment"

logger -t reset-runners "Reset sequence completed successfully"
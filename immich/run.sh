#!/bin/bash
# Runner for Immich

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

if [[ " $@ " =~ " --clean " ]]; then
    echo ">> Cleaning init state..."
    rm -f "${INIT_FLAG}"
    rm -f ./docker-compose.yml
    rm -rf ./local/postgres-data
    rm -rf ./local/cache
fi

if [ ! -f "${INIT_FLAG}" ]; then
    echo ">> Not initialized, running init.sh..."
    source ./init.sh
    if [ ! -f "${INIT_FLAG}" ]; then
        echo ">> Initialization incomplete. Aborting."
        exit 1
    fi
    sleep 1
fi

# Remove existing containers if --force flag is used
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing immich containers..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
    docker compose down
fi

# Run docker compose
if [[ " $@ " =~ " --persist " ]]; then
    docker compose up -d
else
    docker compose up
fi

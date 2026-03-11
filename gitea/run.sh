#!/bin/bash
# Runner for Gitea (docker-compose)

source ../run-preprocess.tpl.sh

# Create local data directories if they don't exist
mkdir -p ./local/gitea
mkdir -p ./local/runner

# Process docker-compose.yml.tpl to substitute environment variables
if [ ! -f ./docker-compose.yml ]; then
    envsubst < ./docker-compose.yml.tpl > ./docker-compose.yml
fi

# Remove existing containers if --force flag is used
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing gitea containers..."
    docker compose down
fi

# Run docker compose
if [[ " $@ " =~ " --persist " ]]; then
    docker compose up -d
else
    docker compose up
fi


#!/bin/bash
# Runner for Paperless-ngx

source ../run-preprocess.tpl.sh

# Create .data directories if they don't exist
mkdir -p ./.data/data
mkdir -p ./.data/media
mkdir -p ./export
mkdir -p ./consume

# Process docker-compose.yml.tpl to substitute environment variables
# This ensures variables like ${NETWORK_NAME} are properly substituted
if [ -f ./docker-compose.yml.tpl ]; then
    # Create processed compose file in same directory
    envsubst < ./docker-compose.yml.tpl > ./docker-compose.yml
fi

# Remove existing containers if --force flag is used
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing paperless-ngx containers..."
    docker compose down
fi

# Run docker compose
if [[ " $@ " =~ " --persist " ]]; then
    docker compose up -d
else
    docker compose up
fi
#!/bin/bash
# Runner for Immich

source ../run-preprocess.tpl.sh

# Create .data directories if they don't exist
mkdir -p ./.data/model-cache
mkdir -p ./.data/postgres-data
mkdir -p ${UPLOAD_LOCATION}

# Process docker-compose.yml.tpl to substitute environment variables
# This ensures variables like ${NETWORK_NAME} are properly substituted
if [ -f ./docker-compose.yml.tpl ]; then
    # Source env files to make variables available for envsubst
    set -a
    [ -f public.env ] && source public.env
    [ -f .env ] && source .env
    set +a
    # Create processed compose file in same directory
    envsubst < ./docker-compose.yml.tpl > ./docker-compose.yml
fi

# Remove existing containers if --force flag is used
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing immich containers..."
    # Remove by container name first (in case of leftover containers from old setup)
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
    # Then use docker compose down
    docker compose down -v 2>/dev/null || true
fi

# Run docker compose
if [[ " $@ " =~ " --persist " ]]; then
    docker compose up -d
else
    docker compose up
fi

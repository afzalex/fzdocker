#!/bin/bash
# Runner for Grafana

source ../run-preprocess.tpl.sh

# Create .data directories if they don't exist
mkdir -p ./.data/grafana
if [ ! -f ./.data/prometheus.yml ]; then
    echo "Processing prometheus.yml.tpl..."
    mkdir -p ./.data/prometheus
    envsubst < ./prometheus.yml.tpl > ./.data/prometheus.yml
fi


# Process docker-compose.yml.tpl to substitute environment variables
# This ensures variables like ${NETWORK_NAME} are properly substituted
if [ ! -f ./docker-compose.yml ]; then
    # Create processed compose file in same directory
    envsubst < ./docker-compose.yml.tpl > ./docker-compose.yml
fi

# Remove existing containers if --force flag is used
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing grafana containers..."
    # Then use docker compose down
    docker compose down
fi

# Run docker compose
if [[ " $@ " =~ " --persist " ]]; then
    docker compose up -d
else
    docker compose up
fi

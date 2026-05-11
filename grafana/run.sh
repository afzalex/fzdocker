#!/bin/bash
# Runner for Grafana

source ../run-preprocess.tpl.sh


# Create local directory if it doesn't exist
mkdir -p ./local/prometheus
mkdir -p ./local/grafana

# Copy prometheus.yml.tpl to local directory if it doesn't exist
if [ ! -f ./local/prometheus.yml ]; then
    echo "Copying prometheus.yml.tpl to local..."
    envsubst < ./config/prometheus.yml.tpl > ./local/prometheus.yml
fi
if [ ! -f ./local/blackbox/blackbox.yml ]; then
    echo "Copying blackbox.yml.tpl to local..."
    envsubst < ./config/blackbox.yml.tpl > ./local/blackbox.yml
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

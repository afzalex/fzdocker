#!/bin/bash
source ../run-preprocess.tpl.sh

# Create .data directory if it doesn't exist
mkdir -p ./.data

# Remove existing container if running
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
fi

if [ ! -f ./.data/config.yaml ]; then
    echo "Copying config.yaml to .data..."
    mkdir -p ./.data/dex
    cat ./config.docker.yaml.tpl > ./.data/dex/config.docker.yaml
fi


docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    -v ./.data/dex/:/etc/dex/ \
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:5556"; fi) \
    dexidp/dex:latest-alpine


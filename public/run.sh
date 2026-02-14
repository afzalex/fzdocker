#!/bin/bash
# Runner for public

export DOCKER_IMAGE=caddy:latest

source ../run-preprocess.tpl.sh

# Create local directory if it doesn't exist
mkdir -p ./local

# Copy index.html to local/html if it doesn't exist
if [ ! -f ./local/config.yaml ] && [ -f ./config.yaml ]; then
    echo "Copying config.yaml to local..."
    mkdir -p ./local
    cp ./config.yaml ./local/config.yaml
fi


# Remove existing container if running
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
fi

docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    -p ${PORT_MAPPING}:80 \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    -v ./local/config.yaml:/usr/share/caddy/config.yaml \
    ${IMAGE_NAME}
    




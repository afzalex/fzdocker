#!/bin/bash
# Runner for SilverBullet

export DOCKER_IMAGE=ghcr.io/silverbulletmd/silverbullet:latest

source ../run-preprocess.tpl.sh

# Create local directory for space if it doesn't exist
mkdir -p ./local/space

# Remove existing container if running
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
fi

docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    --add-host=host.docker.internal:host-gateway \
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:3000"; fi) \
    -v ./local/space:/space \
    -l traefik.enable=true \
    -l traefik.http.services.fzsilverbullet.loadbalancer.server.port=3000 \
    ${DOCKER_IMAGE}

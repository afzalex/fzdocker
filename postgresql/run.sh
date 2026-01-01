#!/bin/bash
# Runner for PostgreSQL

source ../run-preprocess.tpl.sh

# Create .data directory if it doesn't exist
mkdir -p ./.data/var/lib/postgresql/data

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
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:5432"; fi) \
    -v ./.data/var/lib/postgresql/data:/var/lib/postgresql/data \
    ${IMAGE_NAME}


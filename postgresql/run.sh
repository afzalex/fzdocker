#!/bin/bash
# Runner for PostgreSQL

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"
DATA_DIR="./local/var/lib/postgresql/data"

if [[ " $@ " =~ " --clean " ]]; then
    echo ">> Cleaning init state..."
    rm -f "${INIT_FLAG}"
    rm -f ./Dockerfile
    rm -rf "${DATA_DIR}"
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
    -v "${DATA_DIR}":/var/lib/postgresql/data \
    ${IMAGE_NAME}


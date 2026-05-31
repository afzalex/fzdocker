#!/bin/bash
# Runner for Node-RED

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

if [ ! -f "${INIT_FLAG}" ]; then
    echo ">> Not initialized, running init.sh..."
    ./init.sh
    if [ ! -f "${INIT_FLAG}" ]; then
        echo ">> Initialization incomplete. Aborting."
        exit 1
    fi
fi

mkdir -p "${DATA_DIR}"

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
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:1880"; fi) \
    -v "${DATA_DIR}:/data" \
    "${IMAGE_NAME}"

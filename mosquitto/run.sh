#!/bin/bash
# Runner for Mosquitto MQTT Broker

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

if [ ! -f "${INIT_FLAG}" ]; then
    echo ">> Not initialized, running init.sh..."
    ./init.sh
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
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:1883"; fi) \
    -p 9001:9001 \
    -v "${CONFIG_DIR}:/mosquitto/config" \
    "${IMAGE_NAME}"


#!/bin/bash
# Runner for the combined Aria2 + AriaNg container

source ../run-preprocess.tpl.sh

mkdir -p ./local/downloads
mkdir -p ./local/config

# Remove the current container and the legacy two-container deployment.
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container(s)..."
    docker rm -f "${CONTAINER_NAME}" "${CONTAINER_NAME}-aria2" 2>/dev/null || true
fi

exec docker run --name "${CONTAINER_NAME}" -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    -e PUID="$(id -u)" \
    -e PGID="$(id -g)" \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    -p "${PORT_MAPPING}:8080" \
    -p "${LISTEN_PORT_MAPPING}:${LISTEN_PORT}" \
    -p "${LISTEN_PORT_MAPPING}:${LISTEN_PORT}/udp" \
    -v "$(pwd)/local/config:/aria2/conf" \
    -v "$(pwd)/local/downloads:/aria2/data" \
    "${IMAGE_NAME}" \
    --conf-path=/aria2/conf/aria2.conf \
    --listen-port="${LISTEN_PORT}" \
    --dht-listen-port="${LISTEN_PORT}"

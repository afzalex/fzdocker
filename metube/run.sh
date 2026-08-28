#!/bin/bash
# Runner for MeTube

set -e

DOCKER_IMAGE=alexta69/metube:latest

source ../run-preprocess.tpl.sh

mkdir -p ./.data/downloads

if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
fi

runtime_flags=(--rm)
if [[ " $@ " =~ " --persist " ]]; then
    runtime_flags=(--restart unless-stopped -d)
fi

port_flags=()
if [ -n "${PORT_MAPPING}" ]; then
    port_flags=(-p "${PORT_MAPPING}:8081")
fi

exec docker run --name "${CONTAINER_NAME}" -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    "${runtime_flags[@]}" \
    --add-host=host.docker.internal:host-gateway \
    "${port_flags[@]}" \
    -v "$(pwd)/.data/downloads:/downloads" \
    "${DOCKER_IMAGE}"

#!/bin/bash
# Runner for Remark42

set -e

export DOCKER_IMAGE=ghcr.io/umputun/remark42:latest

source ../run-preprocess.tpl.sh

# Create the persistent Remark42 data directory if it does not exist.
mkdir -p ./local/var

required_variables=(
    SECRET
)

for variable in "${required_variables[@]}"; do
    if [ -z "${!variable}" ]; then
        echo ">> Error: ${variable} is not configured in remark42/.env"
        exit 1
    fi
done

# Remove the existing container when explicitly requested.
if [[ " $@ " =~ " --force " ]]; then
    echo ">> Removing existing ${CONTAINER_NAME} container..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
fi

docker run --name "${CONTAINER_NAME}" -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    --add-host=host.docker.internal:host-gateway \
    -v "$(pwd)/local/var:/srv/var" \
    -p ${PORT_MAPPING}:8080 \
    "${DOCKER_IMAGE}"


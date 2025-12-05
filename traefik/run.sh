#!/bin/bash
# Runner for traefik

source ../run-preprocess.tpl.sh

# Create .data directory if it doesn't exist
mkdir -p ./.data

echo "HOST_NAME: ${HOST_NAME}"
    
# Check if HOST_WORKDIR contains any non-yml files
if ls "${HOST_WORKDIR}"/* >/dev/null 2>&1 && find "${HOST_WORKDIR}" -type f ! -name "*.yml" -print -quit | grep -q .; then
    TRAEFIK_DYNAMIC_CONFIGS_DIR="./.data/dynamic"
    # Create dynamic directory if it doesn't exist
    mkdir -p "${TRAEFIK_DYNAMIC_CONFIGS_DIR}"
    # Add common.yml and other example config files if config directory is empty
    if ! ls "${TRAEFIK_DYNAMIC_CONFIGS_DIR}"/*.yml >/dev/null 2>&1; then
        cp config/commons.yml "${TRAEFIK_DYNAMIC_CONFIGS_DIR}/commons.yml"
        for file in config/*.example.yml; do
            cp "${file}" "${TRAEFIK_DYNAMIC_CONFIGS_DIR}/$(basename "${file/.example/}")"
        done
    fi
else
    TRAEFIK_DYNAMIC_CONFIGS_DIR="${HOST_WORKDIR}"
fi

echo "TRAEFIK_DYNAMIC_CONFIGS_DIR: ${TRAEFIK_DYNAMIC_CONFIGS_DIR}"

# Copy traefik.yml to .data directory if it doesn't exist
if [ ! -f "./.data/traefik.yml" ]; then
    cp config/traefik.yml ./.data/traefik.yml
fi

# Create certs directory if it doesn't exist
mkdir -p ./.data/certs

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
    -p ${PORT_MAPPING_SECURE}:443 \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    --add-host=host.docker.internal:host-gateway \
    -v ./.data/certs:/etc/traefik/certs \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ./.data/traefik.yml:/etc/traefik/traefik.yml \
    -v "${TRAEFIK_DYNAMIC_CONFIGS_DIR}":/etc/traefik/dynamic \
    ${CONTAINER_NAME} \
    --api.basePath=/dashboard
    




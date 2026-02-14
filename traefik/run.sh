#!/bin/bash
# Runner for traefik

export DOCKER_IMAGE=traefik:v3.6.8

source ../run-preprocess.tpl.sh

# Create local directory if it doesn't exist
mkdir -p ./local

echo "HOST_NAME: ${HOST_NAME}"
    
# Check if HOST_WORKDIR contains any non-yml files
if ls "${HOST_WORKDIR}"/* >/dev/null 2>&1 && find "${HOST_WORKDIR}" -type f ! -name "*.yml" -print -quit | grep -q .; then
    TRAEFIK_DYNAMIC_CONFIGS_DIR="./local/dynamic"
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

# Copy traefik.yml to local directory if it doesn't exist
if [ ! -f "./local/traefik.yml" ]; then
    cp config/traefik.yml ./local/traefik.yml
fi

# Create certs directory if it doesn't exist
mkdir -p ./local/certs

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
    -v ./local/certs:/etc/traefik/certs \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ./local/traefik.yml:/etc/traefik/traefik.yml \
    -v "${TRAEFIK_DYNAMIC_CONFIGS_DIR}":/etc/traefik/dynamic \
    ${DOCKER_IMAGE} \
    --api.basePath=/dashboard \
    --providers.docker=true \
    --providers.docker.exposedbydefault=false \
    --experimental.plugins.traefikoidc.modulename=github.com/lukaszraczylo/traefikoidc \
    --experimental.plugins.traefikoidc.version=v0.7.10


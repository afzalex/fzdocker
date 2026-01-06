#!/bin/bash
# Runner for DNSmasq

source ../run-preprocess.tpl.sh

# Create .data directory if it doesn't exist
mkdir -p ./.data

# Process template file if it exists and .data/dnsmasq.conf doesn't exist
if [ -f ./dnsmasq.conf.tpl ] && [ ! -f ./.data/dnsmasq.conf ]; then
    echo "Processing dnsmasq.conf.tpl..."
    # Source env files to make variables available for envsubst
    set -a
    [ -f public.env ] && source public.env
    [ -f .env ] && source .env
    set +a
    envsubst < ./dnsmasq.conf.tpl > ./.data/dnsmasq.conf
fi

# Remove existing container if running
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
fi

# DNSmasq typically requires NET_ADMIN capability and may need host network
# Adjust the network configuration based on your needs
docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    --env-file "public.env" \
    --env-file ".env" \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:53/udp -p ${PORT_MAPPING}:53/tcp"; fi) \
    $(if [ -f ./.data/dnsmasq.conf ]; then echo "-v $(pwd)/.data/dnsmasq.conf:/etc/dnsmasq.conf:ro"; fi) \
    ${IMAGE_NAME}


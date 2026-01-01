#!/bin/bash
# Runner for RedisInsight

export ENVRIONMENT_PREFIX="FZREDISINSIGHT"

source ../run-preprocess.tpl.sh

# Create .data directory if it doesn't exist
mkdir -p ./.data

# Remove existing container if running
if [[ " $@ " =~ " --force " ]]; then
    echo ">> Removing existing ${CONTAINER_NAME} container..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
fi

docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    -p ${PORT_MAPPING}:5540 \
    -v ./.data:/data \
    ${IMAGE_NAME}


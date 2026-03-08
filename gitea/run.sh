#!/bin/bash
# Runner for Gitea

source ../run-preprocess.tpl.sh

mkdir -p ./local/gitea

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
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:3000"; fi) \
    $(if [ ! -z "${SSH_PORT_MAPPING}" ]; then echo "-p ${SSH_PORT_MAPPING}:22"; fi) \
    -v ./local/gitea:/data \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    docker.gitea.com/gitea:1.24.2


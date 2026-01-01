#!/bin/bash
source ../run-preprocess.tpl.sh

docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    -p ${PORT_MAPPING}:4180 --rm \
    --add-host $(hostname):192.168.29.114 \
    ${IMAGE_NAME}


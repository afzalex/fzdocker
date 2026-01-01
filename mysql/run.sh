#!/bin/bash
# Runner for mysql

source ../run-preprocess.tpl.sh

docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    -v ./.data/var/lib/mysql:/var/lib/mysql \
    -p ${PORT_MAPPING}:3306 --rm \
    ${IMAGE_NAME}
#!/bin/bash
# Runner for Apache Guacamole

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

if [ ! -f "${INIT_FLAG}" ]; then
    echo ">> Not initialized, running init.sh..."
    ./init.sh
    if [ ! -f "${INIT_FLAG}" ]; then
        echo ">> Initialization incomplete. Aborting."
        exit 1
    fi
fi

mkdir -p "${POSTGRES_DATA_LOCATION}" "${INIT_SQL_DIR}" ./local/drive ./local/record

if [ ! -f ./docker-compose.yml ]; then
    envsubst < ./docker-compose.yml.tpl > ./docker-compose.yml
fi

if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing guacamole containers..."
    docker rm -f ${CONTAINER_NAME} ${CONTAINER_NAME}-guacd ${CONTAINER_NAME}-postgres 2>/dev/null || true
    docker compose down 2>/dev/null || true
fi

if [[ " $@ " =~ " --persist " ]]; then
    docker compose up -d
else
    docker compose up
fi

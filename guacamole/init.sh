#!/bin/bash
# Initialize Guacamole PostgreSQL schema (run once before first stack start)

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"
INIT_SQL="${INIT_SQL_DIR}/initdb.sql"

mkdir -p "${POSTGRES_DATA_LOCATION}" "${INIT_SQL_DIR}" ./local/drive ./local/record

if [ -f "${INIT_SQL}" ]; then
    echo ">> ${INIT_SQL} already exists"
else
    echo ">> Generating Guacamole PostgreSQL schema at ${INIT_SQL}..."
    docker run --rm "${IMAGE_GUACAMOLE}" /opt/guacamole/bin/initdb.sh --postgresql > "${INIT_SQL}"
    echo ">> Schema written to ${INIT_SQL}"
fi

mkdir -p ./local
touch "${INIT_FLAG}"
echo ">> Guacamole initialized. Start with ./run.sh"

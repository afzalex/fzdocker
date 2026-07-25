#!/bin/bash
# Initialize Immich docker-compose.yml from template

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

# Create local directories
mkdir -p ./local/cache
mkdir -p ./local/postgres-data
mkdir -p ${UPLOAD_LOCATION}

# Prompt for database creation if IMMICH_CREATE_DATABASE is not set
if [ -z "${IMMICH_CREATE_DATABASE+x}" ]; then
    read -p "Do you want to create a PostgreSQL database container in Docker Compose? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        export IMMICH_CREATE_DATABASE=true
    else
        export IMMICH_CREATE_DATABASE=false
    fi
fi

db_create_value="$(printf '%s' "${IMMICH_CREATE_DATABASE}" | tr '[:upper:]' '[:lower:]')"
if [[ "${db_create_value}" =~ ^(1|true|yes|y)$ ]]; then
    export DATABASE_COMPOSE_SECTION="$(envsubst '$CONTAINER_NAME $NETWORK_NAME $DB_DATA_LOCATION' < ./include/database/compose-service)"
    export DATABASE_DEPENDS_ON="      - database"
    export DB_HOSTNAME="${DB_HOSTNAME:-database}"
    echo "PostgreSQL database container included."
else
    export DATABASE_COMPOSE_SECTION=""
    export DATABASE_DEPENDS_ON=""
    if [ -z "${DB_HOSTNAME}" ] || [ "${DB_HOSTNAME}" = "database" ]; then
        export DB_HOSTNAME="${DB_HOSTNAME_EXTERNAL:-fzpostgres}"
    fi
    echo "Using existing database at: ${DB_HOSTNAME}"
fi

# Prompt for Redis creation if IMMICH_CREATE_REDIS is not set
if [ -z "${IMMICH_CREATE_REDIS+x}" ]; then
    read -p "Do you want to create a Redis container in Docker Compose? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        export IMMICH_CREATE_REDIS=true
    else
        export IMMICH_CREATE_REDIS=false
    fi
fi

redis_create_value="$(printf '%s' "${IMMICH_CREATE_REDIS}" | tr '[:upper:]' '[:lower:]')"
if [[ "${redis_create_value}" =~ ^(1|true|yes|y)$ ]]; then
    export REDIS_COMPOSE_SECTION="$(envsubst '$REDIS_CONTAINER_NAME $NETWORK_NAME' < ./include/redis/compose-service)"
    export REDIS_DEPENDS_ON="      - redis"
    export REDIS_HOSTNAME="${REDIS_HOSTNAME:-redis}"
    echo "Redis container included."
else
    export REDIS_COMPOSE_SECTION=""
    export REDIS_DEPENDS_ON=""
    if [ -z "${REDIS_HOSTNAME}" ] || [ "${REDIS_HOSTNAME}" = "redis" ]; then
        export REDIS_HOSTNAME="${REDIS_HOSTNAME_EXTERNAL:-fzredis}"
    fi
    echo "Using existing Redis at: ${REDIS_HOSTNAME}"
fi

# Generate docker-compose.yml from template
# Only substitute public variables; secrets like DB_PASSWORD remain as placeholders
# and are resolved at runtime from .env
if [ -f ./docker-compose.yml.tpl ]; then
    public_vars=$(sed -n -E 's/^\s*([A-Za-z_][A-Za-z0-9_]*)=.*/\1/p' public.env | tr '\n' ' ' | sed 's/ *$//')
    all_vars="$public_vars DATABASE_COMPOSE_SECTION DATABASE_DEPENDS_ON DB_HOSTNAME REDIS_COMPOSE_SECTION REDIS_DEPENDS_ON REDIS_HOSTNAME"
    envsubst "$(printf '$%s ' $all_vars)" < ./docker-compose.yml.tpl > ./docker-compose.yml
    echo "Created docker-compose.yml from template."
fi

# Mark initialization complete
mkdir -p "$(dirname "${INIT_FLAG}")"
touch "${INIT_FLAG}"
echo "Immich initialization complete."

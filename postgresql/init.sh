#!/bin/bash
# Initialize PostgreSQL Dockerfile and local state

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

# Create local data directory if it doesn't exist
mkdir -p ./local/var/lib/postgresql/data

# Define Dockerfile template variables
export POSTGRES_TAG=${POSTGRES_TAG:-17-bookworm}

# Prompt for pgvector if not already set
if [ -z "${POSTGRES_ENABLE_PGVECTOR+x}" ]; then
    read -p "Do you want to install pgvector support? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        export POSTGRES_ENABLE_PGVECTOR=true
    else
        export POSTGRES_ENABLE_PGVECTOR=false
    fi
fi

# Load pgvector Dockerfile snippets if enabled
export PGVECTOR_DOCKERFILE_PRE="" PGVECTOR_DOCKERFILE_POST=""
pgvector_value="$(printf '%s' "${POSTGRES_ENABLE_PGVECTOR}" | tr '[:upper:]' '[:lower:]')"
if [[ "${pgvector_value}" =~ ^(1|true|yes|y)$ ]]; then
    export PGVECTOR_DOCKERFILE_PRE="$(cat ./include/pgvector/dockerfile-pre)"
    export PGVECTOR_DOCKERFILE_POST="$(cat ./include/pgvector/dockerfile-post)"
    echo "pgvector support enabled."
else
    echo "pgvector support skipped."
fi

# Generate Dockerfile from Dockerfile.tpl if needed
if [ -f ./Dockerfile.tpl ]; then
    envsubst < ./Dockerfile.tpl > ./Dockerfile
    echo "Created Dockerfile from Dockerfile.tpl"
fi

echo ">> Building image ${IMAGE_NAME} from Dockerfile..."
docker build -t "${IMAGE_NAME}" .

# Mark initialization complete
mkdir -p "$(dirname "${INIT_FLAG}")"
touch "${INIT_FLAG}"
echo "PostgreSQL initialization complete."

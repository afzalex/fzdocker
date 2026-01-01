#!/bin/bash

export IMMICH_IMAGE_PROCESSING_NAME="fzimmich-image-processing"
export IMMICH_POSTGRES_NAME="fzimmich-postgres"

source ../run-preprocess.tpl.sh

# Create .data directories if they don't exist
mkdir -p ./.data/data
mkdir -p ./.data/postgres-data

# Remove existing container if running
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
    docker rm -f ${IMMICH_IMAGE_PROCESSING_NAME} 2>/dev/null || true
    docker rm -f ${IMMICH_POSTGRES_NAME} 2>/dev/null || true
fi

# Start postgres database
docker run -d \
  --name ${IMMICH_POSTGRES_NAME} \
  --network "${NETWORK_NAME}" \
  --shm-size=128m \
  -e POSTGRES_PASSWORD=${DB_PASSWORD} \
  -e POSTGRES_USER=${DB_USERNAME} \
  -e POSTGRES_DB=${DB_DATABASE_NAME} \
  -e POSTGRES_INITDB_ARGS='--data-checksums' \
  -v ./.data/postgres-data:/var/lib/postgresql/data \
  ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23

# Start image processing service
docker run -d \
  --name ${IMMICH_IMAGE_PROCESSING_NAME} \
  --network "${NETWORK_NAME}" \
  --env-file "public.env" \
  --env-file ".env" \
  -v ./.data/model-cache:/cache \
  ghcr.io/immich-app/immich-machine-learning:$IMMICH_VERSION



# Wait for postgres container to be running
echo "Waiting for postgres to start..."
while ! docker ps --format '{{.Names}}' | grep -q "^${IMMICH_POSTGRES_NAME}$"; do
  sleep 1
done
echo "Postgres is running"

# Start immich server
docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    -e DB_HOSTNAME=${IMMICH_POSTGRES_NAME} \
    -e IMMICH_MACHINE_LEARNING_URL=http://${IMMICH_IMAGE_PROCESSING_NAME}:3003 \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    --add-host=host.docker.internal:host-gateway \
    $(if [ ! -z "${PORT_MAPPING}" ]; then echo "-p ${PORT_MAPPING}:2283"; fi) \
    -v ./.data/data:/data \
    ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}



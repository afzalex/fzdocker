#
# WARNING: To install Immich, follow our guide: https://docs.immich.app/install/docker-compose
#
# Make sure to use the docker-compose.yml of the current release:
#
# https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
#
# The compose file on main may not be compatible with the latest release.

name: fzimmich

services:
  immich-server:
    container_name: ${CONTAINER_NAME}
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    restart: unless-stopped
    networks:
      - ${NETWORK_NAME}
    # extends:
    #   file: hwaccel.transcoding.yml
    #   service: cpu # set to one of [nvenc, quicksync, rkmpp, vaapi, vaapi-wsl] for accelerated transcoding
    volumes:
      - ${UPLOAD_LOCATION}:/data
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - public.env
      - .env
    environment:
      DB_HOSTNAME: database
      IMMICH_MACHINE_LEARNING_URL: http://immich-machine-learning:3003
    ports:
      - "${PORT_MAPPING:-2283}:2283"
    depends_on:
      - database
      - immich-machine-learning
    healthcheck:
      disable: false

  immich-machine-learning:
    # For hardware acceleration, add one of -[armnn, cuda, rocm, openvino, rknn] to the image tag.
    # Example tag: ${IMMICH_VERSION:-release}-cuda
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    restart: unless-stopped
    networks:
      - ${NETWORK_NAME}
    # extends: # uncomment this section for hardware acceleration - see https://docs.immich.app/features/ml-hardware-acceleration
    #   file: hwaccel.ml.yml
    #   service: cpu # set to one of [armnn, cuda, rocm, openvino, openvino-wsl, rknn] for accelerated inference - use the `-wsl` version for WSL2 where applicable
    volumes:
      - ./.data/model-cache:/cache
    env_file:
      - public.env
      - .env
    healthcheck:
      disable: false

  database:
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23
    restart: unless-stopped
    networks:
      - ${NETWORK_NAME}
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: '--data-checksums'
      # Uncomment the DB_STORAGE_TYPE: 'HDD' var if your database isn't stored on SSDs
      # DB_STORAGE_TYPE: 'HDD'
    volumes:
      - ./.data/postgres-data:/var/lib/postgresql/data
    shm_size: 128mb

networks:
  ${NETWORK_NAME}:
    external: true

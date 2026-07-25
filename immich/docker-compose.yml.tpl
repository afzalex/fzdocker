#
# WARNING: To install Immich, follow our guide: https://docs.immich.app/install/docker-compose
#
# Make sure to use the docker-compose.yml of the current release:
#
# https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
#
# The compose file on main may not be compatible with the latest release.

name: ${CONTAINER_NAME}

services:
  immich-server:
    container_name: ${CONTAINER_NAME}
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    restart: unless-stopped
    networks: [${NETWORK_NAME}]
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
      DB_HOSTNAME: ${DB_HOSTNAME}
      IMMICH_MACHINE_LEARNING_URL: http://immich-machine-learning:3003
      # IMMICH_MACHINE_LEARNING_URL: http://immich-ml-gateway:3003
      REDIS_HOSTNAME: ${REDIS_HOSTNAME}
    ports:
      - "${PORT_MAPPING:-2283}:2283"
    depends_on:
      - immich-machine-learning
${DATABASE_DEPENDS_ON}
${REDIS_DEPENDS_ON}
    healthcheck:
      disable: false

  immich-machine-learning:
    container_name: ${CONTAINER_NAME}-machine-learning
    # For hardware acceleration, add one of -[armnn, cuda, rocm, openvino, rknn] to the image tag.
    # Example tag: ${IMMICH_VERSION:-release}-cuda
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    restart: unless-stopped
    networks: [${NETWORK_NAME}]
    # extends: # uncomment this section for hardware acceleration - see https://docs.immich.app/features/ml-hardware-acceleration
    #   file: hwaccel.ml.yml
    #   service: cpu # set to one of [armnn, cuda, rocm, openvino, openvino-wsl, rknn] for accelerated inference - use the `-wsl` version for WSL2 where applicable
    volumes:
      - ./local/cache:/cache
    env_file:
      - public.env
      - .env
    healthcheck:
      disable: false

${DATABASE_COMPOSE_SECTION}

${REDIS_COMPOSE_SECTION}

  # immich-ml-gateway:
  #   image: haproxy:2.9
  #   container_name: immich-ml-gateway
  #   networks: [${NETWORK_NAME}]
  #   volumes:
  #     - ./local/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
  #   restart: unless-stopped

networks:
  ${NETWORK_NAME}:
    external: true

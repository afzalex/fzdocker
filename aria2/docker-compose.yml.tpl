name: ${CONTAINER_NAME}

services:
  aria2:
    image: p3terx/aria2-pro:latest
    container_name: ${CONTAINER_NAME}-aria2
    networks: [${NETWORK_NAME}]
    env_file:
      - public.env
      - .env
    environment:
      - PUID=${UID}
      - PGID=${GID}
    volumes:
      - ./local/config:/config
      - ./local/downloads:/downloads
    ports:
      - ${RPC_PORT_MAPPING}:${RPC_PORT}
      - ${LISTEN_PORT_MAPPING}:${LISTEN_PORT}
      - ${LISTEN_PORT_MAPPING}:${LISTEN_PORT}/udp
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: 1m

  ariang:
    image: p3terx/ariang:latest
    container_name: ${CONTAINER_NAME}
    networks: [${NETWORK_NAME}]
    command: --port 6880
    depends_on:
      - aria2
    volumes:
      - ./local/AriaNg:/AriaNg:ro
    ports:
      - ${PORT_MAPPING}:6880
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: 1m

networks:
  ${NETWORK_NAME}:
    external: true

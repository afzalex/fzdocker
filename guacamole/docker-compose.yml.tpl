name: ${CONTAINER_NAME}

services:
  guacd:
    container_name: ${CONTAINER_NAME}-guacd
    image: ${IMAGE_GUACD}
    restart: unless-stopped
    networks: [${NETWORK_NAME}]
    volumes:
      - ./local/drive:/drive:rw
      - ./local/record:/record:rw

  postgres:
    container_name: ${CONTAINER_NAME}-postgres
    image: ${IMAGE_POSTGRES}
    restart: unless-stopped
    networks: [${NETWORK_NAME}]
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ${POSTGRES_DATA_LOCATION}:/var/lib/postgresql/data
      - ${INIT_SQL_DIR}:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 12
      start_period: 30s

  guacamole:
    container_name: ${CONTAINER_NAME}
    image: ${IMAGE_GUACAMOLE}
    restart: unless-stopped
    networks: [${NETWORK_NAME}]
    env_file:
      - public.env
      - .env
    environment:
      GUACD_HOSTNAME: guacd
      POSTGRES_HOSTNAME: postgres
      POSTGRES_DATABASE: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${PORT_MAPPING}:8080"
    depends_on:
      postgres:
        condition: service_healthy
      guacd:
        condition: service_started

networks:
  ${NETWORK_NAME}:
    external: true

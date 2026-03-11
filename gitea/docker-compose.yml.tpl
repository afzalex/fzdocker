name: ${CONTAINER_NAME}

services:
  gitea:
    container_name: ${CONTAINER_NAME}
    image: docker.gitea.com/gitea:1.24.2
    restart: unless-stopped
    networks: [${NETWORK_NAME}]
    env_file:
      - public.env
      - .env
    volumes:
      - ./local/gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "${PORT_MAPPING:-3000}:3000"
      - "${SSH_PORT_MAPPING:-2222}:22"
    extra_hosts:
      - "host.docker.internal:host-gateway"

  runner:
    container_name: ${CONTAINER_NAME}-runner
    image: docker.io/gitea/act_runner:nightly
    restart: unless-stopped
    networks: [${NETWORK_NAME}]
    depends_on:
      - gitea
    env_file:
      - public.env
      - .env
    environment:
      - CONFIG_FILE=/config.yaml
      - GITEA_INSTANCE_URL=${GITEA_INSTANCE_URL:?GITEA_INSTANCE_URL not set}
      - GITEA_RUNNER_REGISTRATION_TOKEN=${GITEA_RUNNER_REGISTRATION_TOKEN:?GITEA_RUNNER_REGISTRATION_TOKEN not set}
      - GITEA_RUNNER_NAME=${GITEA_RUNNER_NAME:?GITEA_RUNNER_NAME not set}
      - GITEA_RUNNER_LABELS=${GITEA_RUNNER_LABELS:?GITEA_RUNNER_LABELS not set}
    volumes:
      - ./local/runner/config.yaml:/config.yaml
      - ./local/runner/data:/data
      - /var/run/docker.sock:/var/run/docker.sock

networks:
  ${NETWORK_NAME}:
    external: true


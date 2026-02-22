name: ${CONTAINER_NAME}

services:
  prometheus:
    image: prom/prometheus:latest
    user: "${UID}:${GID}"
    networks: [${NETWORK_NAME}]
    container_name: ${CONTAINER_NAME}-prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --storage.tsdb.retention.time=7d
      # optional: cap size too (uncomment if you want)
      # - --storage.tsdb.retention.size=5GB
    volumes:
      - .data/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      # - ${CONTAINER_NAME}-prometheus-data:/prometheus
      - ./.data/prometheus:/prometheus
    # expose to host only if you want to open Prometheus UI directly
    # ports:
    #   - "9090:9090"
    restart: unless-stopped
    # optional resource guardrails
    deploy:
      resources:
        limits:
          memory: 700M

  node-exporter:
    image: quay.io/prometheus/node-exporter:latest
    networks: [${NETWORK_NAME}]
    container_name: ${CONTAINER_NAME}-node-exporter
    pid: host
    command:
      - --path.rootfs=/host
    volumes:
      - /:/host:ro,rslave
    # ports:
    #   - "9100:9100"
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 128M
  cadvisor:
    image: ghcr.io/google/cadvisor:0.56.2
    networks: [${NETWORK_NAME}]
    container_name: ${CONTAINER_NAME}-cadvisor
    privileged: true
    # cgroupns: host
    devices:
      - /dev/kmsg:/dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
      - /var/lib/docker:/var/lib/docker:ro
      - /dev/disk:/dev/disk:ro
    # ports:
    #   - 8080
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    networks: [${NETWORK_NAME}]
    container_name: ${CONTAINER_NAME}
    user: "${UID}:${GID}"
    env_file:
      - public.env
      - .env
    volumes:
      - ./.data/grafana:/var/lib/grafana
    ports:
      - ${PORT_MAPPING}:3000
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 500M

networks:
  ${NETWORK_NAME}:
    external: true


volumes:
  ${CONTAINER_NAME}-prometheus-data:


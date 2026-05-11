global:
  scrape_interval: 30s
  evaluation_interval: 30s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["${CONTAINER_NAME}-prometheus:9090"]

  - job_name: "node"
    static_configs:
      - targets: ["${CONTAINER_NAME}-node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["${CONTAINER_NAME}-cadvisor:8080"]

  - job_name: "blackbox-http"
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://fzpi.afzalex.com
          - https://immich.afzalex.com
          - https://finance.afzalex.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: "${CONTAINER_NAME}-blackbox-exporter:9115"

  - job_name: "blackbox-dns"
    metrics_path: /probe
    params:
      module: [dns_check]
    static_configs:
      - targets:
          - ${DNS_SERVER_1}
          - ${DNS_SERVER_2}
          - ${DNS_SERVER_3}
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: "${CONTAINER_NAME}-blackbox-exporter:9115"

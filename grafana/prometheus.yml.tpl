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

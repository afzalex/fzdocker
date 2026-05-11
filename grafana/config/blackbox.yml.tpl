modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_status_codes: [200, 301, 302]

  dns_check:
    prober: dns
    timeout: 5s
    dns:
      query_name: ${DNS_RECORD_NAME}
      query_type: A
      valid_rcodes:
        - NOERROR
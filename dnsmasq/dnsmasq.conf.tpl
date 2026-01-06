# Listen only on LAN interface (set this correctly: eth0 or wlan0)
interface=${DNSMASQ_INTERFACE}
bind-interfaces

# Upstream DNS (works when internet is up)
server=${DNSMASQ_UPSTREAM_DNS_1}
server=${DNSMASQ_UPSTREAM_DNS_2}
server=${DNSMASQ_UPSTREAM_DNS_3}

# Your local override (works even if internet is OFF)
address=/${DNSMASQ_LOCAL_DOMAIN}/${DNSMASQ_LOCAL_IP}

# DHCP range (only if YOU disable DHCP on Jio router)
# dhcp-range=${DNSMASQ_DHCP_RANGE_START},${DNSMASQ_DHCP_RANGE_END},${DNSMASQ_DHCP_NETMASK},${DNSMASQ_DHCP_LEASE_TIME}

# Gateway = Jio router
# dhcp-option=option:router,${DNSMASQ_GATEWAY}

# DNS handed to clients = this Pi
# dhcp-option=option:dns-server,${DNSMASQ_DNS_SERVER}

# (optional) log for debugging
# Uncomment the following lines if you want logging
log-queries
log-dhcp



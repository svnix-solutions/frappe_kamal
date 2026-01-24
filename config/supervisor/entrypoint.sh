#!/bin/bash
set -e

# Export environment variables for supervisor to use
export FRAPPE_SITE_NAME_HEADER="${FRAPPE_SITE_NAME_HEADER:-erp.example.com}"

# Hardcoded nginx settings (internal to container)
export BACKEND="127.0.0.1:8000"
export SOCKETIO="127.0.0.1:9000"
export UPSTREAM_REAL_IP_ADDRESS="127.0.0.1"
export UPSTREAM_REAL_IP_HEADER="X-Forwarded-For"
export UPSTREAM_REAL_IP_RECURSIVE="off"
export PROXY_READ_TIMEOUT="120"
export CLIENT_MAX_BODY_SIZE="50m"

echo "=== Starting ERPNext services ==="
echo "Site: ${FRAPPE_SITE_NAME_HEADER}"

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

#!/bin/bash
set -e

# Get site name from environment or use default
SITE_NAME="${FRAPPE_SITE_NAME_HEADER:-erp.example.com}"

# Check if site already exists - skip all setup if so
if [[ -d "sites/${SITE_NAME}" ]]; then
    echo "=== Site ${SITE_NAME} already exists, skipping configuration ==="
    exit 0
fi

# Fix ownership of mounted directories (they're created as root by Kamal)
if [[ $(id -u) -eq 0 ]]; then
    echo "Running as root, fixing permissions..."
    chown -R frappe:frappe /home/frappe/frappe-bench/sites
    chown -R frappe:frappe /home/frappe/frappe-bench/logs
    # Re-run this script as frappe user
    exec su frappe -c "$0"
fi

ls -1 apps > sites/apps.txt

# Create common_site_config.json if it doesn't exist
[[ -f sites/common_site_config.json ]] || echo "{}" > sites/common_site_config.json

# Configure bench settings
bench set-config -gp db_port "${DB_PORT:-3306}"
bench set-config -g db_host "${DB_HOST:-erpnext-db}"
bench set-config -g redis_cache "${REDIS_CACHE:-redis://erpnext-redis-cache:6379}"
bench set-config -g redis_queue "${REDIS_QUEUE:-redis://erpnext-redis-queue:6379}"
bench set-config -g redis_socketio "${REDIS_QUEUE:-redis://erpnext-redis-queue:6379}"
bench set-config -gp socketio_port "${SOCKETIO_PORT:-9000}"

echo "=== Site ${SITE_NAME} does not exist, creating... ==="

# Wait for MariaDB to be ready
echo "Waiting for database..."
for i in {1..60}; do
    if mariadb -h "${DB_HOST:-erpnext-db}" -P "${DB_PORT:-3306}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" &>/dev/null; then
        echo "Database is ready!"
        break
    fi
    echo "Waiting for database... ($i/60)"
    sleep 2
done

# Create new site
bench new-site "${SITE_NAME}" \
    --db-host="${DB_HOST:-erpnext-db}" \
    --db-port="${DB_PORT:-3306}" \
    --db-root-username=root \
    --db-root-password="${MYSQL_ROOT_PASSWORD}" \
    --admin-password="${ADMIN_PASSWORD}" \
    --mariadb-user-host-login-scope='%'

# Install all apps from the apps directory (excluding frappe which is always installed)
echo "=== Installing apps ==="
for app in $(ls apps | grep -v frappe); do
    echo "Installing app: ${app}"
    bench --site "${SITE_NAME}" install-app "${app}" || echo "Warning: Failed to install ${app}"
done

echo "=== Site ${SITE_NAME} created successfully ==="

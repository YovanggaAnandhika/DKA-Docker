#!/bin/sh
set -e

# Default upstream app
APP_SERVICE_HOST="${APP_SERVICE_HOST:-dka-product-pos-server-app}"
APP_SERVICE_PORT="${APP_SERVICE_PORT:-80}"

# Generate config dari template kalau ada
if [ -f /etc/nginx/conf.template.d/default.tpl ]; then
    echo "Generating /etc/nginx/conf.d/default.conf from template..."
    export APP_SERVICE_HOST APP_SERVICE_PORT
    envsubst '$APP_SERVICE_HOST $APP_SERVICE_PORT' \
        < /etc/nginx/conf.template.d/default.tpl \
        > /etc/nginx/conf.d/default.conf
fi

echo "Testing Nginx config..."
if ! nginx -t; then
    echo "========================================================"
    echo " NGINX CONFIG ERROR"
    echo " Container nggak dimatiin, nunggu biar bisa kamu debug."
    echo " Cek /etc/nginx/conf.d/default.conf atau log error."
    echo "========================================================"
    # Biar container tetap hidup buat remote debug
    tail -f /dev/null
fi

echo "Starting Nginx (HTTP/2 + HTTP/3-ready)..."
exec nginx;

#!/bin/bash
set -e

# Start PHP-FPM
echo "Starting PHP-FPM System..."
php-fpm83 -F &  # Jalankan PHP-FPM di latar belakang

# Start Nginx
echo "Starting Nginx System..."
nginx &  # Jalankan Nginx di latar belakang

# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    # If arguments exist, execute them
    exec "$@"
else
    # If no arguments were passed, wait for background processes
    echo "Logging Health Monitoring started ..."
    wait
fi

#!/bin/bash
set -e

# Memeriksa apakah file 'composer.json' ada
if [ -f "composer.json" ]; then
    echo "File 'composer.json' ditemukan, menjalankan composer install..."
    composer install
fi

# Start PHP-FPM and log output to console
echo "Starting PHP-FPM..."
php-fpm83 -F &

# Start Nginx and log output to console
echo "Starting Nginx..."
nginx &

# shellcheck disable=SC2198
if [ -z "$@" ]; then
    # If no arguments were passed to exec, run a fallback command
    exec tail -f /var/log/*/**.log
else
    # If arguments exist, execute them
    exec "$@"
fi
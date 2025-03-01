#!/bin/sh
set -e


# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    # If arguments exist, execute them
    exec "$@"
else
    # Start Nginx
    echo "Starting React Production with Nginx..."
    nginx  # Jalankan Nginx di latar belakang
fi
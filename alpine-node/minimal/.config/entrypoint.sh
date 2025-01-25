#!/bin/sh
set -e


# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    # If arguments exist, execute them
    exec "$@"
else
    # If no arguments were passed, check if package.json exists
    if [ -f "package.json" ]; then
        echo "Memulai Default Entry point main di package.json"
        node .
    else
        # If package.json doesn't exist, wait for background processes
        echo "package.json tidak ditemukan. Mulai Ulang Container dengan command. atau buat point di file package.json"
        tail -f /dev/null
    fi
fi
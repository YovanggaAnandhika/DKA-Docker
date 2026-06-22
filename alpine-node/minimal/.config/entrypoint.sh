#!/bin/sh
set -e

# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    # If arguments exist, execute them
    exec "$@"
else
    # If no arguments were passed, check if package.json exists
    if [ -f "package.json" ]; then
        echo "Starting default entry point main in package.json"
        if { [ -f "bun.lockb" ] || [ -f "bun.lock" ]; } && command -v bun >/dev/null 2>&1; then
            echo "⚡ Detected Bun lockfile. Running with Bun..."
            bun .
        else
            echo "🟢 Running with Node..."
            node .
        fi
    else
        # If package.json doesn't exist, wait for background processes
        echo "package.json not found. recreated container with command. or create main point field in package.json file"
        tail -f /dev/null
    fi
fi
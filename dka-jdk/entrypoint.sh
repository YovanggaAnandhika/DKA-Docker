#!/bin/bash
set -e


# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    # If arguments exist, execute them
    exec "$@"
else
    # If no arguments were passed, wait for background processes
    exec tail -f /dev/null
fi
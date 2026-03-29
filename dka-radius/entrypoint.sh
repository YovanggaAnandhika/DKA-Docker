#!/bin/sh

# Start NestJS API in the background
echo "Starting NestJS API..."
cd /app && node dist/main &

# Start FreeRADIUS in the foreground
echo "Starting FreeRADIUS..."
# -f: run in foreground
# -x: debug mode (optional, but good for logs)
# -l stdout: log to stdout
# /usr/sbin/radiusd -f -l stdout
radiusd -fl stdout

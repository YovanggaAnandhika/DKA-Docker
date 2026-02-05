#!/bin/bash
# DKA Research Center - Universal MongoDB Healthcheck
set -e

HOST="127.0.0.1"
PORT="27017"
USER="${DKA_MONGO_USERNAME:-root}"
PASS="${DKA_MONGO_PASSWORD:-123456789}"

run_mongo_cmd() {
    local cmd=$1
    # Menggunakan kredensial agar tidak ditolak oleh MongoDB (Security Enabled)
    mongosh --host "$HOST" --port "$PORT" \
            --username "$USER" --password "$PASS" \
            --authenticationDatabase admin \
            --quiet --eval "$cmd" 2>/dev/null
}

# --- LOGIKA UTAMA ---
# 1. Cek Liveness (Ping)
# Ini memastikan engine mongod merespons
ALIVE_CHECK=$(run_mongo_cmd "db.adminCommand('ping').ok")

if [[ "$ALIVE_CHECK" != *"1"* ]]; then
    echo "CRITICAL: MongoDB engine is not responding."
    exit 1
fi

# 2. Cek Readiness (Primary/Secondary status)
# Ini memastikan DB bukan dalam mode STARTUP/RECOVERING
READY_CHECK=$(run_mongo_cmd "let s=db.isMaster(); print(s.ismaster || s.secondary || s.isMaster)")

if [[ "$READY_CHECK" == *"true"* ]]; then
    echo "HEALTHY: MongoDB is alive and ready for connections."
    exit 0
else
    echo "WARN: MongoDB is alive but still initializing or in maintenance."
    exit 1
fi
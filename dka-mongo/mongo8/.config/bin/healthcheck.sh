#!/bin/bash
set -e

HOST="127.0.0.1"
PORT="27017"
USER="${DKA_MONGO_USERNAME:-root}"
PASS="${DKA_MONGO_PASSWORD}"
# Ambil variabel repl dari env agar sinkron dengan entrypoint
REPL_ENABLED="${DKA_REPL_ENABLED:-false}"

run_mongo_cmd() {
    local cmd=$1
    if ! mongosh --host "$HOST" --port "$PORT" --quiet --eval "$cmd" > /dev/null 2>&1; then
        mongosh --host "$HOST" --port "$PORT" \
                --username "$USER" --password "$PASS" \
                --authenticationDatabase admin \
                --quiet --eval "$cmd"
    else
        # Jika berhasil tanpa auth, kita kembalikan output aslinya
        mongosh --host "$HOST" --port "$PORT" --quiet --eval "$cmd" 2>/dev/null
    fi
}

case "$1" in
    readiness)
        if [ "$REPL_ENABLED" = "true" ]; then
            # Mode Replica Set: Harus Primary atau Secondary
            IS_READY=$(run_mongo_cmd "let s=db.isMaster(); print(s.ismaster || s.secondary)")
        else
            # Mode Standalone: Cukup cek apakah dia Master (selalu true jika standalone nyala)
            IS_READY=$(run_mongo_cmd "db.isMaster().ismaster")
        fi

        if [[ "$IS_READY" == *"true"* ]]; then
            exit 0
        else
            exit 1
        fi
        ;;

    liveness|*)
        # Liveness tetap sama untuk semua mode: cukup respon Ping
        IS_ALIVE=$(run_mongo_cmd "db.adminCommand('ping').ok")
        if [[ "$IS_ALIVE" == *"1"* ]]; then
            exit 0
        else
            exit 1
        fi
        ;;
esac
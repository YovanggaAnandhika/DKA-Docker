#!/bin/sh
set -e


export DKA_NAS_SECRET="${DKA_NAS_SECRET:-radius}"
export DKA_SERVER_REST_HOST="${DKA_SERVER_REST_HOST:-127.0.0.1}"
export DKA_SERVER_REST_PROTOCOL="${DKA_SERVER_REST_PROTOCOL:-http://}"
export DKA_SERVER_REST_ENDPOINT="${DKA_SERVER_REST_ENDPOINT:-/api/radius}"
export DKA_NAS_IP_ADDRESS="${DKA_NAS_IP_ADDRESS:-113.113.0.7}"
export DKA_NAS_TYPE="${DKA_NAS_TYPE:-Mikrotik}"
# Fungsi untuk memeriksa apakah server backend REST dapat dijangkau
check_backend() {
    # Gantilah dengan URL endpoint backend REST Anda
    # shellcheck disable=SC3043
    local DKA_SERVER_REST="${DKA_SERVER_REST_PROTOCOL}${DKA_SERVER_REST_HOST}${DKA_SERVER_REST_ENDPOINT}"  # Ubah URL sesuai endpoint backend Anda

    # Tunggu sampai backend dapat dijangkau
    until curl --silent --head "$DKA_SERVER_REST"; do
        echo "Rest Server Radius in ${DKA_SERVER_REST} Not Activated. Listening..."
        sleep 5  # Tunggu 5 detik sebelum mencoba lagi
    done

    echo "Rest Server Radius is reachable. Continue..."
}

# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    # If arguments exist, execute them
    exec "$@"
else
    # If no arguments were passed, wait for background processes
    check_backend
    radiusd -X
fi
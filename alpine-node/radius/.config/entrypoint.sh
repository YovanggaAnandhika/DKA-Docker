#!/bin/sh
set -e

export DKA_NAS_SECRET="${DKA_NAS_SECRET:-radius}"

# Fungsi untuk memonitor MariaDB dan restart jika gagal
watch_services() {
  while true; do
    # Memeriksa apakah node, radiusd berjalan
    if ! pgrep node > /dev/null || ! pgrep radiusd > /dev/null; then
      echo "Salah satu service berhenti. shutdown container ..."
      exit 1
    fi
    sleep 3
  done
}

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
    exec "$@" &
    check_backend
    radiusd -X &
    watch_services
else
    # If no arguments were passed, check if package.json exists
    if [ -f "package.json" ]; then
        echo "Memulai Default Entry point main di package.json"
        node . &
        check_backend
        radiusd -X &
        watch_services
    else
        # If package.json doesn't exist, wait for background processes
        echo "package.json tidak ditemukan. Mulai Ulang Container dengan command. atau buat point di file package.json"
        tail -f /dev/null
    fi
fi
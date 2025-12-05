#!/bin/sh

HOST=${DKA_SERVER_HOST:-127.0.0.1}
PORT=${DKA_SERVER_PORT:-80}

EP1="/up"
EP2="/"

check() {
  curl -fsS \
    --connect-timeout 1 \
    --max-time 3 \
    "http://$HOST:$PORT$1" >/dev/null 2>&1
}
# Jalanin dua cek sekaligus di background
check "$EP1" &
PID1=$!
check "$EP2" &
PID2=$!
# Tunggu keduanya satu-satu.
# Kalau salah satu sukses duluan → langsung exit 0 dan matiin yang lain.
for PID in "$PID1" "$PID2"; do
  if wait "$PID"; then
    # Ada yang sehat → kill proses cek lain (kalau masih hidup), lalu sukses
    kill "$PID1" "$PID2" 2>/dev/null
    exit 0
  fi
done
# Kalau dua-duanya gagal
exit 1

#!/bin/sh

# ==============================================================================
# DKA POSTGRESQL UNIVERSAL ENTRYPOINT (LXC, DOCKER, K8S READY)
# ==============================================================================

# --- 1. Konfigurasi Variabel & Jalur ---
HOSTNAME=$(hostname)
DATA_DIR="/var/lib/postgresql/data"
DEFAULT_CONFIG_PATH="$DATA_DIR/postgresql.conf"
DEFAULT_CONFIG_HBA_PATH="$DATA_DIR/pg_hba.conf"

# Konfigurasi Fitur & Database
ENABLED_CRON=${DKA_CRON_ENABLE:-false}
CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}
ROOT_USERNAME=${DKA_ROOT_USERNAME:-postgres}
ROOT_PASSWORD=${DKA_ROOT_PASSWORD:-postgres}
DB_NAME=${DKA_DB_NAME:-test}
DB_USERNAME=${DKA_DB_USERNAME:-test}
DB_PASSWORD=${DKA_DB_PASSWORD:-test}
DB_MAX_CONNECTION=${DKA_DB_MAX_CONNECTION:-200}

get_container_runtime() {
    if [ -d "/var/run/secrets/kubernetes.io" ]; then echo "KUBERNETES"
    elif [ -f /.dockerenv ]; then echo "DOCKER"
    elif grep -aq "container=lxc" /proc/1/environ 2>/dev/null; then echo "LXC"
    else echo "STANDALONE"; fi
}

# ==============================================================================
# --- 2. TAHAP ROOT: NETWORKING & PERMISSIONS ---
# ==============================================================================
if [ "$(id -u)" = '0' ]; then
  RUNTIME=$(get_container_runtime)
  echo "🛡️ [DKA] Runtime: $RUNTIME (Root Phase)"

  if [ "$RUNTIME" = "LXC" ]; then
    echo "📦 [LXC Mode] Dynamic Interface Activation..."

    # Bangunkan Loopback (Wajib untuk pg_isready)
    ip link set lo up 2>/dev/null || true

    # Pancing semua interface fisik agar UP (Mencegah status M-DOWN)
    for iface in $(ls /sys/class/net | grep -v lo); do
        echo "🔗 Powering up: $iface"
        ip link set "$iface" up 2>/dev/null || true
    done

    # Jalankan ifupdown-ng untuk memproses /etc/network/interfaces
    if command -v ifup >/dev/null; then
        echo "⚙️ Executing: ifup -a"
        ifup -a >/dev/null 2>&1 || true
    fi
  fi

  # Pastikan struktur folder dan izin akses tepat sebelum drop privilege
  mkdir -p /var/run/postgresql /run/postgresql "$DATA_DIR" /var/log/postgresql
  chown -R postgres:postgres /var/run/postgresql /run/postgresql "$DATA_DIR" /var/log/postgresql /etc/cron.d

  echo "👤 Dropping privileges to postgres user..."
  exec su-exec postgres "$0" "$@"
fi

# ==============================================================================
# --- 3. TAHAP USER POSTGRES: DATABASE LOGIC ---
# ==============================================================================

set_hba() {
  echo "host    all             all             0.0.0.0/0            scram-sha-256" >> "$DEFAULT_CONFIG_HBA_PATH"
  echo "host    all             all             ::/0                 scram-sha-256" >> "$DEFAULT_CONFIG_HBA_PATH"
}

set_memory() {
  PERCENT_MEMORY=0.8
  MEMORY_MAX=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
  if [ "$MEMORY_MAX" = "max" ] || [ -z "$MEMORY_MAX" ]; then
      MEMORY_MAX=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
      [ -z "$MEMORY_MAX" ] && MEMORY_MAX=$(free -b | grep Mem | awk '{print $2}')
  fi

  MEMORY_MAX=$(echo "$MEMORY_MAX * $PERCENT_MEMORY" | bc)
  MEMORY_MAX=$(printf "%.0f" "$MEMORY_MAX")
  MEMORY_MAX_MB=$((MEMORY_MAX / 1024 / 1024))

  SHARED_BUFFERS=$((MEMORY_MAX / 4 / 1024 / 1024))"MB"
  WORK_MEM=$((MEMORY_MAX / 4 / DB_MAX_CONNECTION / 1024))"kB"

  echo "📈 Memory detected: ${MEMORY_MAX_MB}MB. Setting shared_buffers to $SHARED_BUFFERS"

  sed -i "s|^\s*#*shared_buffers =.*|shared_buffers = $SHARED_BUFFERS|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*max_connections =.*|max_connections = $DB_MAX_CONNECTION|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*work_mem =.*|work_mem = $WORK_MEM|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*listen_addresses =.*|listen_addresses = '*'|g" "$DEFAULT_CONFIG_PATH"
}

checkPostgreSQLIsRunning(){
    TIMEOUT=60
    while [ $TIMEOUT -gt 0 ]; do
        # Gunakan Unix Socket path untuk kestabilan di LXC
        if pg_isready -h /run/postgresql -U "$ROOT_USERNAME" >/dev/null 2>&1; then
            echo "✅ PostgreSQL Server is ready."
            return 0
        fi
        echo "⏳ Waiting for PostgreSQL ($TIMEOUT)..."
        sleep 2
        TIMEOUT=$((TIMEOUT - 2))
    done
    exit 1
}

initiate_postgresql() {
  echo "🔄 Starting Temporary PostgreSQL..."
  pg_ctl start -D "$DATA_DIR" -l "$DATA_DIR/startup.log" &
  pid="$!"
  checkPostgreSQLIsRunning
}

set_users_and_grant() {
  # Logic sederhana untuk inject user/db
  echo "👤 Setting up database $DB_NAME for user $DB_USERNAME..."
  psql -U "$ROOT_USERNAME" -c "ALTER USER $ROOT_USERNAME WITH PASSWORD '$ROOT_PASSWORD';"
  psql -U "$ROOT_USERNAME" -c "CREATE USER $DB_USERNAME WITH PASSWORD '$DB_PASSWORD';"
  psql -U "$ROOT_USERNAME" -c "CREATE DATABASE $DB_NAME OWNER $DB_USERNAME;"
  psql -U "$ROOT_USERNAME" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;"
}

clear_postmaster_pid() {
  echo "🧹 Cleaning stale files..."
  rm -f "$DATA_DIR/postmaster.pid"
  rm -rf /run/postgresql/* 2>/dev/null || true
  mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql
}

# --- MAIN FLOW ---
echo "--- DKA POSTGRESQL STARTING ---"
clear_postmaster_pid

if [ ! -f "$DATA_DIR/DKA_POSTGRESQL_INIT" ]; then
    echo "🚀 First Run: Initiating database..."
    pg_ctl init -D "$DATA_DIR"
    initiate_postgresql
    set_users_and_grant

    echo "🛑 Shutting down temporary instance..."
    pg_ctl stop -D "$DATA_DIR"
    wait "$pid"

    set_memory
    set_hba
    touch "$DATA_DIR/DKA_POSTGRESQL_INIT"
else
    set_memory
fi

# Jalankan Cron jika ENABLED
if [ "$ENABLED_CRON" = "true" ]; then
  crond && echo "⏰ Cron active."
fi

echo "🚀 Running Final Postgres Engine..."
pg_ctl start -D "$DATA_DIR" -l "$DATA_DIR/main_server.log"
checkPostgreSQLIsRunning

# Graceful Shutdown Handler
shutdown_handler() {
  echo "🛑 Received shutdown signal! Stopping PostgreSQL..."
  pg_ctl stop -D "$DATA_DIR" -m fast
  exit 0
}
trap 'shutdown_handler' TERM INT

# Tail log agar container tetap hidup dan trap tertangkap
tail -f "$DATA_DIR/main_server.log" &
wait $!
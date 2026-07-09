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

# Auto maintenance / optimizer
MAINTENANCE_ENABLE=${DKA_MAINTENANCE_ENABLE:-false}
MAINTENANCE_CRON=${DKA_MAINTENANCE_CRON:-}
MAINTENANCE_AT=${DKA_MAINTENANCE_AT:-03:00}
MAINTENANCE_LOG=${DKA_MAINTENANCE_LOG:-/var/log/postgresql/maintenance.log}

get_container_runtime() {
    if [ -d "/var/run/secrets/kubernetes.io" ]; then echo "KUBERNETES"
    elif [ -f /.dockerenv ]; then echo "DOCKER"
    elif grep -aq "container=lxc" /proc/1/environ 2>/dev/null; then echo "LXC"
    else echo "STANDALONE"; fi
}

export_cron_file() {
  echo "Exporting cron files..."

  if [ "$ENABLED_CRON" = "true" ]; then
    for file in /usr/cron.d/*; do
      [ -f "$file" ] || continue
      cron_name=$(basename "$file")
      echo "${CRON_PRIODIC} root /bin/sh $file" > "/etc/cron.d/$cron_name"
    done
  fi

  if [ "$MAINTENANCE_ENABLE" = "true" ]; then
    if [ -n "$MAINTENANCE_CRON" ]; then
      schedule="$MAINTENANCE_CRON"
    else
      schedule=$(echo "$MAINTENANCE_AT" | awk -F: '{printf "%s %s * * *", $2, $1}')
    fi

    echo "${schedule} root /usr/local/bin/maintenance >> $MAINTENANCE_LOG 2>&1" > "/etc/cron.d/maintenance"
  fi
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

  # Optimasi chown: Hindari chown -R secara rekursif pada DATA_DIR jika sudah dimiliki oleh postgres (UID 70)
  # untuk mencegah startup delay/timeout pada volume basis data yang sangat besar.
  if [ "$(stat -c '%U' "$DATA_DIR" 2>/dev/null)" = 'postgres' ] || [ "$(stat -c '%u' "$DATA_DIR" 2>/dev/null)" = '70' ]; then
    chown postgres:postgres "$DATA_DIR"
  else
    chown -R postgres:postgres "$DATA_DIR"
  fi

  # Direktori sistem lainnya tetap chown -R karena ukurannya sangat kecil
  chown -R postgres:postgres /var/run/postgresql /run/postgresql /var/log/postgresql /etc/cron.d

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

  # 1. Alokasi Dasar
  SHARED_BUFFERS=$((MEMORY_MAX / 4 / 1024 / 1024))"MB"
  WORK_MEM=$((MEMORY_MAX / 4 / DB_MAX_CONNECTION / 1024))"kB"

  # 2. Perhitungan Lanjutan untuk Performa
  EFFECTIVE_CACHE_SIZE=$((MEMORY_MAX_MB * 3 / 4))"MB" # 75% dari alokasi memori
  MAINTENANCE_WORK_MEM=$((MEMORY_MAX_MB / 10))"MB"   # 10% dari alokasi memori (min 64MB)
  if [ $((MEMORY_MAX_MB / 10)) -lt 64 ]; then MAINTENANCE_WORK_MEM="64MB"; fi

  echo "📈 Memory detected: ${MEMORY_MAX_MB}MB. Tuning PostgreSQL for High Performance..."

  # --- Konfigurasi Dasar ---
  sed -i "s|^\s*#*shared_buffers =.*|shared_buffers = $SHARED_BUFFERS|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*max_connections =.*|max_connections = $DB_MAX_CONNECTION|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*work_mem =.*|work_mem = $WORK_MEM|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*listen_addresses =.*|listen_addresses = '*'|g" "$DEFAULT_CONFIG_PATH"

  # --- Optimasi Read (Baca) ---
  sed -i "s|^\s*#*effective_cache_size =.*|effective_cache_size = $EFFECTIVE_CACHE_SIZE|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*random_page_cost =.*|random_page_cost = 1.1|g" "$DEFAULT_CONFIG_PATH" # Asumsi menggunakan SSD

  # --- Optimasi Write (Tulis) & Checkpoint ---
  sed -i "s|^\s*#*maintenance_work_mem =.*|maintenance_work_mem = $MAINTENANCE_WORK_MEM|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*wal_buffers =.*|wal_buffers = 16MB|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*checkpoint_timeout =.*|checkpoint_timeout = 15min|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*checkpoint_completion_target =.*|checkpoint_completion_target = 0.9|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*max_wal_size =.*|max_wal_size = 2GB|g" "$DEFAULT_CONFIG_PATH"
  sed -i "s|^\s*#*min_wal_size =.*|min_wal_size = 1GB|g" "$DEFAULT_CONFIG_PATH"
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

if [ "$ENABLED_CRON" = "true" ] || [ "$MAINTENANCE_ENABLE" = "true" ]; then
  export_cron_file
  touch "$MAINTENANCE_LOG" 2>/dev/null || true
  chown postgres:postgres "$MAINTENANCE_LOG" 2>/dev/null || true
  crond && echo "⏰ Cron active."
  if [ "$MAINTENANCE_ENABLE" = "true" ]; then
    echo "🛠️ Auto maintenance enabled. Schedule: ${MAINTENANCE_CRON:-$MAINTENANCE_AT}" >> "$MAINTENANCE_LOG"
  fi
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
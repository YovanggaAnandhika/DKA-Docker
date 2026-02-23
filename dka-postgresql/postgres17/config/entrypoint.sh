#!/bin/sh

# --- 1. Konfigurasi Variabel ---
HOSTNAME=$(hostname)
DEFAULT_CONFIG_PATH=${DKA_CONFIG_PATH:-/var/lib/postgresql/data/postgresql.conf}
DEFAULT_CONFIG_HBA_PATH=${DKA_CONFIG_HBA_PATH:-/var/lib/postgresql/data/pg_hba.conf}

# Cron Env
ENABLED_CRON=${DKA_CRON_ENABLE:-false}
CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}

# Credentials
ROOT_USERNAME=${DKA_ROOT_USERNAME:-postgres}
ROOT_PASSWORD=${DKA_ROOT_PASSWORD:-postgres}
DB_NAME=${DKA_DB_NAME:-test}
DB_USERNAME=${DKA_DB_USERNAME:-test}
DB_PASSWORD=${DKA_DB_PASSWORD:-test}

DB_MAX_CONNECTION=${DKA_DB_MAX_CONNECTION:-200}

# --- 2. Fungsi Utilitas & Konfigurasi ---

set_hba() {
  echo "host    all             all             0.0.0.0/0            scram-sha-256" >> $DEFAULT_CONFIG_HBA_PATH
  echo "host    all             all             ::/0                 scram-sha-256" >> $DEFAULT_CONFIG_HBA_PATH
}

set_memory() {
  PERCENT_MEMORY=0.8
  MEMORY_MAX=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)

  if [ "$MEMORY_MAX" = "max" ] || [ -z "$MEMORY_MAX" ]; then
      MEMORY_MAX=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
      if [ -z "$MEMORY_MAX" ]; then
          MEMORY_MAX=$(free -b | grep Mem | awk '{print $2}')
      fi
  fi

  # Kalkulasi menggunakan bc
  MEMORY_MAX=$(echo "$MEMORY_MAX * $PERCENT_MEMORY" | bc)
  MEMORY_MAX=$(printf "%.0f" "$MEMORY_MAX")
  MEMORY_MAX_MB=$((MEMORY_MAX / 1024 / 1024))

  SHARED_BUFFERS=$((MEMORY_MAX / 4 / 1024 / 1024))"MB"
  WORK_MEM=$((MEMORY_MAX / 4 / DB_MAX_CONNECTION / 1024))"kB"

  echo "📈 Memory detected: ${MEMORY_MAX_MB}MB. Setting shared_buffers to $SHARED_BUFFERS"

  sed -i "s|^\s*shared_buffers = 128MB|shared_buffers = $SHARED_BUFFERS|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*max_connections = 100|max_connections = $DB_MAX_CONNECTION|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*#*work_mem\s*=.*|work_mem = $WORK_MEM|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*#*password_encryption = scram-sha-256|password_encryption = scram-sha-256|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*#*listen_addresses = 'localhost'|listen_addresses = '*'|g" $DEFAULT_CONFIG_PATH
}

checkPostgreSQLIsRunning(){
    TIMEOUT=60
    while [ $TIMEOUT -gt 0 ]; do
        if pg_isready -h localhost -U $ROOT_USERNAME >/dev/null 2>&1; then
            echo "✅ PostgreSQL Server is running and ready."
            return 0
        fi
        echo "⏳ Waiting for PostgreSQL to start ($TIMEOUT)..."
        sleep 2
        TIMEOUT=$((TIMEOUT - 2))
    done
    echo "❌ ERROR: PostgreSQL failed to start within timeout."
    exit 1
}

initiate_postgresql() {
  echo "🔄 Starting PostgreSQL Temporary..."
  pg_ctl start -D /var/lib/postgresql/data -l /var/lib/postgresql/data/startup.log &
  pid="$!"
  checkPostgreSQLIsRunning
}

set_users_and_grant() {
  TEMPLATE="/docker-entrypoint-initdb.d/create_users_and_grants.sql.tmpl"
  OUTPUT="/docker-entrypoint-initdb.d/create_users_and_grants.sql"

  if [ -f "$TEMPLATE" ]; then
    : > "$OUTPUT"
    i=1
    while :; do
      eval CUR_DB_NAME=\$DKA_DB_NAME_$i
      eval CUR_DB_USERNAME=\$DKA_DB_USERNAME_$i
      eval CUR_DB_PASSWORD=\$DKA_DB_PASSWORD_$i

      if [ "$i" -eq 1 ] && [ -z "$CUR_DB_NAME" ] && [ -n "$DB_NAME" ]; then
        CUR_DB_NAME="$DB_NAME"
        CUR_DB_USERNAME="$DB_USERNAME"
        CUR_DB_PASSWORD="$DB_PASSWORD"
      fi

      [ -z "$CUR_DB_NAME" ] && break

      echo "👤 Generating user & db: $CUR_DB_NAME ($CUR_DB_USERNAME)"
      sed -e "s|{{ROOT_PASSWORD}}|$ROOT_PASSWORD|g" \
          -e "s|{{DB_USERNAME}}|$CUR_DB_USERNAME|g" \
          -e "s|{{DB_PASSWORD}}|$CUR_DB_PASSWORD|g" \
          -e "s|{{DB_NAME}}|$CUR_DB_NAME|g" \
          "$TEMPLATE" >> "$OUTPUT"

      # Pastikan PostGIS terpasang otomatis untuk setiap DB yang dibuat
      PGPASSWORD=$ROOT_PASSWORD psql -U $ROOT_USERNAME -d $CUR_DB_NAME -c "CREATE EXTENSION IF NOT EXISTS postgis;" >/dev/null 2>&1

      echo "" >> "$OUTPUT"
      i=$((i+1))
    done
  else
    echo "⚠️ Template .tmpl tidak ditemukan. Menggunakan mode single-DB legacy."
    sed -i "s|{{ROOT_PASSWORD}}|$ROOT_PASSWORD|g; s|{{DB_USERNAME}}|$DB_USERNAME|g; s|{{DB_PASSWORD}}|$DB_PASSWORD|g; s|{{DB_NAME}}|$DB_NAME|g" "/docker-entrypoint-initdb.d/create_users_and_grants.sql"
  fi
}

load_init_sql_template() {
  if [ -d "/docker-entrypoint-initdb.d" ]; then
      # Urutkan file agar create_postgis_extensions.sql berjalan sebelum data
      for sql_file in $(ls /docker-entrypoint-initdb.d/*.sql | sort); do
          if [ -f "$sql_file" ]; then
              echo "📜 Running init script: $sql_file..."
              PGPASSWORD=$ROOT_PASSWORD psql -U $ROOT_USERNAME -f "$sql_file" >/dev/null 2>&1
          fi
      done
  fi
}

load_automation_sql_template() {
  if [ -d "/docker-entrypoint.d" ]; then
      for sql_file in /docker-entrypoint.d/*.sql; do
          if [ -f "$sql_file" ]; then
              echo "🤖 Running automation script: $sql_file..."
              PGPASSWORD=$ROOT_PASSWORD psql -U $ROOT_USERNAME -f "$sql_file"
          fi
      done
  fi
}

load_cron_scheduler(){
  if [ "$ENABLED_CRON" = "true" ]; then
    for file in /usr/cron.d/*; do
      if [ -x "$file" ]; then
        cron_name=$(basename "$file")
        echo "$CRON_PRIODIC /bin/bash $file >> /var/log/postgresql/cron.log 2>&1" > "/etc/cron.d/$cron_name"
      fi
    done
    crond
    echo "⏰ Cron scheduler active."
  fi
}

checkIsInitDB() {
  if [ ! -f "/var/lib/postgresql/data/DKA_POSTGRESQL_INIT" ]; then
      echo "🚀 First Run: Initiating system server..."
      pg_ctl init -D /var/lib/postgresql/data
      initiate_postgresql
      set_users_and_grant
      load_init_sql_template
      echo "🛑 Shutting down Temporary PostgreSQL..."
      pg_ctl stop -D /var/lib/postgresql/data
      wait "$pid"
      set_memory
      set_hba
      touch "/var/lib/postgresql/data/DKA_POSTGRESQL_INIT"
      echo "✅ Inisialisasi database selesai."
  else
      echo "ℹ️ Database already initiated. Skipping first run setup."
  fi
}

clear_postmaster_pid() {
  rm -f "/var/lib/postgresql/data/postmaster.pid"
  rm -f "/run/postgresql/.s.PGSQL.5432.lock"
}

# --- 3. Main Execution Flow ---

echo "--- DKA POSTGRESQL ENTRYPOINT STARTING ---"
clear_postmaster_pid

# Sangat Penting: Memastikan direktori socket tersedia untuk pg_isready
mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql

checkIsInitDB
load_cron_scheduler
logrotate -f /etc/logrotate.conf >/dev/null 2>&1

echo "📦 Starting Final Postgres Engine..."
# Menjalankan mesin utama
pg_ctl start -D /var/lib/postgresql/data -l /var/lib/postgresql/data/main_server.log
checkPostgreSQLIsRunning

load_automation_sql_template
echo "📊 Monitoring database logs..."

# Gunakan tail pada file log agar container tetap hidup dan log terlihat di docker logs
exec tail -f /var/lib/postgresql/data/main_server.log
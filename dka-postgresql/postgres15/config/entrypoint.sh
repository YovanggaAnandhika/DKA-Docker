#!/bin/sh

HOSTNAME=$(hostname)
DEFAULT_CONFIG_PATH=${DKA_CONFIG_PATH:-/var/lib/postgresql/data/postgresql.conf}
DEFAULT_CONFIG_HBA_PATH=${DKA_CONFIG_HBA_PATH:-/var/lib/postgresql/data/pg_hba.conf}
# Cron Env
ENABLED_CRON=${DKA_CRON_ENABLE:-false}
CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}
# Set default values if environment variables are not provided
ROOT_PASSWORD=${DKA_ROOT_PASSWORD:-postgres}
DB_NAME=${DKA_DB_NAME:-test}
DB_USERNAME=${DKA_DB_USERNAME:-test}
DB_PASSWORD=${DKA_DB_PASSWORD:-test}

DB_MAX_CONNECTION=${DKA_DB_MAX_CONNECTION:-200}

set_hba() {
  # Mengizinkan koneksi dari semua host untuk semua database dan user menggunakan MD5
  echo "host    all             all             0.0.0.0/0            scram-sha-256" >> $DEFAULT_CONFIG_HBA_PATH
  echo "host    all             all             ::/0                 scram-sha-256" >> $DEFAULT_CONFIG_HBA_PATH
}

set_memory() {
  # PERCENT_MEMORY sebagai persentase
  PERCENT_MEMORY=0.8
  # Membaca nilai memory.max dalam byte
  MEMORY_MAX=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
  # Cek jika nilai memory.max adalah "max" atau kosong
  # shellcheck disable=SC3014
  if [ "$MEMORY_MAX" == "max" ] || [ -z "$MEMORY_MAX" ]; then
      echo "memory.max not exist. check with memory.limit_in_bytes ..."
      MEMORY_MAX=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
      # Jika memory.limit_in_bytes juga tidak ada, gunakan total memori host
      if [ -z "$MEMORY_MAX" ]; then
          echo "limit max memory not exist. fallback use host max memory"
          MEMORY_MAX=$(free -b | grep Mem | awk '{print $2}')
      fi
  fi

  # Mengalikan MEMORY_MAX dengan PERCENT_MEMORY menggunakan bc
  MEMORY_MAX=$(echo "$MEMORY_MAX * $PERCENT_MEMORY" | bc)
  # Membulatkan hasil ke bawah menjadi bilangan bulat
  MEMORY_MAX=$(printf "%.0f" "$MEMORY_MAX")
  # Mengonversi nilai byte ke MB
  MEMORY_MAX_MB=$((MEMORY_MAX / 1024 / 1024))
  # Menambahkan akhiran 'M' untuk format MB
  MEMORY_MAX_MB="${MEMORY_MAX_MB}M"
  echo "Limit memory is $MEMORY_MAX_MB. detected";

  # Mengatur shared_buffers di PostgreSQL
  SHARED_BUFFERS=$((MEMORY_MAX / 4 / 1024 / 1024))
  SHARED_BUFFERS="${SHARED_BUFFERS}MB"

  # Hitung work_mem dalam kB
  WORK_MEM=$((MEMORY_MAX / 4 / DB_MAX_CONNECTION / 1024))
  WORK_MEM="${WORK_MEM}kB"

  # Mengganti shared_buffers dengan nilai dari variabel SHARED_BUFFERS
  sed -i "s|^\s*shared_buffers = 128MB|shared_buffers = $SHARED_BUFFERS|g" $DEFAULT_CONFIG_PATH
  # Mengganti max_connection dengan nilai dari variabel $DB_MAX_CONNECTION
  sed -i "s|^\s*max_connections = 100|max_connections = $DB_MAX_CONNECTION|g" $DEFAULT_CONFIG_PATH
  # Ganti work_mem
  sed -i "s|^\s*#*work_mem\s*=.*|work_mem = $WORK_MEM|g" $DEFAULT_CONFIG_PATH
  # Menghapus komentar dari password_encryption
  sed -i "s|^\s*#*password_encryption = scram-sha-256|password_encryption = scram-sha-256|g" $DEFAULT_CONFIG_PATH
  # Mengganti listen_addresses agar PostgreSQL mendengarkan koneksi dari semua alamat IP
  sed -i "s|^\s*#*listen_addresses = 'localhost'|listen_addresses = '*'|g" $DEFAULT_CONFIG_PATH

}

checkPostgreSQLIsRunning(){
  # Wait for PostgreSQL to start
    until pg_isready >/dev/null 2>&1; do
        echo "Waiting for PostgreSQL to start..."
        sleep 2
    done
    echo "PostgreSQL Server Is Running..."
}

# Fungsi untuk memulai PostgreSQL
initiate_postgresql() {
  echo "Starting PostgreSQL Temporary..."
  pg_ctl start -D /var/lib/postgresql/data &
  pid="$!"
  checkPostgreSQLIsRunning
}

set_users_and_grant() {
  TEMPLATE="/docker-entrypoint-initdb.d/create_users_and_grants.sql.tmpl"
  OUTPUT="/docker-entrypoint-initdb.d/create_users_and_grants.sql"

  # Jika .tmpl ada → generate file final
  if [ -f "$TEMPLATE" ]; then
    : > "$OUTPUT"  # kosongkan file final

    i=1
    while :; do
      eval CUR_DB_NAME=\$DKA_DB_NAME_$i
      eval CUR_DB_USERNAME=\$DKA_DB_USERNAME_$i
      eval CUR_DB_PASSWORD=\$DKA_DB_PASSWORD_$i

      # fallback: kalau gak ada index, tapi ada single DB klasik
      if [ "$i" -eq 1 ] && [ -z "$CUR_DB_NAME" ] && [ -n "$DB_NAME" ]; then
        CUR_DB_NAME="$DB_NAME"
        CUR_DB_USERNAME="$DB_USERNAME"
        CUR_DB_PASSWORD="$DB_PASSWORD"
      fi

      # kalau gak ada DB_NAME → stop
      [ -z "$CUR_DB_NAME" ] && break

      echo "→ Generate user & db untuk index $i: $CUR_DB_NAME ($CUR_DB_USERNAME)"

      sed \
        -e "s|{{ROOT_PASSWORD}}|$ROOT_PASSWORD|g" \
        -e "s|{{DB_USERNAME}}|$CUR_DB_USERNAME|g" \
        -e "s|{{DB_PASSWORD}}|$CUR_DB_PASSWORD|g" \
        -e "s|{{DB_NAME}}|$CUR_DB_NAME|g" \
        "$TEMPLATE" >> "$OUTPUT"

      echo "" >> "$OUTPUT"
      i=$((i+1))
    done

    echo "✓ create_users_and_grants.sql berhasil dibuat."

  else
    echo "⚠️ Template .tmpl tidak ditemukan. Pakai mode single-DB legacy."
    sed -i "s|{{ROOT_PASSWORD}}|$ROOT_PASSWORD|g" "/docker-entrypoint-initdb.d/create_users_and_grants.sql"
    sed -i "s|{{DB_USERNAME}}|$DB_USERNAME|g" "/docker-entrypoint-initdb.d/create_users_and_grants.sql"
    sed -i "s|{{DB_PASSWORD}}|$DB_PASSWORD|g" "/docker-entrypoint-initdb.d/create_users_and_grants.sql"
    sed -i "s|{{DB_NAME}}|$DB_NAME|g" "/docker-entrypoint-initdb.d/create_users_and_grants.sql"
  fi
}


load_init_sql_template() {
  # Mengeksekusi skrip SQL dari direktori /docker-entrypoint-initdb.d jika ada
  if [ -d "/docker-entrypoint-initdb.d" ]; then
      for sql_file in /docker-entrypoint-initdb.d/*.sql; do
          if [ -f "$sql_file" ]; then
              echo "Running script : $sql_file..."
              psql -U postgres -f "$sql_file" >/dev/null 2>&1;
          fi
      done
  fi
}

load_automation_sql_template() {
  echo "checking sql file script on /docker-entrypoint.d if exist"
  # Mengeksekusi skrip SQL dari direktori /docker-entrypoint.d jika ada
  if [ -d "/docker-entrypoint.d" ]; then
      for sql_file in /docker-entrypoint.d/*.sql; do
          if [ -f "$sql_file" ]; then
              echo "Running script : $sql_file..."
              psql -U postgres -w "$ROOT_PASSWORD" -f "$sql_file"
          fi
      done
  fi
  echo "task sql file automation is complete"
}

load_cron_scheduler(){
  # Menjalankan cron jika diaktifkan
  if [ "$ENABLED_CRON" = "true" ]; then
    for file in /usr/cron.d/*; do
      if [ -x "$file" ]; then
        cron_name=$(basename "$file")
        # Menambahkan log output ke file log
        echo "$CRON_PRIODIC /bin/bash $file >> /var/log/mysql/cron.log 2>&1" > "/etc/cron.d/$cron_name"
      fi
    done
  fi
}

checkIsInitDB(){
  # Memeriksa apakah database sudah ada
  if [ ! -f "/var/lib/postgresql/data/DKA_POSTGRESQL_INIT" ]; then
      echo "first Run. initiate system server..."
      pg_ctl init -D /var/lib/postgresql/data
      echo "Database Successfully initiate..."
      initiate_postgresql
      set_users_and_grant
      load_init_sql_template
      echo "shutdown PostgreSQL Temporary..."
      pg_ctl stop -D /var/lib/postgresql/data
      wait "$pid"
      echo "PostgreSQL successfully stopped."
      set_memory
      set_hba
      touch "/var/lib/postgresql/data/DKA_POSTGRESQL_INIT"
  else
      echo "system PostgreSQL is initiate.., continue running server."
  fi
}

# Periksa dan hapus postmaster.pid jika ada sebelum memulai PostgreSQL
clear_postmaster_pid() {
  POSTMASTER_PID_FILE="/var/lib/postgresql/data/postmaster.pid"
  if [ -f "$POSTMASTER_PID_FILE" ]; then
    echo "Removing existing postmaster.pid file..."
    rm -f "$POSTMASTER_PID_FILE"
  fi

  SOCKET_LOCK_FILE="/run/postgresql/.s.PGSQL.5432.lock"
    if [ -f "$SOCKET_LOCK_FILE" ]; then
      echo "Removing existing socket lock file..."
      rm -f "$SOCKET_LOCK_FILE"
    fi
}

echo "checking init server..."
clear_postmaster_pid  # Tambahkan pemanggilan fungsi di awal
checkIsInitDB
echo "load cron scheduler..."
load_cron_scheduler
echo "Running Logrotate..."
logrotate -f /etc/logrotate.conf >/dev/null 2>&1;
# Memulai server PostgreSQL secara normal
echo "🚀 Running Postgres Engine..."
pg_ctl start -D /var/lib/postgresql/data
checkPostgreSQLIsRunning
load_automation_sql_template
echo "📈 Health monitoring active."
# supaya container tidak mati
exec tail -f /dev/null

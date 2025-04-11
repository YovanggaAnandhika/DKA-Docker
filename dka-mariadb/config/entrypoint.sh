#!/bin/sh

HOSTNAME=$(hostname)
DEFAULT_CONFIG_PATH=${DKA_CONFIG_PATH:-/etc/my.cnf}
# Cron Env
ENABLED_CRON=${DKA_CRON_ENABLE:-false}
CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}
# Set default values if environment variables are not provided
ROOT_PASSWORD=${DKA_ROOT_PASSWORD:-root}
DB_NAME=${DKA_DB_NAME:-test}
DB_USERNAME=${DKA_DB_USERNAME:-test}
DB_PASSWORD=${DKA_DB_PASSWORD:-test}

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
  # Menghitung QUERY_CACHE_SIZE sebagai 5% dari MEMORY_MAX
  QUERY_CACHE_SIZE_MB=$((MEMORY_MAX / 20 / 1024 / 1024))
  QUERY_CACHE_SIZE="${QUERY_CACHE_SIZE_MB}M"
  # Menghitung TMP_TABLE_SIZE sebagai 10% dari MEMORY_MAX
  TMP_TABLE_SIZE_MB=$((MEMORY_MAX / 10 / 1024 / 1024))
  TMP_TABLE_SIZE="${TMP_TABLE_SIZE_MB}M"
  # Mengganti placeholder dalam my.cnf dengan nilai yang didapatkan
  sed -i "s|{{INNODB_BUFFER_POOL_SIZE}}|$MEMORY_MAX_MB|g" /etc/my.cnf
  sed -i "s|{{QUERY_CACHE_SIZE}}|$QUERY_CACHE_SIZE|g" /etc/my.cnf
  sed -i "s|{{TMP_TABLE_SIZE}}|$TMP_TABLE_SIZE|g" /etc/my.cnf
}

checkMariaDBIsRunning(){
  # Wait for MariaDB to start
    until mariadb-admin ping >/dev/null 2>&1; do
        echo "Waiting for MariaDB to start..."
        sleep 2
    done
    echo "MariaDB Server Is Running..."
}
# Fungsi untuk memulai MariaDB
initiate_mariadb() {
  echo "Starting MariaDB Temporary..."
  mariadbd-safe --defaults-file="${DEFAULT_CONFIG_PATH}" &
  pid="$!"
  checkMariaDBIsRunning
}
set_users_and_grant() {
  sed -i "s|{{DB_USERNAME}}|$(printf '%s' "$DB_USERNAME" | sed 's/[&/]/\\&/g')|g" /docker-entrypoint-initdb.d/create_users_and_grants.sql
  sed -i "s|{{DB_NAME}}|$(printf '%s' "$DB_NAME" | sed 's/[&/]/\\&/g')|g" /docker-entrypoint-initdb.d/create_users_and_grants.sql
  sed -i "s|{{ROOT_PASSWORD}}|$(printf '%s' "$ROOT_PASSWORD" | sed 's/[&/]/\\&/g')|g" /docker-entrypoint-initdb.d/create_users_and_grants.sql
  sed -i "s|{{DB_PASSWORD}}|$(printf '%s' "$DB_PASSWORD" | sed 's/[&/]/\\&/g')|g" /docker-entrypoint-initdb.d/create_users_and_grants.sql
}


load_init_sql_template() {
  # Mengeksekusi skrip SQL dari direktori /docker-entrypoint-initdb.d jika ada
  if [ -d "/docker-entrypoint-initdb.d" ]; then
      for sql_file in /docker-entrypoint-initdb.d/*.sql; do
          if [ -f "$sql_file" ]; then
              echo "Running script : $sql_file..."
              mariadb < "$sql_file"
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
              mariadb < "$sql_file"
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
  if [ ! -d "/var/lib/mysql/mysql" ]; then
      set_memory
      echo "first Run. initiate system server..."
      mariadb-install-db --defaults-file="${DEFAULT_CONFIG_PATH}" > /dev/null 2>&1
      echo "Database Successfully initiate..."
      initiate_mariadb
      set_users_and_grant
      load_init_sql_template
      echo "shutdown MariaDB Temporary..."
      mariadb-admin shutdown
      wait "$pid"
      echo "MariaDB successfully stopped."
  else
      set_memory
      echo "system MariaDB is initiate.., continue running server."
  fi
}

# Fungsi untuk memonitor MariaDB dan restart jika gagal
watch_services() {
  echo "started health monitoring process ..."
  while true; do
    # Memeriksa apakah mongod, cron berjalan
    if ! pgrep mariadbd > /dev/null || ! pgrep cron > /dev/null; then
      echo "one or more process stopped. exit container ..."
      exit 1
    fi
    sleep 3
  done
}

echo "checking init server..."
checkIsInitDB
echo "load cron scheduler..."
load_cron_scheduler
echo "Running Logrotate..."
logrotate -f /etc/logrotate.conf >/dev/null 2>&1;
echo "Running Scheduler Cron"
crond &
# Memulai server MariaDB secara normal
echo "Final Running mariadb..."
mariadbd --defaults-file="${DEFAULT_CONFIG_PATH}" &
checkMariaDBIsRunning
load_automation_sql_template
watch_services

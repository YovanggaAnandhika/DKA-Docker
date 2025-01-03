#!/bin/sh

DEFAULT_CONFIG_PATH=${DKA_CONFIG_PATH:-/etc/my.cnf}
# Cron Env
ENABLED_CRON=${DKA_CRON_ENABLE:-true}
CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}
# Set default values if environment variables are not provided
ROOT_PASSWORD=${DKA_ROOT_PASSWORD:-root}
DB_NAME=${DKA_DB_NAME:-test}
DB_USERNAME=${DKA_DB_USERNAME:-test}
DB_PASSWORD=${DKA_DB_PASSWORD:-test}

# PERCENT_MEMORY sebagai persentase
PERCENT_MEMORY=0.8
# Membaca nilai memory.max dalam byte
MEMORY_MAX=$(cat /sys/fs/cgroup/memory.max)
# Mengalikan MEMORY_MAX dengan PERCENT_MEMORY menggunakan bc
MEMORY_MAX=$(echo "$MEMORY_MAX * $PERCENT_MEMORY" | bc)
# Membulatkan hasil ke bawah menjadi bilangan bulat
MEMORY_MAX=$(printf "%.0f" $MEMORY_MAX)
# Mengonversi nilai byte ke MB
MEMORY_MAX_MB=$((MEMORY_MAX / 1024 / 1024))
# Menambahkan akhiran 'M' untuk format MB
MEMORY_MAX_MB="${MEMORY_MAX_MB}M"
# Menampilkan nilai memory max dalam MB
echo "Memory Max: $MEMORY_MAX_MB"
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


# Fungsi untuk memulai MariaDB
start_mariadb() {
  echo "Starting MariaDB Temporary..."
  mariadbd-safe --defaults-file=${DEFAULT_CONFIG_PATH} &
  pid="$!"

  # Wait for MariaDB to start
  until mariadb-admin ping >/dev/null 2>&1; do
      echo "Waiting for MariaDB to start..."
      sleep 2
  done
  echo "MariaDB Temporary Server Is Running..."
}

# Memeriksa apakah database sudah ada
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "first Run. initiate system server..."
    # Inisialisasi sistem tabel MariaDB jika database belum ada
    mariadb-install-db --defaults-file=${DEFAULT_CONFIG_PATH} > /dev/null 2>&1
    echo "Database Successfully initiate..."

    # Mulai MariaDB sementara untuk mengeksekusi skrip inisialisasi
    start_mariadb

    # Mengeksekusi skrip SQL dari direktori /docker-entrypoint-initdb.d jika ada
    if [ -d "/docker-entrypoint-initdb.d" ]; then
        for sql_file in /docker-entrypoint-initdb.d/*.sql; do
            if [ -f "$sql_file" ]; then
                echo "Running script : $sql_file..."
                mariadb < "$sql_file"
            fi
        done
    fi

    mariadb -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME"
    mariadb -u root -e "CREATE USER IF NOT EXISTS '$DB_USERNAME'@'%' IDENTIFIED BY '$DB_PASSWORD'"
    mariadb -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USERNAME'@'%'"

    mariadb -u root -e "CREATE USER 'root'@'%' IDENTIFIED BY '$ROOT_PASSWORD'"
    mariadb -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION"

    mariadb -u root -e "FLUSH PRIVILEGES"
    # Shutdown MariaDB sementara setelah inisialisasi selesai
    echo "shutdown MariaDB Temporary..."
    mariadb-admin shutdown
    wait "$pid"
    echo "MariaDB successfully stopped."
else
    echo "system MariaDB is initiate.., continue running server."
fi

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

# Menjalankan logrotate
echo "Running Logrotate..."
logrotate -f /etc/logrotate.conf >/dev/null 2>&1;

# Running Crond Scheduler
echo "Running Scheduler Cron"
crond &
# Memulai server MariaDB secara normal
echo "Final Running mariadb..."
# Check if $@ is empty or invalid
if [ -z "$@" ]; then
    # If no arguments were passed to exec, run a fallback command
    mariadbd --defaults-file=${DEFAULT_CONFIG_PATH}
else
    # If arguments exist, execute them
    exec "$@"
fi

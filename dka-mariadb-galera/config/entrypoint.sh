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

WSREP_IS_PRIMARY=${DKA_WSREP_IS_PRIMARY:-false}

export WSREP_ON=${DKA_WSREP_ON:-OFF}
export WSREP_CLUSTER_NAME=${DKA_WSREP_CLUSTER_NAME:-DKACluster}
export WSREP_CLUSTER_ADDRESS=${DKA_WSREP_CLUSTER_ADDRESS:-gcomm://}
export WSREP_PROVIDER=${DKA_WSREP_PROVIDER:-/usr/lib/libgalera_smm.so}

export WSREP_NODE_NAME=${DKA_WSREP_NODE_NAME:-node1}
export WSREP_NODE_ADDRESS=${DKA_WSREP_NODE_ADDRESS:-127.0.0.1}
export WSREP_SST_METHOD=${DKA_WSREP_SST_METHOD:-rsync}

#inject config
inject_my_cnf() {

  # Debugging: cek nilai variabel sebelum injeksi
  echo "WSREP_ON=${WSREP_ON}"
  echo "WSREP_PROVIDER=${WSREP_PROVIDER}"
  echo "WSREP_CLUSTER_NAME=${WSREP_CLUSTER_NAME}"
  echo "WSREP_CLUSTER_ADDRESS=${WSREP_CLUSTER_ADDRESS}"
  echo "WSREP_NODE_NAME=${WSREP_NODE_NAME}"
  echo "WSREP_NODE_ADDRESS=${WSREP_NODE_ADDRESS}"

  # Inject configuration into my.cnf
  echo "Menginjeksi konfigurasi ke ${DEFAULT_CONFIG_PATH}..."
  envsubst < /etc/my.cnf.template > "${DEFAULT_CONFIG_PATH}"
  chmod 644 "${DEFAULT_CONFIG_PATH}"
  cat /etc/my.cnf
}

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

    # check configurasi galera
    if [ "$WSREP_ON" = "ON" ]; then
      echo "WSREP is ON. inject the config"
      inject_my_cnf
    fi
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

# check configurasi galera
if [ "$WSREP_ON" = "ON" ]; then
  echo "WSREP is ON. inject the config"
  inject_my_cnf
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

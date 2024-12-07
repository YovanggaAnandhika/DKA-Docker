#!/bin/sh

ENABLED_CRON=${DKA_CRON_ENABLE:-false}
CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}

# Fungsi untuk memulai MariaDB
start_mariadb() {
    echo "Memulai MariaDB..."
    mysqld_safe &
    pid="$!"

    # Wait for MariaDB to start
    until mysqladmin ping >/dev/null 2>&1; do
        echo "Waiting for MariaDB to start..."
        sleep 2
    done
    echo "MariaDB sudah berjalan."
}

# Memeriksa apakah database sudah ada
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Inisialisasi database..."

    # Set default values if environment variables are not provided
    ROOT_PASSWORD=${DKA_ROOT_PASSWORD:-root}
    DB_NAME=${DKA_DB_NAME:-test}
    DB_USERNAME=${DKA_DB_USERNAME:-test}
    DB_PASSWORD=${DKA_DB_PASSWORD:-test}

    # Inisialisasi sistem tabel MariaDB jika database belum ada
    mariadb-install-db --defaults-file=/etc/my.cnf
    echo "Database berhasil diinisialisasi."

    # Mulai MariaDB sementara untuk mengeksekusi skrip inisialisasi
    start_mariadb

    # Mengeksekusi skrip SQL dari direktori /docker-entrypoint-initdb.d jika ada
    if [ -d "/docker-entrypoint-initdb.d" ]; then
        for sql_file in /docker-entrypoint-initdb.d/*.sql; do
            if [ -f "$sql_file" ]; then
                echo "Menjalankan skrip: $sql_file..."
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
    echo "Shutdown MariaDB sementara..."
    mysqladmin shutdown
    wait "$pid"
    echo "MariaDB dihentikan."
else
    echo "Database sudah ada, melanjutkan dengan start MariaDB."
fi

if [ "$ENABLED_CRON" = "true" ]; then
  # Loop through all files in /usr/local/bin
  for file in /usr/cron.d/*; do
    if [ -x "$file" ]; then
      # Get the name of the file to use as the cron job name
      cron_name=$(basename "$file")
      # Example: Running the script every day at midnight
      echo "$CRON_PRIODIC $file" > "/etc/cron.d/$cron_name"
    fi
  done
fi


# Menjalankan logrotate
echo "Menjalankan logrotate..."
logrotate -f /etc/logrotate.conf >/dev/null 2>&1;
# Running Crond Scheduler
echo "running cron"
crond &
# Memulai server MariaDB secara normal
echo "Memulai server MariaDB..."
exec "$@"

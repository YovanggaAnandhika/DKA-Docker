#!/bin/bash
set -e

export DKA_HOSTNAME=$(hostname) # Ambil hostname sistem

export DKA_MONGO_USERNAME=${DKA_MONGO_USERNAME:-root}
export DKA_MONGO_PASSWORD=${DKA_MONGO_PASSWORD:-123456789}
export DKA_CRON_ENABLE=${DKA_CRON_ENABLE:-false}
export DKA_CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}

export GLIBC_TUNABLES=glibc.pthread.rseq=0
export DKA_REPL_ENABLED=${DKA_REPL_ENABLED:-false}
export DKA_REPL_NAME=${DKA_REPL_NAME:-rs0}

# Fungsi untuk memonitor MariaDB dan restart jika gagal
watch_services() {
  while true; do
    # Memeriksa apakah mongod, cron berjalan
    if ! pgrep mongod > /dev/null || ! pgrep cron > /dev/null || ! pgrep node > /dev/null; then
      echo "one or more process stopped. exit container ..."
      exit 1
    fi
    sleep 3
  done
}


wait_mongo_start() {
  until mongosh --eval "print('MongoDB is ready')" >/dev/null 2>&1; do
      echo "Waiting for MongoDB to start..."
      sleep 1
  done
  echo "MongoDB is up and running."
}

start_first_mongo() {
   if [ "$DKA_REPL_ENABLED" = "true" ]; then
      mongod --logpath /var/log/mongodb/mongod.log --logappend --replSet "$DKA_REPL_NAME" &
      MONGOD_PID=$!
   else
     mongod --logpath /var/log/mongodb/mongod.log --logappend &
     MONGOD_PID=$!
   fi
}

running_init_file() {
  if [ -d /docker-entrypoint-initdb.d ]; then
      for file in /docker-entrypoint-initdb.d/*.js; do
          if [ -f "$file" ]; then
              echo "Running $file"
              mongosh --verbose < "$file" >> /var/log/mongosh-init.log 2>&1
          fi
      done
  fi
}


running_after_init_file() {
  if [ -d /entrypoint.d ]; then
      for file in /entrypoint.d/*.js; do
          if [ -f "$file" ]; then
              echo "Running $file"
              # Menggunakan eval untuk memuat file dan mencetak output yang dihasilkan
              mongosh --verbose --username "$DKA_MONGO_USERNAME" --password "$DKA_MONGO_PASSWORD" < "$file" >> /var/log/mongosh-init.log 2>&1
          fi
      done
  fi
}

shutdown_mongod() {
  echo "Shutting down MongoDB..."
  mongod --shutdown > /dev/null 2>&1 || echo "MongoDB shutdown encountered an issue."
}

# Mendeteksi MongoDB Pertama Kali
if [ -z "$(ls -A /data/db)" ]; then
    echo "First-time installation detected. Initializing..."
    touch /var/log/mongodb/mongod.log
    start_first_mongo
    wait_mongo_start
    running_init_file
    shutdown_mongod
else
    echo "Existing MongoDB data detected. Continuing..."
fi

export_cron_file() {
  echo "exporting cron file ..."
  # Menjalankan cron jika diaktifkan
  if [ "$DKA_CRON_ENABLE" = "true" ]; then
    for file in /usr/cron.d/*; do
      if [ -x "$file" ]; then
        cron_name=$(basename "$file")
        # Menambahkan log output ke file log
        echo "${DKA_CRON_PRIODIC} root /bin/bash $file" > "/etc/cron.d/$cron_name"
      fi
    done
  fi
  echo "cron file is exported..."
}

start_log_rotate(){
  echo "starting rotate log ..."
  logrotate -f /etc/logrotate.conf &
  echo "rotate log started ..."
}

start_mongo_with_replication(){
  start_log_rotate
  export_cron_file
  # Start cron in the background
  echo "Starting crontab scheduler ..."
  cron &
  echo "mongo engine starting ..."
  exec mongod --config /etc/mongod.conf --replSet "$DKA_REPL_NAME" &
  echo "mongo engine started"
  wait_mongo_start
  running_after_init_file
  echo "show system log ..."
  tail -f /var/log/mongodb/mongod.log &
  echo "starting monitoring service health check"
}

start_mongo_without_replication(){
  start_log_rotate
  export_cron_file
  # Start cron in the background
  echo "Starting crontab scheduler..."
  cron &
  echo "mongo engine starting ..."
  exec mongod --config /etc/mongod.conf &
  echo "mongo engine started"
  wait_mongo_start
  running_after_init_file
  echo "show system log ..."
  tail -f /var/log/mongodb/mongod.log &
  echo "starting monitoring service health check"
}


start_node(){
  if [ "$#" -gt 0 ]; then
      # If arguments exist, execute them
      echo "Memulai Default Entry point main dengan arguments"
      exec "$@"
  else
     # If no arguments were passed, check if package.json exists
      if [ -f "package.json" ]; then
          echo "Memulai Default Entry point main di package.json"
          node . &
      else
          # If package.json doesn't exist, wait for background processes
          echo "package.json tidak ditemukan. Mulai Ulang Container dengan command. atau buat point di file package.json"
      fi
  fi
}

# If no arguments were passed, start MongoDB
if [ "$DKA_REPL_ENABLED" = "true" ]; then
    start_mongo_with_replication
    start_node
    watch_services
else
    start_mongo_without_replication
    start_node
    watch_services
fi

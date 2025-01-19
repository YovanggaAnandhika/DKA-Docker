#!/bin/bash
set -e

export DKA_HOSTNAME=$(hostname) # Ambil hostname sistem

export DKA_MONGO_USERNAME=${DKA_MONGO_USERNAME:-root}
export DKA_MONGO_PASSWORD=${DKA_MONGO_PASSWORD:-123456789}

export GLIBC_TUNABLES=glibc.pthread.rseq=0
export DKA_REPL_ENABLED=${DKA_REPL_ENABLED:-false}
export DKA_REPL_NAME=${DKA_REPL_NAME:-rs0}

# Fungsi untuk memonitor MariaDB dan restart jika gagal
watch_services() {
  while true; do
    # Memeriksa apakah mariadbd, nginx, dan php-fpm berjalan
    if ! pgrep mongod > /dev/null; then
      echo "mongod process stopped. exit container ..."
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
      mongod --replSet "$DKA_REPL_NAME" &
      MONGOD_PID=$!
   else
     mongod &
     MONGOD_PID=$!
   fi
}

running_init_file() {
  if [ -d /docker-entrypoint-initdb.d ]; then
      for file in /docker-entrypoint-initdb.d/*.init.js; do
          if [ -f "$file" ]; then
              echo "Running $file"
              mongosh < "$file" > /dev/null 2>&1;
          fi
      done
  fi
}

shutdown_mongod() {
  echo "Shutting down MongoDB..."
  mongod --shutdown || echo "MongoDB shutdown encountered an issue."
}

# Mendeteksi MongoDB Pertama Kali
if [ -z "$(ls -A /data/db)" ]; then
    echo "First-time installation detected. Initializing..."
    start_first_mongo
    wait_mongo_start
    running_init_file
    shutdown_mongod
else
    echo "Existing MongoDB data detected. Continuing..."
fi

# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    # If arguments exist, execute them
    exec "$@"
else
    # If no arguments were passed, start MongoDB
    if [ "$DKA_REPL_ENABLED" = "true" ]; then
        echo "mongo engine starting ..."
        exec mongod --config /etc/mongod.conf --replSet "$DKA_REPL_NAME" &
        echo "mongo engine started"
        watch_services
    else
        echo "mongo engine starting ..."
        exec mongod --config /etc/mongod.conf &
        echo "mongo engine started"
        watch_services
    fi
fi

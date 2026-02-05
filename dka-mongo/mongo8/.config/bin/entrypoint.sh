#!/bin/bash
set -e

# --- Visual Styling ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}${BOLD}"
echo "=========================================================="
echo "      DKA RESEARCH CENTER - MONGODB ENGINE STARTING       "
echo "=========================================================="
echo -e "${NC}"

# --- Environment Variables ---
export DKA_HOSTNAME=${DKA_HOSTNAME:-127.0.0.1}
export DKA_MONGO_USERNAME=${DKA_MONGO_USERNAME:-root}
export DKA_MONGO_PASSWORD=${DKA_MONGO_PASSWORD:-123456789}
export DKA_CRON_ENABLE=${DKA_CRON_ENABLE:-false}
export DKA_CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}
export DKA_REPL_ENABLED=${DKA_REPL_ENABLED:-false}
export DKA_REPL_NAME=${DKA_REPL_NAME:-rs0}
export GLIBC_TUNABLES=glibc.pthread.rseq=0

log_info "Configuration Loaded:"
log_info " -> Hostname: ${DKA_HOSTNAME}"
log_info " -> ReplicaSet: ${DKA_REPL_NAME} (Enabled: ${DKA_REPL_ENABLED})"
log_info " -> User Admin: ${DKA_MONGO_USERNAME}"

# --- Helper Functions ---

mkdir -p /var/log/mongodb
touch /var/log/mongodb/mongod.log
chown -R mongodb:mongodb /var/log/mongodb

# Fungsi watch_services dihapus sesuai permintaan untuk menggunakan healthcheck

wait_mongo_start() {
  echo -n -e "${YELLOW}[WAIT] Waiting for MongoDB to be ready...${NC}"
  for i in {1..30}; do
    # Coba ping tanpa auth (untuk awal) ATAU dengan auth (setelah user root dibuat)
    if mongosh --quiet --eval "db.adminCommand('ping')" >/dev/null 2>&1 || \
       mongosh --quiet --username "$DKA_MONGO_USERNAME" --password "$DKA_MONGO_PASSWORD" \
       --authenticationDatabase admin --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
      echo -e " ${GREEN}[READY]${NC}"
      return 0
    fi
    echo -n "."
    sleep 1
  done
  echo -e " ${RED}[TIMEOUT]${NC}"
  return 1
}

running_init_file() {
  if [ -d /docker-entrypoint-initdb.d ]; then
      echo -e "${BLUE}----------------------------------------------------------${NC}"
      log_info "🚀 Running First-Time Init Files (/docker-entrypoint-initdb.d/)..."
      for file in /docker-entrypoint-initdb.d/*.js; do
          if [ -f "$file" ]; then
              echo -e "${YELLOW}[EXEC] Executing: $(basename $file)${NC}"
              mongosh --quiet < "$file" 2>&1 | tee -a /var/log/mongosh-init.log

              if [ ${PIPESTATUS[0]} -eq 0 ]; then
                  log_success "✅ $(basename $file) finished successfully."
              else
                  log_error "❌ $(basename $file) failed! Check /var/log/mongosh-init.log"
              fi
          fi
      done
      echo -e "${BLUE}----------------------------------------------------------${NC}"
  fi
}

running_after_init_file() {
  if [ -d /entrypoint.d ]; then
      echo -e "${BLUE}----------------------------------------------------------${NC}"
      log_info "🛠️ Running Post-Boot Files (/entrypoint.d/)..."
      for file in /entrypoint.d/*.js; do
          if [ -f "$file" ]; then
              echo -e "${YELLOW}[EXEC] Executing: $(basename $file) (Auth Mode)${NC}"
              mongosh --quiet --username "$DKA_MONGO_USERNAME" \
                      --password "$DKA_MONGO_PASSWORD" \
                      --authenticationDatabase admin < "$file" 2>&1 | tee -a /var/log/mongosh-init.log

              if [ ${PIPESTATUS[0]} -eq 0 ]; then
                  log_success "✅ $(basename $file) finished successfully."
              else
                  log_error "❌ $(basename $file) failed! Check logs for 'NotWritablePrimary' errors."
              fi
          fi
      done
      echo -e "${BLUE}----------------------------------------------------------${NC}"
  fi
}

export_cron_file() {
  if [ "$DKA_CRON_ENABLE" = "true" ]; then
    log_info "Exporting cron files to /etc/cron.d/..."
    for file in /usr/cron.d/*; do
      if [ -x "$file" ]; then
        cron_name=$(basename "$file")
        echo "${DKA_CRON_PRIODIC} root /bin/bash $file >> /var/log/mongodb/cron.log 2>&1" > "/etc/cron.d/$cron_name"
        chmod 0644 "/etc/cron.d/$cron_name"
      fi
    done
    cron && log_success "Crontab scheduler is active."
  fi
}

# --- Main Logic ---

# 1. Deteksi Instalasi Pertama
if [ ! -f "/data/db/storage.bson" ]; then
    log_warn "Empty data directory detected. Initializing First-Time Setup..."

    if [ "$DKA_REPL_ENABLED" = "true" ]; then
      mongod --dbpath /data/db --replSet "$DKA_REPL_NAME" --bind_ip_all --fork --logpath /var/log/mongodb/mongod.log
    else
      mongod --dbpath /data/db --bind_ip_all --fork --logpath /var/log/mongodb/mongod.log
    fi

    wait_mongo_start
    running_init_file

    log_info "Shutting down temporary instance for final configuration..."
    mongod --dbpath /data/db --shutdown
    log_success "Database initialization complete."
else
    log_success "Existing MongoDB data found. Resuming operations."
fi

# 2. Jalankan Engine Utama
start_mongo_engine() {
  start_log_rotate() { log_info "Triggering logrotate..."; logrotate -f /etc/logrotate.conf || true; }
  start_log_rotate
  export_cron_file

  # Menjalankan script post-boot di background agar tidak memblock exec mongod
  (
    wait_mongo_start
    running_after_init_file
    log_success "Post-boot scripts execution finished."
  ) &

  log_info "Starting MongoDB Main Engine (/etc/mongod.conf) as PID 1..."

  # Menggunakan exec agar MongoDB mengambil alih shell dan menjadi PID 1
  if [ "$DKA_REPL_ENABLED" = "true" ]; then
    exec mongod --config /etc/mongod.conf --replSet "$DKA_REPL_NAME" --bind_ip_all
  else
    exec mongod --config /etc/mongod.conf --bind_ip_all
  fi
}

if [ "$#" -gt 0 ]; then
    log_info "Executing custom command: $@"
    exec "$@"
else
    start_mongo_engine
fi
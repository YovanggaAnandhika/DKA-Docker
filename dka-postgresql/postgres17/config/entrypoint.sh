#!/bin/sh

# ==============================================================================
# ENTRYPOINT SCRIPT DKA POSTGRESQL (ALPINE LINUX)
# Tujuan Utama: Menangani inisialisasi awal database, konfigurasi jaringan 
# dinamis, manajemen memori otomatis, serta Graceful Shutdown di container.
# ==============================================================================

# --- 1. Konfigurasi Variabel Jalur & Akses ---
HOSTNAME=$(hostname)
DEFAULT_CONFIG_PATH=${DKA_CONFIG_PATH:-/var/lib/postgresql/data/postgresql.conf}
DEFAULT_CONFIG_HBA_PATH=${DKA_CONFIG_HBA_PATH:-/var/lib/postgresql/data/pg_hba.conf}

# Konfigurasi Fitur Cron
ENABLED_CRON=${DKA_CRON_ENABLE:-false}
CRON_PRIODIC=${DKA_CRON_PRIODIC:-0 3 * * *}

# Kredensial Akses Database (Username / Password)
ROOT_USERNAME=${DKA_ROOT_USERNAME:-postgres}
ROOT_PASSWORD=${DKA_ROOT_PASSWORD:-postgres}
DB_NAME=${DKA_DB_NAME:-test}
DB_USERNAME=${DKA_DB_USERNAME:-test}
DB_PASSWORD=${DKA_DB_PASSWORD:-test}

# Konfigurasi Limitas Batas Koneksi 
DB_MAX_CONNECTION=${DKA_DB_MAX_CONNECTION:-200}

# ==============================================================================
# --- 2. Kumpulan Fungsi Utilitas & Konfigurasi Inti ---
# ==============================================================================

# Fungsi set_hba()
# Mengizinkan akses jaringan (Listen) dari seluruh IPv4/IPv6 menggunakan metode 
# otentikasi hashing password yang aman (scram-sha-256).
set_hba() {
  echo "host    all             all             0.0.0.0/0            scram-sha-256" >> $DEFAULT_CONFIG_HBA_PATH
  echo "host    all             all             ::/0                 scram-sha-256" >> $DEFAULT_CONFIG_HBA_PATH
}

# Fungsi set_memory()
# Mendeteksi limit memori container dari Cgroup host, lalu mengatur parameter 
# cache di dalam postgresql.conf (seperti shared_buffers) secara otomatis sebesar 
# 80% dari total memori RAM yang diperbolehkan.
set_memory() {
  PERCENT_MEMORY=0.8
  # Mencoba membaca memori dari cgroup v2
  MEMORY_MAX=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)

  # Fallback ke cgroup v1 atau kapasitas utuh host jika file max tidak tersedia
  if [ "$MEMORY_MAX" = "max" ] || [ -z "$MEMORY_MAX" ]; then
      MEMORY_MAX=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
      if [ -z "$MEMORY_MAX" ]; then
          MEMORY_MAX=$(free -b | grep Mem | awk '{print $2}')
      fi
  fi

  # Mengalikan maksimal RAM sistem dengan persentase threshold RAM
  MEMORY_MAX=$(echo "$MEMORY_MAX * $PERCENT_MEMORY" | bc)
  MEMORY_MAX=$(printf "%.0f" "$MEMORY_MAX")
  MEMORY_MAX_MB=$((MEMORY_MAX / 1024 / 1024))

  # Kaidah best-practice: shared_buffers adalah 1/4 dari total RAM tersedia
  SHARED_BUFFERS=$((MEMORY_MAX / 4 / 1024 / 1024))"MB"
  # Mengkalkulasikan per-koneksi RAM untuk caching agregasi dan sort (work_mem)
  WORK_MEM=$((MEMORY_MAX / 4 / DB_MAX_CONNECTION / 1024))"kB"

  echo "📈 Memory detected: ${MEMORY_MAX_MB}MB. Setting shared_buffers to $SHARED_BUFFERS"

  # Menimpa konfigurasi parameter dengan limitasi memori dinamis
  sed -i "s|^\s*shared_buffers = 128MB|shared_buffers = $SHARED_BUFFERS|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*max_connections = 100|max_connections = $DB_MAX_CONNECTION|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*#*work_mem\s*=.*|work_mem = $WORK_MEM|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*#*password_encryption = scram-sha-256|password_encryption = scram-sha-256|g" $DEFAULT_CONFIG_PATH
  sed -i "s|^\s*#*listen_addresses = 'localhost'|listen_addresses = '*'|g" $DEFAULT_CONFIG_PATH
}

# Fungsi checkPostgreSQLIsRunning()
# Memeriksa nyawa server sementara dengan ping. Menghentikan script jika engine gagal boot.
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

# Fungsi initiate_postgresql()
# Digunakan khusus untuk menyalakan engine sementara selama proses setup (First Initialization)
initiate_postgresql() {
  echo "🔄 Starting PostgreSQL Temporary..."
  pg_ctl start -D /var/lib/postgresql/data -l /var/lib/postgresql/data/startup.log &
  pid="$!"
  checkPostgreSQLIsRunning
}

# Fungsi set_users_and_grant()
# Memanfaatkan file template SQL bawaan (.tmpl) untuk menginjeksi daftar username dan database custom,
# serta meng-generate extension 'postgis' pada setiap database yang diciptakan.
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

# Fungsi load_init_sql_template()
# Mengeksekusi secara alfabetis semua kueri '.sql' pada map initdb (First Run).
load_init_sql_template() {
  if [ -d "/docker-entrypoint-initdb.d" ]; then
      # Urutkan file agar create_postgis_extensions.sql berjalan sebelum data dummy
      for sql_file in $(ls /docker-entrypoint-initdb.d/*.sql | sort); do
          if [ -f "$sql_file" ]; then
              echo "📜 Running init script: $sql_file..."
              PGPASSWORD=$ROOT_PASSWORD psql -U $ROOT_USERNAME -f "$sql_file" >/dev/null 2>&1
          fi
      done
  fi
}

# Fungsi load_automation_sql_template()
# Digunakan untuk menjalankan kueri berulang (Contoh: Reset cron/event scheduler) tiap kali server nyala.
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

# Fungsi load_cron_scheduler()
# Mengaktifkan daemon dcron Alpine untuk utilitas back-end di sisi sistem operasi
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

# Fungsi checkIsInitDB()
# Skrip sentral pendeteksi status basis data. Skrip memeriksa keberadaan file flag 'DKA_POSTGRESQL_INIT'.
# Kalau file belum ada (volume masih kosong), dia akan membuat pondasi DB `pg_ctl init`,
# menjalankan fungsi grant/init SQL sementara, kemudian mematikan lagi layanannya (Temporary stop).
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
      
      # Membuat tanda bahwasannya InitDB telah berhasil
      touch "/var/lib/postgresql/data/DKA_POSTGRESQL_INIT"
      echo "✅ Inisialisasi database perdana selesai."
  else
      echo "ℹ️ Database already initiated. Skipping first run setup."
  fi
}

# Fungsi clear_postmaster_pid() (Sapu Jagat)
# Mencegah Stuck Connection pada saat sistem KUBERNETES / DOCKER PV terguncang mati paksa.
# Menghapus paksa riwayat kunci socket lama jika container me-restart sistem dengan tidak wajar.
clear_postmaster_pid() {
  echo "🧹 Cleaning up stale PostgreSQL socket and pid files..."
  rm -f "/var/lib/postgresql/data/postmaster.pid"
  rm -f "/run/postgresql/.s.PGSQL.5432.lock"
  rm -f "/run/postgresql/.s.PGSQL.5432"
  rm -rf /run/postgresql/* 2>/dev/null || true
  
  # Memastikan /run/postgresql kembali bisa ditulisi postgres
  mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql 2>/dev/null || true
}

# ==============================================================================
# --- 3. ALUR EKSEKUSI UTAMA (MAIN FLOW) ---
# ==============================================================================

# --- TAHAP A: MANAJEMEN NETWORKING (MENJALANKAN DENGAN HAK ROOT) ---
# Memanfaatkan desain Dockerfile "USER root" untuk menginisiasi skrip jaringan.
if [ "$(id -u)" = '0' ]; then
  echo "⚙️ Running as root. Setting up network and preparing directories..."
  
  # [FITUR: Dynamic Hotplug DHCP]
  # Mengaktifkan detektor DHCP Network di latar belakang tanpa me-lagging proses startup (Docker Friendly).
  # Ini penting saat server Proxmox menjejalkan interface jaringan ke CT lxc secara live.
  echo "📡 Starting dhcpcd in background for dynamic network configuration..."
  dhcpcd -b >/dev/null 2>&1 &
  
  # Pastikan file/direktori penting aman sebelum lepas hak akses root, menghindari "Permission Denied" 
  # pada Persistent Volume Kubernetes yang salah mengubah status 'Owner/Group'.
  mkdir -p /var/run/postgresql /run/postgresql /var/lib/postgresql /var/log/postgresql
  chown -R postgres:postgres /var/run/postgresql /run/postgresql /var/lib/postgresql /var/log/postgresql /etc/cron.d
  
  # [FITUR: Hak Akses Dialihkan]
  # Menyerahkan tongkat estafet dan melakukan penggantian Sesi secara paksa (menggunakan teknik Switch-Exec) dari 
  # root ke user "postgres" sambil mengeksekusi ULANG skrip yang sama beserta parameternya supaya tidak putus PID 1.
  echo "👤 Dropping privileges and switching to postgres user..."
  exec su-exec postgres "$0" "$@"
fi

# ==============================================================================
# Mulai dari baris ini, user saat ini sudah dipastikan berjalan murni sebagai "postgres"
# ==============================================================================
echo "--- DKA POSTGRESQL ENTRYPOINT STARTING ---"

# Eksekusi blok operasi (Check PID, Init Volume Baru, Setting Cron, Log Rotate)
clear_postmaster_pid

# Sangat Penting: Memastikan struktur map socket tersedia untuk dipakai pg_isready dan runtime server
mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql

checkIsInitDB
load_cron_scheduler
logrotate -f /etc/logrotate.conf >/dev/null 2>&1

echo "📦 Starting Final Postgres Engine..."
# Menjalankan mesin utama basis data tanpa melakukan blocking
pg_ctl start -D /var/lib/postgresql/data -l /var/lib/postgresql/data/main_server.log
checkPostgreSQLIsRunning

# Memanggil Auto-Run (Scheduler)
load_automation_sql_template
echo "📊 Monitoring database logs..."

# --- TAHAP B: FITUR GRACEFUL SHUTDOWN (MENJAGA STARTUP CEPAT KETIKA REBOOT) ---
# Berfungsi me-naikkan perisai (trap) guna mendengarkan jika kernel (Proxmox/Kubernetes) 
# sedang mencoba membunuh container. Kita bisa membereskannya dengan anggun daripada menunggu 60 detik freeze/heng!
shutdown_handler() {
  echo "🛑 Received shutdown signal! Stopping PostgreSQL gracefully..."
  # Meluncurkan mode "fast" stop, melepaskan socket dengan wajar/aman tanpa delay.
  pg_ctl stop -D /var/lib/postgresql/data -m fast
  echo "✅ PostgreSQL stopped cleanly. Container exiting."
  
  clear_postmaster_pid
  exit 0
}

# Menyaring Sinyal Sistem Khusus dari Docker Engine / Containerd
trap 'shutdown_handler' TERM INT

# Mengerahkan utilitas komando "tail" untuk menggantikan posisi blok shell ini. 
# Selain mencegah layar konsol kosong, cara ini menjaga kelangsungan hidup skrip serta membuat Trap Listener kita bereaksi instan.
tail -f /var/lib/postgresql/data/main_server.log &
TAIL_PID=$!
wait "$TAIL_PID"
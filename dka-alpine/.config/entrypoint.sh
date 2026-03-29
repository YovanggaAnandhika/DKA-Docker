#!/bin/sh
set -e

# ==============================================================================
# ENTRYPOINT SCRIPT DKA BASE ALPINE
# Mendukung Ekosistem: Kubernetes (PV Permissions), LXC Proxmox (DHCP), Docker
# ==============================================================================
get_container_runtime() {
    if [ -d "/var/run/secrets/kubernetes.io" ]; then echo "KUBERNETES"
    elif [ -f /.dockerenv ]; then echo "DOCKER"
    elif grep -aq "container=lxc" /proc/1/environ 2>/dev/null; then echo "LXC"
    else echo "STANDALONE"; fi
}

# --- TAHAP A: MANAJEMEN NETWORKING & PRIVILEGE DROP (ROOT LEVEL) ---
if [ "$(id -u)" = '0' ]; then
  echo "⚙️ Running as root. Setting up network and preparing directories..."
  # Aktifkan dhcpcd untuk mendukung dynamic IP pada Proxmox LXC secara Hotplug
  #echo "📡 Starting dhcpcd in background for dynamic network configuration..."
  #dhcpcd -b >/dev/null 2>&1 &
  # Amankan Directory utama /home/app untuk Kubernetes Persistent Volumes
  chown -R www-data:www-data /home/app
  # Pindahkan eksekusi skrip ini murni kepada "www-data" secara aman
  echo "👤 Dropping privileges and switching to 'www-data' user..."
  exec su-exec www-data "$0" "$@"
fi

# ==============================================================================
# TAHAP B: APLIKASI UTAMA (USER LEVEL)
# ==============================================================================
echo "🛡️ [DKA] Runtime: $(get_container_runtime)"
# 1. Jika pengguna memberikan argumen custom (misal: "bash", "node app.js")
if [ "$#" -gt 0 ]; then
    echo "▶️ Forwarding command arguments to execution..."
    exec "$@"
fi

# 2. Jika tidak ada argumen, periksa apakah executabel "./app" tersedia
if [ -f "./app" ]; then
    echo "🚀 Starting default entry point 'main' in ./app"
    # Memaksa ./app menjadi PID 1 agar ./app tersebut bisa menangkap Sinyal OS
    exec ./app
else
    # 3. Mode Standby (Fallback): Jika image base dipakai sebagai wadah mentah
    echo "⚠️ File executable './app' tidak ditemukan."
    echo "⏳ Menjalankan container di mode Standby (Tail-wait)."
    
    # --- GRACEFUL SHUTDOWN HANDLER (STANDBY MODE) ---
    # Memastikan eksekusi "tail" tidak nyangkut saat sistem minta restart
    shutdown_handler() {
      echo "🛑 Shutdown signal received! Exiting standby mode safely."
      exit 0
    }
    trap 'shutdown_handler' TERM INT
    
    tail -f /dev/null &
    TAIL_PID=$!
    wait "$TAIL_PID"
fi
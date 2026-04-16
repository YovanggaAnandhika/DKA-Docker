#!/bin/sh
set -e

# ==============================================================================
# DKA UNIVERSAL ENTRYPOINT (FULL ROOT MODE)
# Optimized for: Proxmox LXC, Kubernetes, & Docker
# ==============================================================================

get_container_runtime() {
    if [ -d "/var/run/secrets/kubernetes.io" ]; then echo "KUBERNETES"
    elif [ -f /.dockerenv ]; then echo "DOCKER"
    elif grep -aq "container=lxc" /proc/1/environ 2>/dev/null; then echo "LXC"
    else echo "STANDALONE"; fi
}

# --- 1. MANAJEMEN NETWORKING (LANGSUNG EXEC) ---
RUNTIME=$(get_container_runtime)
echo "🛡️ [DKA] Runtime: $RUNTIME (User: $(whoami))"

if [ "$RUNTIME" = "LXC" ]; then
    echo "📦 [LXC Detected] Initializing Network Interfaces..."

    # Bangunkan Loopback secara paksa (Wajib!)
    ip link set lo up 2>/dev/null || true

    # Bangunkan semua interface fisik (eth0, eth1, dst)
    for iface in $(ls /sys/class/net | grep -v lo); do
        echo "🔗 Powering up interface: $iface"
        ip link set "$iface" up 2>/dev/null || true
    done

    # Eksekusi ifupdown-ng untuk membaca /etc/network/interfaces
    if command -v ifup >/dev/null; then
        echo "⚙️ Executing: ifup -a"
        ifup -a >/dev/null 2>&1 || true
    fi
fi

# Pastikan direktori kerja siap (Owner tetap root)
mkdir -p /home/app

# --- 2. GRACEFUL SHUTDOWN HANDLER ---
# Menangkap sinyal dari Proxmox/Host
shutdown_handler() {
  echo "🛑 [DKA] Shutdown signal received! Stopping application..."
  if [ -n "$APP_PID" ]; then
    kill -TERM "$APP_PID" 2>/dev/null || true
    wait "$APP_PID"
  fi
  echo "✅ Cleanup complete. Exiting safely."
  exit 0
}

# Pasang Trap (SIGTERM = Stop di Proxmox, SIGINT = Ctrl+C)
trap 'shutdown_handler' TERM INT

# --- 3. LOGIKA EKSEKUSI APLIKASI ---

if [ "$#" -gt 0 ]; then
    # Jika ada argumen command (docker run ... bash)
    echo "▶️ Forwarding command: $@"
    "$@" &
    APP_PID=$!
    wait "$APP_PID"
elif [ -f "./app" ]; then
    # Jika ada binary ./app
    echo "🚀 Starting application binary..."
    ./app &
    APP_PID=$!
    wait "$APP_PID"
else
    # Mode Standby (Tail) jika kosongan
    echo "⏳ Standby mode active. Waiting for signal..."
    tail -f /dev/null &
    APP_PID=$!
    wait "$APP_PID"
fi
#!/bin/sh
set -e

TUNNEL_NAME=${DKA_TUNNEL_NAME:-$(hostname)}

createDNSRoute() {
  echo "🔍 Checking is DNS Is Exist for $TUNNEL_NAME..."
  # Cek dari cloudflared tunnel route list (DNS)
  if cloudflared tunnel route dns --list 2>/dev/null | grep -qw "$TUNNEL_NAME"; then
    echo "✅ DNS route for $TUNNEL_NAME exists, skip registration DNS route."
  else
    echo "🌐 Adding DNS route for $TUNNEL_NAME to $TUNNEL_ID..."
    cloudflared tunnel route dns "$TUNNEL_ID" "$TUNNEL_NAME"
    echo "✅ DNS route successfully added."
  fi
}

createConfig() {
  CONFIG_PATH="/root/.cloudflared/config.yml"
  echo "🛠️ Make config.yml in $CONFIG_PATH"
  cat <<-EOF > "$CONFIG_PATH"
  tunnel: $TUNNEL_ID
  credentials-file: $TUNNEL_JSON

  ingress:
    - hostname: ${TUNNEL_NAME:-example.com}
      service: http://localhost:80
    - service: http_status:404
EOF
  echo "✅ successfully created $CONFIG_PATH"
}

createTunnel() {
 if cloudflared tunnel list | grep -qw "$TUNNEL_NAME"; then
     echo "✅ Tunnel '$TUNNEL_NAME' is Exists, ignore recreate tunnel."
     TUNNEL_ID=$(cloudflared tunnel list --output json | grep -B 2 "\"name\": \"$TUNNEL_NAME\"" | grep '"id":' | cut -d'"' -f4)
     TUNNEL_JSON="/root/.cloudflared/$TUNNEL_ID.json"
   else
     echo "🚧 Tunnel '$TUNNEL_NAME' not exists, new create..."
     TUNNEL_CREATE_OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME")
     TUNNEL_JSON=$(echo "$TUNNEL_CREATE_OUTPUT" | grep -o '/root/.cloudflared/[^ ]*\.json')
     TUNNEL_ID=$(grep -o '"TunnelID"[ ]*:[ ]*"[^"]*"' "$TUNNEL_JSON" | cut -d'"' -f4)
   fi

   echo "🔑 TUNNEL_ID: $TUNNEL_ID"
   echo "📄 TUNNEL_JSON: $TUNNEL_JSON"
}

checkTunnelIsExist() {
  if [ -f "/root/.cloudflared/cert.pem" ]; then
    echo "Detected cloudflared configuration ..."
    createTunnel
    createConfig
    createDNSRoute
    cloudflared tunnel run "$TUNNEL_NAME" &
  else
    echo "🚧 not detected cloudflare tunnel configuration. skipped ..."
    echo "🚧 to used tunnel. running in exec -it with 'cloudflared tunnel login' and set hostname in service compose.yml file"
    echo "🚧 and create volume persistent to /root/.cloudflared to persistent volume. prevent loss cloudflared configuration"
  fi
}

# Tunggu jika tidak ada argumen, atau eksekusi argumen jika ada
if [ "$#" -gt 0 ]; then
    checkTunnelIsExist
    # If arguments exist, execute them
    exec "$@"
else
    # If no arguments were passed, check if package.json exists
    if [ -f "package.json" ]; then
        echo "Starting default entry point main in package.json"
        checkTunnelIsExist
        if { [ -f "bun.lockb" ] || [ -f "bun.lock" ]; } && command -v bun >/dev/null 2>&1; then
            echo "⚡ Detected Bun lockfile. Running with Bun..."
            bun .
        else
            echo "🟢 Running with Node..."
            node .
        fi
    else
        # If package.json doesn't exist, wait for background processes
        echo "package.json not found. recreated container with command. or create main point field in package.json file"
        tail -f /dev/null
    fi
fi
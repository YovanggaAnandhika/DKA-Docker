# ============================
# NGINX vhost (HTTP/1.1 + HTTP/2 + mTLS)
# ============================

# upstream ke app (Docker, dll)
upstream app_upstream {
    server ${APP_SERVICE_HOST}:${APP_SERVICE_PORT};
}

server {
    # TCP: HTTP/1.1 + TLS
    listen 443 ssl;

    # HTTP/2 aktif
    http2 on;

    server_name _;

    # ============================
    # TLS
    # ============================
    ssl_certificate     /etc/cert/server/certificate.crt;
    ssl_certificate_key /etc/cert/server/private.key;
    ssl_password_file   /etc/cert/server/passphrase.txt;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EECDH+CHACHA20:EECDH+AES256:!aNULL:!MD5:!DSS";

    # ============================
    # MUTUAL TLS (client cert)
    # ============================
    ssl_client_certificate /etc/cert/ca/certificate.crt;
    ssl_verify_client on;
    ssl_verify_depth 2;

    root /var/www;
    index index.html index.htm;

    access_log /dev/stdout;
    error_log /dev/stderr;

    # ============================
    # Routing
    # ============================
    location / {
        try_files $uri @app;
    }

    location ^~ /uploads/ {
        # langsung lempar ke upstream Node
        proxy_pass http://app_upstream;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        # kalau nggak pakai websocket di /uploads, gak perlu Upgrade/Connection
        # proxy_set_header Upgrade           $http_upgrade;
        # proxy_set_header Connection        "upgrade";

        # optional caching header di sisi client
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header X-Content-Type-Options "nosniff";
    }

    location @app {
        proxy_pass http://app_upstream;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "upgrade";

        # forward info mTLS ke backend
        # proxy_set_header X-Client-Cert       $ssl_client_cert;
        # proxy_set_header X-Client-Verify     $ssl_client_verify;
        # proxy_set_header X-Client-Subject-DN $ssl_client_s_dn;
        # proxy_set_header X-Client-Issuer-DN  $ssl_client_i_dn;
    }

    # hidden files
    location ~ /\. {
        deny all;
    }
}

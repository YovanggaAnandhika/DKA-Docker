# Use the official Alpine Linux image as a base
FROM rust:alpine3.21

# Maintainer Labels
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"

# 1. Install Packages
# Menggabungkan update dan install dalam satu layer (Standard Practice)
# Tambahkan 'pkgconfig' dan 'openssl-dev'
RUN apk update && apk add --no-cache pkgconfig protobuf-dev openssl-libs-static openssl-dev \
    musl-dev gcc cgroup-tools tzdata htop nano dcron logrotate bash rsync &&  \
    rm -rf /var/cache/apk/* && apk cache clean
# 2. Set timezone
ENV TZ=Asia/Makassar
# 3. Setup User & Directory
# Menggabungkan addgroup, adduser, dan setup direktori untuk efisiensi
RUN addgroup -g 1000 app && adduser -D -u 1000 -G app -h /home/app -s /bin/sh app
RUN mkdir -p /home/app && chown -R app:app /home/app && chmod 755 /home/app
# 4. Copy Set Default Work Dir
WORKDIR /home/app
# 5. Copy Scripts & Permissions
# --chown=root:root adalah default, tapi kita pastikan script sistem tetap milik root
# agar tidak bisa dimodifikasi oleh user 'app' (Security feature)
COPY config/bin /usr/local/bin/
# Make scripts executable
# Kita lakukan chmod di sini. Pastikan 'entrypoint.sh' ada di dalam folder 'config/bin'
RUN chmod +x /usr/local/bin/*
# 6. Switch User
# PENTING: Semua perintah CMD/ENTRYPOINT setelah baris ini akan dijalankan sebagai 'app'
USER app
# installing cargo watch
RUN cargo install cargo-watch
# 7. Start
ENTRYPOINT ["entrypoint.sh"]
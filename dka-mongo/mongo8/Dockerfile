FROM debian:12-slim

# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.title="Base Mongo"
LABEL org.opencontainers.image.description="Base Mongo"
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/yovanggaanandhika/mongo"
LABEL org.opencontainers.image.source="https://hub.docker.com/r/yovanggaanandhika/mongo"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.vendor="DKA Research Center Organization"
# Install dependencies in a single RUN command and clean up afterward
RUN apt-get update && apt-get install -y gnupg curl bash procps tzdata cron nano logrotate \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list  \
    && apt-get update && apt-get install -y --no-install-recommends mongodb-org mongodb-org-shell mongodb-org-tools mongodb-mongosh mongodb-org-mongos mongodb-org-database  \
    && rm -rf /var/lib/apt/lists/* && apt-get clean && rm -rf /tmp/* /var/tmp/*
# Generate a keyfile for replica set authentication
RUN openssl rand -base64 756 > /etc/mongo-keyfile && chmod 600 /etc/mongo-keyfile && chown mongodb:mongodb /etc/mongo-keyfile
# Create Default dB Path & Directories
RUN mkdir -p /data/db && chown mongodb:mongodb -R /data/db  \
    && mkdir -p /nonexistent && chown mongodb:mongodb -R /nonexistent \
    && mkdir -p /backup && chown -R mongodb:mongodb /backup \
    && mkdir -p /home/app && chown -R www-data:www-data /home/app && chmod -R 775 /home/app \
    && mkdir -p /entrypoint.d /docker-entrypoint-initdb.d
# Setting env
ENV TZ=Asia/Makassar
# --- Copy Configurations ---
COPY .config/etc/* /etc/
COPY .config/logrotate.d /etc/logrotate.d/
# --- Copy Scripts & Binaries ---
COPY .config/bin/* /usr/local/bin/
# Pastikan healthcheck.sh ikut tersalin di sini (atau tambahkan COPY khusus jika letaknya berbeda)
# Jika healthcheck.sh ada di .config/bin/, maka baris di atas sudah cukup.
# Copy backup script to the image (Cron)
COPY .config/cron/* /usr/cron.d/
RUN chmod -R 644 /usr/cron.d/* && chmod +x /usr/cron.d/*
# Local Bin scripts
COPY .config/cron/* /usr/local/bin/
# Ensure all binaries are executable
RUN chmod +x /usr/local/bin/*
# --- Copy Database Init Scripts ---
COPY .config/docker.entrypoint.d/* /docker-entrypoint-initdb.d/
COPY .config/entrypoint.d/* /entrypoint.d/
# set Working Dir
WORKDIR /home/app
# expose port
EXPOSE 27017
# --- Docker Native Healthcheck ---
# Ini akan mendeteksi status 'healthy'/'unhealthy' pada docker ps
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
  CMD ["/bin/bash", "/usr/local/bin/mongodb-healthcheck.sh", "liveness"]
# Set the entrypoint
ENTRYPOINT ["entrypoint.sh"]
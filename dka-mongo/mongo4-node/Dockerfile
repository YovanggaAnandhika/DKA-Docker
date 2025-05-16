FROM debian:10-slim
# Maintainer
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.title="Base Mongo With Nodejs & Mongo"
LABEL org.opencontainers.image.description="Base Mongo With Nodejs & Mongo"
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/yovanggaanandhika/mongo"
LABEL org.opencontainers.image.source="https://hub.docker.com/r/yovanggaanandhika/mongo"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.vendor="DKA Research Center Organization"
# Install dependencies in a single RUN command and clean up afterward
RUN apt-get update && apt-get install -y gnupg curl bash procps tzdata cron nano logrotate \
    && curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && apt-get install -y nodejs \
    && apt-get install -y openssl iputils-ping certbot python3-certbot-dns-cloudflare \
    && npm install -g yarn \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | gpg -o /usr/share/keyrings/mongodb-server-4.4.gpg --dearmor && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list  \
    && apt-get update && apt-get install -y --no-install-recommends mongodb-org=4.4.18 mongodb-org-shell=4.4.18 mongodb-org-tools=4.4.18 mongodb-mongosh mongodb-org-mongos \
    && rm -rf /var/lib/apt/lists/* && apt-get clean && rm -rf /tmp/* /var/tmp/*
# Generate a keyfile for replica set authentication
RUN openssl rand -base64 756 > /etc/mongo-keyfile && chmod 600 /etc/mongo-keyfile && chown mongodb:mongodb /etc/mongo-keyfile
# Create Default dB Path
RUN mkdir -p /data/db && chown mongodb:mongodb -R /data/db  \
    && mkdir -p /nonexistent && chown mongodb:mongodb -R /nonexistent \
    && mkdir -p /backup && chown -R mongodb:mongodb /backup \
    && mkdir -p /home/app && chown -R www-data:www-data /home/app && chmod -R 775 /home/app \
    && mkdir -p /entrypoint.d
# Setting env
ENV TZ=Asia/Makassar
# Copy Default Mongo Conf
COPY .config/etc/* /etc/
# Copy existing log rotate config
COPY .config/logrotate.d /etc/logrotate.d/
# Copy all bind folder & allow Execution
COPY .config/bin/* /usr/local/bin/
# Copy backup script to the image
COPY .config/cron/* /usr/cron.d/
RUN chmod -R 644 /usr/cron.d/* && chmod +x /usr/cron.d/*
# Local Bin & Create entrypoint.d directory and copy init.js
COPY .config/cron/* /usr/local/bin/
RUN chmod +x /usr/local/bin/* && mkdir -p /docker-entrypoint-initdb.d
COPY .config/docker.entrypoint.d/* /docker-entrypoint-initdb.d/
# Run Entrypoint JS After init
COPY .config/entrypoint.d/* /entrypoint.d/
#Set Working Dir
WORKDIR /home/app
# expose port
EXPOSE 27017 80
# Set the entrypoint
ENTRYPOINT ["entrypoint.sh"]


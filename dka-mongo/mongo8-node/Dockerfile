FROM debian:12-slim
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install dependencies in a single RUN command and clean up afterward
RUN apt-get update && apt-get install -y gnupg curl bash procps tzdata cron nano logrotate \
    && apt-get install -y openssl nodejs npm iputils-ping certbot python3-certbot-dns-cloudflare && npm install -g yarn \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list  \
    && apt-get update && apt-get install -y --no-install-recommends mongodb-org mongodb-org-shell mongodb-org-tools mongodb-mongosh mongodb-org-mongos mongodb-org-database  \
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
# Set Working Dir
WORKDIR /home/app
# expose port
EXPOSE 27017 80
# Set the entrypoint
ENTRYPOINT ["entrypoint.sh"]


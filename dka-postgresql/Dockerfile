# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Run update & Install Mariadb
RUN apk update && apk add --no-cache cgroup-tools tzdata htop nano dcron logrotate bash rsync \
    postgresql15 postgresql15-contrib postgresql15-client && rm -rf /var/cache/apk/*
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Copy existing log rotate config
COPY config/logrotate.d /etc/logrotate.d/
# Add Log System
RUN mkdir -p /var/log/postgresql && chown postgres:postgres /var/log/postgresql &&  \
    mkdir /backup && chown postgres:postgres /backup && chmod -R 755 /backup && \
    mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql && \
    mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql
# Add cron dir
COPY config/cron.d /usr/cron.d/
RUN chmod +x /usr/cron.d/*
# add Another Script
COPY config/bin /usr/local/bin/
# Copy initialization script
COPY config/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/*
COPY config/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
# Create Automation SQL
COPY config/docker-entrypoint.d /docker-entrypoint.d
RUN chown postgres:postgres /docker-entrypoint.d
# Set User Whoami
USER postgres
# Buka port untuk komunikasi Postgresql
EXPOSE 5432
# Use the entrypoint script to start the database
ENTRYPOINT ["entrypoint.sh"]
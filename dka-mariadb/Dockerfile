# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Run update & Install Mariadb
RUN apk update && apk add --no-cache cgroup-tools tzdata htop nano dcron logrotate bash rsync \
    mariadb mariadb-client mariadb-server-utils && rm -rf /var/cache/apk/*
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Copy Mariadb configuration file
COPY config/mysql/my.cnf /etc/my.cnf
# Copy existing log rotate config
COPY config/logrotate.d /etc/logrotate.d/
# Add Log System
RUN mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql &&  \
    mkdir /backup && chown mysql:mysql /backup && chmod -R 755 /backup && \
    mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld
# Add cron dir
COPY config/cron.d /usr/cron.d/
RUN chmod +x /usr/cron.d/*
# add Another Script
COPY config/bin /usr/local/bin/
# Copy initialization script
COPY config/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/*
COPY config/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
# Buka port untuk komunikasi MariaDB dan Galera
EXPOSE 3306
# Use the entrypoint script to start the database
ENTRYPOINT ["entrypoint.sh"]
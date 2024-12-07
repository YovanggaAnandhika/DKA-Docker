# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install Mariadb
RUN apk add --no-cache mariadb mariadb-client mariadb-server-utils
# Install tzdata
RUN apk add --no-cache tzdata
# Install Htop & nano
RUN apk add --no-cache htop nano
# Install cron for scheduling backups
RUN apk add --no-cache dcron
# Install logrotate
RUN apk add --no-cache logrotate
# Install bash
RUN apk add --no-cache bash
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Copy Mariadb configuration file
COPY config/mysql/my.cnf /etc/my.cnf
# Copy existing log rotate config
COPY config/logrotate.d /etc/logrotate.d/
# Add Log System
RUN mkdir -p /var/log/mysql
RUN chown mysql:mysql /var/log/mysql
# add backup directory
RUN mkdir /backup
RUN chown mysql:mysql /backup
RUN chmod -R 755 /backup
# Add cron dir
COPY config/cron.d /usr/cron.d/
RUN chmod +x /usr/cron.d/*
# add Another Script
COPY config/bin /usr/local/bin/
# Copy initialization script
COPY config/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/*
COPY config/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
# Expose the default MariaDB port
EXPOSE 3306
# Use the entrypoint script to start the database
ENTRYPOINT ["entrypoint.sh"]
# Start the MariaDB server
CMD ["mariadbd-safe"]
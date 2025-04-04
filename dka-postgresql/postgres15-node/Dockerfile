# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Run update & Install Mariadb
RUN apk update && apk add --no-cache openssl nodejs npm iputils-ping cgroup-tools tzdata htop nano dcron logrotate bash rsync  \
    certbot certbot-dns-cloudflare postgresql15 postgresql15-contrib postgresql15-client && \
    npm install -g yarn && \
    rm -rf /var/cache/apk/*
#############################################################################
# End Base Dependencies
#############################################################################
#----------------------------------------------------------------------------
RUN adduser -S www-data -G www-data
#############################################################################
# Adding Config
#############################################################################
WORKDIR /home/app
#############################################################################
# End Adding Config
#############################################################################
RUN chown -R www-data:www-data /home/app && chmod -R 775 /home/app
#############################################################################
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Copy existing log rotate config
COPY config/logrotate.d /etc/logrotate.d/
# Add Log System
RUN mkdir -p /var/log/postgresql && chown postgres:postgres /var/log/postgresql &&  \
    mkdir /backup && chown postgres:postgres /backup && chmod -R 755 /backup && \
    mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql && \
    mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql
# add Another Script
COPY config/bin /usr/local/bin/
# Copy initialization script
COPY config/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/*
COPY config/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
RUN chown postgres:postgres /docker-entrypoint-initdb.d
# Create Automation SQL
COPY config/docker-entrypoint.d /docker-entrypoint.d
RUN chown postgres:postgres /docker-entrypoint.d
# Set User Whoami
USER postgres
# Buka port untuk komunikasi Postgresql
EXPOSE 5432 80
# Use the entrypoint script to start the database
ENTRYPOINT ["entrypoint.sh"]
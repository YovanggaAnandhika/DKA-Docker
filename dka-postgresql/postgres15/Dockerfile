# Use the official Alpine Linux image as a base
FROM alpine:3.21
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.title="Base Postgresql Alpine Image"
LABEL org.opencontainers.image.description="DKA Alpine Base Postgresql Image"
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/yovanggaanandhika/postgresql"
LABEL org.opencontainers.image.source="https://hub.docker.com/r/yovanggaanandhika/postgresql"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.vendor="DKA Research Center Organization"
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
COPY config/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/*
RUN chown -R postgres:postgres /etc/cron.d/
COPY config/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
RUN chown postgres:postgres /docker-entrypoint-initdb.d
# healty check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=15s \
  CMD /usr/local/bin/healthcheck.sh
# Create Automation SQL
COPY config/docker-entrypoint.d /docker-entrypoint.d
RUN chown postgres:postgres /docker-entrypoint.d
# Set User Whoami
USER postgres
# Buka port untuk komunikasi Postgresql
EXPOSE 5432
# Use the entrypoint script to start the database
ENTRYPOINT ["entrypoint.sh"]
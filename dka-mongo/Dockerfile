FROM debian:12-slim as builder
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install dependencies in a single RUN command and clean up afterward
RUN apt-get update && apt-get install -y gnupg curl bash
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list
RUN apt-get update && apt-get install -y --no-install-recommends mongodb-org mongodb-org-shell mongodb-org-tools mongodb-mongosh mongodb-org-mongos mongodb-org-database
RUN rm -rf /var/lib/apt/lists/* && apt-get clean && rm -rf /tmp/* /var/tmp/*
# Generate a keyfile for replica set authentication
RUN openssl rand -base64 756 > /etc/mongo-keyfile && \
    chmod 600 /etc/mongo-keyfile && \
    chown mongodb:mongodb /etc/mongo-keyfile
# Create Default dB Path
RUN mkdir -p /data/db && chown mongodb:mongodb -R /data/db
# extend Setting
RUN mkdir -p /nonexistent
RUN chown mongodb:mongodb -R /nonexistent

FROM debian:12-slim as prod
COPY --from=builder /usr/local/bin /usr/local/bin/
COPY --from=builder /nonexistent /nonexistent/
COPY --from=builder /data/db /data/db/
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
RUN apt-get update && apt-get install -y gnupg curl bash

# Copy Default Mongo Conf
COPY .config/etc/* /etc/
# Copy all bind folder & allow Execution
COPY .config/bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*
# Create entrypoint.d directory and copy init.js
RUN mkdir -p /docker-entrypoint-initdb.d
COPY .config/entrypoint.d/* /docker-entrypoint-initdb.d/
# set User mongo
USER mongodb
# expose port
EXPOSE 27017
# Set the entrypoint
ENTRYPOINT ["entrypoint.sh"]

FROM debian:12-slim
# Install dependencies in a single RUN command and clean up afterward
RUN apt-get update && \
    apt-get install -y gnupg curl && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends mongodb-org mongodb-org-shell mongodb-org-tools mongodb-mongosh mongodb-org-mongos mongodb-org-database && \
    rm -rf /var/lib/apt/lists/*
# Generate a keyfile for replica set authentication
RUN openssl rand -base64 756 > /etc/mongo-keyfile && \
    chmod 400 /etc/mongo-keyfile && \
    chown mongodb:mongodb /etc/mongo-keyfile
# Copy Default Mongo Conf
COPY etc/* /etc/
# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
# Create entrypoint.d directory and copy init.js
RUN mkdir -p /docker-entrypoint-initdb.d
COPY entrypoint.d/* /docker-entrypoint-initdb.d/
EXPOSE 27017
# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

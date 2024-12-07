# Get Image From Docker Hub
FROM debian:bookworm-slim AS app
# Add Author Info
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Update and install required packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends gnupg openssl nodejs npm curl bash nano iputils-ping ca-certificates tzdata openssh-server
# Import MongoDB GPG key and add MongoDB repository
RUN curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
# Install Yarn globally
RUN npm install -g yarn
# Install MongoDB
RUN apt-get update && apt-get install -y mongodb-org mongodb-org-shell
RUN rm -rf /var/lib/apt/lists/*
# Set timezone
ENV TZ=Asia/Makassar
# Create app directory
RUN mkdir /home/app
# Set Working Directory
WORKDIR /home/app
# Copy SSH Config
COPY .config/ssh /etc/ssh
# Add MongoDB Config (if needed)
COPY .config/mongo/etc/* /etc/
# Delete SRC Folder and .config after building
RUN rm -rf src .config
# Create SSHD Run
RUN mkdir -p /run/sshd
# Expose Ports
EXPOSE 80 22 27017
# Copy All Entrypoint
COPY .config/mongo/entrypoint-initdb.d /docker-entrypoint-initdb.d
# Copy Entry point
COPY .config/entrypoint.sh /usr/local/bin/entrypoint.sh
# allow Execution
RUN chmod +x /usr/local/bin/entrypoint.sh
# Set the entrypoint script as the default command
ENTRYPOINT ["entrypoint.sh"]

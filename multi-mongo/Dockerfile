FROM mongo:latest

MAINTAINER "Yovangga Anandhika Hadi Putra <dka.tech.dev@gmail.com>"

VOLUME /data
WORKDIR /
# Install openssl
RUN apt-get update && apt-get install -y openssl
# Create the keyfile directory
RUN openssl rand -base64 741 > /data/configdb/keyfile
RUN chmod 400 /data/configdb/keyfile
COPY ./init-replica.sh /docker-entrypoint-initdb.d/init-replica.sh
RUN chmod +x ./docker-entrypoint-initdb.d/init-replica.sh

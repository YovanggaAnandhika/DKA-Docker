# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Installing Radius
RUN apk add --no-cache nano bash openssl freeradius freeradius-utils freeradius-mysql freeradius-postgresql \
    freeradius-radclient freeradius-perl freeradius-sqlite \
    libressl libressl-dev libpcap
RUN rm -rf /var/cache/apk/*
# Create necessary directories
#RUN mkdir -p /etc/raddb /var/log/radius /var/run/radius
# Set Working Dir
WORKDIR /app
# Configure entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# set Execution bin dir
RUN chmod +x /usr/local/bin/*
# Expose RADIUS standard ports
EXPOSE 1812/udp 1813/udp
# Set the entrypoint to the script
ENTRYPOINT ["entrypoint.sh"]
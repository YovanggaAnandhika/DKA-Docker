# Use Alpine as the base image
FROM alpine:latest
# Maintainer
MAINTAINER "Yovangga Anandhika Hadi Putra <dka.tech.dev@gmail.com>"
# Install iptables
RUN apk add --no-cache iptables
# Create the /etc/iptables folder in the Docker image
RUN mkdir -p /etc/iptables

# Copy the etc folder from the host to the Docker image
COPY etc/ /etc/
# Copy Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Make Entrypoint executable
RUN chmod +x /usr/local/bin/entrypoint.sh
# Set the user to root to ensure permissions for the entrypoint
USER root
# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]

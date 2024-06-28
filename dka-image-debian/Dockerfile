# Use the official Debian slim image
FROM debian
# Switch to root user to execute privileged commands
USER root
# Update package list and install any updates
RUN apt-get update && apt-get upgrade -y && apt-get clean
# Install iptables if not already installed
RUN apt-get install -y iptables
# Copy the iptables rules file into the image
COPY ./Security/iptables/rules.v4 /etc/iptables/rules.v4
# Ensure proper permissions on the rules file
RUN chmod 644 /etc/iptables/rules.v4


# Command to run on container start
CMD ["sh"]

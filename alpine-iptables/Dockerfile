FROM alpine:3.20
#############################################################################
# Installing Base Dependencies
#############################################################################
# Install iptables
RUN apk update
RUN apk --no-cache add iptables
RUN mkdir -p /etc/iptables
COPY .config/etc/iptables/* /etc/iptables/
#############################################################################
# End Installing Base Dependencies
#############################################################################
USER root
RUN echo 1 > /proc/sys/net/ipv4/ip_forward
#############################################################################
# Start Set Config
#############################################################################
COPY .config/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN ls -l /usr/local/bin/entrypoint.sh  # Debug line to verify file is copied
#############################################################################
# End Set Config
#############################################################################
# Remove Src folder
RUN rm -rf src .config
# adding Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM alpine:3.22
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.title="Base Node Alpine Image"
LABEL org.opencontainers.image.description="DKA Alpine Base NodeJS Image"
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/yovanggaanandhika/node"
LABEL org.opencontainers.image.source="https://hub.docker.com/r/yovanggaanandhika/node"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.vendor="DKA Research Center Organization"

ARG TARGETARCH
# Update Repo
RUN apk update && apk add --no-cache openssl nodejs npm bash nano iputils-ping eudev-libs libusb tzdata curl protobuf-dev qt5-qtbase qt5-qtbase-x11 poppler-qt5 openresolv jq && npm install -g yarn
# remove cache and apt cleancertbot certbot-dns-cloudflare
RUN rm -rf /var/cache/apk/* && apk cache clean
#############################################################################
# End Base Dependencies
#############################################################################
#----------------------------------------------------------------------------
RUN adduser -S www-data -G www-data
#############################################################################
# Adding Directory
#############################################################################

#############################################################################
# Adding Config
#############################################################################
WORKDIR /home/app
#############################################################################
# End Adding Config
#############################################################################
RUN chown -R www-data:www-data /home/app && chmod -R 775 /home/app
#############################################################################
# Adding ENV Script
#############################################################################
ENV TZ=Asia/Makassar
#############################################################################
# End ENV Script
#############################################################################
#----------------------------------------------------------------------------
#############################################################################
# Set Entrypoint Script
#############################################################################
COPY .config /usr/local/bin/
RUN chmod +x /usr/local/bin/*
#############################################################################
# End Entrypoint Script
#############################################################################
# healty check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=15s \
  CMD /usr/local/bin/healthcheck.sh
#----------------------------------------------------------------------------
#----------------------------------------------------------------------------
# Adding Entrypoint
ENTRYPOINT ["entrypoint.sh"]
#----------------------------------------------------------------------------
# Run Default CMD

#----------------------------------------------------------------------------

FROM alpine:3.21
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
# Update Repo
RUN apk update && apk add --no-cache openssl nodejs npm bash nano iputils-ping tzdata certbot certbot-dns-cloudflare && npm install -g yarn
RUN rm -rf /var/cache/apk/* && apk cache clean
#############################################################################
# End Base Dependencies
#############################################################################
#----------------------------------------------------------------------------
RUN adduser -S www-data -G www-data
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
COPY .config/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/*
#############################################################################
# End Entrypoint Script
#############################################################################
#----------------------------------------------------------------------------
#----------------------------------------------------------------------------
# Adding Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
#----------------------------------------------------------------------------
# Run Default CMD

#----------------------------------------------------------------------------

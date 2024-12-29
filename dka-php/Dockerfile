# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install tzdata
RUN apk add --no-cache tzdata
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Install Nginx
RUN apk add --no-cache nginx
# Install Required PHP Extensions
RUN apk add --no-cache libxml2-dev
RUN apk add --no-cache oniguruma-dev
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS
RUN apk add --no-cache json-c-dev
RUN apk add --no-cache libpng-dev
RUN apk add --no-cache libjpeg-turbo-dev
RUN apk add --no-cache freetype-dev
RUN apk add --no-cache curl-dev

RUN apk add --no-cache bash
RUN apk add --no-cache libzip-dev
RUN apk add --no-cache zlib-dev
RUN apk add --no-cache icu-dev
RUN apk add --no-cache gettext-dev
RUN apk add --no-cache nano iputils-ping
RUN apk add --no-cache curl zip multitail
RUN apk add --no-cache libxml2-dev
# Install PHP and its extensions
RUN apk add --no-cache php
RUN apk add --no-cache php83-ctype
RUN apk add --no-cache php83-fpm
RUN apk add --no-cache php83-dom
RUN apk add --no-cache php83-mysqli
RUN apk add --no-cache php83-opcache
RUN apk add --no-cache php83-mbstring
RUN apk add --no-cache php83-xml
RUN apk add --no-cache php83-zip
RUN apk add --no-cache php83-curl
RUN apk add --no-cache php83-gd
RUN apk add --no-cache php83-bcmath
RUN apk add --no-cache php83-intl
RUN apk add --no-cache php83-soap
RUN apk add --no-cache php83-pdo
RUN apk add --no-cache php83-pdo_mysql
RUN apk add --no-cache php83-gettext
RUN apk add --no-cache php83-session
RUN apk add --no-cache php83-tokenizer
RUN apk add --no-cache php83-cli
RUN apk add --no-cache php83-phar
RUN apk add --no-cache php83-json
RUN apk add --no-cache php83-iconv
RUN apk add --no-cache php83-openssl
RUN apk add --no-cache php83-mysqlnd
RUN apk add --no-cache php83-intl
RUN apk add --no-cache php83-xmlwriter
RUN apk add --no-cache php83-fileinfo
RUN apk add --no-cache php83-sqlite3
RUN apk add --no-cache php83-pdo_sqlite

# Create a user
RUN adduser -S www-data -G www-data
# Copy Nginx configuration file
COPY .config/nginx /etc/nginx
# Copy PHP-FPM configuration file
COPY .config/php /etc/php83
# Create the application directory
RUN mkdir -p /var/www
COPY www /var/www
# Create Log Dir
COPY .config/log /var/log/
# Create the run directory
RUN mkdir -p /var/run/php
# Set permissions
RUN chown -R www-data:www-data /var/www
RUN find /var/www -type d -exec chmod 774 {} \;
RUN find /var/www -type f -exec chmod 774 {} \;
# Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
# Set the working directory
WORKDIR /var/www
# Configure entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# set Execution bin dir
RUN chmod +x /usr/local/bin/*
# Expose ports
EXPOSE 80 443
# Set the entrypoint to the script
ENTRYPOINT ["entrypoint.sh"]


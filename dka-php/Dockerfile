# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install apk system
RUN apk add --no-cache nginx tzdata json-c-dev libpng-dev libjpeg-turbo-dev freetype-dev curl-dev bash \
    libzip-dev zlib-dev icu-dev gettext-dev iputils-ping curl zip libxml2-dev \
    libxml2-dev oniguruma-dev --virtual .build-deps $PHPIZE_DEPS
# Install PHP and its extensions
RUN apk add --no-cache php php83-ctype php83-fpm php83-dom php83-mysqli php83-opcache \
    php83-mbstring php83-xml php83-zip php83-curl php83-gd php83-bcmath php83-intl php83-soap php83-pdo \
    php83-pdo_mysql php83-gettext php83-session php83-tokenizer php83-cli php83-phar php83-json php83-iconv php83-openssl \
    php83-mysqlnd php83-intl php83-xmlwriter php83-fileinfo php83-sqlite3 php83-pdo_sqlite
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Create a user
RUN adduser -S www-data -G www-data
# Create the application directory
RUN mkdir -p /var/www && mkdir -p /var/run/php
# Copy Example Root apps
COPY www /var/www
# Copy Nginx configuration file
COPY .config/nginx /etc/nginx
# Copy PHP-FPM configuration file
COPY .config/php /etc/php83
# Create Log Dir
COPY .config/log /var/log/
# Set permissions
RUN chown -R www-data:www-data /var/www && find /var/www -type d -exec chmod 774 {} \; && find /var/www -type f -exec chmod 774 {} \;
# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
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


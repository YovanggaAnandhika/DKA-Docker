# Use the official Alpine Linux image as a base
FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install system packages & PHP + build deps
RUN apk update && apk add --no-cache \
  tzdata bash nano curl git zip unzip openssl \
  nginx nodejs npm \
  iputils iproute2 \
  certbot certbot-dns-cloudflare \
  imagemagick imagemagick-dev \
  libpng-dev libjpeg-turbo-dev freetype-dev libzip-dev zlib-dev \
  icu-dev gettext-dev libxml2-dev oniguruma-dev \
  php php83 php83-fpm php83-cli php83-common php83-opcache php83-phar php83-ctype \
  php83-curl php83-dom php83-exif php83-fileinfo php83-gd php83-gettext php83-iconv \
  php83-intl php83-json php83-mbstring php83-mysqli php83-mysqlnd php83-pdo \
  php83-pdo_mysql php83-pdo_sqlite php83-simplexml php83-soap php83-sockets \
  php83-sodium php83-sqlite3 php83-session php83-tokenizer php83-xml php83-xmlreader \
  php83-xmlwriter php83-zip php83-openssl php83-ldap \
  autoconf g++ make php83-dev php83-pear \
  && npm install -g yarn \
  && pecl install imagick \
  && echo "extension=imagick.so" > /etc/php83/conf.d/00_imagick.ini \
  && rm -rf /tmp/pear /var/cache/apk/*
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Create a user
RUN adduser -S www-data -G www-data
# Create the application directory
RUN mkdir -p /var/www && mkdir -p /var/run/php
# Copy Nginx configuration file
COPY .config/nginx /etc/nginx
# Copy PHP-FPM configuration file
COPY .config/php /etc/php83
# Create Log Dir
COPY .config/log /var/log/
# Set permissions
RUN chown -R www-data:www-data /var/www && find /var/www -type d -exec chmod 774 {} \; && find /var/www -type f -exec chmod 774 {} \;
# hapus folder bawaan nginx
RUN rm -rf /var/www/localhost
# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
# Set the working directory
WORKDIR /var/www
# Install Laravel On Global
RUN composer create-project laravel/laravel .
# set permission laravel storage
RUN chown -R www-data:www-data storage database bootstrap/cache && chmod -R 775 storage database bootstrap/cache
# Configure entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# set Execution bin dir
RUN chmod +x /usr/local/bin/*
# Expose ports
EXPOSE 80
# Set the entrypoint to the script
ENTRYPOINT ["entrypoint.sh"]
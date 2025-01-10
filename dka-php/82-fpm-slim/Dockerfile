# Use the official Alpine Linux image as a base
FROM alpine:3.20.3
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install apk system
RUN apk add --no-cache nginx tzdata json-c-dev libpng-dev libjpeg-turbo-dev freetype-dev curl-dev bash \
    libzip-dev zlib-dev icu-dev gettext-dev iputils-ping curl zip libxml2-dev \
    libxml2-dev oniguruma-dev --virtual .build-deps $PHPIZE_DEPS
# Install PHP and its extensions
RUN apk add --no-cache php82 php82-ctype php82-fpm php82-dom php82-mysqli php82-opcache \
    php82-mbstring php82-xml php82-zip php82-curl php82-gd php82-bcmath php82-intl php82-soap php82-pdo \
    php82-pdo_mysql php82-gettext php82-session php82-tokenizer php82-cli php82-phar php82-json php82-iconv php82-openssl \
    php82-mysqlnd php82-intl php82-xmlwriter php82-fileinfo php82-sqlite3 php82-pdo_sqlite php82-simplexml php82-xmlreader
# Set the timezone (e.g., Asia/Makassar)
ENV TZ=Asia/Makassar
# Create a user
RUN adduser -S www-data -G www-data
# Create the application directory
RUN mkdir -p /var/www && mkdir -p /var/run/php && mkdir -p /usr/local/bin
# Copy Example Root apps
COPY www /var/www
# Copy Nginx configuration file
COPY .config/nginx /etc/nginx
# Copy PHP-FPM configuration file
COPY .config/php /etc/php82
# Create Log Dir
COPY .config/log /var/log/
# Set permissions
RUN chown -R www-data:www-data /var/www && find /var/www -type d -exec chmod 774 {} \; && find /var/www -type f -exec chmod 774 {} \;
# alises
RUN ln -s $(which php82) /usr/bin/php
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


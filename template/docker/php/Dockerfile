ARG PHP_IMAGE=php:8.2-fpm-bookworm
FROM ${PHP_IMAGE}

LABEL description="Universal PHP-FPM image for Bitrix projects"

ARG ENABLE_XDEBUG=0

RUN apt-get update && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        libzip-dev \
        unzip \
        curl \
        git \
        libxml2-dev \
        libicu-dev \
        libonig-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libc-client-dev \
        libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo_mysql \
        mbstring \
        gd \
        intl \
        zip \
        opcache \
        bcmath \
        exif \
        soap \
        sockets \
    && pecl install apcu \
    && docker-php-ext-enable apcu

COPY php.ini /usr/local/etc/php/conf.d/bitrix.ini
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY xdebug.ini /tmp/xdebug.ini

RUN if [ "$ENABLE_XDEBUG" = "1" ]; then \
        pecl install xdebug \
        && docker-php-ext-enable xdebug \
        && cp /tmp/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini; \
    fi

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

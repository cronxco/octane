FROM dunglas/frankenphp:1.12.2-php8-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    nodejs \
    npm \
    git \
    curl \
    unzip \
    bash

# Install PHP extensions required by Spark
RUN install-php-extensions \
    pdo_pgsql \
    pgsql \
    redis \
    opcache \
    pcntl \
    intl \
    zip \
    bcmath \
    mbstring

# Install Composer globally
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Use production PHP ini
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# OPcache tuning for production (files are immutable between Octane restarts)
RUN echo "opcache.enable=1" >> "$PHP_INI_DIR/php.ini" && \
    echo "opcache.validate_timestamps=0" >> "$PHP_INI_DIR/php.ini" && \
    echo "opcache.memory_consumption=256" >> "$PHP_INI_DIR/php.ini" && \
    echo "opcache.max_accelerated_files=20000" >> "$PHP_INI_DIR/php.ini"

WORKDIR /var/www/spark/current

# FrankenPHP listens on plain HTTP — TLS is terminated at Jupiter
ENV SERVER_NAME=":80"

# Default command: start Octane with FrankenPHP in worker mode
CMD ["php", "artisan", "octane:frankenphp", \
     "--host=0.0.0.0", \
     "--port=80", \
     "--workers=4", \
     "--max-requests=500"]

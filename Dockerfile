FROM php:7.2-apache

# Buster is EOL — repoint apt at the Debian archive and disable expiry checks
RUN echo "deb http://archive.debian.org/debian buster main contrib non-free" > /etc/apt/sources.list \
 && echo "deb http://archive.debian.org/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list \
 && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

# System dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libmcrypt-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    zip \
    unzip \
    git \
    curl \
 && docker-php-ext-install pdo_mysql mbstring zip \
 && docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr \
 && docker-php-ext-install gd \
 && pecl install mcrypt-1.0.3 \
 && docker-php-ext-enable mcrypt

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Apache config
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

WORKDIR /var/www/html

# App source
COPY . /var/www/html

# Generate .env from sample (real deployments should mount/inject a proper .env instead)
RUN cp .env.sample .env

# Install PHP dependencies
RUN composer install --no-interaction --optimize-autoloader

# Generate a real Laravel application key
RUN php artisan key:generate

# Permissions
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 775 storage bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]
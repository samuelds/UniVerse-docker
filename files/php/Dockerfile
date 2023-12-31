# .phpize-deps $PHPIZE_DEPS
# .build-deps

ARG PHP_VERSION=latest
#ARG HOST_UID=1000
#ARG HOST_GID=1000

#--------------------------------------
# PHP-FPM
#--------------------------------------
FROM php:${PHP_VERSION}-fpm-alpine as fpm

# Optional, force UTC as server time
RUN apk add --no-cache tzdata shadow
RUN echo "Europe/Paris" > /etc/timezone

# Install dependencies
ARG PHP_EXTENSIONS="apcu xdebug intl intl opcache pdo pdo_mysql zip http gd gmp imagick soap xsl"
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions $PHP_EXTENSIONS

# Change current directory to the location of the application files
WORKDIR /var/www/app

# Define permissions for the application files
RUN chown -R www-data:www-data /var/www/html
RUN mkdir -p /var/www/app && chown -R www-data:www-data /var/www/app

# Set user default user to www-data
USER www-data

# Expose port 9000 for PHP-FPM  
EXPOSE 9000

# Command to run when the container is started
CMD ["php-fpm"]

#--------------------------------------
# Composer
#--------------------------------------
FROM php:${PHP_VERSION}-cli-alpine as composer

# Optional, force UTC as server time
RUN apk add --no-cache tzdata shadow
RUN echo "Europe/Paris" > /etc/timezone

# Install dependencies
ARG PHP_EXTENSIONS="apcu xdebug intl intl opcache pdo pdo_mysql zip http gd gmp imagick soap xsl"
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions $PHP_EXTENSIONS

# Change current directory to the location of the application files
WORKDIR /var/www/app

# Define permissions for the application files
RUN chown -R www-data:www-data /var/www/html
RUN mkdir -p /var/www/app && chown -R www-data:www-data /var/www/app

# Set user default user to www-data
USER www-data

# Install composer form the official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
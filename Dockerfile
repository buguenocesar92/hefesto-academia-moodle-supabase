FROM php:8.3-apache-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl libpq-dev libicu-dev libzip-dev libpng-dev libjpeg62-turbo-dev \
    libfreetype6-dev libxml2-dev libonig-dev libsodium-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j2 pgsql intl zip gd soap mbstring opcache exif \
 && rm -rf /var/lib/apt/lists/*
ARG MOODLE_URL=https://download.moodle.org/download.php/direct/stable503/moodle-5.3.tgz
ARG MOODLE_SHA256=7e5edf110555956571f40e42acffde0eb23681ebebd212a2fec0fe7d795dd511
RUN curl -fL --retry 3 "$MOODLE_URL" -o /tmp/moodle.tgz \
 && echo "$MOODLE_SHA256  /tmp/moodle.tgz" | sha256sum -c - \
 && tar -xzf /tmp/moodle.tgz -C /var/www \
 && rm /tmp/moodle.tgz \
 && test -f /var/www/moodle/admin/cli/install_database.php \
 && test -f /var/www/moodle/public/index.php \
 && mkdir -p /var/moodledata && chown www-data:www-data /var/moodledata
COPY docker/apache.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/hefesto.ini
COPY docker/config.php /var/www/moodle/config.php
COPY scripts /opt/hefesto
COPY branding /opt/branding
RUN chmod +x /opt/hefesto/*.sh \
 && for f in /opt/hefesto/*.php /var/www/moodle/config.php; do php -l "$f" || exit 1; done \
 && a2enmod rewrite headers
WORKDIR /var/www/moodle
ENTRYPOINT ["/opt/hefesto/entrypoint.sh"]
CMD ["apache2-foreground"]
RUN printf "ok\n" > /var/www/moodle/public/healthz.txt

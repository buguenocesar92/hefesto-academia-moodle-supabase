# =============================================================================
# CVE-2026-109618 / CVE-2026-109619 (PHP2Shell, 2026-10-22)
# CVE-2026-126714 (GHSA-fm2m-fjf5-v3cp, 2026-11-19)
# =============================================================================
# La imagen se construye con PHP 8.3.37, que es la version PARCHEADA de las
# dos series que tocan a esta imagen:
#   - PHP2Shell (CVE-2026-109618 / CVE-2026-109619): 8.2.35 / 8.3.36 / 8.4.27 / 8.5.12
#   - CVE-2026-126714 (GHSA-fm2m-fjf5-v3cp):          8.2.36 / 8.3.37 / 8.4.28 / 8.5.13
#
# Verificado el 2026-11-19, con el tag y el digest exactos:
#
#     $ docker buildx imagetools inspect php:8.3.37-apache-bookworm
#     Digest: sha256:d60f7be79a869deb1562b6ecb2f555bccb65c8dd4af930b50ae4d14d4bd4696c
#
# La base va FIJA por tag Y digest. Antes era un tag flotante
# (`php:8.3-apache-bookworm`, que hoy resuelve a PHP 8.3.36, la parcheada de
# PHP2Shell pero no la de CVE-2026-126714): ahora es `php:8.3.37-apache-bookworm`
# con su digest, que no puede mudar sin que se note en el diff. La comprobacion
# sigue igual en el candado (scripts/verificar-*.php), que falla si la base
# vuelve a quedar por debajo de la version parcheada.
#
# OJO: LA IMAGEN DESPLIEGADA HAY QUE RECONSTRUIRLA. El parche de PHP entra en
# el contenedor por la IMAGEN, no por este repositorio: mientras no se
# reconstruya y se redespliegue, el contenedor sigue con el PHP viejo. El
# endurecimiento de mas abajo (el ini y el archivo de Apache) es la red de seguridad
# para ese mientras, y lo que sobrevive a un redeploy.
FROM php:8.3.37-apache-bookworm@sha256:d60f7be79a869deb1562b6ecb2f555bccb65c8dd4af930b50ae4d14d4bd4696c
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
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

# Endurecimiento PHP2Shell (CVE-2026-109618 / CVE-2026-109619):
# la via CONFIRMADA (session.upload_progress) apagada, y los hijos de
# Apache reciclados cada 100 peticiones.
COPY docker/99-php2shell-hardening.ini /usr/local/etc/php/conf.d/99-php2shell-hardening.ini
COPY docker/zz-php2shell-apache.conf /etc/apache2/conf-available/zz-php2shell-hardening.conf

# Mitigacion CVE-2026-126714 (GHSA-fm2m-fjf5-v3cp): el save handler «files» de
# ext-session reescribe el archivo de sesion sin truncarlo; una escritura
# interrumpida mezcla sesion nueva y vieja y permite inyectar objetos al
# deserializar. Se apaga el vector (session.upload_progress) y se endurece el
# formato de sesion nativo.
COPY docker/php/99-security-cve-2026-126714.ini /usr/local/etc/php/conf.d/99-security-cve-2026-126714.ini
COPY docker/config.php /var/www/moodle/config.php
COPY scripts /opt/hefesto
COPY branding /opt/branding
RUN chmod +x /opt/hefesto/*.sh \
 && for f in /opt/hefesto/*.php /var/www/moodle/config.php; do php -l "$f" || exit 1; done \
 && a2enmod rewrite headers \
 && a2enconf zz-php2shell-hardening \
 && php /opt/hefesto/verificar-endurecimiento-php2shell.php --imagen
WORKDIR /var/www/moodle
ENTRYPOINT ["/opt/hefesto/entrypoint.sh"]
CMD ["apache2-foreground"]
RUN printf "ok\n" > /var/www/moodle/public/healthz.txt

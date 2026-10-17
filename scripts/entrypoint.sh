#!/bin/sh
set -eu
if [ "$(id -u)" = 0 ]; then
  mkdir -p /var/moodledata
  chown www-data:www-data /var/moodledata
  chmod 0770 /var/moodledata
fi
exec docker-php-entrypoint "$@"

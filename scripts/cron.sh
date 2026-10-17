#!/bin/sh
set -eu
while :; do
  if [ -f /var/moodledata/.hefesto-installed ]; then
    php /var/www/moodle/admin/cli/cron.php || echo 'Cron fallo: revisar logs' >&2
  fi
  sleep 60 &
  wait $!
done

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'Instalacion nativa de Moodle: exige esquema vacio y acepta licencia GPL de Moodle.'
read -r -p 'Escribe ACEPTO para continuar: ' acceptance
[[ "$acceptance" == ACEPTO ]] || exit 1
docker compose exec -T --user www-data web php /opt/hefesto/preflight.php
read -r -p 'Correo administrador: ' admin_email
read -r -s -p 'Clave administrador (14+ caracteres, mayusculas, minusculas, numeros y simbolos): ' admin_password
printf '\n'
printf '%s\n%s\n' "$admin_password" "$admin_email" | docker compose exec -T --user www-data web php -d disable_functions=cli_set_process_title /opt/hefesto/install.php
unset admin_password
docker compose exec -T --user www-data web php /opt/hefesto/brand.php
docker compose exec -T --user www-data web touch /var/moodledata/.hefesto-installed
echo 'Instalacion terminada. Configura SMTP y prueba alumno, actividad y cron.'

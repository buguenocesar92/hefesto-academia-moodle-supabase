# Validacion y limites

Preparado 14-10-2026. Archivo oficial Moodle 5.3 descargado y SHA-256 comparado con checksum oficial: 7e5edf110555956571f40e42acffde0eb23681ebebd212a2fec0fe7d795dd511.

Se inspeccionaron rutas reales en el tar: public/index.php, config-dist.php, lib/setup.php y admin/cli/install_database.php. Se revisaron opciones del driver PostgreSQL y del instalador. Las rutas CLI permanecen fuera de public. La configuracion se basa en ellas, no en la estructura de Moodle antiguo.

Validaciones locales: estructura ZIP, scripts shell y parseo de configuracion Compose. El build incluye comprobaciones de rutas y sintaxis PHP. No habia Docker ni PHP disponibles en el entorno de preparacion: no se ejecuto imagen, compilacion de extensiones, instalacion Moodle, SMTP, carga ni conexion Supabase. Se requieren esas comprobaciones en staging antes de produccion. Healthcheck HTTP comprueba Apache, no estado de DB ni cron.

No contiene secreto ni contenido real del cliente. Integraciones, plugins comerciales y migracion desde prototipos pendientes segun alcance. No se publico una nueva demo de Academia que simule Moodle.

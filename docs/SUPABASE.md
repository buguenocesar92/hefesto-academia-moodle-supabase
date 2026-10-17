# Base de datos

Moodle 5.3 requiere PostgreSQL 17+. Confirma en Supabase SQL Editor: `SHOW server_version;`. Si tu proyecto usa otra version, actualiza por la via soportada o crea uno compatible; no instales 5.3 sobre PostgreSQL 15/16.

Usa un proyecto dedicado para esta academia. Ejecuta el SQL provisto como administrador; la aplicacion usa solo moodle_app. En Connect copia el host **Direct connection**, puerto 5432, database postgres. La clave es la del rol moodle_app que definiste, no la clave anon ni service_role.

Este paquete soporta conexion directa. El host directo puede requerir IPv6 o el complemento IPv4 de Supabase: verificar red del VPS antes de comprar/desplegar. No cambiar a transaction pooler 6543. Session pooler 5432 requiere adaptar y probar opciones de sesion del driver Moodle y esta fuera de la configuracion entregada.

SSL: require cifra el trafico, pero no verifica identidad del servidor. Recomendado en produccion: descargar CA del proyecto, guardarla en certs/supabase-ca.crt y usar DB_SSL=verify-full. En Coolify montar el certificado en esa misma ruta en ambos contenedores. No desactivar SSL para resolver errores.

No exponer el esquema moodle en Data API ni permitir anon/authenticated. Moodle aplica sus roles y permisos: no agregar RLS a sus tablas sin un proyecto especifico de compatibilidad. No modificar tablas Moodle desde frontend Supabase, Odoo o n8n; usar API Moodle autorizada.

Archivos, entregas, sesiones y caches viven en moodledata. Un backup de Supabase no los incluye. Supabase Auth no maneja las cuentas de Moodle. Supabase Storage requeriria un plugin compatible, no incluido.

Fuentes: https://moodledev.io/general/releases/5.3 y https://supabase.com/docs/guides/database/connecting-to-postgres
